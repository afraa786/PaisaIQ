package com.alpharedge.document;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Document(collection = "coin_signals")
public class CoinSignal {
    @Id
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
    private Signal signal;
    private SignalStrength strength;
    private BigDecimal volatilityScore;
    private BigDecimal momentumScore;
    private String signalExplanation;
    private Integer riskScore;

    @Builder.Default
    private LocalDateTime computedAt = LocalDateTime.now();

    public enum Signal {
        BUY,
        HOLD,
        SELL
    }

    public enum SignalStrength {
        WEAK,
        MODERATE,
        STRONG
    }
}
