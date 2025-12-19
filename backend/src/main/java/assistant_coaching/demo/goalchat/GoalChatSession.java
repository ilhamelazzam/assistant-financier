package assistant_coaching.demo.goalchat;

import assistant_coaching.demo.llm.LlmMessage;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

public class GoalChatSession {

    private final String sessionId;
    private final String goalId;
    private final String goalLabel;
    private final Long userId;
    private final Instant createdAt;
    private final List<LlmMessage> history = new ArrayList<>();
    private int fallbackQuestionIndex = 0;
    private boolean fallbackNoticeShown = false;
    private boolean fallbackPlanSent = false;
    private final List<FallbackAnswer> fallbackAnswers = new ArrayList<>();
    private String pendingFallbackQuestion;

    public GoalChatSession(String sessionId, String goalId, String goalLabel, Long userId) {
        this.sessionId = sessionId;
        this.goalId = goalId;
        this.goalLabel = goalLabel;
        this.userId = userId;
        this.createdAt = Instant.now();
    }

    public String getSessionId() {
        return sessionId;
    }

    public String getGoalId() {
        return goalId;
    }

    public String getGoalLabel() {
        return goalLabel;
    }

    public Long getUserId() {
        return userId;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public List<LlmMessage> getHistory() {
        return history;
    }

    public void addMessage(LlmMessage message) {
        history.add(message);
    }

    /**
     * Returns the next recommended question to ask when the LLM is unavailable.
     * This guarantees we keep progressing through the question bank instead of
     * repeating the same fallback prompt.
     */
    public synchronized String nextFallbackQuestion(List<String> recommendedQuestions) {
        if (recommendedQuestions == null || recommendedQuestions.isEmpty()) {
            pendingFallbackQuestion = null;
            return null;
        }
        if (fallbackQuestionIndex >= recommendedQuestions.size()) {
            pendingFallbackQuestion = null;
            return null;
        }
        String question = recommendedQuestions.get(fallbackQuestionIndex);
        fallbackQuestionIndex++;
        pendingFallbackQuestion = question;
        return question;
    }

    public synchronized boolean hasPendingFallbackQuestion() {
        return pendingFallbackQuestion != null;
    }

    public synchronized void recordFallbackAnswer(String answer) {
        if (pendingFallbackQuestion == null || answer == null || answer.isBlank()) {
            return;
        }
        fallbackAnswers.add(new FallbackAnswer(pendingFallbackQuestion, answer.trim()));
        pendingFallbackQuestion = null;
    }

    public synchronized boolean shouldDeliverFallbackPlan(int totalQuestions) {
        return totalQuestions > 0 && fallbackAnswers.size() >= totalQuestions && !fallbackPlanSent;
    }

    public synchronized List<FallbackAnswer> getFallbackAnswers() {
        return new ArrayList<>(fallbackAnswers);
    }

    public boolean shouldIncludeFallbackNotice() {
        return !fallbackNoticeShown;
    }

    public void markFallbackNoticeShown() {
        fallbackNoticeShown = true;
    }

    public synchronized boolean hasSentFallbackPlan() {
        return fallbackPlanSent;
    }

    public synchronized void markFallbackPlanSent() {
        fallbackPlanSent = true;
    }

    public static class FallbackAnswer {
        private final String question;
        private final String answer;

        public FallbackAnswer(String question, String answer) {
            this.question = question;
            this.answer = answer;
        }

        public String getQuestion() {
            return question;
        }

        public String getAnswer() {
            return answer;
        }
    }
}
