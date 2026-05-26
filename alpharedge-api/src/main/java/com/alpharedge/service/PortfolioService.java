package com.alpharedge.service;

import com.alpharedge.client.ExchangeRateClient;
import com.alpharedge.document.Holding;
import com.alpharedge.document.Portfolio;
import com.alpharedge.document.PriceSnapshot;
import com.alpharedge.document.TrackedCoin;
import com.alpharedge.dto.request.AddHoldingRequest;
import com.alpharedge.dto.request.CreatePortfolioRequest;
import com.alpharedge.dto.response.PortfolioDTO;
import com.alpharedge.dto.response.PortfolioHistoryDTO;
import com.alpharedge.dto.response.PortfolioSummaryDTO;
import com.alpharedge.exception.CoinNotFoundException;
import com.alpharedge.exception.UnauthorizedException;
import com.alpharedge.mapper.PortfolioMapper;
import com.alpharedge.repository.PortfolioRepository;
import com.alpharedge.repository.PriceSnapshotRepository;
import com.alpharedge.repository.TrackedCoinRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
public class PortfolioService {

    private final PortfolioRepository portfolioRepository;
    private final TrackedCoinRepository trackedCoinRepository;
    private final PriceSnapshotRepository priceSnapshotRepository;
    private final ExchangeRateClient exchangeRateClient;
    private final PortfolioMapper portfolioMapper;

    @Autowired
    public PortfolioService(PortfolioRepository portfolioRepository,
                            TrackedCoinRepository trackedCoinRepository,
                            PriceSnapshotRepository priceSnapshotRepository,
                            ExchangeRateClient exchangeRateClient,
                            PortfolioMapper portfolioMapper) {
        this.portfolioRepository = portfolioRepository;
        this.trackedCoinRepository = trackedCoinRepository;
        this.priceSnapshotRepository = priceSnapshotRepository;
        this.exchangeRateClient = exchangeRateClient;
        this.portfolioMapper = portfolioMapper;
    }

    public PortfolioDTO createPortfolio(String userId, CreatePortfolioRequest request) {
        try {
            log.info("Creating portfolio for user: {}", userId);
            Portfolio portfolio = Portfolio.builder()
                    .userId(userId)
                    .name(request.getName())
                    .holdings(new ArrayList<>())
                    .build();

            portfolio = portfolioRepository.save(portfolio);
            return portfolioMapper.toDTO(portfolio);
        } catch (Exception ex) {
            log.error("Error creating portfolio", ex);
            throw ex;
        }
    }

    public List<PortfolioDTO> getPortfolios(String userId) {
        try {
            log.debug("Fetching portfolios for user: {}", userId);
            List<Portfolio> portfolios = portfolioRepository.findByUserId(userId);
            return portfolios.stream()
                    .map(portfolioMapper::toDTO)
                    .collect(Collectors.toList());
        } catch (Exception ex) {
            log.error("Error fetching portfolios", ex);
            return new ArrayList<>();
        }
    }

    public PortfolioDTO addHolding(String portfolioId, String userId, AddHoldingRequest request) {
        try {
            log.info("Adding holding to portfolio: {} for user: {}", portfolioId, userId);
            Portfolio portfolio = portfolioRepository.findByIdAndUserId(portfolioId, userId)
                    .orElseThrow(() -> new UnauthorizedException("Portfolio not found or access denied"));

            TrackedCoin trackedCoin = trackedCoinRepository.findByCoinId(request.getCoinId())
                    .orElseThrow(() -> new CoinNotFoundException("Coin not found: " + request.getCoinId()));

            Holding holding = Holding.builder()
                    .coinId(request.getCoinId())
                    .coinName(trackedCoin.getName())
                    .symbol(trackedCoin.getSymbol())
                    .quantity(request.getQuantity())
                    .buyPriceUsd(request.getBuyPriceUsd())
                    .buyDate(request.getBuyDate())
                    .notes(request.getNotes())
                    .build();

            portfolio.getHoldings().add(holding);
            portfolio = portfolioRepository.save(portfolio);

            return portfolioMapper.toDTO(portfolio);
        } catch (Exception ex) {
            log.error("Error adding holding to portfolio", ex);
            throw ex;
        }
    }

    public PortfolioDTO removeHolding(String portfolioId, String holdingId, String userId) {
        try {
            log.info("Removing holding from portfolio: {} for user: {}", portfolioId, userId);
            Portfolio portfolio = portfolioRepository.findByIdAndUserId(portfolioId, userId)
                    .orElseThrow(() -> new UnauthorizedException("Portfolio not found or access denied"));

            portfolio.setHoldings(portfolio.getHoldings().stream()
                    .filter(h -> !h.getHoldingId().equals(holdingId))
                    .collect(Collectors.toList()));

            portfolio = portfolioRepository.save(portfolio);
            return portfolioMapper.toDTO(portfolio);
        } catch (Exception ex) {
            log.error("Error removing holding from portfolio", ex);
            throw ex;
        }
    }

    public PortfolioSummaryDTO getPortfolioSummary(String portfolioId, String userId) {
        try {
            log.debug("Fetching portfolio summary: {} for user: {}", portfolioId, userId);
            Portfolio portfolio = portfolioRepository.findByIdAndUserId(portfolioId, userId)
                    .orElseThrow(() -> new UnauthorizedException("Portfolio not found or access denied"));

            BigDecimal usdToInr = exchangeRateClient.fetchUsdToInrRate();
            LocalDateTime ago24h = LocalDateTime.now().minusHours(24);

            BigDecimal totalValueUsd = BigDecimal.ZERO;
            BigDecimal totalCostBasisUsd = BigDecimal.ZERO;
            BigDecimal totalValue24hAgoUsd = BigDecimal.ZERO;

            String bestPerformer = null;
            BigDecimal bestGain = BigDecimal.valueOf(Double.NEGATIVE_INFINITY);
            String worstPerformer = null;
            BigDecimal worstGain = BigDecimal.valueOf(Double.POSITIVE_INFINITY);

            List<PortfolioSummaryDTO.HoldingPerformanceDTO> performances = new ArrayList<>();

            for (Holding holding : portfolio.getHoldings()) {
                PriceSnapshot snapshot = priceSnapshotRepository
                        .findTopByCoinIdOrderByFetchedAtDesc(holding.getCoinId())
                        .orElse(null);

                if (snapshot == null) continue;

                BigDecimal currentPriceUsd = snapshot.getPriceUsd();
                BigDecimal currentPriceInr = snapshot.getPriceInr() != null
                        ? snapshot.getPriceInr()
                        : currentPriceUsd.multiply(usdToInr);

                BigDecimal qty = holding.getQuantity();
                BigDecimal currentValueUsd = qty.multiply(currentPriceUsd);
                BigDecimal currentValueInr = qty.multiply(currentPriceInr);
                BigDecimal costBasisUsd = qty.multiply(holding.getBuyPriceUsd());
                BigDecimal costBasisInr = costBasisUsd.multiply(usdToInr);
                BigDecimal pnlUsd = currentValueUsd.subtract(costBasisUsd);
                BigDecimal pnlInr = currentValueInr.subtract(costBasisInr);
                BigDecimal pnlPercent = costBasisUsd.compareTo(BigDecimal.ZERO) != 0
                        ? pnlUsd.multiply(BigDecimal.valueOf(100)).divide(costBasisUsd, 8, RoundingMode.HALF_UP)
                        : BigDecimal.ZERO;

                // 24h day change per holding
                PriceSnapshot snap24h = priceSnapshotRepository
                        .findTopByCoinIdAndFetchedAtBeforeOrderByFetchedAtDesc(holding.getCoinId(), ago24h)
                        .orElse(null);

                BigDecimal holdingDayChangeInr = BigDecimal.ZERO;
                BigDecimal holdingDayChangePercent = BigDecimal.ZERO;
                BigDecimal value24hAgoUsd = BigDecimal.ZERO;

                if (snap24h != null) {
                    BigDecimal price24hInr = snap24h.getPriceInr() != null
                            ? snap24h.getPriceInr()
                            : snap24h.getPriceUsd().multiply(usdToInr);
                    BigDecimal value24hInr = qty.multiply(price24hInr);
                    holdingDayChangeInr = currentValueInr.subtract(value24hInr);
                    if (value24hInr.compareTo(BigDecimal.ZERO) != 0) {
                        holdingDayChangePercent = holdingDayChangeInr
                                .multiply(BigDecimal.valueOf(100))
                                .divide(value24hInr, 8, RoundingMode.HALF_UP);
                    }
                    value24hAgoUsd = qty.multiply(snap24h.getPriceUsd());
                }

                totalValueUsd = totalValueUsd.add(currentValueUsd);
                totalCostBasisUsd = totalCostBasisUsd.add(costBasisUsd);
                totalValue24hAgoUsd = totalValue24hAgoUsd.add(value24hAgoUsd);

                if (pnlPercent.compareTo(bestGain) > 0) {
                    bestGain = pnlPercent;
                    bestPerformer = holding.getSymbol();
                }
                if (pnlPercent.compareTo(worstGain) < 0) {
                    worstGain = pnlPercent;
                    worstPerformer = holding.getSymbol();
                }

                performances.add(PortfolioSummaryDTO.HoldingPerformanceDTO.builder()
                        .holdingId(holding.getHoldingId())
                        .coinId(holding.getCoinId())
                        .symbol(holding.getSymbol())
                        .quantity(qty)
                        .currentPriceUsd(currentPriceUsd)
                        .currentValueUsd(currentValueUsd)
                        .costBasisUsd(costBasisUsd)
                        .pnlUsd(pnlUsd)
                        .pnlPercent(pnlPercent)
                        .currentPriceInr(currentPriceInr)
                        .currentValueInr(currentValueInr)
                        .costBasisInr(costBasisInr)
                        .pnlInr(pnlInr)
                        .dayChangeInr(holdingDayChangeInr)
                        .dayChangePercent(holdingDayChangePercent)
                        .build());
            }

            BigDecimal totalValueInr = totalValueUsd.multiply(usdToInr);
            BigDecimal totalCostBasisInr = totalCostBasisUsd.multiply(usdToInr);
            BigDecimal totalPnlUsd = totalValueUsd.subtract(totalCostBasisUsd);
            BigDecimal totalPnlInr = totalValueInr.subtract(totalCostBasisInr);
            BigDecimal totalPnlPercent = totalCostBasisUsd.compareTo(BigDecimal.ZERO) != 0
                    ? totalPnlUsd.multiply(BigDecimal.valueOf(100)).divide(totalCostBasisUsd, 8, RoundingMode.HALF_UP)
                    : BigDecimal.ZERO;

            BigDecimal totalValue24hAgoInr = totalValue24hAgoUsd.multiply(usdToInr);
            BigDecimal dayChangeInr = totalValue24hAgoInr.compareTo(BigDecimal.ZERO) != 0
                    ? totalValueInr.subtract(totalValue24hAgoInr)
                    : BigDecimal.ZERO;
            BigDecimal dayChangePercent = totalValue24hAgoInr.compareTo(BigDecimal.ZERO) != 0
                    ? dayChangeInr.multiply(BigDecimal.valueOf(100)).divide(totalValue24hAgoInr, 8, RoundingMode.HALF_UP)
                    : BigDecimal.ZERO;

            return PortfolioSummaryDTO.builder()
                    .portfolioId(portfolioId)
                    .portfolioName(portfolio.getName())
                    .totalValueUsd(totalValueUsd)
                    .totalCostBasisUsd(totalCostBasisUsd)
                    .totalPnlUsd(totalPnlUsd)
                    .totalPnlPercent(totalPnlPercent)
                    .totalValueInr(totalValueInr)
                    .totalCostBasisInr(totalCostBasisInr)
                    .totalPnlInr(totalPnlInr)
                    .dayChangeInr(dayChangeInr)
                    .dayChangePercent(dayChangePercent)
                    .bestPerformer(bestPerformer)
                    .bestPerformerGain(bestGain.compareTo(BigDecimal.valueOf(Double.NEGATIVE_INFINITY)) == 0 ? BigDecimal.ZERO : bestGain)
                    .worstPerformer(worstPerformer)
                    .worstPerformerLoss(worstGain.compareTo(BigDecimal.valueOf(Double.POSITIVE_INFINITY)) == 0 ? BigDecimal.ZERO : worstGain)
                    .holdings(performances)
                    .build();
        } catch (Exception ex) {
            log.error("Error fetching portfolio summary", ex);
            throw ex;
        }
    }

    public PortfolioHistoryDTO getPortfolioHistory(String portfolioId, String userId, int days) {
        try {
            log.debug("Fetching portfolio history: {} for user: {}, days={}", portfolioId, userId, days);
            Portfolio portfolio = portfolioRepository.findByIdAndUserId(portfolioId, userId)
                    .orElseThrow(() -> new UnauthorizedException("Portfolio not found or access denied"));

            BigDecimal usdToInr = exchangeRateClient.fetchUsdToInrRate();
            List<PortfolioHistoryDTO.DailyValueDTO> history = new ArrayList<>();

            for (int i = days - 1; i >= 0; i--) {
                LocalDate date = LocalDate.now().minusDays(i);
                LocalDateTime endOfDay = date.atTime(LocalTime.MAX);

                BigDecimal dailyValueUsd = BigDecimal.ZERO;

                for (Holding holding : portfolio.getHoldings()) {
                    PriceSnapshot snap = priceSnapshotRepository
                            .findTopByCoinIdAndFetchedAtBeforeOrderByFetchedAtDesc(holding.getCoinId(), endOfDay)
                            .orElse(null);

                    if (snap != null) {
                        dailyValueUsd = dailyValueUsd.add(holding.getQuantity().multiply(snap.getPriceUsd()));
                    }
                }

                history.add(PortfolioHistoryDTO.DailyValueDTO.builder()
                        .date(date)
                        .totalValueUsd(dailyValueUsd)
                        .totalValueInr(dailyValueUsd.multiply(usdToInr))
                        .build());
            }

            return PortfolioHistoryDTO.builder()
                    .portfolioId(portfolioId)
                    .portfolioName(portfolio.getName())
                    .history(history)
                    .build();
        } catch (Exception ex) {
            log.error("Error fetching portfolio history", ex);
            throw ex;
        }
    }

    public void fetchAndSaveSnapshots() {
        try {
            List<com.alpharedge.document.TrackedCoin> coins = trackedCoinRepository.findByIsActiveTrue();
            log.info("Snapshot fetch triggered for {} coins (delegated to CoinService)", coins.size());
        } catch (Exception ex) {
            log.error("Error in fetchAndSaveSnapshots", ex);
        }
    }
}
