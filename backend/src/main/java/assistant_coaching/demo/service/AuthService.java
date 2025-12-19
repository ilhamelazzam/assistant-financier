package assistant_coaching.demo.service;

import assistant_coaching.demo.dto.AuthResponse;
import assistant_coaching.demo.dto.LoginRequest;
import assistant_coaching.demo.dto.RegisterRequest;
import assistant_coaching.demo.model.User;
import assistant_coaching.demo.repository.UserRepository;
import jakarta.transaction.Transactional;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.server.ResponseStatusException;

import java.util.Locale;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public AuthService(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        String email = normalizeEmail(request.getEmail());
        userRepository.findByEmail(email).ifPresent(user -> {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Un compte existe déjà avec cet e-mail.");
        });

        String displayName = deriveDisplayName(request);
        User user = new User(email, displayName);
        if (StringUtils.hasText(request.getPhoneNumber())) {
            user.setPhoneNumber(request.getPhoneNumber().trim());
        }
        if (StringUtils.hasText(request.getLocation())) {
            user.setLocation(request.getLocation().trim());
        }
        user.setPasswordHash(passwordEncoder.encode(request.getPassword()));
        User saved = userRepository.save(user);
        return mapToResponse(saved);
    }

    public AuthResponse login(LoginRequest request) {
        String email = normalizeEmail(request.getEmail());
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Identifiants invalides."));

        String storedHash = user.getPasswordHash();
        if (!StringUtils.hasText(storedHash) || !passwordEncoder.matches(request.getPassword(), storedHash)) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Identifiants invalides.");
        }
        return mapToResponse(user);
    }

    private String normalizeEmail(String email) {
        return email.trim().toLowerCase(Locale.ROOT);
    }

    private String deriveDisplayName(RegisterRequest request) {
        if (StringUtils.hasText(request.getDisplayName())) {
            return request.getDisplayName().trim();
        }
        String email = normalizeEmail(request.getEmail());
        int atIndex = email.indexOf('@');
        String prefix = atIndex > 0 ? email.substring(0, atIndex) : email;
        return capitalize(prefix);
    }

    private String capitalize(String value) {
        if (value.isEmpty()) {
            return value;
        }
        return value.substring(0, 1).toUpperCase(Locale.ROOT) + value.substring(1);
    }

    private AuthResponse mapToResponse(User user) {
        return new AuthResponse(user.getId(), user.getEmail(), user.getDisplayName());
    }
}
