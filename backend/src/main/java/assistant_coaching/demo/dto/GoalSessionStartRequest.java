package assistant_coaching.demo.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public class GoalSessionStartRequest {

    @NotBlank
    private String goalId;

    @NotBlank
    private String goalLabel;

    @NotNull
    private Long userId;

    public String getGoalId() {
        return goalId;
    }

    public void setGoalId(String goalId) {
        this.goalId = goalId;
    }

    public String getGoalLabel() {
        return goalLabel;
    }

    public void setGoalLabel(String goalLabel) {
        this.goalLabel = goalLabel;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }
}
