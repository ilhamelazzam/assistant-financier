package assistant_coaching.demo.dto;

import java.time.LocalDateTime;

public class InteractionSummaryDto {
    private final LocalDateTime timestamp;
    private final String userInput;
    private final String assistantReply;

    public InteractionSummaryDto(LocalDateTime timestamp, String userInput, String assistantReply) {
        this.timestamp = timestamp;
        this.userInput = userInput;
        this.assistantReply = assistantReply;
    }

    public LocalDateTime getTimestamp() {
        return timestamp;
    }

    public String getUserInput() {
        return userInput;
    }

    public String getAssistantReply() {
        return assistantReply;
    }
}
