package assistant_coaching.demo.goalchat;

import assistant_coaching.demo.dto.GoalChatConversationDto;
import assistant_coaching.demo.dto.GoalChatHistoryItemDto;
import assistant_coaching.demo.dto.GoalChatMessageDto;
import assistant_coaching.demo.dto.GoalChatRenameRequest;
import assistant_coaching.demo.dto.GoalChatSaveRequest;
import assistant_coaching.demo.dto.GoalMessageRequest;
import assistant_coaching.demo.dto.GoalMessageResponse;
import assistant_coaching.demo.dto.GoalSessionStartRequest;
import assistant_coaching.demo.dto.GoalSessionStartResponse;
import assistant_coaching.demo.goalchat.FallbackCoachFormatter.AnswerValue;
import assistant_coaching.demo.goalchat.FallbackCoachFormatter.FallbackMessage;
import assistant_coaching.demo.llm.LlmMessage;
import assistant_coaching.demo.llm.LlmRequest;
import assistant_coaching.demo.llm.LlmResponse;
import assistant_coaching.demo.llm.LlmResult;
import assistant_coaching.demo.llm.OpenAiProperties;
import assistant_coaching.demo.model.GoalChatHistory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;

import java.time.Duration;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class GoalChatService {

    private static final Logger log = LoggerFactory.getLogger(GoalChatService.class);

    private final OpenAiProperties properties;
    private final WebClient openAiWebClient;
    private final GoalQuestionBank questionBank;
    private final FallbackCoachFormatter fallbackFormatter;
    private final GoalChatHistoryService historyService;
    private final Map<String, GoalChatSession> sessions = new ConcurrentHashMap<>();

    public GoalChatService(OpenAiProperties properties, WebClient openAiWebClient,
                           GoalQuestionBank questionBank,
                           FallbackCoachFormatter fallbackFormatter,
                           GoalChatHistoryService historyService) {
        this.properties = properties;
        this.openAiWebClient = openAiWebClient;
        this.questionBank = questionBank;
        this.fallbackFormatter = fallbackFormatter;
        this.historyService = historyService;
    }

    public GoalSessionStartResponse startSession(GoalSessionStartRequest request) {
        String sessionId = UUID.randomUUID().toString();
        GoalChatSession session = new GoalChatSession(
                sessionId,
                request.getGoalId(),
                request.getGoalLabel(),
                request.getUserId());

        List<LlmMessage> messages = new ArrayList<>();
        LlmMessage systemMessage = new LlmMessage("system", systemPrompt(request.getGoalLabel(), request.getGoalId()));
        LlmMessage userMessage = new LlmMessage("user",
                "L'utilisateur a choisi l'objectif \"" + request.getGoalLabel()
                        + "\". Commence la conversation, salue brievement, et pose la premiere question adaptee.");
        messages.add(systemMessage);
        messages.add(userMessage);
        session.addMessage(systemMessage);
        session.addMessage(userMessage);

        LlmResult result = query(session, messages);
        session.addMessage(new LlmMessage("assistant", result.getReply()));
        historyService.recordEntry(
                sessionId,
                request.getUserId(),
                request.getGoalId(),
                request.getGoalLabel(),
                null,
                result.getReply(),
                result.getModel(),
                result.getPromptTokens(),
                result.getCompletionTokens(),
                result.getTotalTokens());
        sessions.put(sessionId, session);

        return new GoalSessionStartResponse(
                sessionId,
                result.getReply(),
                result.getFallbackNotice(),
                result.getQuickReplies());
    }

    public GoalMessageResponse continueConversation(GoalMessageRequest request) {
        GoalChatSession session = ensureSessionLoaded(request.getSessionId(), request.getUserId());
        session.recordFallbackAnswer(request.getMessage());
        session.addMessage(new LlmMessage("user", request.getMessage()));
        LlmResult result = query(session, session.getHistory());
        session.addMessage(new LlmMessage("assistant", result.getReply()));
        historyService.recordEntry(
                session.getSessionId(),
                request.getUserId(),
                session.getGoalId(),
                session.getGoalLabel(),
                request.getMessage(),
                result.getReply(),
                result.getModel(),
                result.getPromptTokens(),
                result.getCompletionTokens(),
                result.getTotalTokens());
        return new GoalMessageResponse(result.getReply(), result.getFallbackNotice(), result.getQuickReplies());
    }

    public List<GoalChatHistoryItemDto> recentHistory(Integer limit, Long userId) {
        return historyService.recentSessions(limit, userId).stream()
                .map(entry -> new GoalChatHistoryItemDto(
                        entry.getId(),
                        entry.getSessionId(),
                        entry.getGoalId(),
                        entry.getGoalLabel(),
                        entry.getUserInput(),
                        entry.getAssistantReply(),
                        GoalAmountParser.normalizeLabel(entry.getUserInput()),
                        entry.getTimestamp(),
                        entry.isStarred()))
                .toList();
    }

    public void saveSession(GoalChatSaveRequest request) {
        historyService.markSessionStarred(request.getSessionId(), request.getUserId(), request.isStarred());
    }

    private GoalChatSession ensureSessionLoaded(String sessionId, Long userId) {
        return ensureSessionLoaded(sessionId, userId, null);
    }

    private GoalChatSession ensureSessionLoaded(String sessionId, Long userId, List<GoalChatHistory> cachedEntries) {
        GoalChatSession existing = sessions.get(sessionId);
        if (existing != null) {
            if (userId != null && !userId.equals(existing.getUserId())) {
                throw new IllegalArgumentException("Session introuvable: " + sessionId);
            }
            return existing;
        }
        GoalChatSession restored = restoreSessionFromHistory(sessionId, userId, cachedEntries);
        sessions.put(sessionId, restored);
        return restored;
    }

    private GoalChatSession restoreSessionFromHistory(String sessionId, Long userId, List<GoalChatHistory> cachedEntries) {
        List<GoalChatHistory> entries = cachedEntries != null ? cachedEntries : historyService.entriesForSession(sessionId, userId);
        if (entries.isEmpty()) {
            throw new IllegalArgumentException("Session introuvable: " + sessionId);
        }
        GoalChatHistory reference = entries.get(0);
        GoalChatSession session = new GoalChatSession(sessionId, reference.getGoalId(), reference.getGoalLabel(), reference.getUserId());
        session.addMessage(new LlmMessage("system", systemPrompt(reference.getGoalLabel(), reference.getGoalId())));
        for (GoalChatHistory entry : entries) {
            if (entry.getUserInput() != null && !entry.getUserInput().isBlank()) {
                session.addMessage(new LlmMessage("user", entry.getUserInput()));
            }
            if (entry.getAssistantReply() != null && !entry.getAssistantReply().isBlank()) {
                session.addMessage(new LlmMessage("assistant", entry.getAssistantReply()));
            }
        }
        return session;
    }

    public GoalChatConversationDto conversation(String sessionId, Long userId) {
        List<GoalChatHistory> entries = historyService.entriesForSession(sessionId, userId);
        if (entries.isEmpty()) {
            throw new IllegalArgumentException("Session introuvable: " + sessionId);
        }
        ensureSessionLoaded(sessionId, userId, entries);
        GoalChatHistory first = entries.get(0);
        List<GoalChatMessageDto> messages = new ArrayList<>();
        for (GoalChatHistory entry : entries) {
            if (entry.getUserInput() != null && !entry.getUserInput().isBlank()) {
                messages.add(new GoalChatMessageDto("user", entry.getUserInput(), entry.getTimestamp()));
            }
            if (entry.getAssistantReply() != null && !entry.getAssistantReply().isBlank()) {
                messages.add(new GoalChatMessageDto("assistant", entry.getAssistantReply(), entry.getTimestamp()));
            }
        }
        return new GoalChatConversationDto(
                sessionId,
                first.getGoalId(),
                first.getGoalLabel(),
                messages);
    }

    public void renameConversation(GoalChatRenameRequest request) {
        historyService.renameSession(request.getSessionId(), request.getUserId(), request.getNewLabel());
        sessions.remove(request.getSessionId());
    }

    public void deleteConversation(String sessionId, Long userId) {
        historyService.deleteSession(sessionId, userId);
        sessions.remove(sessionId);
    }

    private String systemPrompt(String goalLabel, String goalId) {
        List<String> recommendedQuestions = questionBank.questionsFor(goalId);
        StringBuilder builder = new StringBuilder();
        builder.append("Tu es un coach financier personnel qui guide un utilisateur francophone. ")
                .append("Objectif prioritaire : ").append(goalLabel).append(". ")
                .append("Tu poses UNE seule question a la fois, de maniere claire et empathique. ")
                .append("Commence toujours par collecter les informations necessaires avant de proposer un plan d'action. ")
                .append("Questions recommandees : ");
        for (int i = 0; i < recommendedQuestions.size(); i++) {
            builder.append(i + 1).append(". ").append(recommendedQuestions.get(i)).append(" ");
        }
        builder.append("Quand tu as assez d'informations, propose un resume, un plan d'action en trois etapes maximum, ")
                .append("puis termine avec une question de suivi unique. Reste prudent : pas de promesses irrealistes ni de conseils illegaux.");
        return builder.toString();
    }

    private LlmResult query(GoalChatSession session, List<LlmMessage> messages) {
        if (!properties.isEnabled() || properties.getApiKey() == null || properties.getApiKey().isBlank()) {
            return fallback(session, "LLM desactive ou cle absente");
        }

        LlmRequest payload = new LlmRequest(properties.getModel(), properties.getTemperature(), properties.getMaxTokens(), messages);
        try {
            LlmResponse response = openAiWebClient.post()
                    .bodyValue(payload)
                    .retrieve()
                    .bodyToMono(LlmResponse.class)
                    .block(Duration.ofSeconds(properties.getTimeoutSeconds()));
            if (response == null || response.getChoices().isEmpty()) {
                return fallback(session, null);
            }
            String content = Optional.ofNullable(response.getChoices().get(0))
                    .map(choice -> choice.getMessage().getContent())
                    .orElse("");
            if (content == null || content.isBlank()) {
                return fallback(session, null);
            }
            LlmResponse.Usage usage = response.getUsage();
            Integer promptTokens = usage != null ? usage.getPromptTokens() : null;
            Integer completionTokens = usage != null ? usage.getCompletionTokens() : null;
            Integer totalTokens = usage != null ? usage.getTotalTokens() : null;
            return new LlmResult(content.trim(), properties.getModel(), promptTokens, completionTokens, totalTokens);
        } catch (WebClientResponseException ex) {
            String reason = describeError(ex);
            log.warn("Goal chat LLM error {} {} ({})", ex.getStatusCode(), ex.getResponseBodyAsString(), reason);
            return fallback(session, reason);
        } catch (RuntimeException ex) {
            log.warn("Goal chat LLM failure", ex);
            return fallback(session, ex.getClass().getSimpleName());
        }
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

    private LlmResult fallback(GoalChatSession session, String reason) {
        String goalLabel = session != null ? session.getGoalLabel() : "cet objectif";
        String reasonLabel = (reason == null || reason.isBlank()) ? null : reason;
        List<String> recommendedQuestions = session != null
                ? questionBank.questionsFor(session.getGoalId())
                : Collections.emptyList();

        if (session != null && session.shouldDeliverFallbackPlan(recommendedQuestions.size())) {
            FallbackMessage planMessage = fallbackFormatter.buildPlanMessage(
                    goalLabel,
                    toAnswerValues(session.getFallbackAnswers()));
            session.markFallbackPlanSent();
            return new LlmResult(planMessage.message(), properties.getModel(), 0, 0, 0, true, null, planMessage.quickReplies());
        }

        String fallbackNotice = null;
        if (session == null || session.shouldIncludeFallbackNotice()) {
            fallbackNotice = "Mode hors-ligne activé – je continue avec un plan simplifié.";
            if (session != null) {
                session.markFallbackNoticeShown();
            }
        }

        String nextQuestion = null;
        if (session != null) {
            nextQuestion = session.nextFallbackQuestion(recommendedQuestions);
        }

        FallbackMessage fallbackMessage = fallbackFormatter.buildQuestionMessage(goalLabel, nextQuestion);
        return new LlmResult(
                fallbackMessage.message(),
                properties.getModel(),
                0,
                0,
                0,
                true,
                fallbackNotice,
                fallbackMessage.quickReplies());
    }

    private List<AnswerValue> toAnswerValues(List<GoalChatSession.FallbackAnswer> answers) {
        if (answers == null || answers.isEmpty()) {
            return Collections.emptyList();
        }
        List<AnswerValue> result = new ArrayList<>();
        for (GoalChatSession.FallbackAnswer answer : answers) {
            result.add(new AnswerValue(answer.getQuestion(), answer.getAnswer()));
        }
        return result;
    }
}
