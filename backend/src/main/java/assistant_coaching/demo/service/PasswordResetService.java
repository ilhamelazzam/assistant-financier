package assistant_coaching.demo.service;

import assistant_coaching.demo.dto.PasswordResetConfirmRequest;
import assistant_coaching.demo.dto.PasswordResetRequest;
import assistant_coaching.demo.dto.PasswordResetResponse;
import assistant_coaching.demo.model.PasswordResetCode;
import assistant_coaching.demo.model.User;
import assistant_coaching.demo.repository.PasswordResetCodeRepository;
import assistant_coaching.demo.repository.UserRepository;
import jakarta.transaction.Transactional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.MailException;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.server.ResponseStatusException;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import java.security.SecureRandom;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Locale;

import static org.springframework.http.HttpStatus.BAD_REQUEST;
import static org.springframework.http.HttpStatus.INTERNAL_SERVER_ERROR;
import static org.springframework.http.HttpStatus.NOT_FOUND;

@Service
public class PasswordResetService {

    private static final Logger log = LoggerFactory.getLogger(PasswordResetService.class);
    private static final DateTimeFormatter HUMAN_DATE_FORMAT = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");

    private final UserRepository userRepository;
    private final PasswordResetCodeRepository codeRepository;
    private final JavaMailSender mailSender;
    private final PasswordEncoder passwordEncoder;
    private final SecureRandom secureRandom = new SecureRandom();

    @Value("${app.password-reset.code-ttl-minutes:10}")
    private long codeTtlMinutes;

    @Value("${app.password-reset.sender:}")
    private String sender;

    @Value("${spring.mail.username:}")
    private String mailUsername;

    @Value("${spring.mail.password:}")
    private String mailPassword;

    @Value("${spring.mail.properties.mail.smtp.auth:true}")
    private boolean smtpAuthRequired;

    @Value("${app.password-reset.expose-code:false}")
    private boolean exposeCode;

    public PasswordResetService(UserRepository userRepository,
                                PasswordResetCodeRepository codeRepository,
                                JavaMailSender mailSender,
                                PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.codeRepository = codeRepository;
        this.mailSender = mailSender;
        this.passwordEncoder = passwordEncoder;
    }

    @Transactional
    public PasswordResetResponse requestResetCode(PasswordResetRequest request) {
        String normalizedEmail = normalizeEmail(request.getEmail());
        User user = userRepository.findByEmail(normalizedEmail)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Aucun compte associe a cet e-mail."));

        invalidateActiveCodes(user.getId());

        String code = generateCode();
        LocalDateTime expiresAt = LocalDateTime.now().plusMinutes(codeTtlMinutes);
        PasswordResetCode resetCode = new PasswordResetCode(user, code, expiresAt);
        codeRepository.save(resetCode);

        boolean emailSent = sendCodeEmail(normalizedEmail, code, expiresAt);
        if (!emailSent && !exposeCode) {
            throw new ResponseStatusException(INTERNAL_SERVER_ERROR, "Service email non configure.");
        }
        String exposedCode = emailSent ? null : code;
        return new PasswordResetResponse(emailSent, exposedCode, expiresAt);
    }

    @Transactional
    public void confirmReset(PasswordResetConfirmRequest request) {
        String normalizedEmail = normalizeEmail(request.getEmail());
        User user = userRepository.findByEmail(normalizedEmail)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Aucun compte associe a cet e-mail."));

        PasswordResetCode latest = codeRepository.findTopByUserIdOrderByCreatedAtDesc(user.getId())
                .orElseThrow(() -> new ResponseStatusException(BAD_REQUEST, "Aucun code actif. Demandez un nouveau code."));

        validateCode(latest, request.getCode());

        user.setPasswordHash(passwordEncoder.encode(request.getNewPassword()));
        latest.markUsed(LocalDateTime.now());
        userRepository.save(user);
        codeRepository.save(latest);
    }

    private void validateCode(PasswordResetCode latest, String code) {
        if (latest.getUsedAt() != null) {
            throw new ResponseStatusException(BAD_REQUEST, "Ce code a deja ete utilise.");
        }
        if (latest.getExpiresAt().isBefore(LocalDateTime.now())) {
            throw new ResponseStatusException(BAD_REQUEST, "Ce code a expire.");
        }
        if (!latest.getCode().equals(code)) {
            throw new ResponseStatusException(BAD_REQUEST, "Code invalide.");
        }
    }

    private void invalidateActiveCodes(Long userId) {
        List<PasswordResetCode> active = codeRepository.findByUserIdAndUsedAtIsNullAndExpiresAtAfter(
                userId, LocalDateTime.now());
        if (active.isEmpty()) {
            return;
        }
        LocalDateTime now = LocalDateTime.now();
        active.forEach(code -> code.markUsed(now));
        codeRepository.saveAll(active);
    }

    private boolean sendCodeEmail(String email, String code, LocalDateTime expiresAt) {
        String from = StringUtils.hasText(sender) ? sender : mailUsername;
        if (!StringUtils.hasText(from) || requiresCredentialsButMissing()) {
            log.warn("Password reset email skipped for {} because mail is not configured.", email);
            log.info("Password reset code for {}: {} (expires at {}).", email, code, expiresAt);
            return false;
        }
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, false, StandardCharsets.UTF_8.name());
            helper.setTo(email);
            helper.setFrom(from);
            helper.setSubject("Code de reinitialisation du mot de passe");

            String formattedExpiry = expiresAt.format(HUMAN_DATE_FORMAT);
            String htmlBody = String.format("""
                    <div style="font-family: Arial, sans-serif; line-height: 1.5; color: #1f2937;">
                      <p>Bonjour,</p>
                      <p>Voici votre code de reinitialisation&nbsp;:</p>
                      <p style="font-size: 24px; font-weight: bold; letter-spacing: 2px; color: #0ea5e9;">%s</p>
                      <p>Valable jusqu'au : <strong>%s</strong></p>
                      <p style="margin-top: 16px;">Si vous n'etes pas a l'origine de cette demande, ignorez cet e-mail.</p>
                      <p>Assistant Coaching Financier</p>
                    </div>
                    """, code, formattedExpiry);
            helper.setText(htmlBody, true);

            mailSender.send(message);
        } catch (MailException | MessagingException ex) {
            log.warn("Failed to send password reset email to {}", email, ex);
            throw new ResponseStatusException(INTERNAL_SERVER_ERROR, "Echec d'envoi de l'email.");
        }
        return true;
    }

    private String generateCode() {
        int value = 100000 + secureRandom.nextInt(900000);
        return String.valueOf(value);
    }

    private String normalizeEmail(String email) {
        return email.trim().toLowerCase(Locale.ROOT);
    }

    private boolean requiresCredentialsButMissing() {
        if (!smtpAuthRequired) {
            return false;
        }
        return !StringUtils.hasText(mailUsername) || !StringUtils.hasText(mailPassword);
    }
}
