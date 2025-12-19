package assistant_coaching.demo.controller;

import assistant_coaching.demo.dto.FinancialAnalysisResponse;
import assistant_coaching.demo.service.FinancialAnalysisService;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/analysis")
public class FinancialAnalysisController {

    private final FinancialAnalysisService service;

    public FinancialAnalysisController(FinancialAnalysisService service) {
        this.service = service;
    }

    @GetMapping
    public FinancialAnalysisResponse getAnalysis() {
        return service.getAnalysis();
    }

    @GetMapping(value = "/report.pdf", produces = MediaType.APPLICATION_PDF_VALUE)
    public ResponseEntity<byte[]> downloadReport() {
        byte[] pdf = service.generatePdfReport();
        HttpHeaders headers = new HttpHeaders();
        headers.add(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"rapport_financier.pdf\"");
        return ResponseEntity.ok()
                .headers(headers)
                .contentType(MediaType.APPLICATION_PDF)
                .body(pdf);
    }
}
