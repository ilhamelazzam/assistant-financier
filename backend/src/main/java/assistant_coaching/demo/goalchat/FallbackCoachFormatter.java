package assistant_coaching.demo.goalchat;

import java.text.Normalizer;
import java.text.NumberFormat;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Locale;

import assistant_coaching.demo.goalchat.BudgetSnapshot.BudgetCategory;
import org.springframework.stereotype.Component;

/**
 * Builds user-facing fallback replies so they follow the UX guidelines:
 * mini résumé + actions + une seule question + quick replies.
 */
@Component
public class FallbackCoachFormatter {

    private static final List<String> SPENDING_OPTIONS = List.of("Restos", "Shopping", "Abonnements", "Transport");
    private final BudgetSnapshot snapshot;

    public FallbackCoachFormatter() {
        this(BudgetSnapshot.defaultSnapshot());
    }

    public FallbackCoachFormatter(BudgetSnapshot snapshot) {
        this.snapshot = snapshot;
    }

    public FallbackMessage buildQuestionMessage(String goalLabel, String fallbackQuestion) {
        String followUp = fallbackQuestion == null || fallbackQuestion.isBlank()
                ? "Peux-tu me donner ton revenu mensuel net approximatif pour que je puisse affiner le plan ?"
                : fallbackQuestion.trim();
        List<String> quickReplies = quickRepliesFor(followUp);
        return new FallbackMessage(followUp, quickReplies);
    }

    public FallbackMessage buildPlanMessage(String goalLabel, List<AnswerValue> answers) {
        StringBuilder builder = new StringBuilder();
        builder.append(buildSummaryLine(goalLabel)).append("\n");
        builder.append("Actions (cette semaine) :\n");

        List<String> actions = new ArrayList<>(buildActionLines());
        if (!answers.isEmpty()) {
            AnswerValue latest = answers.get(answers.size() - 1);
            actions.set(0, "Garde en tête ce que tu viens de préciser : \"" + latest.answer() + "\".");
        }
        for (String action : actions) {
            builder.append("• ").append(action).append("\n");
        }
        builder.append("Question : Souhaites-tu qu'on fasse un point ensemble après ces trois actions ?");
        List<String> quickReplies = List.of("Oui, rappel", "Je gère seul(e)", "Propose autre chose");
        return new FallbackMessage(builder.toString().trim(), quickReplies);
    }

    public record AnswerValue(String question, String answer) {
    }

    public record FallbackMessage(String message, List<String> quickReplies) {
        public FallbackMessage {
            quickReplies = quickReplies == null ? Collections.emptyList() : List.copyOf(quickReplies);
        }
    }

    private String buildSummaryLine(String goalLabel) {
        List<BudgetCategory> topUsage = snapshot.topCategories(2);
        long usagePercent = Math.round(snapshot.getUsagePercent() * 100);
        NumberFormat format = NumberFormat.getIntegerInstance(Locale.FRANCE);
        String spent = format.format(Math.round(snapshot.getSpent()));
        String total = format.format(Math.round(snapshot.getTotalBudget()));
        StringBuilder summary = new StringBuilder("Résumé : Tu utilises ~")
                .append(spent)
                .append(" MAD sur ")
                .append(total)
                .append(" MAD (")
                .append(usagePercent)
                .append("%) pour avancer vers \"")
                .append(goalLabel)
                .append("\".");
        if (topUsage.size() >= 2) {
            BudgetCategory first = topUsage.get(0);
            BudgetCategory second = topUsage.get(1);
            summary.append(" ")
                    .append(first.name())
                    .append(" est à ")
                    .append(first.usagePercentRounded())
                    .append("% et ")
                    .append(second.name())
                    .append(" à ")
                    .append(second.usagePercentRounded())
                    .append("% : concentrons-nous sur ces postes variables.");
        } else if (topUsage.size() == 1) {
            BudgetCategory first = topUsage.get(0);
            summary.append(" ").append(first.name())
                    .append(" est utilisé à ")
                    .append(first.usagePercentRounded())
                    .append("%.");
        }
        return summary.toString();
    }

    private List<String> buildActionLines() {
        NumberFormat format = NumberFormat.getIntegerInstance(Locale.FRANCE);
        List<BudgetCategory> adjustable = snapshot.topAdjustableCategories(3);
        List<String> actions = new ArrayList<>();
        if (adjustable.size() >= 3) {
            actions.add(String.format(
                    "Liste tes 3 postes flexibles clés (%s, %s, %s) et note un objectif réaliste pour chacun.",
                    adjustable.get(0).name(),
                    adjustable.get(1).name(),
                    adjustable.get(2).name()));
        } else if (!adjustable.isEmpty()) {
            actions.add("Liste tes postes flexibles prioritaires et pose des objectifs rapides poste par poste.");
        } else {
            actions.add("Fais un point rapide sur tes postes variables pour garder le contrôle.");
        }

        BudgetCategory focus = adjustable.isEmpty() ? null : adjustable.get(0);
        if (focus != null) {
            String limit = format.format(Math.round(focus.limit()));
            String spent = format.format(Math.round(focus.spent()));
            actions.add(String.format(
                    "Fixe un plafond confort/loisirs à %s MAD max (actuellement %s MAD sur %s).",
                    limit,
                    spent,
                    focus.name()));
        } else {
            actions.add("Fixe un plafond confort hebdomadaire et respecte-le.");
        }

        long suggestedTransfer = Math.max(200,
                Math.min(600, Math.round(snapshot.getAvailable() * 0.3 / 10) * 10));
        if (suggestedTransfer == 0) {
            suggestedTransfer = 200;
        }
        actions.add("Automatise " + format.format(suggestedTransfer) + " MAD d'épargne juste après le salaire.");
        return actions;
    }

    private List<String> quickRepliesFor(String question) {
        if (question == null) {
            return SPENDING_OPTIONS;
        }
        String normalized = Normalizer.normalize(question, Normalizer.Form.NFD)
                .replaceAll("\\p{M}+", "")
                .toLowerCase(Locale.ROOT);
        if (containsAny(normalized, "depense", "reduire", "budget", "confort")) {
            return SPENDING_OPTIONS;
        }
        if (containsAny(normalized, "revenu", "salaire", "gagne")) {
            return List.of("< 7 000 MAD", "7 000 - 12 000 MAD", "> 12 000 MAD", "Variable");
        }
        if (containsAny(normalized, "date", "echeance", "quand")) {
            return List.of("Ce trimestre", "6 mois", "1 an", "Je ne sais pas");
        }
        if (containsAny(normalized, "epargne", "mettre de cote", "montant")) {
            return List.of("100 MAD", "300 MAD", "500 MAD", "Je ne sais pas");
        }
        return List.of("OK", "Je reformule", "Plus tard");
    }

    private boolean containsAny(String value, String... keywords) {
        for (String keyword : keywords) {
            if (value.contains(keyword)) {
                return true;
            }
        }
        return false;
    }
}
