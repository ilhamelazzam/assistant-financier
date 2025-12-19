package assistant_coaching.demo.dto;

import assistant_coaching.demo.model.AnalysisPeriod;

import java.util.List;

public class PeriodAnalysisDto {

    private final AnalysisPeriod period;
    private final double revenue;
    private final double revenueChange;
    private final double expense;
    private final double expenseChange;
    private final List<Double> revenueTrend;
    private final List<Double> expenseTrend;
    private final List<CategoryShareDto> distribution;
    private final String insightTitle;
    private final String insightBody;
    private final List<String> recommendations;

    public PeriodAnalysisDto(
            AnalysisPeriod period,
            double revenue,
            double revenueChange,
            double expense,
            double expenseChange,
            List<Double> revenueTrend,
            List<Double> expenseTrend,
            List<CategoryShareDto> distribution,
            String insightTitle,
            String insightBody,
            List<String> recommendations) {
        this.period = period;
        this.revenue = revenue;
        this.revenueChange = revenueChange;
        this.expense = expense;
        this.expenseChange = expenseChange;
        this.revenueTrend = revenueTrend;
        this.expenseTrend = expenseTrend;
        this.distribution = distribution;
        this.insightTitle = insightTitle;
        this.insightBody = insightBody;
        this.recommendations = recommendations;
    }

    public AnalysisPeriod getPeriod() {
        return period;
    }

    public double getRevenue() {
        return revenue;
    }

    public double getRevenueChange() {
        return revenueChange;
    }

    public double getExpense() {
        return expense;
    }

    public double getExpenseChange() {
        return expenseChange;
    }

    public List<Double> getRevenueTrend() {
        return revenueTrend;
    }

    public List<Double> getExpenseTrend() {
        return expenseTrend;
    }

    public List<CategoryShareDto> getDistribution() {
        return distribution;
    }

    public String getInsightTitle() {
        return insightTitle;
    }

    public String getInsightBody() {
        return insightBody;
    }

    public List<String> getRecommendations() {
        return recommendations;
    }
}
