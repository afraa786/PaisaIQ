package com.alpharedge.engine;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
public class TechnicalAnalysisService {

    private static final int SCALE = 8;
    private static final RoundingMode ROUNDING_MODE = RoundingMode.HALF_UP;

    public BigDecimal computeRSI(List<BigDecimal> prices, int period) {
        if (prices == null || prices.size() < period + 1) {
            return BigDecimal.ZERO;
        }

        try {
            List<BigDecimal> changes = new ArrayList<>();
            for (int i = 1; i < prices.size(); i++) {
                changes.add(prices.get(i).subtract(prices.get(i - 1)));
            }

            List<BigDecimal> gains = changes.stream()
                    .map(c -> c.compareTo(BigDecimal.ZERO) > 0 ? c : BigDecimal.ZERO)
                    .collect(Collectors.toList());

            List<BigDecimal> losses = changes.stream()
                    .map(c -> c.compareTo(BigDecimal.ZERO) < 0 ? c.abs() : BigDecimal.ZERO)
                    .collect(Collectors.toList());

            BigDecimal sumGains = gains.stream().reduce(BigDecimal.ZERO, BigDecimal::add);
            BigDecimal sumLosses = losses.stream().reduce(BigDecimal.ZERO, BigDecimal::add);

            BigDecimal avgGain = sumGains.divide(new BigDecimal(period), SCALE, ROUNDING_MODE);
            BigDecimal avgLoss = sumLosses.divide(new BigDecimal(period), SCALE, ROUNDING_MODE);

            if (avgLoss.compareTo(BigDecimal.ZERO) == 0) {
                return BigDecimal.valueOf(100);
            }

            BigDecimal rs = avgGain.divide(avgLoss, SCALE, ROUNDING_MODE);
            BigDecimal rsi = BigDecimal.valueOf(100).subtract(
                    BigDecimal.valueOf(100).divide(BigDecimal.ONE.add(rs), SCALE, ROUNDING_MODE)
            );

            return rsi.setScale(SCALE, ROUNDING_MODE);
        } catch (Exception ex) {
            log.error("Error computing RSI", ex);
            return BigDecimal.ZERO;
        }
    }

    public BigDecimal computeEMA(List<BigDecimal> prices, int period) {
        if (prices == null || prices.isEmpty() || prices.size() < period) {
            return BigDecimal.ZERO;
        }

        try {
            BigDecimal multiplier = new BigDecimal(2).divide(
                    new BigDecimal(period + 1), SCALE, ROUNDING_MODE
            );

            BigDecimal seed = prices.stream()
                    .limit(period)
                    .reduce(BigDecimal.ZERO, BigDecimal::add)
                    .divide(new BigDecimal(period), SCALE, ROUNDING_MODE);

            BigDecimal ema = seed;
            for (int i = period; i < prices.size(); i++) {
                ema = prices.get(i).subtract(ema)
                        .multiply(multiplier)
                        .add(ema)
                        .setScale(SCALE, ROUNDING_MODE);
            }

            return ema;
        } catch (Exception ex) {
            log.error("Error computing EMA", ex);
            return BigDecimal.ZERO;
        }
    }

    public MACDResult computeMACD(List<BigDecimal> prices) {
        if (prices == null || prices.size() < 26) {
            return MACDResult.builder()
                    .macdLine(BigDecimal.ZERO)
                    .signalLine(BigDecimal.ZERO)
                    .histogram(BigDecimal.ZERO)
                    .build();
        }

        try {
            BigDecimal ema12 = computeEMA(prices, 12);
            BigDecimal ema26 = computeEMA(prices, 26);
            BigDecimal macdLine = ema12.subtract(ema26).setScale(SCALE, ROUNDING_MODE);

            List<BigDecimal> macdSeries = new ArrayList<>();
            for (int i = 25; i < prices.size(); i++) {
                BigDecimal e12 = computeEMA(prices.subList(0, i + 1), 12);
                BigDecimal e26 = computeEMA(prices.subList(0, i + 1), 26);
                macdSeries.add(e12.subtract(e26));
            }

            BigDecimal signalLine = computeEMA(macdSeries, 9);
            BigDecimal histogram = macdLine.subtract(signalLine).setScale(SCALE, ROUNDING_MODE);

            return MACDResult.builder()
                    .macdLine(macdLine)
                    .signalLine(signalLine)
                    .histogram(histogram)
                    .build();
        } catch (Exception ex) {
            log.error("Error computing MACD", ex);
            return MACDResult.builder()
                    .macdLine(BigDecimal.ZERO)
                    .signalLine(BigDecimal.ZERO)
                    .histogram(BigDecimal.ZERO)
                    .build();
        }
    }

    public BigDecimal computeSMA(List<BigDecimal> prices, int period) {
        if (prices == null || prices.size() < period) {
            return BigDecimal.ZERO;
        }

        try {
            BigDecimal sum = prices.stream()
                    .skip(prices.size() - period)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);

            return sum.divide(new BigDecimal(period), SCALE, ROUNDING_MODE);
        } catch (Exception ex) {
            log.error("Error computing SMA", ex);
            return BigDecimal.ZERO;
        }
    }

    public BollingerBandsResult computeBollingerBands(List<BigDecimal> prices) {
        if (prices == null || prices.size() < 20) {
            return BollingerBandsResult.builder()
                    .upper(BigDecimal.ZERO)
                    .middle(BigDecimal.ZERO)
                    .lower(BigDecimal.ZERO)
                    .build();
        }

        try {
            BigDecimal middle = computeSMA(prices, 20);
            List<BigDecimal> lastTwenty = prices.stream()
                    .skip(prices.size() - 20)
                    .collect(Collectors.toList());

            BigDecimal sumSquaredDiff = lastTwenty.stream()
                    .map(p -> p.subtract(middle).pow(2))
                    .reduce(BigDecimal.ZERO, BigDecimal::add);

            BigDecimal variance = sumSquaredDiff.divide(new BigDecimal(20), SCALE, ROUNDING_MODE);
            BigDecimal stdDev = new BigDecimal(Math.sqrt(variance.doubleValue()));

            BigDecimal upper = middle.add(stdDev.multiply(new BigDecimal(2))).setScale(SCALE, ROUNDING_MODE);
            BigDecimal lower = middle.subtract(stdDev.multiply(new BigDecimal(2))).setScale(SCALE, ROUNDING_MODE);

            return BollingerBandsResult.builder()
                    .upper(upper)
                    .middle(middle)
                    .lower(lower)
                    .build();
        } catch (Exception ex) {
            log.error("Error computing Bollinger Bands", ex);
            return BollingerBandsResult.builder()
                    .upper(BigDecimal.ZERO)
                    .middle(BigDecimal.ZERO)
                    .lower(BigDecimal.ZERO)
                    .build();
        }
    }

    public BigDecimal computeVolatilityScore(List<BigDecimal> prices) {
        if (prices == null || prices.size() < 2) {
            return BigDecimal.ZERO;
        }

        try {
            int lookback = Math.min(30, prices.size());
            List<BigDecimal> lastPrices = prices.stream()
                    .skip(prices.size() - lookback)
                    .collect(Collectors.toList());

            List<BigDecimal> dailyReturns = new ArrayList<>();
            for (int i = 1; i < lastPrices.size(); i++) {
                BigDecimal prevPrice = lastPrices.get(i - 1);
                if (prevPrice.compareTo(BigDecimal.ZERO) != 0) {
                    BigDecimal dailyReturn = lastPrices.get(i)
                            .subtract(prevPrice)
                            .divide(prevPrice, SCALE, ROUNDING_MODE);
                    dailyReturns.add(dailyReturn);
                }
            }

            if (dailyReturns.isEmpty()) {
                return BigDecimal.ZERO;
            }

            BigDecimal meanReturn = dailyReturns.stream()
                    .reduce(BigDecimal.ZERO, BigDecimal::add)
                    .divide(new BigDecimal(dailyReturns.size()), SCALE, ROUNDING_MODE);

            BigDecimal variance = dailyReturns.stream()
                    .map(r -> r.subtract(meanReturn).pow(2))
                    .reduce(BigDecimal.ZERO, BigDecimal::add)
                    .divide(new BigDecimal(dailyReturns.size()), SCALE, ROUNDING_MODE);

            BigDecimal stdDev = new BigDecimal(Math.sqrt(variance.doubleValue()));
            BigDecimal volatility = stdDev.multiply(new BigDecimal(1000));

            return new BigDecimal(Math.min(volatility.doubleValue(), 100)).setScale(SCALE, ROUNDING_MODE);
        } catch (Exception ex) {
            log.error("Error computing volatility score", ex);
            return BigDecimal.ZERO;
        }
    }

    public BigDecimal computeMomentumScore(BigDecimal change24h, BigDecimal change7d, BigDecimal change30d) {
        if (change24h == null || change7d == null || change30d == null) {
            return BigDecimal.ZERO;
        }

        try {
            BigDecimal score = change24h.multiply(new BigDecimal("0.5"))
                    .add(change7d.multiply(new BigDecimal("0.3")))
                    .add(change30d.multiply(new BigDecimal("0.2")));

            return new BigDecimal(Math.max(-100, Math.min(100, score.doubleValue())))
                    .setScale(SCALE, ROUNDING_MODE);
        } catch (Exception ex) {
            log.error("Error computing momentum score", ex);
            return BigDecimal.ZERO;
        }
    }

    public SignalResult generateSignal(BigDecimal rsi, BigDecimal currentPrice,
                                      BigDecimal bollingerLower, BigDecimal bollingerUpper,
                                      BigDecimal macd, BigDecimal macdSignal) {
        if (rsi == null || currentPrice == null || bollingerLower == null || 
            bollingerUpper == null || macd == null || macdSignal == null) {
            return SignalResult.builder()
                    .signal("HOLD")
                    .strength("WEAK")
                    .build();
        }

        try {
            boolean buyRsi = rsi.compareTo(new BigDecimal(30)) < 0;
            boolean buyPrice = currentPrice.compareTo(bollingerLower) < 0;
            boolean buyMacd = macd.compareTo(macdSignal) > 0;

            boolean sellRsi = rsi.compareTo(new BigDecimal(70)) > 0;
            boolean sellPrice = currentPrice.compareTo(bollingerUpper) > 0;
            boolean sellMacd = macd.compareTo(macdSignal) < 0;

            int buyCount = (buyRsi ? 1 : 0) + (buyPrice ? 1 : 0) + (buyMacd ? 1 : 0);
            int sellCount = (sellRsi ? 1 : 0) + (sellPrice ? 1 : 0) + (sellMacd ? 1 : 0);

            String signal = "HOLD";
            String strength = "WEAK";

            if (buyCount == 3) {
                signal = "BUY";
                strength = "STRONG";
            } else if (buyCount == 2) {
                signal = "BUY";
                strength = "MODERATE";
            } else if (buyCount == 1) {
                signal = "BUY";
                strength = "WEAK";
            } else if (sellCount == 3) {
                signal = "SELL";
                strength = "STRONG";
            } else if (sellCount == 2) {
                signal = "SELL";
                strength = "MODERATE";
            } else if (sellCount == 1) {
                signal = "SELL";
                strength = "WEAK";
            }

            return SignalResult.builder()
                    .signal(signal)
                    .strength(strength)
                    .buyConditionCount(buyCount)
                    .sellConditionCount(sellCount)
                    .build();
        } catch (Exception ex) {
            log.error("Error generating signal", ex);
            return SignalResult.builder()
                    .signal("HOLD")
                    .strength("WEAK")
                    .build();
        }
    }

    public String generateExplanation(BigDecimal rsi, BigDecimal macd, BigDecimal macdSignal,
                                      BigDecimal change7d, BigDecimal volatility,
                                      String signal, String strength) {
        try {
            StringBuilder sb = new StringBuilder();

            // Momentum sentence
            if (change7d != null) {
                double c7 = change7d.doubleValue();
                if (c7 > 5) {
                    sb.append(String.format("Strong buying momentum over 7 days (+%.1f%%). ", c7));
                } else if (c7 > 0) {
                    sb.append(String.format("Mild positive momentum over 7 days (+%.1f%%). ", c7));
                } else if (c7 < -5) {
                    sb.append(String.format("Strong selling pressure over 7 days (%.1f%%). ", c7));
                } else {
                    sb.append(String.format("Flat price action over 7 days (%.1f%%). ", c7));
                }
            }

            // RSI sentence
            if (rsi != null) {
                double r = rsi.doubleValue();
                if (r >= 70) {
                    sb.append(String.format("RSI at %.0f is overbought — caution for new buys. ", r));
                } else if (r <= 30) {
                    sb.append(String.format("RSI at %.0f is oversold — potential reversal zone. ", r));
                } else {
                    sb.append(String.format("RSI at %.0f is neutral, not overbought. ", r));
                }
            }

            // MACD sentence
            if (macd != null && macdSignal != null) {
                if (macd.compareTo(macdSignal) > 0) {
                    sb.append("MACD is above signal line — bullish crossover active. ");
                } else {
                    sb.append("MACD is below signal line — bearish crossover active. ");
                }
            }

            // Volatility sentence
            if (volatility != null) {
                double v = volatility.doubleValue();
                if (v > 60) {
                    sb.append("High volatility detected — position sizing recommended. ");
                } else if (v > 30) {
                    sb.append("Moderate volatility. ");
                } else {
                    sb.append("Low volatility environment. ");
                }
            }

            // Overall verdict
            sb.append(String.format("Overall signal: %s (%s).", signal, strength.toLowerCase()));

            return sb.toString().trim();
        } catch (Exception ex) {
            log.error("Error generating explanation", ex);
            return String.format("Overall signal: %s (%s).", signal, strength.toLowerCase());
        }
    }

    public int computeRiskScore(BigDecimal volatility, BigDecimal currentPrice,
                                BigDecimal bollingerUpper, BigDecimal bollingerMiddle) {
        try {
            double score = 1.0;

            // Volatility contributes up to 6 points (0-100 maps to 0-6)
            if (volatility != null) {
                score += (volatility.doubleValue() / 100.0) * 6.0;
            }

            // Distance above Bollinger middle contributes up to 3 points
            if (currentPrice != null && bollingerUpper != null && bollingerMiddle != null) {
                double upper = bollingerUpper.doubleValue();
                double middle = bollingerMiddle.doubleValue();
                double current = currentPrice.doubleValue();
                double band = upper - middle;
                if (band > 0) {
                    double distanceFraction = Math.max(0, (current - middle) / band);
                    score += Math.min(distanceFraction, 1.0) * 3.0;
                }
            }

            return Math.max(1, Math.min(10, (int) Math.round(score)));
        } catch (Exception ex) {
            log.error("Error computing risk score", ex);
            return 5;
        }
    }

    public CoinSignalResult computeAll(List<BigDecimal> prices, BigDecimal change24h,
                                      BigDecimal change7d, BigDecimal change30d,
                                      BigDecimal currentPrice) {
        try {
            BigDecimal rsi = computeRSI(prices, 14);
            MACDResult macd = computeMACD(prices);
            BigDecimal sma7 = computeSMA(prices, 7);
            BigDecimal sma30 = computeSMA(prices, 30);
            BollingerBandsResult bollinger = computeBollingerBands(prices);
            BigDecimal volatility = computeVolatilityScore(prices);
            BigDecimal momentum = computeMomentumScore(change24h, change7d, change30d);

            SignalResult signal = generateSignal(
                    rsi,
                    currentPrice,
                    bollinger.getLower(),
                    bollinger.getUpper(),
                    macd.getMacdLine(),
                    macd.getSignalLine()
            );

            String explanation = generateExplanation(
                    rsi, macd.getMacdLine(), macd.getSignalLine(),
                    change7d, volatility, signal.getSignal(), signal.getStrength()
            );

            int riskScore = computeRiskScore(volatility, currentPrice,
                    bollinger.getUpper(), bollinger.getMiddle());

            return CoinSignalResult.builder()
                    .rsi(rsi)
                    .macd(macd.getMacdLine())
                    .macdSignal(macd.getSignalLine())
                    .macdHistogram(macd.getHistogram())
                    .sma7(sma7)
                    .sma30(sma30)
                    .bollingerUpper(bollinger.getUpper())
                    .bollingerMiddle(bollinger.getMiddle())
                    .bollingerLower(bollinger.getLower())
                    .signal(signal.getSignal())
                    .strength(signal.getStrength())
                    .volatilityScore(volatility)
                    .momentumScore(momentum)
                    .signalExplanation(explanation)
                    .riskScore(riskScore)
                    .build();
        } catch (Exception ex) {
            log.error("Error computing all technical indicators", ex);
            return CoinSignalResult.builder()
                    .rsi(BigDecimal.ZERO)
                    .macd(BigDecimal.ZERO)
                    .macdSignal(BigDecimal.ZERO)
                    .macdHistogram(BigDecimal.ZERO)
                    .sma7(BigDecimal.ZERO)
                    .sma30(BigDecimal.ZERO)
                    .bollingerUpper(BigDecimal.ZERO)
                    .bollingerMiddle(BigDecimal.ZERO)
                    .bollingerLower(BigDecimal.ZERO)
                    .signal("HOLD")
                    .strength("WEAK")
                    .volatilityScore(BigDecimal.ZERO)
                    .momentumScore(BigDecimal.ZERO)
                    .signalExplanation("Insufficient data to generate explanation.")
                    .riskScore(5)
                    .build();
        }
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class MACDResult {
        private BigDecimal macdLine;
        private BigDecimal signalLine;
        private BigDecimal histogram;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class BollingerBandsResult {
        private BigDecimal upper;
        private BigDecimal middle;
        private BigDecimal lower;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class SignalResult {
        private String signal;
        private String strength;
        private Integer buyConditionCount;
        private Integer sellConditionCount;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class CoinSignalResult {
        private BigDecimal rsi;
        private BigDecimal macd;
        private BigDecimal macdSignal;
        private BigDecimal macdHistogram;
        private BigDecimal sma7;
        private BigDecimal sma30;
        private BigDecimal bollingerUpper;
        private BigDecimal bollingerMiddle;
        private BigDecimal bollingerLower;
        private String signal;
        private String strength;
        private BigDecimal volatilityScore;
        private BigDecimal momentumScore;
        private String signalExplanation;
        private Integer riskScore;
    }
}
