package assistant_coaching.demo.dto;

import java.time.LocalDateTime;

public class PasswordResetResponse {

    private final boolean emailSent;
    private final String code;
    private final LocalDateTime expiresAt;

    public PasswordResetResponse(boolean emailSent, String code, LocalDateTime expiresAt) {
        this.emailSent = emailSent;
        this.code = code;
        this.expiresAt = expiresAt;
    }

    public boolean isEmailSent() {
        return emailSent;
    }

    public String getCode() {
        return code;
    }

    public LocalDateTime getExpiresAt() {
        return expiresAt;
    }
}
