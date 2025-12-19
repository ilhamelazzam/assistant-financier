package assistant_coaching.demo.llm;

import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.List;

public class LlmRequest {

    private final String model;
    private final double temperature;

    @JsonProperty("max_tokens")
    private final int maxTokens;
    private final List<LlmMessage> messages;

    public LlmRequest(String model, double temperature, int maxTokens, List<LlmMessage> messages) {
        this.model = model;
        this.temperature = temperature;
        this.maxTokens = maxTokens;
        this.messages = messages;
    }

    public String getModel() {
        return model;
    }

    public double getTemperature() {
        return temperature;
    }

    public int getMaxTokens() {
        return maxTokens;
    }

    public List<LlmMessage> getMessages() {
        return messages;
    }
}
