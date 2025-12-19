package assistant_coaching.demo.llm;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;

public class LlmMessage {
    private final String role;
    private final String content;

    @JsonCreator
    public LlmMessage(@JsonProperty("role") String role,
                      @JsonProperty("content") String content) {
        this.role = role;
        this.content = content;
    }

    public String getRole() {
        return role;
    }

    public String getContent() {
        return content;
    }
}
