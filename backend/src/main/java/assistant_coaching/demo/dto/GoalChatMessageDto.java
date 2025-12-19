package assistant_coaching.demo.dto;

import java.time.LocalDateTime;

public class GoalChatMessageDto {

    private final String role;
    private final String text;
    private final LocalDateTime timestamp;

    public GoalChatMessageDto(String role, String text, LocalDateTime timestamp) {
        this.role = role;
        this.text = text;
        this.timestamp = timestamp;
    }

    public String getRole() {
        return role;
    }

    public String getText() {
        return text;
    }

    public LocalDateTime getTimestamp() {
        return timestamp;
    }
}
