package com.alpharedge.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CoinPriceDTO {
    private String coinId;
    private BigDecimal priceUSD;
    private BigDecimal priceINR;
    private LocalDateTime lastUpdated;
}
