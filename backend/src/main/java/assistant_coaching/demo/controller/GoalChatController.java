package assistant_coaching.demo.controller;

import assistant_coaching.demo.dto.GoalChatConversationDto;
import assistant_coaching.demo.dto.GoalChatHistoryItemDto;
import assistant_coaching.demo.dto.GoalChatRenameRequest;
import assistant_coaching.demo.dto.GoalChatSaveRequest;
import assistant_coaching.demo.dto.GoalMessageRequest;
import assistant_coaching.demo.dto.GoalMessageResponse;
import assistant_coaching.demo.dto.GoalSessionStartRequest;
import assistant_coaching.demo.dto.GoalSessionStartResponse;
import assistant_coaching.demo.goalchat.GoalChatService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/voice")
public class GoalChatController {

    private final GoalChatService goalChatService;

    public GoalChatController(GoalChatService goalChatService) {
        this.goalChatService = goalChatService;
    }

    @PostMapping("/start")
    public ResponseEntity<GoalSessionStartResponse> start(@Valid @RequestBody GoalSessionStartRequest request) {
        return ResponseEntity.ok(goalChatService.startSession(request));
    }

    @PostMapping("/message")
    public ResponseEntity<GoalMessageResponse> message(@Valid @RequestBody GoalMessageRequest request) {
        return ResponseEntity.ok(goalChatService.continueConversation(request));
    }

    @GetMapping("/history")
    public ResponseEntity<List<GoalChatHistoryItemDto>> history(
            @RequestParam(name = "userId") Long userId,
            @RequestParam(name = "limit", required = false) Integer limit) {
        return ResponseEntity.ok(goalChatService.recentHistory(limit, userId));
    }

    @GetMapping("/history/{sessionId}")
    public ResponseEntity<GoalChatConversationDto> conversation(
            @PathVariable String sessionId,
            @RequestParam(name = "userId") Long userId) {
        return ResponseEntity.ok(goalChatService.conversation(sessionId, userId));
    }

    @PostMapping("/history/save")
    public ResponseEntity<Void> saveHistory(@Valid @RequestBody GoalChatSaveRequest request) {
        goalChatService.saveSession(request);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/history/rename")
    public ResponseEntity<Void> renameHistory(@Valid @RequestBody GoalChatRenameRequest request) {
        goalChatService.renameConversation(request);
        return ResponseEntity.ok().build();
    }

    @DeleteMapping("/history/{sessionId}")
    public ResponseEntity<Void> deleteHistory(
            @PathVariable String sessionId,
            @RequestParam(name = "userId") Long userId) {
        goalChatService.deleteConversation(sessionId, userId);
        return ResponseEntity.noContent().build();
    }
}
