package assistant_coaching.demo.service;

import assistant_coaching.demo.dto.StartSessionRequest;
import assistant_coaching.demo.model.CoachingSession;
import assistant_coaching.demo.model.FinancialGoal;
import assistant_coaching.demo.model.InteractionLog;
import assistant_coaching.demo.model.User;
import assistant_coaching.demo.repository.CoachingSessionRepository;
import assistant_coaching.demo.repository.FinancialGoalRepository;
import assistant_coaching.demo.repository.InteractionLogRepository;
import assistant_coaching.demo.repository.UserRepository;
import jakarta.transaction.Transactional;
import org.springframework.stereotype.Service;

import org.springframework.util.StringUtils;

import java.util.List;
import java.util.Locale;
import java.util.Optional;

@Service
public class SessionService {

    private final UserRepository userRepository;
    private final CoachingSessionRepository sessionRepository;
    private final FinancialGoalRepository goalRepository;
    private final InteractionLogRepository logRepository;

    public SessionService(UserRepository userRepository,
                          CoachingSessionRepository sessionRepository,
                          FinancialGoalRepository goalRepository,
                          InteractionLogRepository logRepository) {
        this.userRepository = userRepository;
        this.sessionRepository = sessionRepository;
        this.goalRepository = goalRepository;
        this.logRepository = logRepository;
    }

    @Transactional
    public CoachingSession startSession(StartSessionRequest request) {
        String email = normalizeEmail(request.getEmail());
        String displayName = normalizeDisplayName(request.getDisplayName(), email);
        User owner = userRepository.findByEmail(email)
                .orElseGet(() -> userRepository.save(new User(email, displayName)));

        FinancialGoal goal = new FinancialGoal(request.getGoalTitle(), request.getTargetAmount(), request.getTargetDate());
        owner.addGoal(goal);
        goalRepository.save(goal);

        CoachingSession session = new CoachingSession(owner, goal);
        owner.addSession(session);
        return sessionRepository.save(session);
    }

    public Optional<CoachingSession> findSession(Long sessionId) {
        return sessionRepository.findById(sessionId);
    }

    public List<InteractionLog> getInteractions(Long sessionId) {
        return logRepository.findBySessionIdOrderByTimestampAsc(sessionId);
    }

    public InteractionLog recordInteraction(CoachingSession session, String channel, String userInput, String assistantReply,
                                            String modelName, Integer promptTokens, Integer completionTokens, Integer totalTokens) {
        InteractionLog log = new InteractionLog(channel, userInput, assistantReply);
        session.addInteraction(log);
        log.setSession(session);
        log.setModelName(modelName);
        log.setPromptTokens(promptTokens);
        log.setCompletionTokens(completionTokens);
        log.setTotalTokens(totalTokens);
        return logRepository.save(log);
    }

    private String normalizeEmail(String email) {
        return email.trim().toLowerCase(Locale.ROOT);
    }

    private String normalizeDisplayName(String displayName, String email) {
        if (StringUtils.hasText(displayName)) {
            return displayName.trim();
        }
        int atIndex = email.indexOf('@');
        if (atIndex > 0) {
            return capitalize(email.substring(0, atIndex));
        }
        return capitalize(email);
    }

    private String capitalize(String value) {
        if (value.isEmpty()) {
            return value;
        }
        return value.substring(0, 1).toUpperCase(Locale.ROOT) + value.substring(1);
    }
}
