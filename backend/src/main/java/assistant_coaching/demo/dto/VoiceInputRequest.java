package assistant_coaching.demo.dto;

public class VoiceInputRequest {
    private Long sessionId;
    private String transcript;
    private String language;

    public VoiceInputRequest() {
        // Serialization
    }

    public Long getSessionId() {
        return sessionId;
    }

    public void setSessionId(Long sessionId) {
        this.sessionId = sessionId;
    }

    public String getTranscript() {
        return transcript;
    }

    public void setTranscript(String transcript) {
        this.transcript = transcript;
    }

    public String getLanguage() {
        return language;
    }

    public void setLanguage(String language) {
        this.language = language;
    }
}
