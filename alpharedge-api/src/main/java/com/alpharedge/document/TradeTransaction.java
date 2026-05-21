package com.alpharedge.document;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Document(collection = "trade_transactions")
public class TradeTransaction {

    @Id
    private String id;

    @Indexed
    private String userId;

    private EntityType entityType;

    private String businessName;

    private String coinSymbol;

    private TradeType type;

    private BigDecimal quantity;

    private BigDecimal pricePerUnit;

    private BigDecimal totalAmount;

    private BigDecimal tdsPaid;

    private LocalDateTime timestamp;

    private String financialYear;

    private String exchangeName;

    private String notes;

    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    public enum EntityType {
        INDIVIDUAL,
        BUSINESS
    }

    public enum TradeType {
        BUY,
        SELL,
        TRANSFER_IN,
        TRANSFER_OUT,
        PAYMENT_RECEIVED,
        PAYMENT_SENT
    }

    public enum Exchange {
        WazirX,
        CoinDCX,
        Zebpay,
        Manual
    }

    /**
     * Indian financial year: April–March.
     * April 2025 → "2025-26", January 2026 → "2025-26"
     */
    public static String computeFinancialYear(LocalDateTime timestamp) {
        int year = timestamp.getYear();
        int month = timestamp.getMonthValue();
        if (month >= 4) {
            int shortNext = (year + 1) % 100;
            return String.format("%d-%02d", year, shortNext);
        } else {
            int shortCurrent = year % 100;
            return String.format("%d-%02d", year - 1, shortCurrent);
        }
    }
}
