package assistant_coaching.demo.service;

import assistant_coaching.demo.dto.UpdateUserProfileRequest;
import assistant_coaching.demo.dto.UserProfileResponse;
import assistant_coaching.demo.model.User;
import assistant_coaching.demo.repository.UserRepository;
import jakarta.transaction.Transactional;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.server.ResponseStatusException;

@Service
public class UserService {

    private final UserRepository repository;

    public UserService(UserRepository repository) {
        this.repository = repository;
    }

    public UserProfileResponse getProfile(long id) {
        User user = repository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Utilisateur introuvable"));
        return toResponse(user);
    }

    @Transactional
    public UserProfileResponse updateProfile(long id, UpdateUserProfileRequest request) {
        User user = repository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Utilisateur introuvable"));

        String normalizedEmail = request.getEmail().trim().toLowerCase();
        if (repository.existsByEmailIgnoreCaseAndIdNot(normalizedEmail, id)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Cet e-mail est deja utilise.");
        }

        user.setDisplayName(request.getDisplayName().trim());
        user.setEmail(normalizedEmail);
        user.setPhoneNumber(StringUtils.hasText(request.getPhoneNumber()) ? request.getPhoneNumber().trim() : null);
        user.setLocation(StringUtils.hasText(request.getLocation()) ? request.getLocation().trim() : null);
        user.setBio(StringUtils.hasText(request.getBio()) ? request.getBio().trim() : null);

        User saved = repository.save(user);
        return toResponse(saved);
    }

    private UserProfileResponse toResponse(User user) {
        return new UserProfileResponse(
                user.getId(),
                user.getDisplayName(),
                user.getEmail(),
                user.getPhoneNumber(),
                user.getLocation(),
                user.getMemberSince(),
                user.getBio()
        );
    }
}
