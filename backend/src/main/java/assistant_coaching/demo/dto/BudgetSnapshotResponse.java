package assistant_coaching.demo.dto;

import java.util.List;

public class BudgetSnapshotResponse {
    private final int month;
    private final int year;
    private final double totalBudget;
    private final double totalSpent;
    private final double remaining;
    private final List<BudgetCategoryResponse> categories;
    private final BudgetTipDto advice;

    public BudgetSnapshotResponse(int month, int year, double totalBudget, double totalSpent,
                                  double remaining, List<BudgetCategoryResponse> categories,
                                  BudgetTipDto advice) {
        this.month = month;
        this.year = year;
        this.totalBudget = totalBudget;
        this.totalSpent = totalSpent;
        this.remaining = remaining;
        this.categories = categories;
        this.advice = advice;
    }

    public int getMonth() {
        return month;
    }

    public int getYear() {
        return year;
    }

    public double getTotalBudget() {
        return totalBudget;
    }

    public double getTotalSpent() {
        return totalSpent;
    }

    public double getRemaining() {
        return remaining;
    }

    public List<BudgetCategoryResponse> getCategories() {
        return categories;
    }

    public BudgetTipDto getAdvice() {
        return advice;
    }
}
