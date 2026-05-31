package com.alpharedge.engine;

import com.alpharedge.document.TradeTransaction;
import com.alpharedge.document.TradeTransaction.TradeType;
import com.alpharedge.dto.tax.SimulateTradeRequest;
import com.alpharedge.dto.tax.SimulationResult;
import com.alpharedge.dto.tax.TaxSummary;
import com.alpharedge.repository.TradeTransactionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class TaxEngineService {

    private static final BigDecimal TAX_RATE      = new BigDecimal("0.30");
    private static final BigDecimal TDS_RATE      = new BigDecimal("0.01");
    private static final int        SCALE         = 2;
    private static final RoundingMode ROUND       = RoundingMode.HALF_UP;

    private final TradeTransactionRepository tradeRepo;

    // ── Public API ────────────────────────────────────────────────────────────

    public TaxSummary calculateForUser(String userId, String financialYear) {
        List<TradeTransaction> trades =
                tradeRepo.findByUserIdAndFinancialYear(userId, financialYear);
        return calculate(userId, financialYear, trades);
    }

    public SimulationResult simulate(String userId, SimulateTradeRequest req) {
        String currentFY = TradeTransaction.computeFinancialYear(LocalDateTime.now());
        List<TradeTransaction> realTrades =
                tradeRepo.findByUserIdAndFinancialYear(userId, currentFY);

        BigDecimal saleValue = req.getQuantity()
                .multiply(req.getCurrentPriceInr())
                .setScale(SCALE, ROUND);
        BigDecimal tds = saleValue.multiply(TDS_RATE).setScale(SCALE, ROUND);

        // Hypothetical sell — NOT saved to DB
        TradeTransaction hypotheticalSell = TradeTransaction.builder()
                .userId(userId)
                .coinSymbol(req.getCoinSymbol().toUpperCase())
                .type(TradeType.SELL)
                .quantity(req.getQuantity())
                .pricePerUnit(req.getCurrentPriceInr())
                .totalAmount(saleValue)
                .tdsPaid(tds)
                .timestamp(LocalDateTime.now())
                .financialYear(currentFY)
                .build();

        List<TradeTransaction> combined = new ArrayList<>(realTrades);
        combined.add(hypotheticalSell);

        TaxSummary withSell    = calculate(userId, currentFY, combined);
        TaxSummary withoutSell = calculate(userId, currentFY, realTrades);

        BigDecimal profit = withSell.getNetProfitLossInr()
                .subtract(withoutSell.getNetProfitLossInr())
                .setScale(SCALE, ROUND);
        BigDecimal tax = profit.compareTo(BigDecimal.ZERO) > 0
                ? profit.multiply(TAX_RATE).setScale(SCALE, ROUND)
                : BigDecimal.ZERO;
        BigDecimal netReceived = saleValue.subtract(tax).subtract(tds).setScale(SCALE, ROUND);
        BigDecimal effectiveRate = saleValue.compareTo(BigDecimal.ZERO) != 0
                ? tax.add(tds).multiply(BigDecimal.valueOf(100))
                        .divide(saleValue, SCALE, ROUND)
                : BigDecimal.ZERO;

        List<String> steps = buildSimulationSteps(req, saleValue, profit, tax, tds, netReceived);
        String recommendation = buildRecommendation(profit, tax, saleValue);

        return SimulationResult.builder()
                .saleValueInr(saleValue)
                .projectedProfitInr(profit)
                .projectedTaxInr(tax)
                .projectedTdsInr(tds)
                .netReceivedInr(netReceived)
                .effectiveTaxRatePct(effectiveRate)
                .calculationSteps(steps)
                .recommendation(recommendation)
                .build();
    }

    // ── Core FIFO engine ──────────────────────────────────────────────────────

    TaxSummary calculate(String userId, String financialYear,
                         List<TradeTransaction> trades) {
        List<String> steps = new ArrayList<>();
        steps.add("Financial Year: " + financialYear);
        steps.add("Total trades loaded: " + trades.size());

        Map<String, List<TradeTransaction>> byCoin = trades.stream()
                .sorted(Comparator.comparing(TradeTransaction::getTimestamp,
                        Comparator.nullsLast(Comparator.naturalOrder())))
                .collect(Collectors.groupingBy(
                        t -> t.getCoinSymbol().toUpperCase(),
                        LinkedHashMap::new,
                        Collectors.toList()));

        BigDecimal totalProfit = BigDecimal.ZERO;
        BigDecimal totalLoss   = BigDecimal.ZERO;
        double tdsPaid = tradeRepo.sumTdsPaid(userId, financialYear);
        BigDecimal tdsPaidBD = BigDecimal.valueOf(tdsPaid).setScale(SCALE, ROUND);

        List<TaxSummary.CoinTaxDetail> perCoin = new ArrayList<>();

        for (Map.Entry<String, List<TradeTransaction>> entry : byCoin.entrySet()) {
            String coin = entry.getKey();
            List<TradeTransaction> coinTrades = entry.getValue();

            steps.add("--- " + coin + " ---");
            FifoResult result = runFifo(coin, coinTrades, steps);

            BigDecimal coinTax = result.profit.compareTo(BigDecimal.ZERO) > 0
                    ? result.profit.multiply(TAX_RATE).setScale(SCALE, ROUND)
                    : BigDecimal.ZERO;
            BigDecimal coinTds = result.sellValue.multiply(TDS_RATE).setScale(SCALE, ROUND);

            if (result.profit.compareTo(BigDecimal.ZERO) > 0) {
                totalProfit = totalProfit.add(result.profit);
            } else {
                totalLoss = totalLoss.add(result.profit.abs());
            }

            perCoin.add(TaxSummary.CoinTaxDetail.builder()
                    .coinSymbol(coin)
                    .unitsBought(result.unitsBought)
                    .unitsSold(result.unitsSold)
                    .profitLossInr(result.profit)
                    .taxInr(coinTax)
                    .tdsInr(coinTds)
                    .build());
        }

        // Indian crypto law: losses cannot offset profits from other coins
        BigDecimal netPnl    = totalProfit.subtract(BigDecimal.ZERO); // losses not deductible
        BigDecimal taxOwed   = totalProfit.multiply(TAX_RATE).setScale(SCALE, ROUND);
        BigDecimal netTaxDue = taxOwed.subtract(tdsPaidBD).max(BigDecimal.ZERO);

        steps.add("=== TOTALS ===");
        steps.add("Total profit: ₹" + fmt(totalProfit));
        steps.add("Total loss (not deductible under Section 115BBH): ₹" + fmt(totalLoss));
        steps.add("Tax @ 30% on profits only: ₹" + fmt(taxOwed));
        steps.add("TDS already paid (Section 194S): ₹" + fmt(tdsPaidBD));
        steps.add("Net tax still due: ₹" + fmt(netTaxDue));

        return TaxSummary.builder()
                .userId(userId)
                .financialYear(financialYear)
                .totalProfitInr(totalProfit)
                .totalLossInr(totalLoss)
                .netProfitLossInr(totalProfit.subtract(totalLoss))
                .taxOwedInr(taxOwed)
                .tdsPaidInr(tdsPaidBD)
                .netTaxDueInr(netTaxDue)
                .perCoinBreakdown(perCoin)
                .calculationSteps(steps)
                .build();
    }

    // ── FIFO per coin ─────────────────────────────────────────────────────────

    private FifoResult runFifo(String coin, List<TradeTransaction> trades, List<String> steps) {
        Deque<BuyLot> buyQueue  = new ArrayDeque<>();
        BigDecimal profit       = BigDecimal.ZERO;
        BigDecimal unitsBought  = BigDecimal.ZERO;
        BigDecimal unitsSold    = BigDecimal.ZERO;
        BigDecimal sellValue    = BigDecimal.ZERO;

        for (TradeTransaction t : trades) {
            if (t.getType() == TradeType.BUY || t.getType() == TradeType.TRANSFER_IN
                    || t.getType() == TradeType.PAYMENT_RECEIVED) {
                buyQueue.add(new BuyLot(t.getQuantity(), t.getPricePerUnit()));
                unitsBought = unitsBought.add(t.getQuantity());
                steps.add(coin + " BUY: " + t.getQuantity() + " @ ₹" + fmt(t.getPricePerUnit()));

            } else if (t.getType() == TradeType.SELL || t.getType() == TradeType.TRANSFER_OUT
                    || t.getType() == TradeType.PAYMENT_SENT) {
                BigDecimal toSell   = t.getQuantity();
                BigDecimal sellPrice = t.getPricePerUnit();
                sellValue = sellValue.add(toSell.multiply(sellPrice));
                unitsSold = unitsSold.add(toSell);

                steps.add(coin + " SELL: " + toSell + " @ ₹" + fmt(sellPrice));

                while (toSell.compareTo(BigDecimal.ZERO) > 0 && !buyQueue.isEmpty()) {
                    BuyLot lot = buyQueue.peek();
                    BigDecimal use = lot.qty.min(toSell);
                    BigDecimal gain = use.multiply(sellPrice.subtract(lot.price))
                            .setScale(SCALE, ROUND);
                    profit = profit.add(gain);
                    steps.add("  FIFO: " + use + " units cost ₹" + fmt(lot.price)
                            + " → gain ₹" + fmt(gain));
                    lot.qty = lot.qty.subtract(use);
                    toSell  = toSell.subtract(use);
                    if (lot.qty.compareTo(BigDecimal.ZERO) == 0) buyQueue.poll();
                }
                if (toSell.compareTo(BigDecimal.ZERO) > 0) {
                    steps.add("  WARNING: " + toSell + " units sold with no matching BUY (cost basis = 0)");
                }
            }
        }

        steps.add(coin + " net P&L: ₹" + fmt(profit));
        return new FifoResult(profit, unitsBought, unitsSold, sellValue);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private List<String> buildSimulationSteps(SimulateTradeRequest req,
            BigDecimal saleValue, BigDecimal profit,
            BigDecimal tax, BigDecimal tds, BigDecimal netReceived) {
        List<String> s = new ArrayList<>();
        s.add("Hypothetical sell: " + req.getQuantity() + " " + req.getCoinSymbol()
                + " @ ₹" + fmt(req.getCurrentPriceInr()));
        s.add("Sale value: " + req.getQuantity() + " × ₹" + fmt(req.getCurrentPriceInr())
                + " = ₹" + fmt(saleValue));
        s.add("FIFO cost basis subtracted from real trade history.");
        s.add("Projected profit from this sale: ₹" + fmt(profit));
        s.add("Tax @ 30% (Section 115BBH): ₹" + fmt(profit) + " × 30% = ₹" + fmt(tax));
        s.add("TDS @ 1% (Section 194S): ₹" + fmt(saleValue) + " × 1% = ₹" + fmt(tds));
        s.add("Net received: ₹" + fmt(saleValue) + " − ₹" + fmt(tax)
                + " − ₹" + fmt(tds) + " = ₹" + fmt(netReceived));
        return s;
    }

    private String buildRecommendation(BigDecimal profit, BigDecimal tax, BigDecimal saleValue) {
        if (profit.compareTo(BigDecimal.ZERO) <= 0) {
            return "This sale results in a loss. No tax owed. However, losses cannot offset "
                    + "gains from other coins under Section 115BBH.";
        }
        double taxPct = saleValue.compareTo(BigDecimal.ZERO) != 0
                ? tax.doubleValue() / saleValue.doubleValue() * 100 : 0;
        return String.format(
                "Selling now incurs ₹%s in tax (%.1f%% of proceeds). "
                + "Indian crypto tax is a flat 30%% regardless of holding duration — "
                + "there is no long-term capital gains benefit. "
                + "Consult a CA before filing.", fmt(tax), taxPct);
    }

    private static String fmt(BigDecimal v) {
        if (v == null) return "0.00";
        return String.format("%,.2f", v.doubleValue());
    }

    private static class BuyLot {
        BigDecimal qty;
        final BigDecimal price;
        BuyLot(BigDecimal qty, BigDecimal price) { this.qty = qty; this.price = price; }
    }

    private record FifoResult(BigDecimal profit, BigDecimal unitsBought,
                              BigDecimal unitsSold, BigDecimal sellValue) {}
}
