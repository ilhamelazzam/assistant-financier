package assistant_coaching.demo.repository;

import assistant_coaching.demo.model.PasswordResetCode;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public interface PasswordResetCodeRepository extends JpaRepository<PasswordResetCode, Long> {

    Optional<PasswordResetCode> findTopByUserIdOrderByCreatedAtDesc(Long userId);

    List<PasswordResetCode> findByUserIdAndUsedAtIsNullAndExpiresAtAfter(Long userId, LocalDateTime now);
}
