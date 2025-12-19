package assistant_coaching.demo.goalchat;

import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * Lightweight snapshot that mirrors the static budget screen data so we can
 * craft concrete fallback suggestions (montants + catégories).
 */
public class BudgetSnapshot {

    private final double totalBudget;
    private final double spent;
    private final List<BudgetCategory> categories;

    private BudgetSnapshot(double totalBudget, double spent, List<BudgetCategory> categories) {
        this.totalBudget = totalBudget;
        this.spent = spent;
        this.categories = categories;
    }

    public static BudgetSnapshot defaultSnapshot() {
        return new BudgetSnapshot(
                8_500,
                6_520,
                List.of(
                        new BudgetCategory("Alimentation", 1_850, 2_500, true),
                        new BudgetCategory("Transport", 650, 800, true),
                        new BudgetCategory("Logement", 3_000, 3_000, false),
                        new BudgetCategory("Shopping", 420, 1_000, true),
                        new BudgetCategory("Santé", 280, 500, true),
                        new BudgetCategory("Loisirs", 320, 700, true)
                )
        );
    }

    public double getTotalBudget() {
        return totalBudget;
    }

    public double getSpent() {
        return spent;
    }

    public double getUsagePercent() {
        if (totalBudget == 0) {
            return 0;
        }
        return spent / totalBudget;
    }

    public double getAvailable() {
        return Math.max(totalBudget - spent, 0);
    }

    public List<BudgetCategory> topCategories(int count) {
        return categories.stream()
                .sorted(Comparator.comparingDouble(BudgetCategory::usageRatio).reversed())
                .limit(Math.max(count, 0))
                .collect(Collectors.toList());
    }

    public List<BudgetCategory> topAdjustableCategories(int count) {
        return categories.stream()
                .filter(BudgetCategory::adjustable)
                .sorted(Comparator.comparingDouble(BudgetCategory::usageRatio).reversed())
                .limit(Math.max(count, 0))
                .collect(Collectors.toList());
    }

    public Optional<BudgetCategory> findByName(String label) {
        if (label == null) {
            return Optional.empty();
        }
        String normalized = label.toLowerCase(Locale.ROOT);
        return categories.stream()
                .filter(cat -> cat.name().toLowerCase(Locale.ROOT).equals(normalized))
                .findFirst();
    }

    public record BudgetCategory(String name, double spent, double limit, boolean adjustable) {
        public double usageRatio() {
            if (limit == 0) {
                return 0;
            }
            return spent / limit;
        }

        public long usagePercentRounded() {
            return Math.round(usageRatio() * 100);
        }
    }
}
