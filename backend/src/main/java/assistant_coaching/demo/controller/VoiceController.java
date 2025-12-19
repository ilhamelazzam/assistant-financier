package assistant_coaching.demo.controller;

import assistant_coaching.demo.dto.InteractionSummaryDto;
import assistant_coaching.demo.dto.StartSessionRequest;
import assistant_coaching.demo.dto.StartSessionResponse;
import assistant_coaching.demo.dto.VoiceInputRequest;
import assistant_coaching.demo.dto.VoiceResponseDto;
import assistant_coaching.demo.model.CoachingSession;
import assistant_coaching.demo.model.FinancialGoal;
import assistant_coaching.demo.service.SessionService;
import assistant_coaching.demo.service.VoiceService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/voice")
public class VoiceController {

    private final VoiceService voiceService;
    private final SessionService sessionService;

    public VoiceController(VoiceService voiceService, SessionService sessionService) {
        this.voiceService = voiceService;
        this.sessionService = sessionService;
    }

    @PostMapping("/voice-input")
    public ResponseEntity<VoiceResponseDto> receiveVoice(@RequestBody VoiceInputRequest request) {
        VoiceResponseDto response = voiceService.processVoiceInput(request);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/sessions")
    public ResponseEntity<StartSessionResponse> startSession(@Valid @RequestBody StartSessionRequest request) {
        StartSessionResponse response = buildStartSessionResponse(request);
        return ResponseEntity.ok(response);
    }

    /**
     * Alias used by the Flutter client (`/sessions/start`).
     */
    @PostMapping("/sessions/start")
    public ResponseEntity<StartSessionResponse> startSessionAlias(@Valid @RequestBody StartSessionRequest request) {
        StartSessionResponse response = buildStartSessionResponse(request);
        return ResponseEntity.ok(response);
    }

    private StartSessionResponse buildStartSessionResponse(StartSessionRequest request) {
        CoachingSession session = sessionService.startSession(request);
        String focusGoal = Optional.ofNullable(session.getFocusGoal())
                .map(FinancialGoal::getTitle)
                .orElse("objectif général");
        String message = String.format("Session ouverte pour %s autour de %s", session.getUser().getDisplayName(), focusGoal);
        return new StartSessionResponse(
                session.getId(),
                session.getStatus().name(),
                focusGoal,
                session.getUser().getDisplayName(),
                message
        );
    }

    @GetMapping("/responses/{sessionId}")
    public ResponseEntity<List<InteractionSummaryDto>> listResponses(@PathVariable Long sessionId) {
        List<InteractionSummaryDto> interactions = voiceService.getSessionInteractions(sessionId);
        return ResponseEntity.ok(interactions);
    }
}
