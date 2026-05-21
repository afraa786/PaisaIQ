package com.alpharedge.dto.request;

import com.alpharedge.document.TradeTransaction;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CreateTradeRequest {

    @NotBlank(message = "User ID is required")
    private String userId;

    @NotNull(message = "Entity type is required")
    private TradeTransaction.EntityType entityType;

    private String businessName;

    @NotBlank(message = "Coin symbol is required")
    private String coinSymbol;

    @NotNull(message = "Trade type is required")
    private TradeTransaction.TradeType type;

    @NotNull(message = "Quantity is required")
    @DecimalMin(value = "0.00000001", message = "Quantity must be greater than 0")
    private BigDecimal quantity;

    @NotNull(message = "Price per unit is required")
    @DecimalMin(value = "0.01", message = "Price per unit must be at least 0.01")
    private BigDecimal pricePerUnit;

    @NotNull(message = "Timestamp is required")
    private LocalDateTime timestamp;

    @NotBlank(message = "Exchange name is required")
    private String exchangeName;

    private String notes;
}
