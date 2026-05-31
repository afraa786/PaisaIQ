package com.alpharedge.dto.tax;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "Hypothetical sell trade for what-if tax simulation")
public class SimulateTradeRequest {

    @NotBlank(message = "Coin symbol is required")
    @Schema(description = "Coin symbol e.g. BTC, ETH", example = "ETH")
    private String coinSymbol;

    @NotNull(message = "Quantity is required")
    @DecimalMin(value = "0.00000001", message = "Quantity must be greater than 0")
    @Schema(description = "Number of coins to hypothetically sell", example = "2.0")
    private BigDecimal quantity;

    @NotNull(message = "Current price is required")
    @DecimalMin(value = "0.01", message = "Price must be greater than 0")
    @Schema(description = "Current sell price in INR per coin", example = "200000.00")
    private BigDecimal currentPriceInr;
}
