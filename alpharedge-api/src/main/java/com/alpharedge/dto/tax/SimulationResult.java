package com.alpharedge.dto.tax;

import io.swagger.v3.oas.annotations.media.Schema;
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
@Schema(description = "Result of a what-if tax simulation for a hypothetical sell")
public class SimulationResult {

    @Schema(description = "Total sale proceeds in INR (qty × price)")
    private BigDecimal saleValueInr;

    @Schema(description = "Profit from this sale after FIFO cost basis (INR)")
    private BigDecimal projectedProfitInr;

    @Schema(description = "Tax owed on this sale at 30% flat rate (INR)")
    private BigDecimal projectedTaxInr;

    @Schema(description = "TDS deducted at source at 1% of sale value (INR)")
    private BigDecimal projectedTdsInr;

    @Schema(description = "Amount you actually receive after tax and TDS (INR)")
    private BigDecimal netReceivedInr;

    @Schema(description = "Effective tax rate as percentage of sale value")
    private BigDecimal effectiveTaxRatePct;

    @Schema(description = "Step-by-step calculation trail")
    private List<String> calculationSteps;

    @Schema(description = "Plain English recommendation")
    private String recommendation;
}
