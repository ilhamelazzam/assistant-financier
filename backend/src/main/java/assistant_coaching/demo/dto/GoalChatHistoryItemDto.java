package assistant_coaching.demo.dto;

import java.time.LocalDateTime;

public class GoalChatHistoryItemDto {

    private final Long id;
    private final String sessionId;
    private final String goalId;
    private final String goalLabel;
    private final String userInput;
    private final String assistantReply;
    private final String normalizedUserInput;
    private final LocalDateTime timestamp;
    private final boolean starred;

    public GoalChatHistoryItemDto(Long id,
                                  String sessionId,
                                  String goalId,
                                  String goalLabel,
                                  String userInput,
                                  String assistantReply,
                                  String normalizedUserInput,
                                  LocalDateTime timestamp,
                                  boolean starred) {
        this.id = id;
        this.sessionId = sessionId;
        this.goalId = goalId;
        this.goalLabel = goalLabel;
        this.userInput = userInput;
        this.assistantReply = assistantReply;
        this.normalizedUserInput = normalizedUserInput;
        this.timestamp = timestamp;
        this.starred = starred;
    }

    public Long getId() {
        return id;
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

    public String getUserInput() {
        return userInput;
    }

    public String getAssistantReply() {
        return assistantReply;
    }

    public String getNormalizedUserInput() {
        return normalizedUserInput;
    }

    public LocalDateTime getTimestamp() {
        return timestamp;
    }

    public boolean isStarred() {
        return starred;
    }
}
