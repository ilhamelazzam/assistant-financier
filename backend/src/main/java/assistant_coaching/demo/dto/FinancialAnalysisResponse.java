package assistant_coaching.demo.dto;

import java.util.List;

public class FinancialAnalysisResponse {

    private final List<PeriodAnalysisDto> periods;

    public FinancialAnalysisResponse(List<PeriodAnalysisDto> periods) {
        this.periods = periods;
    }

    public List<PeriodAnalysisDto> getPeriods() {
        return periods;
    }
}
