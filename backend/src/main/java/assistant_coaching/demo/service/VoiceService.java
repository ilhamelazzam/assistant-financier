package assistant_coaching.demo.service;

import assistant_coaching.demo.dto.InteractionSummaryDto;
import assistant_coaching.demo.dto.VoiceInputRequest;
import assistant_coaching.demo.dto.VoiceResponseDto;
import assistant_coaching.demo.llm.LlmResult;
import assistant_coaching.demo.llm.LlmService;
import assistant_coaching.demo.model.CoachingSession;
import assistant_coaching.demo.model.FinancialGoal;
import assistant_coaching.demo.model.InteractionLog;
import jakarta.transaction.Transactional;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class VoiceService {

    private final SessionService sessionService;
    private final LlmService llmService;

    public VoiceService(SessionService sessionService, LlmService llmService) {
        this.sessionService = sessionService;
        this.llmService = llmService;
    }

    @Transactional
    public VoiceResponseDto processVoiceInput(VoiceInputRequest request) {
        CoachingSession session = sessionService.findSession(request.getSessionId())
                .orElseThrow(() -> new IllegalArgumentException("Session introuvable"));

        List<InteractionLog> history = sessionService.getInteractions(session.getId());
        LlmResult llmResult = llmService.generateReply(session, history, request.getTranscript());
        sessionService.recordInteraction(
                session,
                "voice",
                request.getTranscript(),
                llmResult.getReply(),
                llmResult.getModel(),
                llmResult.getPromptTokens(),
                llmResult.getCompletionTokens(),
                llmResult.getTotalTokens()
        );

        List<InteractionSummaryDto> recent = sessionService.getInteractions(session.getId()).stream()
                .map(this::toSummary)
                .collect(Collectors.toList());

        String focusGoal = Optional.ofNullable(session.getFocusGoal())
                .map(FinancialGoal::getTitle)
                .orElse("objectif général");

        return new VoiceResponseDto(
                session.getId(),
                llmResult.getReply(),
                session.getStatus().name(),
                focusGoal,
                recent,
                llmResult.getFallbackNotice(),
                llmResult.getQuickReplies());
    }

    public List<InteractionSummaryDto> getSessionInteractions(Long sessionId) {
        return sessionService.getInteractions(sessionId).stream()
                .map(this::toSummary)
                .collect(Collectors.toList());
    }

    private InteractionSummaryDto toSummary(InteractionLog log) {
        return new InteractionSummaryDto(log.getTimestamp(), log.getUserInput(), log.getAssistantReply());
    }
}
