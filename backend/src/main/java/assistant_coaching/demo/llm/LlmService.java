package assistant_coaching.demo.llm;

import assistant_coaching.demo.goalchat.FallbackCoachFormatter;
import assistant_coaching.demo.goalchat.FallbackCoachFormatter.AnswerValue;
import assistant_coaching.demo.goalchat.FallbackCoachFormatter.FallbackMessage;
import assistant_coaching.demo.goalchat.GoalQuestionBank;
import assistant_coaching.demo.model.CoachingSession;
import assistant_coaching.demo.model.FinancialGoal;
import assistant_coaching.demo.model.InteractionLog;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;

import java.text.Normalizer;
import java.time.Duration;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class LlmService {

    private static final Logger log = LoggerFactory.getLogger(LlmService.class);

    private final OpenAiProperties properties;
    private final WebClient webClient;
    private final GoalQuestionBank questionBank;
    private final FallbackCoachFormatter fallbackFormatter;
    private final Map<Long, FallbackState> fallbackStates = new ConcurrentHashMap<>();

    public LlmService(OpenAiProperties properties, WebClient webClient, GoalQuestionBank questionBank,
                      FallbackCoachFormatter fallbackFormatter) {
        this.properties = properties;
        this.webClient = webClient;
        this.questionBank = questionBank;
        this.fallbackFormatter = fallbackFormatter;
    }

    public LlmResult generateReply(CoachingSession session, List<InteractionLog> history, String transcript) {
        recordFallbackAnswer(session, transcript);

        List<LlmMessage> messages = new ArrayList<>();
        messages.add(new LlmMessage("system", properties.getSystemPrompt()));

        Optional<String> focusGoal = Optional.ofNullable(session.getFocusGoal()).map(FinancialGoal::getTitle);
        focusGoal.ifPresent(goal -> messages.add(new LlmMessage("user", "Objectif cible : " + goal)));

        history.forEach(logEntry -> {
            if (logEntry.getUserInput() != null && !logEntry.getUserInput().isBlank()) {
                messages.add(new LlmMessage("user", logEntry.getUserInput()));
            }
            if (logEntry.getAssistantReply() != null && !logEntry.getAssistantReply().isBlank()) {
                messages.add(new LlmMessage("assistant", logEntry.getAssistantReply()));
            }
        });

        String userMessage = transcript == null || transcript.isBlank()
                ? properties.getEmptyTranscriptPlaceholder()
                : transcript.trim();
        messages.add(new LlmMessage("user", userMessage));

        return query(messages, session);
    }

    private LlmResult query(List<LlmMessage> messages, CoachingSession session) {
        if (!properties.isEnabled() || properties.getApiKey() == null || properties.getApiKey().isBlank()) {
            return fallbackResult(session, "LLM desactive ou cle absente");
        }

        LlmRequest request = new LlmRequest(properties.getModel(), properties.getTemperature(), properties.getMaxTokens(), messages);

        try {
            LlmResponse response = webClient.post()
                    .bodyValue(request)
                    .retrieve()
                    .bodyToMono(LlmResponse.class)
                    .block(Duration.ofSeconds(properties.getTimeoutSeconds()));

            if (response == null || response.getChoices().isEmpty()) {
                return fallbackResult(session, null);
            }

            String content = response.getChoices().get(0).getMessage().getContent();
            if (content == null || content.isBlank()) {
                return fallbackResult(session, null);
            }

            clearFallbackState(session);
            return buildResult(content.trim(), response);
        } catch (WebClientResponseException ex) {
            String reason = describeError(ex);
            log.warn("LLM API responded with {}: {} ({})", ex.getStatusCode(), ex.getResponseBodyAsString(), reason);
            return fallbackResult(session, reason);
        } catch (RuntimeException ex) {
            log.warn("LLM request failed", ex);
            return fallbackResult(session, ex.getClass().getSimpleName());
        }
    }

    private LlmResult buildResult(String content, LlmResponse response) {
        LlmResponse.Usage usage = response.getUsage();
        Integer promptTokens = usage != null ? usage.getPromptTokens() : null;
        Integer completionTokens = usage != null ? usage.getCompletionTokens() : null;
        Integer totalTokens = usage != null ? usage.getTotalTokens() : null;
        return new LlmResult(content, properties.getModel(), promptTokens, completionTokens, totalTokens);
    }

    private String describeError(WebClientResponseException ex) {
        if (ex.getStatusCode().value() == 429) {
            return "quota OpenAI depasse";
        }
        String body = ex.getResponseBodyAsString();
        if (body != null && body.contains("insufficient_quota")) {
            return "quota OpenAI depasse";
        }
        return "erreur " + ex.getStatusCode();
    }

    private LlmResult fallbackResult(CoachingSession session, String reason) {
        Long sessionId = effectiveSessionId(session);
        FinancialGoal goal = session.getFocusGoal();
        String goalLabel = Optional.ofNullable(goal).map(FinancialGoal::getTitle).orElse("vos finances");
        String goalId = resolveGoalId(goal);
        List<String> recommendedQuestions = questionBank.questionsFor(goalId);

        FallbackState state = fallbackStates.computeIfAbsent(sessionId, id -> new FallbackState(goalLabel));
        state.updateContext(goalLabel);

        if (state.shouldDeliverPlan(recommendedQuestions.size())) {
            FallbackMessage plan = fallbackFormatter.buildPlanMessage(goalLabel, toAnswerValues(state.getAnswers()));
            state.markPlanDelivered();
            return new LlmResult(plan.message(), properties.getModel(), 0, 0, 0, true, null, plan.quickReplies());
        }

        String fallbackNotice = null;
        if (state.shouldShowNotice()) {
            fallbackNotice = "Mode hors-ligne activé – je continue avec un plan simplifié.";
            state.markNoticeShown();
        }

        String nextQuestion = state.nextQuestion(recommendedQuestions);
        FallbackMessage fallbackMessage = fallbackFormatter.buildQuestionMessage(goalLabel, nextQuestion);
        return new LlmResult(fallbackMessage.message(), properties.getModel(), 0, 0, 0, true, fallbackNotice, fallbackMessage.quickReplies());
    }

    private void recordFallbackAnswer(CoachingSession session, String transcript) {
        if (session == null || transcript == null || transcript.isBlank()) {
            return;
        }
        Long sessionId = effectiveSessionId(session);
        if (sessionId == null) {
            return;
        }
        FallbackState state = fallbackStates.get(sessionId);
        if (state == null) {
            return;
        }
        state.recordAnswer(transcript.trim());
    }

    private void clearFallbackState(CoachingSession session) {
        if (session == null) {
            return;
        }
        Long sessionId = effectiveSessionId(session);
        if (sessionId == null) {
            return;
        }
        fallbackStates.remove(sessionId);
    }

    private String resolveGoalId(FinancialGoal goal) {
        if (goal == null || goal.getTitle() == null) {
            return "other_goal";
        }
        String normalized = Normalizer.normalize(goal.getTitle(), Normalizer.Form.NFD)
                .replaceAll("\\p{M}+", "")
                .toLowerCase(Locale.ROOT);
        if (containsAny(normalized, "urgence", "matelas", "securite")) {
            return "emergency_fund";
        }
        if (containsAny(normalized, "depense", "reduire", "reduis")) {
            return "spending_cut";
        }
        if (containsAny(normalized, "dette", "credit", "pret", "rembour")) {
            return "debt_repayment";
        }
        if (containsAny(normalized, "achat", "voiture", "maison", "voyage")) {
            return "target_purchase";
        }
        if (containsAny(normalized, "budget", "mensuel", "planifier")) {
            return "monthly_budget";
        }
        if (containsAny(normalized, "invest", "bourse", "placement", "etf")) {
            return "invest_beginner";
        }
        return "other_goal";
    }

    private boolean containsAny(String value, String... keywords) {
        for (String keyword : keywords) {
            if (value.contains(keyword)) {
                return true;
            }
        }
        return false;
    }

    private static final class FallbackState {
        private final List<FallbackAnswer> answers = new ArrayList<>();
        private String goalLabel;
        private int questionIndex = 0;
        private boolean noticeShown = false;
        private String pendingQuestion;
        private boolean planDelivered = false;

        private FallbackState(String goalLabel) {
            this.goalLabel = goalLabel;
        }

        synchronized void updateContext(String goalLabel) {
            this.goalLabel = goalLabel;
        }

        synchronized String nextQuestion(List<String> questions) {
            if (questions == null || questions.isEmpty()) {
                pendingQuestion = null;
                return null;
            }
            if (questionIndex >= questions.size()) {
                pendingQuestion = null;
                return null;
            }
            String question = questions.get(questionIndex);
            questionIndex++;
            pendingQuestion = question;
            return question;
        }

        synchronized void recordAnswer(String answer) {
            if (pendingQuestion == null || answer == null || answer.isBlank()) {
                return;
            }
            answers.add(new FallbackAnswer(pendingQuestion, answer));
            pendingQuestion = null;
        }

        synchronized boolean shouldDeliverPlan(int totalQuestions) {
            return totalQuestions > 0 && answers.size() >= totalQuestions && !planDelivered;
        }

        synchronized void markPlanDelivered() {
            planDelivered = true;
        }

        synchronized boolean shouldShowNotice() {
            return !noticeShown;
        }

        synchronized void markNoticeShown() {
            noticeShown = true;
        }

        synchronized List<FallbackAnswer> getAnswers() {
            return Collections.unmodifiableList(new ArrayList<>(answers));
        }

        synchronized String getGoalLabel() {
            return goalLabel;
        }
    }

    private record FallbackAnswer(String question, String answer) {
    }

    private List<AnswerValue> toAnswerValues(List<FallbackAnswer> answers) {
        if (answers == null || answers.isEmpty()) {
            return Collections.emptyList();
        }
        List<AnswerValue> values = new ArrayList<>();
        for (FallbackAnswer answer : answers) {
            values.add(new AnswerValue(answer.question(), answer.answer()));
        }
        return values;
    }

    private Long effectiveSessionId(CoachingSession session) {
        if (session == null) {
            return null;
        }
        Long id = session.getId();
        if (id != null) {
            return id;
        }
        return (long) System.identityHashCode(session);
    }
}
