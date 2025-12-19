package assistant_coaching.demo.repository;

import assistant_coaching.demo.model.InteractionLog;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface InteractionLogRepository extends JpaRepository<InteractionLog, Long> {
    List<InteractionLog> findBySessionIdOrderByTimestampAsc(Long sessionId);
}
