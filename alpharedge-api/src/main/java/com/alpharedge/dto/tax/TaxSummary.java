package com.alpharedge.dto.tax;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TaxSummary {

    private String userId;
    private String financialYear;

    private BigDecimal totalProfitInr;
    private BigDecimal totalLossInr;
    private BigDecimal netProfitLossInr;
    private BigDecimal taxOwedInr;        // 30% of net profit (Section 115BBH)
    private BigDecimal tdsPaidInr;        // 1% TDS already deducted (Section 194S)
    private BigDecimal netTaxDueInr;      // taxOwed - tdsPaid

    private List<CoinTaxDetail> perCoinBreakdown;
    private List<String> calculationSteps;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class CoinTaxDetail {
        private String coinSymbol;
        private BigDecimal unitsBought;
        private BigDecimal unitsSold;
        private BigDecimal profitLossInr;
        private BigDecimal taxInr;
        private BigDecimal tdsInr;
    }
}
