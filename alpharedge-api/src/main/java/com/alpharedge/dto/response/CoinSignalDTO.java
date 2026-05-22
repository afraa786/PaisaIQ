package com.alpharedge.dto.response;

import com.alpharedge.document.CoinSignal;
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
public class CoinSignalDTO {
    private String id;
    private String coinId;
    private BigDecimal rsi;
    private BigDecimal macd;
    private BigDecimal macdSignal;
    private BigDecimal macdHistogram;
    private BigDecimal sma7;
    private BigDecimal sma30;
    private BigDecimal bollingerUpper;
    private BigDecimal bollingerMiddle;
    private BigDecimal bollingerLower;
    private CoinSignal.Signal signal;
    private CoinSignal.SignalStrength strength;
    private BigDecimal volatilityScore;
    private BigDecimal momentumScore;
    private String signalExplanation;
    private Integer riskScore;
    private LocalDateTime computedAt;
}
