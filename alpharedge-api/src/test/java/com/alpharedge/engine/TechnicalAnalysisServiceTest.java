package com.alpharedge.engine;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

class TechnicalAnalysisServiceTest {

    private TechnicalAnalysisService service;

    @BeforeEach
    void setUp() {
        service = new TechnicalAnalysisService();
    }

    // -----------------------------------------------------------------------
    // RSI tests
    // -----------------------------------------------------------------------

    /**
     * 14 consecutive up-days of +1 each produces RSI close to 100.
     * Using a gentler rising series so RSI lands solidly in overbought (>= 70).
     *
     * Prices: 100, 101, 102, … 115  (15 prices → 14 changes, all gains)
     * avgGain = 1, avgLoss = 0  → RSI = 100.
     */
    @Test
    void computeRSI_overbought_returns70orAbove() {
        List<BigDecimal> prices = new ArrayList<>();
        for (int i = 0; i <= 14; i++) {
            prices.add(BigDecimal.valueOf(100 + i));
        }

        BigDecimal rsi = service.computeRSI(prices, 14);

        assertTrue(rsi.doubleValue() >= 70,
                "Expected RSI >= 70 (overbought) but got " + rsi);
    }

    /**
     * 14 consecutive down-days of -1 each produces RSI close to 0.
     * avgGain = 0, avgLoss = 1  → RSI = 0.
     * Oversold threshold is <= 30.
     */
    @Test
    void computeRSI_oversold_returns30orBelow() {
        List<BigDecimal> prices = new ArrayList<>();
        for (int i = 0; i <= 14; i++) {
            prices.add(BigDecimal.valueOf(100 - i));
        }

        BigDecimal rsi = service.computeRSI(prices, 14);

        assertTrue(rsi.doubleValue() <= 30,
                "Expected RSI <= 30 (oversold) but got " + rsi);
    }

    /**
     * Mixed price series with more gains than losses produces RSI between 30 and 70.
     */
    @Test
    void computeRSI_neutral_returnsMidRange() {
        // 7 up days (+2) then 7 down days (-1) — net positive but mixed
        List<BigDecimal> prices = new ArrayList<>();
        double p = 100;
        prices.add(BigDecimal.valueOf(p));
        for (int i = 0; i < 7; i++) { p += 2; prices.add(BigDecimal.valueOf(p)); }
        for (int i = 0; i < 7; i++) { p -= 1; prices.add(BigDecimal.valueOf(p)); }

        BigDecimal rsi = service.computeRSI(prices, 14);

        assertTrue(rsi.doubleValue() > 30 && rsi.doubleValue() < 70,
                "Expected RSI in neutral range (30-70) but got " + rsi);
    }

    /**
     * Fewer prices than period + 1 must return ZERO (guard clause).
     */
    @Test
    void computeRSI_insufficientData_returnsZero() {
        List<BigDecimal> prices = List.of(
                BigDecimal.valueOf(100),
                BigDecimal.valueOf(101)
        );

        BigDecimal rsi = service.computeRSI(prices, 14);

        assertEquals(0, rsi.compareTo(BigDecimal.ZERO),
                "Expected ZERO for insufficient data but got " + rsi);
    }

    /**
     * All prices identical → no gains, no losses → avgLoss == 0 branch → RSI = 100.
     */
    @Test
    void computeRSI_flatPrices_returns100() {
        List<BigDecimal> prices = new ArrayList<>();
        for (int i = 0; i <= 14; i++) {
            prices.add(BigDecimal.valueOf(100));
        }

        BigDecimal rsi = service.computeRSI(prices, 14);

        assertEquals(0, BigDecimal.valueOf(100).compareTo(rsi),
                "Expected RSI = 100 for flat prices but got " + rsi);
    }

    // -----------------------------------------------------------------------
    // Risk score tests
    // -----------------------------------------------------------------------

    @Test
    void computeRiskScore_highVolatility_returnsHighScore() {
        int score = service.computeRiskScore(
                BigDecimal.valueOf(90),   // very high volatility
                BigDecimal.valueOf(110),  // price above middle
                BigDecimal.valueOf(120),  // upper band
                BigDecimal.valueOf(100)   // middle
        );
        assertTrue(score >= 7, "High volatility should yield score >= 7, got " + score);
    }

    @Test
    void computeRiskScore_lowVolatility_returnsLowScore() {
        int score = service.computeRiskScore(
                BigDecimal.valueOf(5),   // low volatility
                BigDecimal.valueOf(95),  // price below middle
                BigDecimal.valueOf(110), // upper band
                BigDecimal.valueOf(100)  // middle
        );
        assertTrue(score <= 3, "Low volatility below middle should yield score <= 3, got " + score);
    }

    @Test
    void computeRiskScore_alwaysBetween1And10() {
        int low = service.computeRiskScore(BigDecimal.ZERO, BigDecimal.valueOf(80),
                BigDecimal.valueOf(110), BigDecimal.valueOf(100));
        int high = service.computeRiskScore(BigDecimal.valueOf(100), BigDecimal.valueOf(120),
                BigDecimal.valueOf(110), BigDecimal.valueOf(100));

        assertTrue(low >= 1 && low <= 10, "Score out of bounds: " + low);
        assertTrue(high >= 1 && high <= 10, "Score out of bounds: " + high);
    }
}
