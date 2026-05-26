package com.alpharedge.controller;

import com.alpharedge.dto.request.AddHoldingRequest;
import com.alpharedge.dto.request.CreatePortfolioRequest;
import com.alpharedge.dto.response.PortfolioDTO;
import com.alpharedge.dto.response.PortfolioHistoryDTO;
import com.alpharedge.dto.response.PortfolioSummaryDTO;
import com.alpharedge.service.PortfolioService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Slf4j
@Validated
@RestController
@RequestMapping("/api/v1/portfolios")
@Tag(name = "Portfolios", description = "Portfolio management endpoints")
public class PortfolioController {

    private final PortfolioService portfolioService;

    @Autowired
    public PortfolioController(PortfolioService portfolioService) {
        this.portfolioService = portfolioService;
    }

    @PostMapping
    @Operation(summary = "Create portfolio", description = "Create a new portfolio for the user")
    public ResponseEntity<PortfolioDTO> createPortfolio(
            @Parameter(description = "User ID from header")
            @RequestHeader("X-User-Id") String userId,
            @Valid @RequestBody CreatePortfolioRequest request) {
        log.info("Create portfolio request for user: {}", userId);
        PortfolioDTO portfolio = portfolioService.createPortfolio(userId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(portfolio);
    }

    @GetMapping
    @Operation(summary = "Get user portfolios", description = "Retrieve all portfolios for the authenticated user")
    public ResponseEntity<List<PortfolioDTO>> getPortfolios(
            @Parameter(description = "User ID from header")
            @RequestHeader("X-User-Id") String userId) {
        log.debug("Get portfolios request for user: {}", userId);
        List<PortfolioDTO> portfolios = portfolioService.getPortfolios(userId);
        return ResponseEntity.ok(portfolios);
    }

    @PostMapping("/{id}/holdings")
    @Operation(summary = "Add holding to portfolio", description = "Add a cryptocurrency holding to a portfolio")
    public ResponseEntity<PortfolioDTO> addHolding(
            @Parameter(description = "Portfolio ID")
            @PathVariable String id,
            @Parameter(description = "User ID from header")
            @RequestHeader("X-User-Id") String userId,
            @Valid @RequestBody AddHoldingRequest request) {
        log.info("Add holding to portfolio: {} for user: {}", id, userId);
        PortfolioDTO portfolio = portfolioService.addHolding(id, userId, request);
        return ResponseEntity.ok(portfolio);
    }

    @DeleteMapping("/{id}/holdings/{holdingId}")
    @Operation(summary = "Remove holding from portfolio", description = "Remove a cryptocurrency holding from a portfolio")
    public ResponseEntity<PortfolioDTO> removeHolding(
            @Parameter(description = "Portfolio ID")
            @PathVariable String id,
            @Parameter(description = "Holding ID")
            @PathVariable String holdingId,
            @Parameter(description = "User ID from header")
            @RequestHeader("X-User-Id") String userId) {
        log.info("Remove holding from portfolio: {} for user: {}", id, userId);
        PortfolioDTO portfolio = portfolioService.removeHolding(id, holdingId, userId);
        return ResponseEntity.ok(portfolio);
    }

    @GetMapping("/{id}/summary")
    @Operation(summary = "Get portfolio summary", description = "Get portfolio performance summary and statistics")
    public ResponseEntity<PortfolioSummaryDTO> getPortfolioSummary(
            @Parameter(description = "Portfolio ID")
            @PathVariable String id,
            @Parameter(description = "User ID from header")
            @RequestHeader("X-User-Id") String userId) {
        log.debug("Get portfolio summary: {} for user: {}", id, userId);
        PortfolioSummaryDTO summary = portfolioService.getPortfolioSummary(id, userId);
        return ResponseEntity.ok(summary);
    }

    @GetMapping("/{id}/history")
    @Operation(summary = "Get portfolio value history", description = "Returns daily portfolio value in INR and USD for chart display")
    public ResponseEntity<PortfolioHistoryDTO> getPortfolioHistory(
            @Parameter(description = "Portfolio ID")
            @PathVariable String id,
            @Parameter(description = "User ID from header")
            @RequestHeader("X-User-Id") String userId,
            @Parameter(description = "Number of days of history")
            @RequestParam(defaultValue = "30") int days) {
        log.debug("Get portfolio history: {} for user: {}, days={}", id, userId, days);
        PortfolioHistoryDTO history = portfolioService.getPortfolioHistory(id, userId, days);
        return ResponseEntity.ok(history);
    }

    @GetMapping("/{id}/holdings")
    @Operation(summary = "Get portfolio holdings", description = "Get all holdings in a portfolio")
    public ResponseEntity<PortfolioDTO> getPortfolioHoldings(
            @Parameter(description = "Portfolio ID")
            @PathVariable String id,
            @Parameter(description = "User ID from header")
            @RequestHeader("X-User-Id") String userId) {
        log.debug("Get portfolio holdings: {} for user: {}", id, userId);
        List<PortfolioDTO> portfolios = portfolioService.getPortfolios(userId);
        PortfolioDTO portfolio = portfolios.stream()
                .filter(p -> p.getId().equals(id))
                .findFirst()
                .orElse(null);
        return ResponseEntity.ok(portfolio);
    }
}
