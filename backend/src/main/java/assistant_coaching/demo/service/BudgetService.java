package assistant_coaching.demo.service;

import assistant_coaching.demo.dto.BudgetCategoryResponse;
import assistant_coaching.demo.dto.BudgetSnapshotResponse;
import assistant_coaching.demo.dto.BudgetTipDto;
import assistant_coaching.demo.dto.CreateBudgetRequest;
import assistant_coaching.demo.model.Budget;
import assistant_coaching.demo.model.BudgetPeriodType;
import assistant_coaching.demo.repository.BudgetRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.text.NumberFormat;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.stream.Collectors;
import java.util.stream.Stream;

@Service
public class BudgetService {

    private final BudgetRepository repository;
    private final NumberFormat currencyFormat = NumberFormat.getNumberInstance(Locale.FRANCE);

    public BudgetService(BudgetRepository repository) {
        this.repository = repository;
        currencyFormat.setMaximumFractionDigits(0);
    }

    @Transactional(readOnly = true)
    public BudgetSnapshotResponse getSnapshot(Integer year, Integer month) {
        YearMonth resolved = resolveYearMonth(year, month);
        List<Budget> monthly = repository.findByYearMonth(resolved.getYear(), resolved.getMonthValue());
        List<Budget> rangeBudgets = repository.findRangeBudgets(
                resolved.atDay(1),
                resolved.atEndOfMonth(),
                BudgetPeriodType.MONTHLY
        );

        List<Budget> budgets = Stream.concat(monthly.stream(), rangeBudgets.stream())
                .sorted(Comparator.comparing(Budget::getCategory))
                .toList();

        double totalBudget = budgets.stream().mapToDouble(b -> b.getBudgetAmount().doubleValue()).sum();
        double totalSpent = budgets.stream().mapToDouble(b -> b.getSpentAmount().doubleValue()).sum();
        double remaining = Math.max(totalBudget - totalSpent, 0);

        List<BudgetCategoryResponse> categories = budgets.stream()
                .map(BudgetCategoryResponse::new)
                .collect(Collectors.toList());

        BudgetTipDto advice = buildAdvice(budgets, remaining);

        return new BudgetSnapshotResponse(
                resolved.getMonthValue(),
                resolved.getYear(),
                totalBudget,
                totalSpent,
                remaining,
                categories,
                advice
        );
    }

    @Transactional(readOnly = true)
    public BudgetCategoryResponse getBudget(long id) {
        Budget budget = repository.findById(id).orElseThrow(() -> new BudgetNotFoundException(id));
        return new BudgetCategoryResponse(budget);
    }

    @Transactional
    public BudgetCategoryResponse createBudget(CreateBudgetRequest request) {
        YearMonth target = resolveYearMonth(request.getPeriodYear(), request.getPeriodMonth());
        String normalizedCategory = normalizeCategory(request.getCategory());
        LocalDateRange range = resolveDateRange(request, target);
        ensureNotDuplicate(null, normalizedCategory, target, request.getPeriodType(), range);
        Budget budget = new Budget();
        budget.setSpentAmount(BigDecimal.ZERO);
        applyBudgetData(budget, request, normalizedCategory, target, range);
        Budget saved = repository.save(budget);
        return new BudgetCategoryResponse(saved);
    }

    @Transactional
    public BudgetCategoryResponse updateBudget(long id, CreateBudgetRequest request) {
        Budget existing = repository.findById(id).orElseThrow(() -> new BudgetNotFoundException(id));
        YearMonth target = resolveYearMonth(request.getPeriodYear(), request.getPeriodMonth());
        String normalizedCategory = normalizeCategory(request.getCategory());
        LocalDateRange range = resolveDateRange(request, target);
        ensureNotDuplicate(id, normalizedCategory, target, request.getPeriodType(), range);
        applyBudgetData(existing, request, normalizedCategory, target, range);
        Budget saved = repository.save(existing);
        return new BudgetCategoryResponse(saved);
    }

    @Transactional
    public void deleteBudget(long id) {
        Budget existing = repository.findById(id).orElseThrow(() -> new BudgetNotFoundException(id));
        repository.delete(existing);
    }

    private void applyBudgetData(Budget budget,
                                 CreateBudgetRequest request,
                                 String normalizedCategory,
                                 YearMonth target,
                                 LocalDateRange range) {
        validateDates(request);
        budget.setCategory(normalizedCategory);
        budget.setBudgetAmount(request.getAmount());
        if (budget.getSpentAmount() == null) {
            budget.setSpentAmount(BigDecimal.ZERO);
        }
        budget.setPeriodType(request.getPeriodType());
        budget.setPeriodMonth(target.getMonthValue());
        budget.setPeriodYear(target.getYear());
        budget.setAlertThreshold(request.getAlertThreshold());
        budget.setNote(request.getNote());
        budget.setCustomStart(range.start());
        budget.setCustomEnd(range.end());
    }

    private YearMonth resolveYearMonth(Integer year, Integer month) {
        YearMonth now = YearMonth.now();
        if (year == null || month == null) {
            return now;
        }
        return YearMonth.of(year, month);
    }

    private void ensureNotDuplicate(Long budgetId,
                                    String normalizedCategory,
                                    YearMonth target,
                                    BudgetPeriodType type,
                                    LocalDateRange range) {
        boolean existsMonthly = budgetId == null
                ? repository.isDuplicateCategory(normalizedCategory, target.getYear(), target.getMonthValue())
                : repository.existsByCategoryIgnoreCaseAndPeriodYearAndPeriodMonthAndIdNot(
                normalizedCategory, target.getYear(), target.getMonthValue(), budgetId);
        if (existsMonthly) {
            throw new BudgetServiceException("Un budget existe déjà pour cette catégorie ce mois-ci.");
        }
        if (type != BudgetPeriodType.MONTHLY) {
            boolean existsRange = budgetId == null
                    ? repository.isDuplicateWithinRange(normalizedCategory, range.start(), range.end())
                    : repository.isDuplicateWithinRangeExcludingId(normalizedCategory, range.start(), range.end(), budgetId);
            if (existsRange) {
                throw new BudgetServiceException("Cette catégorie possède déjà un budget sur cette période.");
            }
        }
    }

    private String normalizeCategory(String raw) {
        String trimmed = raw == null ? "" : raw.trim();
        if (trimmed.isEmpty()) {
            return "Catégorie";
        }
        return trimmed.substring(0, 1).toUpperCase(Locale.FRENCH) + trimmed.substring(1);
    }

    private void validateDates(CreateBudgetRequest request) {
        if (request.getPeriodType() == BudgetPeriodType.WEEKLY && request.getStartDate() == null) {
            throw new BudgetServiceException("Indiquez un début pour le budget hebdomadaire.");
        }
        if (request.getPeriodType() == BudgetPeriodType.CUSTOM) {
            if (request.getStartDate() == null || request.getEndDate() == null) {
                throw new BudgetServiceException("Choisissez une période personnalisée complète.");
            }
        }
        if ((request.getPeriodType() == BudgetPeriodType.WEEKLY || request.getPeriodType() == BudgetPeriodType.CUSTOM)
                && request.getStartDate() != null && request.getEndDate() != null
                && request.getEndDate().isBefore(request.getStartDate())) {
            throw new BudgetServiceException("La date de fin doit être postérieure au début.");
        }
    }

    private LocalDateRange resolveDateRange(CreateBudgetRequest request, YearMonth target) {
        LocalDate start;
        LocalDate end;
        if (request.getPeriodType() == BudgetPeriodType.MONTHLY) {
            start = target.atDay(1);
            end = target.atEndOfMonth();
        } else if (request.getPeriodType() == BudgetPeriodType.WEEKLY) {
            start = request.getStartDate() != null ? request.getStartDate() : target.atDay(1);
            end = request.getEndDate();
            if (end == null && start != null) {
                end = start.plusDays(6);
            }
        } else {
            start = request.getStartDate() != null ? request.getStartDate() : target.atDay(1);
            end = request.getEndDate() != null ? request.getEndDate() : start;
        }
        return new LocalDateRange(start, end);
    }

    private BudgetTipDto buildAdvice(List<Budget> budgets, double remaining) {
        if (budgets.isEmpty()) {
            return null;
        }

        return budgets.stream()
                .filter(b -> b.getBudgetAmount().doubleValue() > 0)
                .max(Comparator.comparingDouble(Budget::usageRatio))
                .map(topUsage -> {
                    if (topUsage.usageRatio() >= 0.8) {
                        String message = "Attention, vous avez déjà utilisé " + formatPercentage(topUsage.usageRatio())
                                + " de votre budget " + topUsage.getCategory() + ".";
                        return new BudgetTipDto("warning", message, topUsage.getCategory());
                    }
                    Budget bestRemainder = budgets.stream()
                            .max(Comparator.comparingDouble(Budget::remainingAmount))
                            .orElse(topUsage);
                    String message = "Bravo ! Vous pouvez encore économiser "
                            + currencyFormat.format(bestRemainder.remainingAmount()) + " MAD sur "
                            + bestRemainder.getCategory() + ".";
                    return new BudgetTipDto("success", message, bestRemainder.getCategory());
                })
                .orElse(null);
    }

    private String formatPercentage(double ratio) {
        return Math.round(ratio * 100) + "%";
    }

    private record LocalDateRange(LocalDate start, LocalDate end) {
    }
}
