package assistant_coaching.demo.goalchat;

import java.text.NumberFormat;
import java.util.Locale;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

final class GoalAmountParser {

    private static final Pattern NUMBER_PATTERN = Pattern.compile("(\\d+[\\d.,]*)");

    private GoalAmountParser() {
    }

    static String normalizeLabel(String input) {
        if (input == null) {
            return null;
        }
        String trimmed = input.trim();
        if (trimmed.isEmpty()) {
            return null;
        }
        String lower = trimmed.toLowerCase(Locale.ROOT);
        String operator = detectOperator(lower);
        Matcher matcher = NUMBER_PATTERN.matcher(lower.replace(" ", ""));
        if (!matcher.find()) {
            return null;
        }
        String digits = matcher.group(1).replaceAll("[^0-9]", "");
        if (digits.isEmpty()) {
            return null;
        }
        long amount = Long.parseLong(digits);
        String formattedAmount = NumberFormat.getNumberInstance(Locale.FRANCE).format(amount);
        String currency = detectCurrency(lower);
        return operator + " " + formattedAmount + " " + currency;
    }

    private static String detectOperator(String value) {
        if (value.contains("<")) {
            return "<";
        }
        if (value.contains(">")) {
            return ">";
        }
        return "=";
    }

    private static String detectCurrency(String value) {
        if (value.contains("dh") || value.contains("dirham") || value.contains("mad")) {
            return "MAD";
        }
        return "MAD";
    }
}
