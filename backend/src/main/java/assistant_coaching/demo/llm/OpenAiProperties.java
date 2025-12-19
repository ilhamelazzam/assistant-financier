package assistant_coaching.demo.llm;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "llm")
public class OpenAiProperties {

    private String apiKey;
    private String baseUrl = "https://api.openai.com/v1/chat/completions";
    private String model = "gpt-4o-mini";
    private double temperature = 0.45;
    private int maxTokens = 600;
    private int timeoutSeconds = 20;
    private String systemPrompt = "Tu es un assistant vocal de coaching financier qui aide un utilisateur francophone à prendre des décisions d'épargne et d'investissement responsables.";
    private String fallbackReply = "Je ne peux pas accéder au modèle en ce moment ; voici un conseil basé sur vos objectifs (%s).";
    private String emptyTranscriptPlaceholder = "Racontez-moi vos priorités financières afin que je vous aide à faire le prochain pas.";
    private boolean enabled = true;

    public String getApiKey() {
        return apiKey;
    }

    public void setApiKey(String apiKey) {
        this.apiKey = apiKey;
    }

    public String getBaseUrl() {
        return baseUrl;
    }

    public void setBaseUrl(String baseUrl) {
        this.baseUrl = baseUrl;
    }

    public String getModel() {
        return model;
    }

    public void setModel(String model) {
        this.model = model;
    }

    public double getTemperature() {
        return temperature;
    }

    public void setTemperature(double temperature) {
        this.temperature = temperature;
    }

    public int getMaxTokens() {
        return maxTokens;
    }

    public void setMaxTokens(int maxTokens) {
        this.maxTokens = maxTokens;
    }

    public int getTimeoutSeconds() {
        return timeoutSeconds;
    }

    public void setTimeoutSeconds(int timeoutSeconds) {
        this.timeoutSeconds = timeoutSeconds;
    }

    public String getSystemPrompt() {
        return systemPrompt;
    }

    public void setSystemPrompt(String systemPrompt) {
        this.systemPrompt = systemPrompt;
    }

    public String getFallbackReply() {
        return fallbackReply;
    }

    public void setFallbackReply(String fallbackReply) {
        this.fallbackReply = fallbackReply;
    }

    public String getEmptyTranscriptPlaceholder() {
        return emptyTranscriptPlaceholder;
    }

    public void setEmptyTranscriptPlaceholder(String emptyTranscriptPlaceholder) {
        this.emptyTranscriptPlaceholder = emptyTranscriptPlaceholder;
    }

    public boolean isEnabled() {
        return enabled;
    }

    public void setEnabled(boolean enabled) {
        this.enabled = enabled;
    }
}
