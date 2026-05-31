package com.alpharedge.controller;

import com.alpharedge.dto.tax.SimulateTradeRequest;
import com.alpharedge.dto.tax.SimulationResult;
import com.alpharedge.dto.tax.TaxSummary;
import com.alpharedge.engine.TaxEngineService;
import com.alpharedge.service.TaxReportService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;

@Slf4j
@RestController
@RequestMapping("/api/v1/tax")
@RequiredArgsConstructor
@Tag(name = "Tax", description = "Indian crypto tax calculation, PDF reports, and what-if simulation")
public class TaxController {

    private final TaxEngineService taxEngineService;
    private final TaxReportService taxReportService;

    @GetMapping("/{userId}/summary")
    @Operation(
        summary = "Get tax summary",
        description = "Computes FIFO-based tax summary for a user and financial year. "
                    + "Applies Section 115BBH (30% flat) and Section 194S (1% TDS).")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "Tax summary computed",
            content = @Content(schema = @Schema(implementation = TaxSummary.class))),
        @ApiResponse(responseCode = "400", description = "Invalid FY format", content = @Content)
    })
    public ResponseEntity<TaxSummary> getTaxSummary(
            @Parameter(description = "User ID") @PathVariable String userId,
            @Parameter(description = "Financial year e.g. 2025-26", example = "2025-26")
            @RequestParam(defaultValue = "") String fy) {

        String financialYear = resolveFinancialYear(fy);
        log.debug("Tax summary request: userId={}, fy={}", userId, financialYear);
        TaxSummary summary = taxEngineService.calculateForUser(userId, financialYear);
        return ResponseEntity.ok(summary);
    }

    @GetMapping("/{userId}/report/pdf")
    @Operation(
        summary = "Download PDF tax report",
        description = "Generates a 3-page PDF: Page 1 = summary with 4 key numbers, "
                    + "Page 2 = per-coin table, Page 3 = FIFO audit trail. "
                    + "Ready to hand to a CA or upload to ITR portal.")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "PDF generated successfully"),
        @ApiResponse(responseCode = "500", description = "PDF generation failed", content = @Content)
    })
    public ResponseEntity<byte[]> downloadPdfReport(
            @Parameter(description = "User ID") @PathVariable String userId,
            @Parameter(description = "Financial year e.g. 2025-26", example = "2025-26")
            @RequestParam(defaultValue = "") String fy) {

        String financialYear = resolveFinancialYear(fy);
        log.info("PDF report request: userId={}, fy={}", userId, financialYear);

        TaxSummary summary = taxEngineService.calculateForUser(userId, financialYear);
        byte[] pdf = taxReportService.generateTaxReport(summary);

        String filename = "crypto-tax-FY" + financialYear + ".pdf";
        return ResponseEntity.ok()
                .contentType(MediaType.APPLICATION_PDF)
                .header(HttpHeaders.CONTENT_DISPOSITION,
                        "attachment; filename=\"" + filename + "\"")
                .header(HttpHeaders.CACHE_CONTROL, "no-cache, no-store, must-revalidate")
                .body(pdf);
    }

    @PostMapping("/{userId}/simulate")
    @Operation(
        summary = "What-if tax simulator",
        description = "Simulates a hypothetical sell without saving to DB. "
                    + "Returns projected profit, tax (30%), TDS (1%), net received, "
                    + "and plain-English recommendation. "
                    + "Helps users understand tax impact before executing a trade.")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "Simulation result returned",
            content = @Content(schema = @Schema(implementation = SimulationResult.class))),
        @ApiResponse(responseCode = "400", description = "Validation failed", content = @Content)
    })
    public ResponseEntity<SimulationResult> simulateTrade(
            @Parameter(description = "User ID") @PathVariable String userId,
            @Valid @RequestBody SimulateTradeRequest request) {

        log.debug("Simulate trade: userId={}, coin={}, qty={}, price={}",
                userId, request.getCoinSymbol(), request.getQuantity(), request.getCurrentPriceInr());
        SimulationResult result = taxEngineService.simulate(userId, request);
        return ResponseEntity.ok(result);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private String resolveFinancialYear(String fy) {
        if (fy != null && !fy.isBlank()) return fy.trim();
        return computeCurrentFY();
    }

    private String computeCurrentFY() {
        LocalDateTime now = LocalDateTime.now();
        int year = now.getYear();
        int month = now.getMonthValue();
        if (month >= 4) {
            return String.format("%d-%02d", year, (year + 1) % 100);
        } else {
            return String.format("%d-%02d", year - 1, year % 100);
        }
    }
}
