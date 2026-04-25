package com.alpharedge.service;

import com.alpharedge.client.CoinGeckoClient;
import com.alpharedge.document.PriceSnapshot;
import com.alpharedge.dto.coingecko.CoinGeckoGlobalResponse;
import com.alpharedge.dto.coingecko.CoinGeckoTrendingResponse;
import com.alpharedge.dto.response.GlobalMarketDTO;
import com.alpharedge.dto.response.PriceSnapshotDTO;
import com.alpharedge.dto.response.TrendingDTO;
import com.alpharedge.mapper.CoinMapper;
import com.alpharedge.repository.PriceSnapshotRepository;
import com.alpharedge.repository.TrackedCoinRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
public class MarketService {

    private final CoinGeckoClient coinGeckoClient;
    private final PriceSnapshotRepository priceSnapshotRepository;
    private final TrackedCoinRepository trackedCoinRepository;
    private final CoinMapper coinMapper;

    @Autowired
    public MarketService(CoinGeckoClient coinGeckoClient,
                        PriceSnapshotRepository priceSnapshotRepository,
                        TrackedCoinRepository trackedCoinRepository,
                        CoinMapper coinMapper) {
        this.coinGeckoClient = coinGeckoClient;
        this.priceSnapshotRepository = priceSnapshotRepository;
        this.trackedCoinRepository = trackedCoinRepository;
        this.coinMapper = coinMapper;
    }

    public GlobalMarketDTO getGlobalSummary() {
        try {
            log.debug("Fetching global market summary");
            CoinGeckoGlobalResponse response = coinGeckoClient.fetchGlobal();

            if (response == null || response.getGlobalData() == null) {
                log.warn("Empty response from global endpoint");
                return GlobalMarketDTO.builder().build();
            }

            CoinGeckoGlobalResponse.GlobalData data = response.getGlobalData();
            return GlobalMarketDTO.builder()
                    .totalMarketCapUsd(data.getTotalMarketCap() != null ? data.getTotalMarketCap().getUsd() : null)
                    .totalMarketCapInr(data.getTotalMarketCap() != null ? data.getTotalMarketCap().getInr() : null)
                    .totalVolumeUsd(data.getTotalVolume() != null ? data.getTotalVolume().getUsd() : null)
                    .totalVolumeInr(data.getTotalVolume() != null ? data.getTotalVolume().getInr() : null)
                    .btcMarketCapPercent(data.getMarketCapPercentage() != null ? data.getMarketCapPercentage().getBtc() : null)
                    .ethMarketCapPercent(data.getMarketCapPercentage() != null ? data.getMarketCapPercentage().getEth() : null)
                    .activeCryptocurrencies(data.getActiveCryptocurrencies())
                    .build();
        } catch (Exception ex) {
            log.error("Error fetching global market summary", ex);
            return GlobalMarketDTO.builder().build();
        }
    }

    public List<TrendingDTO> getTrending() {
        try {
            log.debug("Fetching trending coins");
            CoinGeckoTrendingResponse response = coinGeckoClient.fetchTrending();

            if (response == null || response.getCoins() == null) {
                log.warn("Empty response from trending endpoint");
                return new ArrayList<>();
            }

            return response.getCoins().stream()
                    .filter(coin -> coin != null && coin.getItem() != null)
                    .map(coin -> TrendingDTO.builder()
                            .coinId(coin.getItem().getCoinId())
                            .name(coin.getItem().getName())
                            .symbol(coin.getItem().getSymbol())
                            .thumb(coin.getItem().getThumb())
                            .marketCapRank(coin.getItem().getMarketCapRank())
                            .build())
                    .collect(Collectors.toList());
        } catch (Exception ex) {
            log.error("Error fetching trending coins", ex);
            return new ArrayList<>();
        }
    }

    public Page<PriceSnapshotDTO> getRankings(String sortBy, String order, Pageable pageable) {
        try {
            log.debug("Fetching rankings: sortBy={}, order={}", sortBy, order);
            List<PriceSnapshot> allSnapshots = new ArrayList<>();

            var trackedCoins = trackedCoinRepository.findByIsActiveTrue();
            for (var coin : trackedCoins) {
                var snapshot = priceSnapshotRepository.findTopByCoinIdOrderByFetchedAtDesc(coin.getCoinId());
                snapshot.ifPresent(allSnapshots::add);
            }

            Comparator<PriceSnapshot> comparator = getComparator(sortBy);
            if ("desc".equalsIgnoreCase(order)) {
                comparator = comparator.reversed();
            }

            List<PriceSnapshotDTO> sorted = allSnapshots.stream()
                    .sorted(comparator)
                    .map(coinMapper::toDTO)
                    .collect(Collectors.toList());

            int start = (int) pageable.getOffset();
            int end = Math.min(start + pageable.getPageSize(), sorted.size());
            List<PriceSnapshotDTO> pageContent = sorted.subList(start, end);

            return new PageImpl<>(pageContent, pageable, sorted.size());
        } catch (Exception ex) {
            log.error("Error fetching rankings", ex);
            return Page.empty(pageable);
        }
    }

    private Comparator<PriceSnapshot> getComparator(String sortBy) {
        return switch (sortBy != null ? sortBy.toLowerCase() : "marketCap") {
            case "price" -> Comparator.comparing(p -> p.getPriceUsd() != null ? p.getPriceUsd() : java.math.BigDecimal.ZERO);
            case "pricechange24h" -> Comparator.comparing(p -> p.getPriceChange24hPercent() != null ? p.getPriceChange24hPercent() : java.math.BigDecimal.ZERO);
            case "pricechange7d" -> Comparator.comparing(p -> p.getPriceChange7dPercent() != null ? p.getPriceChange7dPercent() : java.math.BigDecimal.ZERO);
            case "volume24h" -> Comparator.comparing(p -> p.getVolume24hUsd() != null ? p.getVolume24hUsd() : java.math.BigDecimal.ZERO);
            default -> Comparator.comparing(p -> p.getMarketCapUsd() != null ? p.getMarketCapUsd() : java.math.BigDecimal.ZERO);
        };
    }
}
