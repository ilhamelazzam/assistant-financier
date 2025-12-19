package assistant_coaching.demo.service;

import assistant_coaching.demo.dto.VoiceInputRequest;
import assistant_coaching.demo.llm.LlmResult;
import assistant_coaching.demo.llm.LlmService;
import assistant_coaching.demo.model.CoachingSession;
import assistant_coaching.demo.model.FinancialGoal;
import assistant_coaching.demo.model.InteractionLog;
import assistant_coaching.demo.model.SessionStatus;
import assistant_coaching.demo.model.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.lang.reflect.Field;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class VoiceServiceTest {

    @Mock
    private SessionService sessionService;

    @Mock
    private LlmService llmService;

    @InjectMocks
    private VoiceService voiceService;

    private CoachingSession session;

    @BeforeEach
    void setUp() throws NoSuchFieldException, IllegalAccessException {
        User user = new User("test@example.com", "Test User");
        FinancialGoal goal = new FinancialGoal("Épargne", BigDecimal.valueOf(2000), LocalDate.now().plusMonths(3));
        session = new CoachingSession(user, goal);
        session.setStatus(SessionStatus.ACTIVE);

        Field idField = CoachingSession.class.getDeclaredField("id");
        idField.setAccessible(true);
        idField.set(session, 1L);
    }

    @Test
    void processVoiceInput_recordsLlmReplyAlongsideMetadata() {
        VoiceInputRequest request = new VoiceInputRequest();
        request.setSessionId(1L);
        request.setTranscript("Bonjour");

        LlmResult llmResult = new LlmResult("Conseil", "gpt-test", 10, 5, 15);
        InteractionLog stored = new InteractionLog("voice", "Bonjour", "Conseil");

        when(sessionService.findSession(1L)).thenReturn(Optional.of(session));
        when(sessionService.getInteractions(1L)).thenReturn(Collections.emptyList(), List.of(stored));
        when(llmService.generateReply(session, Collections.emptyList(), "Bonjour")).thenReturn(llmResult);
        when(sessionService.recordInteraction(
                eq(session),
                eq("voice"),
                eq("Bonjour"),
                eq("Conseil"),
                eq("gpt-test"),
                eq(10),
                eq(5),
                eq(15)))
                .thenReturn(stored);

        var response = voiceService.processVoiceInput(request);

        assertThat(response.getSessionId()).isEqualTo(1L);
        assertThat(response.getReply()).isEqualTo("Conseil");
        assertThat(response.getRecentInteractions()).hasSize(1);
        assertThat(response.getRecentInteractions().get(0).getAssistantReply()).isEqualTo("Conseil");
    }
}
