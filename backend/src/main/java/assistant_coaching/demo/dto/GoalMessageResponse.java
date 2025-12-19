package assistant_coaching.demo.dto;

import java.util.List;

public class GoalMessageResponse {

    private final String assistantMessage;
    private final String fallbackNotice;
    private final List<String> quickReplies;

    public GoalMessageResponse(String assistantMessage, String fallbackNotice, List<String> quickReplies) {
        this.assistantMessage = assistantMessage;
        this.fallbackNotice = fallbackNotice;
        this.quickReplies = quickReplies;
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
