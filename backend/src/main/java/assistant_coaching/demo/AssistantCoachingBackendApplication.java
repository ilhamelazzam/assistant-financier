package assistant_coaching.demo;

import assistant_coaching.demo.llm.OpenAiProperties;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;

@SpringBootApplication
@EnableConfigurationProperties(OpenAiProperties.class)
public class AssistantCoachingBackendApplication {

	public static void main(String[] args) {
		SpringApplication.run(AssistantCoachingBackendApplication.class, args);
	}

}
