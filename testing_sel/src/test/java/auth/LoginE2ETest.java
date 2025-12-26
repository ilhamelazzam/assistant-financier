package auth;

import io.github.bonigarcia.wdm.WebDriverManager;
import org.junit.jupiter.api.*;
import org.openqa.selenium.*;
import org.openqa.selenium.chrome.*;
import org.openqa.selenium.interactions.Actions;
import org.openqa.selenium.support.ui.*;

import java.net.URI;
import java.net.http.*;
import java.time.Duration;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

public class LoginE2ETest {

    private WebDriver driver;
    private WebDriverWait wait;

    private static final String BACKEND_BASE =
            System.getProperty("BACKEND_BASE", "http://127.0.0.1:8081");

    private static final String BASE_URL =
            System.getProperty("BASE_URL", "http://127.0.0.1:49290/#/auth");

    @BeforeEach
    void setup() {
        WebDriverManager.chromedriver().setup();

        ChromeOptions options = new ChromeOptions();
        options.addArguments("--window-size=1400,900");
        // options.addArguments("--headless=new");

        driver = new ChromeDriver(options);
        wait = new WebDriverWait(driver, Duration.ofSeconds(30));
    }

    @AfterEach
    void tearDown() {
        if (driver != null) driver.quit();
    }

    @Test
    void login_success_redirects_to_dashboard() throws Exception {
        // 1) créer user
        String email = "test_" + UUID.randomUUID() + "@abir.com";
        String password = "Password123";
        registerUser(email, password);

        // 2) ouvrir login
        driver.get(BASE_URL);

        // ✅ 3) attendre directement les vrais champs (pas flt-semantics)
        WebElement emailInput = wait.until(ExpectedConditions.elementToBeClickable(
                By.cssSelector("input[placeholder='votre@email.com']")
        ));

        WebElement passInput = wait.until(ExpectedConditions.elementToBeClickable(
                By.cssSelector("input[type='password']")
        ));

        // 4) remplir
        clearAndType(emailInput, email);
        clearAndType(passInput, password);

        // ✅ 5) cliquer sur bouton login via texte visible (robuste)
        WebElement loginBtn = wait.until(ExpectedConditions.elementToBeClickable(
                By.xpath("//*[normalize-space()='Se connecter' or contains(normalize-space(),'Se connecter')]")
        ));
        safeClick(loginBtn);

        // 6) vérifier url dashboard
        wait.until(d -> d.getCurrentUrl().contains("#/dashboard"));
        assertTrue(driver.getCurrentUrl().contains("#/dashboard"));
    }

    // ---------------- helpers ----------------

    private void clearAndType(WebElement el, String value) {
        el.click();
        el.sendKeys(Keys.chord(Keys.CONTROL, "a"));
        el.sendKeys(Keys.DELETE);
        el.sendKeys(value);
    }

    private void safeClick(WebElement el) {
        try {
            el.click();
        } catch (Exception e) {
            new Actions(driver).moveToElement(el).click().perform();
        }
    }

    // ---------------- register API ----------------

    private void registerUser(String email, String password) throws Exception {
        String url = BACKEND_BASE + "/auth/register";

        String json = """
        {
          "email": "%s",
          "password": "%s",
          "displayName": "Test User",
          "phoneNumber": "0600000000",
          "location": "Marrakech"
        }
        """.formatted(email, password);

        HttpClient client = HttpClient.newHttpClient();
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(json))
                .build();

        HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());

        if (response.statusCode() != 201 && response.statusCode() != 200) {
            throw new RuntimeException("Register failed: HTTP " + response.statusCode() + " => " + response.body());
        }
    }
}
