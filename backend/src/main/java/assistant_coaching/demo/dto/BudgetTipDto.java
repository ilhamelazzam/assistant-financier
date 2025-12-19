package assistant_coaching.demo.dto;

public class BudgetTipDto {
    private final String tone;
    private final String message;
    private final String category;

    public BudgetTipDto(String tone, String message, String category) {
        this.tone = tone;
        this.message = message;
        this.category = category;
    }

    public String getTone() {
        return tone;
    }

    public String getMessage() {
        return message;
    }

    public String getCategory() {
        return category;
    }
}
