package assistant_coaching.demo.dto;

import java.util.List;

public class GoalChatConversationDto {

    private final String sessionId;
    private final String goalId;
    private final String goalLabel;
    private final List<GoalChatMessageDto> messages;

    public GoalChatConversationDto(String sessionId,
                                   String goalId,
                                   String goalLabel,
                                   List<GoalChatMessageDto> messages) {
        this.sessionId = sessionId;
        this.goalId = goalId;
        this.goalLabel = goalLabel;
        this.messages = messages;
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

    public List<GoalChatMessageDto> getMessages() {
        return messages;
    }
}
