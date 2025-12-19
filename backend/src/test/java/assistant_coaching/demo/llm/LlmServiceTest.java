package assistant_coaching.demo.llm;

import assistant_coaching.demo.goalchat.FallbackCoachFormatter;
import assistant_coaching.demo.goalchat.GoalQuestionBank;
import assistant_coaching.demo.model.CoachingSession;
import assistant_coaching.demo.model.FinancialGoal;
import assistant_coaching.demo.model.User;
import org.junit.jupiter.api.Test;
import org.springframework.web.reactive.function.client.WebClient;

import java.lang.reflect.Field;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class LlmServiceTest {

    @Test
    void generateReply_returnsFallbackWhenDisabled() throws Exception {
        OpenAiProperties properties = new OpenAiProperties();
        properties.setEnabled(false);
        WebClient webClient = WebClient.builder().baseUrl("https://example.com").build();
        GoalQuestionBank questionBank = new GoalQuestionBank();
        FallbackCoachFormatter formatter = new FallbackCoachFormatter();
        LlmService service = new LlmService(properties, webClient, questionBank, formatter);

        User user = new User("hello@example.com", "Voice Tester");
        FinancialGoal goal = new FinancialGoal("But securise", BigDecimal.valueOf(1500), LocalDate.now().plusMonths(1));
        CoachingSession session = new CoachingSession(user, goal);
        Field idField = CoachingSession.class.getDeclaredField("id");
        idField.setAccessible(true);
        idField.set(session, 42L);

        LlmResult result = service.generateReply(session, List.of(), "Quels conseils ?");

        assertThat(result.getReply()).isNotBlank();
        assertThat(result.getFallbackNotice()).contains("Mode hors-ligne activé");
        assertThat(result.getModel()).isEqualTo("gpt-4o-mini");
        assertThat(result.getTotalTokens()).isZero();
    }
}
