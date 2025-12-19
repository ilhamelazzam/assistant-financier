package assistant_coaching.demo.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.LocalDate;
import java.time.YearMonth;
import java.time.format.TextStyle;
import java.util.Locale;

@Entity
@Table(name = "budget",
        uniqueConstraints = @UniqueConstraint(name = "uk_budget_category_period", columnNames = {"category", "period_year", "period_month"}))
public class Budget {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 64)
    private String category;

    @Column(name = "budget_amount", nullable = false, precision = 12, scale = 2)
    private BigDecimal budgetAmount = BigDecimal.ZERO;

    @Column(name = "spent_amount", nullable = false, precision = 12, scale = 2)
    private BigDecimal spentAmount = BigDecimal.ZERO;

    @Enumerated(EnumType.STRING)
    @Column(name = "period_type", nullable = false, length = 16)
    private BudgetPeriodType periodType = BudgetPeriodType.MONTHLY;

    @Column(name = "period_month", nullable = false)
    private Integer periodMonth;

    @Column(name = "period_year", nullable = false)
    private Integer periodYear;

    @Column(name = "alert_threshold")
    private Integer alertThreshold;

    @Column(length = 240)
    private String note;

    @Column(name = "custom_start")
    private LocalDate customStart;

    @Column(name = "custom_end")
    private LocalDate customEnd;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    public Budget() {
    }

    @PrePersist
    public void onCreate() {
        Instant now = Instant.now();
        this.createdAt = now;
        this.updatedAt = now;
    }

    @PreUpdate
    public void onUpdate() {
        this.updatedAt = Instant.now();
    }

    public Long getId() {
        return id;
    }

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
    }

    public BigDecimal getBudgetAmount() {
        return budgetAmount;
    }

    public void setBudgetAmount(BigDecimal budgetAmount) {
        this.budgetAmount = budgetAmount;
    }

    public BigDecimal getSpentAmount() {
        return spentAmount;
    }

    public void setSpentAmount(BigDecimal spentAmount) {
        this.spentAmount = spentAmount;
    }

    public BudgetPeriodType getPeriodType() {
        return periodType;
    }

    public void setPeriodType(BudgetPeriodType periodType) {
        this.periodType = periodType;
    }

    public Integer getPeriodMonth() {
        return periodMonth;
    }

    public void setPeriodMonth(Integer periodMonth) {
        this.periodMonth = periodMonth;
    }

    public Integer getPeriodYear() {
        return periodYear;
    }

    public void setPeriodYear(Integer periodYear) {
        this.periodYear = periodYear;
    }

    public Integer getAlertThreshold() {
        return alertThreshold;
    }

    public void setAlertThreshold(Integer alertThreshold) {
        this.alertThreshold = alertThreshold;
    }

    public String getNote() {
        return note;
    }

    public void setNote(String note) {
        this.note = note;
    }

    public LocalDate getCustomStart() {
        return customStart;
    }

    public void setCustomStart(LocalDate customStart) {
        this.customStart = customStart;
    }

    public LocalDate getCustomEnd() {
        return customEnd;
    }

    public void setCustomEnd(LocalDate customEnd) {
        this.customEnd = customEnd;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }

    public double usageRatio() {
        if (budgetAmount == null || budgetAmount.doubleValue() <= 0) {
            return 0.0;
        }
        return spentAmount.divide(budgetAmount, 4, RoundingMode.HALF_UP).doubleValue();
    }

    public double remainingAmount() {
        if (budgetAmount == null) {
            return 0;
        }
        return budgetAmount.subtract(spentAmount == null ? BigDecimal.ZERO : spentAmount)
                .max(BigDecimal.ZERO)
                .doubleValue();
    }

    public String formattedPeriodLabel() {
        YearMonth ym = YearMonth.of(periodYear, periodMonth);
        String base = ym.getMonth().getDisplayName(TextStyle.FULL, Locale.FRENCH);
        if (periodType == BudgetPeriodType.MONTHLY || (customStart == null && customEnd == null)) {
            return base + " " + periodYear;
        }
        if (customStart != null && customEnd != null) {
            return customStart + " → " + customEnd;
        }
        if (customStart != null) {
            return "Depuis " + customStart;
        }
        return base + " " + periodYear;
    }
}
