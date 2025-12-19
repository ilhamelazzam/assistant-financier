package assistant_coaching.demo.repository;

import assistant_coaching.demo.model.CoachingSession;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface CoachingSessionRepository extends JpaRepository<CoachingSession, Long> {
    List<CoachingSession> findByUserIdOrderByUpdatedAtDesc(Long userId);
}
