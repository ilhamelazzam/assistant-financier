package assistant_coaching.demo.model;

public enum BudgetPeriodType {
    MONTHLY,
    WEEKLY,
    CUSTOM;

    public String label() {
        return switch (this) {
            case MONTHLY -> "Mensuel";
            case WEEKLY -> "Hebdomadaire";
            case CUSTOM -> "Personnalisé";
        };
    }
}
