package assistant_coaching.demo.dto;

import assistant_coaching.demo.model.Budget;
import assistant_coaching.demo.model.BudgetPeriodType;

import java.time.LocalDate;

public class BudgetCategoryResponse {
    private final Long id;
    private final String category;
    private final double budgetAmount;
    private final double spentAmount;
    private final double remaining;
    private final double usage;
    private final BudgetPeriodType periodType;
    private final Integer periodMonth;
    private final Integer periodYear;
    private final String periodLabel;
    private final Integer alertThreshold;
    private final String note;
    private final LocalDate customStart;
    private final LocalDate customEnd;

    public BudgetCategoryResponse(Budget budget) {
        this.id = budget.getId();
        this.category = budget.getCategory();
        this.budgetAmount = budget.getBudgetAmount().doubleValue();
        this.spentAmount = budget.getSpentAmount().doubleValue();
        this.remaining = budget.remainingAmount();
        this.usage = budget.usageRatio();
        this.periodType = budget.getPeriodType();
        this.periodMonth = budget.getPeriodMonth();
        this.periodYear = budget.getPeriodYear();
        this.periodLabel = budget.formattedPeriodLabel();
        this.alertThreshold = budget.getAlertThreshold();
        this.note = budget.getNote();
        this.customStart = budget.getCustomStart();
        this.customEnd = budget.getCustomEnd();
    }

    public Long getId() {
        return id;
    }

    public String getCategory() {
        return category;
    }

    public double getBudgetAmount() {
        return budgetAmount;
    }

    public double getSpentAmount() {
        return spentAmount;
    }

    public double getRemaining() {
        return remaining;
    }

    public double getUsage() {
        return usage;
    }

    public BudgetPeriodType getPeriodType() {
        return periodType;
    }

    public Integer getPeriodMonth() {
        return periodMonth;
    }

    public Integer getPeriodYear() {
        return periodYear;
    }

    public String getPeriodLabel() {
        return periodLabel;
    }

    public Integer getAlertThreshold() {
        return alertThreshold;
    }

    public String getNote() {
        return note;
    }

    public LocalDate getCustomStart() {
        return customStart;
    }

    public LocalDate getCustomEnd() {
        return customEnd;
    }
}
