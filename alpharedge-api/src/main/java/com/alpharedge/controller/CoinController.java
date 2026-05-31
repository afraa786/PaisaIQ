package com.alpharedge.controller;

import com.alpharedge.dto.response.CoinDetailDTO;
import com.alpharedge.dto.response.CoinPriceDTO;
import com.alpharedge.dto.response.CoinSignalDTO;
import com.alpharedge.dto.response.CompareDTO;
import com.alpharedge.dto.response.OhlcDTO;
import com.alpharedge.dto.response.PriceSnapshotDTO;
import com.alpharedge.dto.response.TrackedCoinDTO;
import com.alpharedge.service.CoinService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
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
@RequestMapping("/api/v1/coins")
@Tag(name = "Coins", description = "Cryptocurrency tracking and data endpoints")
public class CoinController {

    private final CoinService coinService;

    @Autowired
    public CoinController(CoinService coinService) {
        this.coinService = coinService;
    }

    @PostMapping("/track")
    @Operation(summary = "Track a new cryptocurrency", description = "Start tracking a cryptocurrency by its CoinGecko ID")
    public ResponseEntity<TrackedCoinDTO> trackCoin(
            @Parameter(description = "CoinGecko coin ID (e.g., 'bitcoin')")
            @RequestParam String coinId) {
        log.info("Track coin request: {}", coinId);
        TrackedCoinDTO tracked = coinService.trackCoin(coinId);
        return ResponseEntity.status(HttpStatus.CREATED).body(tracked);
    }

    @GetMapping
    @Operation(summary = "Get all tracked coins", description = "Retrieve list of all active tracked cryptocurrencies")
    public ResponseEntity<List<TrackedCoinDTO>> getAllCoins() {
        log.debug("Get all coins request");
        List<TrackedCoinDTO> coins = coinService.getAllCoins();
        return ResponseEntity.ok(coins);
    }

    @GetMapping("/{coinId}")
    @Operation(summary = "Get coin details", description = "Get detailed information about a specific tracked coin")
    public ResponseEntity<CoinDetailDTO> getCoinDetail(
            @Parameter(description = "CoinGecko coin ID")
            @PathVariable String coinId) {
        log.debug("Get coin detail request: {}", coinId);
        CoinDetailDTO details = coinService.getCoinDetail(coinId);
        return ResponseEntity.ok(details);
    }

    @GetMapping("/{coinId}/history")
    @Operation(summary = "Get coin price history", description = "Get historical price data for a coin over specified days")
    public ResponseEntity<List<PriceSnapshotDTO>> getCoinHistory(
            @Parameter(description = "CoinGecko coin ID")
            @PathVariable String coinId,
            @Parameter(description = "Number of days to retrieve")
            @RequestParam(defaultValue = "30") int days) {
        log.debug("Get coin history request: coinId={}, days={}", coinId, days);
        List<PriceSnapshotDTO> history = coinService.getCoinHistory(coinId, days);
        return ResponseEntity.ok(history);
    }

    @GetMapping("/{coinId}/signal")
    @Operation(summary = "Get technical analysis signal", description = "Get the latest technical analysis signal for a coin")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Signal returned",
                    content = @Content(schema = @Schema(implementation = CoinSignalDTO.class))),
            @ApiResponse(responseCode = "404", description = "Coin not tracked", content = @Content)
    })
    public ResponseEntity<CoinSignalDTO> getCoinSignal(
            @Parameter(description = "CoinGecko coin ID")
            @PathVariable String coinId) {
        log.debug("Get coin signal request: {}", coinId);
        CoinSignalDTO signal = coinService.getCoinSignal(coinId);
        return ResponseEntity.ok(signal);
    }

    @GetMapping("/{coinId}/signal/explain")
    @Operation(
            summary = "Get signal with plain English explanation",
            description = "Returns the latest technical analysis signal including a plain English explanation and risk score (1=very safe, 10=very risky). Cached for 1 hour."
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Signal with explanation returned",
                    content = @Content(schema = @Schema(implementation = CoinSignalDTO.class))),
            @ApiResponse(responseCode = "404", description = "Coin not tracked or no signal data", content = @Content)
    })
    public ResponseEntity<CoinSignalDTO> getCoinSignalExplain(
            @Parameter(description = "CoinGecko coin ID (e.g. 'bitcoin')")
            @PathVariable String coinId) {
        log.debug("Get signal explain request: {}", coinId);
        CoinSignalDTO signal = coinService.getCoinSignal(coinId);
        return ResponseEntity.ok(signal);
    }

    @GetMapping("/{coinId}/price")
    @Operation(
            summary = "Get coin price",
            description = "Returns cached USD and INR price for a coin. INR computed via live USD/INR exchange rate. Cache TTL: 5 minutes."
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Price data returned",
                    content = @Content(schema = @Schema(implementation = CoinPriceDTO.class))),
            @ApiResponse(responseCode = "404", description = "Coin not tracked",
                    content = @Content),
            @ApiResponse(responseCode = "429", description = "CoinGecko rate limit exceeded",
                    content = @Content)
    })
    public ResponseEntity<CoinPriceDTO> getCoinPrice(
            @Parameter(description = "CoinGecko coin ID (e.g. 'bitcoin')")
            @PathVariable String coinId) {
        log.debug("Get coin price request: {}", coinId);
        CoinPriceDTO price = coinService.getCoinPrice(coinId);
        return ResponseEntity.ok(price);
    }

    @GetMapping("/{coinId}/ohlc")
    @Operation(summary = "Get OHLC candlestick data", description = "Returns daily OHLC candles for charting. Each candle: [timestamp, open, high, low, close].")
    public ResponseEntity<List<OhlcDTO>> getOhlc(
            @Parameter(description = "CoinGecko coin ID") @PathVariable String coinId,
            @Parameter(description = "Number of days") @RequestParam(defaultValue = "30") int days) {
        log.debug("Get OHLC request: coinId={}, days={}", coinId, days);
        return ResponseEntity.ok(coinService.getOhlc(coinId, days));
    }

    @GetMapping("/compare")
    @Operation(summary = "Compare coins", description = "Compare multiple coins by their signals and metrics")
    public ResponseEntity<List<CompareDTO>> compareCoins(
            @Parameter(description = "Comma-separated list of CoinGecko coin IDs")
            @RequestParam String ids) {
        log.debug("Compare coins request: {}", ids);
        List<String> coinIds = List.of(ids.split(","));
        List<CompareDTO> comparison = coinService.compareCoins(coinIds);
        return ResponseEntity.ok(comparison);
    }
}
