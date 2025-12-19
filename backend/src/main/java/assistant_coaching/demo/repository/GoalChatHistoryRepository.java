package assistant_coaching.demo.repository;

import assistant_coaching.demo.model.GoalChatHistory;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface GoalChatHistoryRepository extends JpaRepository<GoalChatHistory, Long> {
    List<GoalChatHistory> findAllByUserIdOrderByTimestampDesc(Long userId, Pageable pageable);

    @Query("""
            SELECT g FROM GoalChatHistory g
            WHERE g.timestamp = (
                SELECT MAX(h.timestamp) FROM GoalChatHistory h WHERE h.sessionId = g.sessionId
            )
            ORDER BY g.timestamp DESC
            """)
    List<GoalChatHistory> findLatestEntriesPerSession(Pageable pageable);

    List<GoalChatHistory> findBySessionIdAndUserId(String sessionId, Long userId);

    List<GoalChatHistory> findBySessionIdAndUserIdOrderByTimestampAsc(String sessionId, Long userId);

    @Modifying
    void deleteBySessionIdAndUserId(String sessionId, Long userId);
}
