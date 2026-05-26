package com.alpharedge.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PortfolioHistoryDTO {
    private String portfolioId;
    private String portfolioName;
    private List<DailyValueDTO> history;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class DailyValueDTO {
        private LocalDate date;
        private BigDecimal totalValueInr;
        private BigDecimal totalValueUsd;
    }
}
