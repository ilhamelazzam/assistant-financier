package assistant_coaching.demo.dto;

public class CategoryShareDto {

    private final String label;
    private final double value;
    private final String color;

    public CategoryShareDto(String label, double value, String color) {
        this.label = label;
        this.value = value;
        this.color = color;
    }

    public String getLabel() {
        return label;
    }

    public double getValue() {
        return value;
    }

    public String getColor() {
        return color;
    }
}
