package com.alpharedge.dto.response;

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
public class PortfolioSummaryDTO {
    private String portfolioId;
    private String portfolioName;

    // USD totals
    private BigDecimal totalValueUsd;
    private BigDecimal totalCostBasisUsd;
    private BigDecimal totalPnlUsd;
    private BigDecimal totalPnlPercent;

    // INR totals (for Flutter display)
    private BigDecimal totalValueInr;
    private BigDecimal totalCostBasisInr;
    private BigDecimal totalPnlInr;

    // 24h change
    private BigDecimal dayChangeInr;
    private BigDecimal dayChangePercent;

    private String bestPerformer;
    private BigDecimal bestPerformerGain;
    private String worstPerformer;
    private BigDecimal worstPerformerLoss;

    private List<HoldingPerformanceDTO> holdings;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class HoldingPerformanceDTO {
        private String holdingId;
        private String coinId;
        private String symbol;
        private BigDecimal quantity;

        // USD
        private BigDecimal currentPriceUsd;
        private BigDecimal currentValueUsd;
        private BigDecimal costBasisUsd;
        private BigDecimal pnlUsd;
        private BigDecimal pnlPercent;

        // INR
        private BigDecimal currentPriceInr;
        private BigDecimal currentValueInr;
        private BigDecimal costBasisInr;
        private BigDecimal pnlInr;

        // 24h change
        private BigDecimal dayChangeInr;
        private BigDecimal dayChangePercent;
    }
}
