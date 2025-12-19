package assistant_coaching.demo.dto;

import java.util.List;

public class VoiceResponseDto {
    private Long sessionId;
    private String reply;
    private String sessionStatus;
    private String focusGoal;
    private List<InteractionSummaryDto> recentInteractions;
    private String fallbackNotice;
    private List<String> quickReplies;

    public VoiceResponseDto(Long sessionId, String reply, String sessionStatus, String focusGoal,
                            List<InteractionSummaryDto> recentInteractions, String fallbackNotice,
                            List<String> quickReplies) {
        this.sessionId = sessionId;
        this.reply = reply;
        this.sessionStatus = sessionStatus;
        this.focusGoal = focusGoal;
        this.recentInteractions = recentInteractions;
        this.fallbackNotice = fallbackNotice;
        this.quickReplies = quickReplies;
    }

    public Long getSessionId() {
        return sessionId;
    }

    public String getReply() {
        return reply;
    }

    public String getSessionStatus() {
        return sessionStatus;
    }

    public String getFocusGoal() {
        return focusGoal;
    }

    public List<InteractionSummaryDto> getRecentInteractions() {
        return recentInteractions;
    }

    public String getFallbackNotice() {
        return fallbackNotice;
    }

    public List<String> getQuickReplies() {
        return quickReplies;
    }
}
