package assistant_coaching.demo.dto;

import java.util.List;

public class GoalSessionStartResponse {

    private final String sessionId;
    private final String assistantMessage;
    private final String fallbackNotice;
    private final List<String> quickReplies;

    public GoalSessionStartResponse(String sessionId, String assistantMessage, String fallbackNotice,
                                    List<String> quickReplies) {
        this.sessionId = sessionId;
        this.assistantMessage = assistantMessage;
        this.fallbackNotice = fallbackNotice;
        this.quickReplies = quickReplies;
    }

    public String getSessionId() {
        return sessionId;
    }

    public String getAssistantMessage() {
        return assistantMessage;
    }

    public String getFallbackNotice() {
        return fallbackNotice;
    }

    public List<String> getQuickReplies() {
        return quickReplies;
    }
}
