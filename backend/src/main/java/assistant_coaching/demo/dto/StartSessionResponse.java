package assistant_coaching.demo.dto;

public class StartSessionResponse {
    private final Long sessionId;
    private final String sessionStatus;
    private final String focusGoal;
    private final String userName;
    private final String message;

    public StartSessionResponse(Long sessionId, String sessionStatus, String focusGoal, String userName, String message) {
        this.sessionId = sessionId;
        this.sessionStatus = sessionStatus;
        this.focusGoal = focusGoal;
        this.userName = userName;
        this.message = message;
    }

    public Long getSessionId() {
        return sessionId;
    }

    public String getSessionStatus() {
        return sessionStatus;
    }

    public String getFocusGoal() {
        return focusGoal;
    }

    public String getUserName() {
        return userName;
    }

    public String getMessage() {
        return message;
    }
}
