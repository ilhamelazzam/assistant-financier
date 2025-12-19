package assistant_coaching.demo.controller;

import assistant_coaching.demo.dto.BudgetCategoryResponse;
import assistant_coaching.demo.dto.BudgetSnapshotResponse;
import assistant_coaching.demo.dto.CreateBudgetRequest;
import assistant_coaching.demo.service.BudgetNotFoundException;
import assistant_coaching.demo.service.BudgetService;
import assistant_coaching.demo.service.BudgetServiceException;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.DeleteMapping;

import java.util.Map;

@RestController
@RequestMapping("/api/budgets")
public class BudgetController {

    private final BudgetService budgetService;

    public BudgetController(BudgetService budgetService) {
        this.budgetService = budgetService;
    }

    @GetMapping
    public BudgetSnapshotResponse getBudgetSnapshot(
            @RequestParam(required = false) Integer year,
            @RequestParam(required = false) Integer month
    ) {
        return budgetService.getSnapshot(year, month);
    }

    @GetMapping("/{id}")
    public BudgetCategoryResponse getBudget(@PathVariable long id) {
        return budgetService.getBudget(id);
    }

    @PostMapping
    public ResponseEntity<BudgetCategoryResponse> createBudget(@Valid @RequestBody CreateBudgetRequest request) {
        BudgetCategoryResponse response = budgetService.createBudget(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @PutMapping("/{id}")
    public BudgetCategoryResponse updateBudget(@PathVariable long id, @Valid @RequestBody CreateBudgetRequest request) {
        return budgetService.updateBudget(id, request);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteBudget(@PathVariable long id) {
        budgetService.deleteBudget(id);
        return ResponseEntity.noContent().build();
    }

    @ExceptionHandler(BudgetServiceException.class)
    public ResponseEntity<Map<String, String>> handleBudgetError(BudgetServiceException exception) {
        return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(Map.of("message", exception.getMessage()));
    }

    @ExceptionHandler(BudgetNotFoundException.class)
    public ResponseEntity<Map<String, String>> handleNotFound(BudgetNotFoundException exception) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(Map.of("message", exception.getMessage()));
    }
}
