package assistant_coaching.demo.goalchat;

import assistant_coaching.demo.model.GoalChatHistory;
import assistant_coaching.demo.repository.GoalChatHistoryRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Service
public class GoalChatHistoryService {

    private static final int DEFAULT_LIMIT = 30;
    private static final int MAX_LIMIT = 200;

    private final GoalChatHistoryRepository historyRepository;

    public GoalChatHistoryService(GoalChatHistoryRepository historyRepository) {
        this.historyRepository = historyRepository;
    }

    @Transactional
    public GoalChatHistory recordEntry(String sessionId,
                                       Long userId,
                                       String goalId,
                                       String goalLabel,
                                       String userInput,
                                       String assistantReply,
                                       String modelName,
                                       Integer promptTokens,
                                       Integer completionTokens,
                                       Integer totalTokens) {
        GoalChatHistory entry = new GoalChatHistory(sessionId, userId, goalId, goalLabel, userInput, assistantReply);
        entry.setModelName(modelName);
        entry.setPromptTokens(promptTokens);
        entry.setCompletionTokens(completionTokens);
        entry.setTotalTokens(totalTokens);
        return historyRepository.save(entry);
    }

    public List<GoalChatHistory> recentSessions(Integer limit, Long userId) {
        int size = normalizeLimit(limit);
        int fetchSize = Math.min(size * 5, MAX_LIMIT * 2);
        List<GoalChatHistory> latestEntries =
                historyRepository.findAllByUserIdOrderByTimestampDesc(userId, PageRequest.of(0, fetchSize));
        List<GoalChatHistory> deduped = new ArrayList<>(size);
        Set<String> seenSessionIds = new HashSet<>();
        for (GoalChatHistory entry : latestEntries) {
            if (!seenSessionIds.add(entry.getSessionId())) {
                continue;
            }
            deduped.add(entry);
            if (deduped.size() >= size) {
                break;
            }
        }
        return deduped;
    }

    @Transactional
    public void markSessionStarred(String sessionId, Long userId, boolean starred) {
        List<GoalChatHistory> entries = historyRepository.findBySessionIdAndUserId(sessionId, userId);
        if (entries.isEmpty()) {
            throw new IllegalArgumentException("Session introuvable: " + sessionId);
        }
        for (GoalChatHistory entry : entries) {
            entry.setStarred(starred);
        }
        historyRepository.saveAll(entries);
    }

    public List<GoalChatHistory> entriesForSession(String sessionId, Long userId) {
        return historyRepository.findBySessionIdAndUserIdOrderByTimestampAsc(sessionId, userId);
    }

    @Transactional
    public void renameSession(String sessionId, Long userId, String newLabel) {
        List<GoalChatHistory> entries = historyRepository.findBySessionIdAndUserId(sessionId, userId);
        if (entries.isEmpty()) {
            throw new IllegalArgumentException("Session introuvable: " + sessionId);
        }
        for (GoalChatHistory entry : entries) {
            entry.setGoalLabel(newLabel);
        }
        historyRepository.saveAll(entries);
    }

    @Transactional
    public void deleteSession(String sessionId, Long userId) {
        historyRepository.deleteBySessionIdAndUserId(sessionId, userId);
    }

    private int normalizeLimit(Integer limit) {
        if (limit == null) {
            return DEFAULT_LIMIT;
        }
        if (limit < 1) {
            return DEFAULT_LIMIT;
        }
        return Math.min(limit, MAX_LIMIT);
    }
}
