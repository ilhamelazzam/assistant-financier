package assistant_coaching.demo.service;

import assistant_coaching.demo.dto.CategoryShareDto;
import assistant_coaching.demo.dto.FinancialAnalysisResponse;
import assistant_coaching.demo.dto.PeriodAnalysisDto;
import assistant_coaching.demo.model.AnalysisPeriod;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdmodel.font.PDType1Font;
import org.springframework.stereotype.Service;

import java.util.List;
import java.io.ByteArrayOutputStream;

@Service
public class FinancialAnalysisService {

    public FinancialAnalysisResponse getAnalysis() {
        return new FinancialAnalysisResponse(
                List.of(buildWeek(), buildMonth(), buildYear())
        );
    }

    public byte[] generatePdfReport() {
        PeriodAnalysisDto month = buildMonth();
        try (PDDocument document = new PDDocument();
             ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            PDPage page = new PDPage(PDRectangle.A4);
            document.addPage(page);

            try (PDPageContentStream content = new PDPageContentStream(document, page)) {
                content.beginText();
                content.setFont(PDType1Font.HELVETICA_BOLD, 18);
                content.newLineAtOffset(50, 770);
                content.showText("Rapport Financier IA");
                content.endText();

                content.beginText();
                content.setFont(PDType1Font.HELVETICA, 12);
                content.newLineAtOffset(50, 740);
                content.showText("Periode: " + "Mois en cours");
                content.endText();

                content.beginText();
                content.setFont(PDType1Font.HELVETICA_BOLD, 14);
                content.newLineAtOffset(50, 710);
                content.showText("Score et tendances");
                content.endText();

                content.beginText();
                content.setFont(PDType1Font.HELVETICA, 12);
                content.newLineAtOffset(50, 690);
                content.showText("Revenus: " + month.getRevenue() + " MAD / Depenses: " + month.getExpense() + " MAD");
                content.endText();

                content.beginText();
                content.setFont(PDType1Font.HELVETICA, 12);
                content.newLineAtOffset(50, 670);
                content.showText("Variation revenus: " + month.getRevenueChange() + "% | Variation depenses: " + month.getExpenseChange() + "%");
                content.endText();

                content.beginText();
                content.setFont(PDType1Font.HELVETICA_BOLD, 14);
                content.newLineAtOffset(50, 640);
                content.showText("Analyse IA");
                content.endText();

                content.beginText();
                content.setFont(PDType1Font.HELVETICA, 12);
                content.newLineAtOffset(50, 620);
                content.showText(shorten(month.getInsightBody()));
                content.endText();

                float y = 590;
                content.beginText();
                content.setFont(PDType1Font.HELVETICA_BOLD, 14);
                content.newLineAtOffset(50, y);
                content.showText("Recommandations");
                content.endText();
                y -= 20;
                for (String reco : month.getRecommendations()) {
                    content.beginText();
                    content.setFont(PDType1Font.HELVETICA, 12);
                    content.newLineAtOffset(55, y);
                    content.showText("- " + shorten(reco));
                    content.endText();
                    y -= 18;
                    if (y < 80) break;
                }
            }

            document.save(out);
            return out.toByteArray();
        } catch (Exception ex) {
            throw new RuntimeException("Impossible de generer le PDF du rapport.", ex);
        }
    }

    private String shorten(String text) {
        if (text == null) return "";
        return text.length() > 140 ? text.substring(0, 140) + "..." : text;
    }

    private PeriodAnalysisDto buildWeek() {
        return new PeriodAnalysisDto(
                AnalysisPeriod.WEEK,
                2_150,
                4.2,
                1_260,
                6.8,
                List.of(1_800d, 1_920d, 2_050d, 2_100d, 2_150d),
                List.of(880d, 950d, 1_040d, 1_180d, 1_260d),
                weekDistribution(),
                "Analyse IA de la semaine",
                "Vos depenses transport ont augmente de 12% cette semaine, surtout a cause des trajets domicile-travail.",
                List.of(
                        "Utilisez le tram pour economiser 120 MAD",
                        "Planifiez vos courses pour reduire les achats impulsifs",
                        "Gardez 10% de marge pour les imprevus"
                )
        );
    }

    private PeriodAnalysisDto buildMonth() {
        return new PeriodAnalysisDto(
                AnalysisPeriod.MONTH,
                8_500,
                5.0,
                4_320,
                12.0,
                List.of(7_800d, 8_100d, 7_900d, 8_300d, 8_500d),
                List.of(3_600d, 3_800d, 3_900d, 4_100d, 4_320d),
                monthDistribution(),
                "Analyse IA du mois",
                "Vos depenses en transport ont augmente de 25% vs le mois dernier. Optimisez les deplacements pour rester dans le budget.",
                List.of(
                        "Utilisez les transports en commun pour economiser 400 MAD",
                        "Reduisez vos achats shopping de 20%",
                        "Excellente tenue sur l'alimentation"
                )
        );
    }

    private PeriodAnalysisDto buildYear() {
        return new PeriodAnalysisDto(
                AnalysisPeriod.YEAR,
                99_400,
                8.4,
                52_350,
                3.2,
                List.of(82_000d, 87_000d, 91_000d, 95_500d, 99_400d),
                List.of(47_000d, 48_000d, 50_000d, 51_500d, 52_350d),
                yearDistribution(),
                "Analyse IA de l'annee",
                "Bonne dynamique: les depenses progressent moins vite que les revenus. La part logement reste toutefois elevee.",
                List.of(
                        "Renegociez votre loyer ou vos abonnements annuels",
                        "Augmentez l'epargne mensuelle de 5%",
                        "Preparez un budget vacances dedie"
                )
        );
    }

    private List<CategoryShareDto> weekDistribution() {
        return List.of(
                new CategoryShareDto("Alimentation", 28, "#1E88E5"),
                new CategoryShareDto("Logement", 24, "#00BFA5"),
                new CategoryShareDto("Sante", 13, "#26C6DA"),
                new CategoryShareDto("Transport", 15, "#00ACC1"),
                new CategoryShareDto("Shopping", 12, "#66BB6A"),
                new CategoryShareDto("Loisirs", 8, "#00796B")
        );
    }

    private List<CategoryShareDto> monthDistribution() {
        return List.of(
                new CategoryShareDto("Alimentation", 30, "#1E88E5"),
                new CategoryShareDto("Logement", 25, "#00BFA5"),
                new CategoryShareDto("Sante", 15, "#26C6DA"),
                new CategoryShareDto("Transport", 12, "#00ACC1"),
                new CategoryShareDto("Shopping", 10, "#66BB6A"),
                new CategoryShareDto("Loisirs", 8, "#00796B")
        );
    }

    private List<CategoryShareDto> yearDistribution() {
        return List.of(
                new CategoryShareDto("Alimentation", 24, "#1E88E5"),
                new CategoryShareDto("Logement", 32, "#00BFA5"),
                new CategoryShareDto("Sante", 9, "#26C6DA"),
                new CategoryShareDto("Transport", 10, "#00ACC1"),
                new CategoryShareDto("Shopping", 15, "#66BB6A"),
                new CategoryShareDto("Loisirs", 10, "#00796B")
        );
    }
}
