package com.alpharedge.service;

import com.alpharedge.client.CoinGeckoClient;
import com.alpharedge.client.ExchangeRateClient;
import com.alpharedge.document.CoinSignal;
import com.alpharedge.document.PriceSnapshot;
import com.alpharedge.document.TrackedCoin;
import com.alpharedge.dto.coingecko.CoinGeckoDetailResponse;
import com.alpharedge.dto.response.CoinDetailDTO;
import com.alpharedge.dto.response.CoinPriceDTO;
import com.alpharedge.dto.response.CoinSignalDTO;
import com.alpharedge.dto.response.CompareDTO;
import com.alpharedge.dto.response.PriceSnapshotDTO;
import com.alpharedge.dto.response.TrackedCoinDTO;
import com.alpharedge.engine.TechnicalAnalysisService;
import com.alpharedge.exception.CoinNotFoundException;
import com.alpharedge.mapper.CoinMapper;
import com.alpharedge.repository.CoinSignalRepository;
import com.alpharedge.repository.PriceSnapshotRepository;
import com.alpharedge.repository.TrackedCoinRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
public class CoinService {

    private final CoinGeckoClient coinGeckoClient;
    private final ExchangeRateClient exchangeRateClient;
    private final TrackedCoinRepository trackedCoinRepository;
    private final PriceSnapshotRepository priceSnapshotRepository;
    private final CoinSignalRepository coinSignalRepository;
    private final CoinMapper coinMapper;
    private final TechnicalAnalysisService technicalAnalysisService;

    @Autowired
    public CoinService(CoinGeckoClient coinGeckoClient,
                      ExchangeRateClient exchangeRateClient,
                      TrackedCoinRepository trackedCoinRepository,
                      PriceSnapshotRepository priceSnapshotRepository,
                      CoinSignalRepository coinSignalRepository,
                      CoinMapper coinMapper,
                      TechnicalAnalysisService technicalAnalysisService) {
        this.coinGeckoClient = coinGeckoClient;
        this.exchangeRateClient = exchangeRateClient;
        this.trackedCoinRepository = trackedCoinRepository;
        this.priceSnapshotRepository = priceSnapshotRepository;
        this.coinSignalRepository = coinSignalRepository;
        this.coinMapper = coinMapper;
        this.technicalAnalysisService = technicalAnalysisService;
    }

    public TrackedCoinDTO trackCoin(String coinId) {
        try {
            var existing = trackedCoinRepository.findByCoinId(coinId);
            if (existing.isPresent()) {
                log.info("Coin already tracked: {}", coinId);
                return coinMapper.toDTO(existing.get());
            }

            log.info("Tracking new coin: {}", coinId);
            CoinGeckoDetailResponse details = coinGeckoClient.fetchCoinDetails(coinId);

            TrackedCoin trackedCoin = TrackedCoin.builder()
                    .coinId(coinId)
                    .symbol(details.getSymbol())
                    .name(details.getName())
                    .isActive(true)
                    .build();
            trackedCoin = trackedCoinRepository.save(trackedCoin);

            PriceSnapshot snapshot = mapDetailResponseToSnapshot(details, coinId);
            priceSnapshotRepository.save(snapshot);

            List<BigDecimal> prices = coinGeckoClient.fetchMarketChart(coinId, 90);
            if (!prices.isEmpty()) {
                TechnicalAnalysisService.CoinSignalResult signalResult = technicalAnalysisService.computeAll(
                        prices,
                        details.getMarketData().getPriceChange24h().getUsd(),
                        details.getMarketData().getPriceChangePercentage7d().getUsd(),
                        details.getMarketData().getPriceChangePercentage30d().getUsd(),
                        details.getMarketData().getCurrentPrice().getUsd()
                );

                CoinSignal signal = buildCoinSignal(coinId, signalResult);
                coinSignalRepository.save(signal);
            }

            return coinMapper.toDTO(trackedCoin);
        } catch (Exception ex) {
            log.error("Error tracking coin: {}", coinId, ex);
            throw ex;
        }
    }

    public List<TrackedCoinDTO> getAllCoins() {
        try {
            List<TrackedCoin> coins = trackedCoinRepository.findByIsActiveTrue();
            return coins.stream()
                    .map(coinMapper::toDTO)
                    .collect(Collectors.toList());
        } catch (Exception ex) {
            log.error("Error fetching all coins", ex);
            return new ArrayList<>();
        }
    }

    public CoinDetailDTO getCoinDetail(String coinId) {
        try {
            TrackedCoin trackedCoin = trackedCoinRepository.findByCoinId(coinId)
                    .orElseThrow(() -> new CoinNotFoundException("Coin not found: " + coinId));

            PriceSnapshotDTO priceSnapshot = priceSnapshotRepository.findTopByCoinIdOrderByFetchedAtDesc(coinId)
                    .map(coinMapper::toDTO)
                    .orElse(null);

            CoinSignalDTO signal = coinSignalRepository.findTopByCoinIdOrderByComputedAtDesc(coinId)
                    .map(coinMapper::toDTO)
                    .orElse(null);

            return CoinDetailDTO.builder()
                    .id(trackedCoin.getId())
                    .coinId(trackedCoin.getCoinId())
                    .symbol(trackedCoin.getSymbol())
                    .name(trackedCoin.getName())
                    .isActive(trackedCoin.getIsActive())
                    .priceSnapshot(priceSnapshot)
                    .signal(signal)
                    .createdAt(trackedCoin.getCreatedAt())
                    .build();
        } catch (Exception ex) {
            log.error("Error fetching coin detail: {}", coinId, ex);
            throw ex;
        }
    }

    public List<PriceSnapshotDTO> getCoinHistory(String coinId, int days) {
        try {
            TrackedCoin tracked = trackedCoinRepository.findByCoinId(coinId)
                    .orElseThrow(() -> new CoinNotFoundException("Coin not found: " + coinId));

            LocalDateTime since = LocalDateTime.now().minusDays(days);
            List<PriceSnapshot> snapshots = priceSnapshotRepository
                    .findByCoinIdAndFetchedAtAfterOrderByFetchedAtDesc(coinId, since);

            return snapshots.stream()
                    .map(coinMapper::toDTO)
                    .collect(Collectors.toList());
        } catch (Exception ex) {
            log.error("Error fetching coin history: {}", coinId, ex);
            throw ex;
        }
    }

    @Cacheable(value = "coinSignals", key = "#coinId")
    public CoinSignalDTO getCoinSignal(String coinId) {
        try {
            CoinSignal signal = coinSignalRepository.findTopByCoinIdOrderByComputedAtDesc(coinId)
                    .orElseThrow(() -> new CoinNotFoundException("No signal data found for coin: " + coinId));

            return coinMapper.toDTO(signal);
        } catch (Exception ex) {
            log.error("Error fetching coin signal: {}", coinId, ex);
            throw ex;
        }
    }

    @Cacheable(value = "coinPrices", key = "#coinId")
    public CoinPriceDTO getCoinPrice(String coinId) {
        try {
            trackedCoinRepository.findByCoinId(coinId)
                    .orElseThrow(() -> new CoinNotFoundException("Coin not found: " + coinId));

            CoinGeckoDetailResponse details = coinGeckoClient.fetchCoinDetails(coinId);
            BigDecimal priceUsd = details.getMarketData().getCurrentPrice().getUsd();
            BigDecimal usdToInr = exchangeRateClient.fetchUsdToInrRate();
            BigDecimal priceInr = priceUsd.multiply(usdToInr);

            return CoinPriceDTO.builder()
                    .coinId(coinId)
                    .priceUSD(priceUsd)
                    .priceINR(priceInr)
                    .lastUpdated(java.time.LocalDateTime.now())
                    .build();
        } catch (Exception ex) {
            log.error("Error fetching coin price: {}", coinId, ex);
            throw ex;
        }
    }

    public PriceSnapshotDTO getLivePrice(String coinId) {
        try {
            TrackedCoin tracked = trackedCoinRepository.findByCoinId(coinId)
                    .orElseThrow(() -> new CoinNotFoundException("Coin not found: " + coinId));

            CoinGeckoDetailResponse details = coinGeckoClient.fetchCoinDetails(coinId);
            PriceSnapshot snapshot = mapDetailResponseToSnapshot(details, coinId);
            snapshot = priceSnapshotRepository.save(snapshot);

            return coinMapper.toDTO(snapshot);
        } catch (Exception ex) {
            log.error("Error fetching live price: {}", coinId, ex);
            throw ex;
        }
    }

    public List<CompareDTO> compareCoins(List<String> coinIds) {
        try {
            return coinIds.stream()
                    .map(coinId -> {
                        try {
                            var snapshot = priceSnapshotRepository.findTopByCoinIdOrderByFetchedAtDesc(coinId).orElse(null);
                            var signal = coinSignalRepository.findTopByCoinIdOrderByComputedAtDesc(coinId).orElse(null);
                            var tracked = trackedCoinRepository.findByCoinId(coinId).orElse(null);

                            if (snapshot == null || tracked == null) {
                                return null;
                            }

                            return CompareDTO.builder()
                                    .coinId(coinId)
                                    .symbol(tracked.getSymbol())
                                    .name(tracked.getName())
                                    .priceUsd(snapshot.getPriceUsd())
                                    .priceChange24hPercent(snapshot.getPriceChange24hPercent())
                                    .marketCapUsd(snapshot.getMarketCapUsd())
                                    .volume24hUsd(snapshot.getVolume24hUsd())
                                    .rsi(signal != null ? signal.getRsi() : BigDecimal.ZERO)
                                    .signal(signal != null ? signal.getSignal().toString() : "N/A")
                                    .momentumScore(signal != null ? signal.getMomentumScore() : BigDecimal.ZERO)
                                    .build();
                        } catch (Exception ex) {
                            log.error("Error comparing coin: {}", coinId, ex);
                            return null;
                        }
                    })
                    .filter(c -> c != null)
                    .sorted(Comparator.comparing(CompareDTO::getMomentumScore).reversed())
                    .collect(Collectors.toList());
        } catch (Exception ex) {
            log.error("Error comparing coins", ex);
            return new ArrayList<>();
        }
    }

    public void fetchAndSaveSnapshots() {
        try {
            List<TrackedCoin> coins = trackedCoinRepository.findByIsActiveTrue();
            for (TrackedCoin coin : coins) {
                try {
                    log.debug("Fetching snapshot for: {}", coin.getCoinId());
                    CoinGeckoDetailResponse details = coinGeckoClient.fetchCoinDetails(coin.getCoinId());
                    PriceSnapshot snapshot = mapDetailResponseToSnapshot(details, coin.getCoinId());
                    priceSnapshotRepository.save(snapshot);
                } catch (Exception ex) {
                    log.error("Error fetching snapshot for coin: {}", coin.getCoinId(), ex);
                }
            }
            log.info("Price snapshot update complete for {} coins", coins.size());
        } catch (Exception ex) {
            log.error("Error in fetchAndSaveSnapshots", ex);
        }
    }

    public void computeAndSaveSignals() {
        try {
            List<TrackedCoin> coins = trackedCoinRepository.findByIsActiveTrue();
            for (TrackedCoin coin : coins) {
                try {
                    log.debug("Computing signals for: {}", coin.getCoinId());
                    List<BigDecimal> prices = coinGeckoClient.fetchMarketChart(coin.getCoinId(), 90);
                    var snapshot = priceSnapshotRepository.findTopByCoinIdOrderByFetchedAtDesc(coin.getCoinId()).orElse(null);

                    if (!prices.isEmpty() && snapshot != null) {
                        TechnicalAnalysisService.CoinSignalResult signalResult = technicalAnalysisService.computeAll(
                                prices,
                                snapshot.getPriceChange24hPercent(),
                                snapshot.getPriceChange7dPercent(),
                                snapshot.getPriceChange30dPercent(),
                                snapshot.getPriceUsd()
                        );

                        CoinSignal signal = buildCoinSignal(coin.getCoinId(), signalResult);
                        coinSignalRepository.save(signal);
                    }
                } catch (Exception ex) {
                    log.error("Error computing signals for coin: {}", coin.getCoinId(), ex);
                }
            }
            log.info("Signal computation complete for {} coins", coins.size());
        } catch (Exception ex) {
            log.error("Error in computeAndSaveSignals", ex);
        }
    }

    private CoinSignal buildCoinSignal(String coinId, TechnicalAnalysisService.CoinSignalResult r) {
        return CoinSignal.builder()
                .coinId(coinId)
                .rsi(r.getRsi())
                .macd(r.getMacd())
                .macdSignal(r.getMacdSignal())
                .macdHistogram(r.getMacdHistogram())
                .sma7(r.getSma7())
                .sma30(r.getSma30())
                .bollingerUpper(r.getBollingerUpper())
                .bollingerMiddle(r.getBollingerMiddle())
                .bollingerLower(r.getBollingerLower())
                .signal(CoinSignal.Signal.valueOf(r.getSignal()))
                .strength(CoinSignal.SignalStrength.valueOf(r.getStrength()))
                .volatilityScore(r.getVolatilityScore())
                .momentumScore(r.getMomentumScore())
                .signalExplanation(r.getSignalExplanation())
                .riskScore(r.getRiskScore())
                .build();
    }

    private PriceSnapshot mapDetailResponseToSnapshot(CoinGeckoDetailResponse details, String coinId) {
        CoinGeckoDetailResponse.MarketData market = details.getMarketData();
        BigDecimal priceUsd = market.getCurrentPrice().getUsd();
        BigDecimal usdToInr = exchangeRateClient.fetchUsdToInrRate();
        BigDecimal priceInr = priceUsd.multiply(usdToInr);
        return PriceSnapshot.builder()
                .coinId(coinId)
                .priceUsd(priceUsd)
                .priceInr(priceInr)
                .marketCapUsd(market.getMarketCap().getUsd())
                .volume24hUsd(market.getVol24h().getUsd())
                .priceChange24hPercent(market.getPriceChange24h().getUsd())
                .priceChange7dPercent(market.getPriceChangePercentage7d().getUsd())
                .priceChange30dPercent(market.getPriceChangePercentage30d().getUsd())
                .allTimeHighUsd(market.getAllTimeHigh().getUsd())
                .allTimeLowUsd(market.getAllTimeLow().getUsd())
                .circulatingSupply(market.getCirculatingSupply().getValue())
                .totalSupply(market.getTotalSupply().getValue())
                .marketCapRank(market.getMarketCapRank())
                .build();
    }
}
