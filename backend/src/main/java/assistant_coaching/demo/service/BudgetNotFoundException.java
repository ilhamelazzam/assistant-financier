package assistant_coaching.demo.service;

public class BudgetNotFoundException extends RuntimeException {
    public BudgetNotFoundException(Long id) {
        super("Budget " + id + " introuvable.");
    }
}
