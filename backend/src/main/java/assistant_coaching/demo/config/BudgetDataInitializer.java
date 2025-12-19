package assistant_coaching.demo.config;

import assistant_coaching.demo.model.Budget;
import assistant_coaching.demo.model.BudgetPeriodType;
import assistant_coaching.demo.repository.BudgetRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.math.BigDecimal;
import java.time.YearMonth;
import java.util.List;

@Configuration
public class BudgetDataInitializer {

    @Bean
    CommandLineRunner seedBudgets(BudgetRepository repository) {
        return args -> {
            if (repository.count() > 0) {
                return;
            }
            YearMonth current = YearMonth.now();

            repository.saveAll(List.of(
                    buildMonthly("Alimentation", 2500, 1850, 90, "Courses + cafés", current),
                    buildMonthly("Transport", 800, 650, 80, "Carburant et tram", current),
                    buildMonthly("Logement", 3000, 3000, 100, "Loyer + charges", current),
                    buildMonthly("Shopping", 1000, 420, 70, "Vêtements et cadeaux", current),
                    buildMonthly("Santé", 500, 280, 70, "Pharmacie / mutuelle", current),
                    buildMonthly("Loisirs", 700, 320, 80, "Sorties weekend", current)
            ));
        };
    }

    private Budget buildMonthly(String category, double budgetAmount, double spentAmount,
                                Integer alertThreshold, String note, YearMonth period) {
        Budget budget = new Budget();
        budget.setCategory(category);
        budget.setBudgetAmount(BigDecimal.valueOf(budgetAmount));
        budget.setSpentAmount(BigDecimal.valueOf(spentAmount));
        budget.setPeriodType(BudgetPeriodType.MONTHLY);
        budget.setPeriodMonth(period.getMonthValue());
        budget.setPeriodYear(period.getYear());
        budget.setAlertThreshold(alertThreshold);
        budget.setNote(note);
        budget.setCustomStart(period.atDay(1));
        budget.setCustomEnd(period.atEndOfMonth());
        return budget;
    }
}
