package assistant_coaching.demo.llm;

import java.util.Collections;
import java.util.List;

public class LlmResult {

    private final String reply;
    private final String model;
    private final Integer promptTokens;
    private final Integer completionTokens;
    private final Integer totalTokens;
    private final boolean fallbackActive;
    private final String fallbackNotice;
    private final List<String> quickReplies;

    public LlmResult(String reply, String model, Integer promptTokens, Integer completionTokens, Integer totalTokens) {
        this(reply, model, promptTokens, completionTokens, totalTokens, false, null, Collections.emptyList());
    }

    public LlmResult(String reply, String model, Integer promptTokens, Integer completionTokens,
                     Integer totalTokens, boolean fallbackActive, String fallbackNotice) {
        this(reply, model, promptTokens, completionTokens, totalTokens, fallbackActive, fallbackNotice, Collections.emptyList());
    }

    public LlmResult(String reply, String model, Integer promptTokens, Integer completionTokens,
                     Integer totalTokens, boolean fallbackActive, String fallbackNotice, List<String> quickReplies) {
        this.reply = reply;
        this.model = model;
        this.promptTokens = promptTokens;
        this.completionTokens = completionTokens;
        this.totalTokens = totalTokens;
        this.fallbackActive = fallbackActive;
        this.fallbackNotice = fallbackNotice;
        this.quickReplies = quickReplies == null ? Collections.emptyList() : List.copyOf(quickReplies);
    }

    public String getReply() {
        return reply;
    }

    public String getModel() {
        return model;
    }

    public Integer getPromptTokens() {
        return promptTokens;
    }

    public Integer getCompletionTokens() {
        return completionTokens;
    }

    public Integer getTotalTokens() {
        return totalTokens;
    }

    public boolean isFallbackActive() {
        return fallbackActive;
    }

    public String getFallbackNotice() {
        return fallbackNotice;
    }

    public List<String> getQuickReplies() {
        return quickReplies;
    }
}
