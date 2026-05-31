package com.alpharedge.client;

import com.alpharedge.dto.coingecko.*;
import com.alpharedge.exception.CoinGeckoApiException;
import com.alpharedge.exception.RateLimitException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.retry.annotation.Backoff;
import org.springframework.retry.annotation.Retryable;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;
import reactor.core.publisher.Mono;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@Slf4j
@Component
public class CoinGeckoClient {

    private final WebClient webClient;

    @Autowired
    public CoinGeckoClient(WebClient webClient) {
        this.webClient = webClient;
    }

    @Retryable(retryFor = Exception.class, maxAttempts = 3, backoff = @Backoff(delay = 2000))
    public CoinGeckoDetailResponse fetchCoinDetails(String coinId) {
        try {
            log.debug("Fetching coin details for: {}", coinId);
            return webClient.get()
                    .uri("/coins/{coinId}?localization=false&tickers=false&community_data=false&developer_data=false", coinId)
                    .retrieve()
                    .bodyToMono(CoinGeckoDetailResponse.class)
                    .block();
        } catch (WebClientResponseException ex) {
            if (ex.getStatusCode().value() == 429) {
                throw new RateLimitException("CoinGecko API rate limit exceeded");
            }
            throw new CoinGeckoApiException("Failed to fetch coin details: " + ex.getMessage(), ex);
        } catch (Exception ex) {
            throw new CoinGeckoApiException("Failed to fetch coin details: " + ex.getMessage(), ex);
        }
    }

    @Retryable(retryFor = Exception.class, maxAttempts = 3, backoff = @Backoff(delay = 2000))
    public List<BigDecimal> fetchMarketChart(String coinId, int days) {
        try {
            log.debug("Fetching market chart for: {} days={}", coinId, days);
            CoinGeckoMarketChartResponse response = webClient.get()
                    .uri("/coins/{coinId}/market_chart?vs_currency=usd&days={days}", coinId, days)
                    .retrieve()
                    .bodyToMono(CoinGeckoMarketChartResponse.class)
                    .block();

            List<BigDecimal> prices = new ArrayList<>();
            if (response != null && response.getPrices() != null) {
                for (Object[] price : response.getPrices()) {
                    if (price.length >= 2 && price[1] != null) {
                        prices.add(new BigDecimal(price[1].toString()));
                    }
                }
            }
            return prices;
        } catch (WebClientResponseException ex) {
            if (ex.getStatusCode().value() == 429) {
                throw new RateLimitException("CoinGecko API rate limit exceeded");
            }
            throw new CoinGeckoApiException("Failed to fetch market chart: " + ex.getMessage(), ex);
        } catch (Exception ex) {
            throw new CoinGeckoApiException("Failed to fetch market chart: " + ex.getMessage(), ex);
        }
    }

    @Retryable(retryFor = Exception.class, maxAttempts = 3, backoff = @Backoff(delay = 2000))
    public CoinGeckoTrendingResponse fetchTrending() {
        try {
            log.debug("Fetching trending coins");
            return webClient.get()
                    .uri("/trending")
                    .retrieve()
                    .bodyToMono(CoinGeckoTrendingResponse.class)
                    .block();
        } catch (WebClientResponseException ex) {
            if (ex.getStatusCode().value() == 429) {
                throw new RateLimitException("CoinGecko API rate limit exceeded");
            }
            throw new CoinGeckoApiException("Failed to fetch trending coins: " + ex.getMessage(), ex);
        } catch (Exception ex) {
            throw new CoinGeckoApiException("Failed to fetch trending coins: " + ex.getMessage(), ex);
        }
    }

    @Retryable(retryFor = Exception.class, maxAttempts = 3, backoff = @Backoff(delay = 2000))
    public CoinGeckoGlobalResponse fetchGlobal() {
        try {
            log.debug("Fetching global market data");
            return webClient.get()
                    .uri("/global")
                    .retrieve()
                    .bodyToMono(CoinGeckoGlobalResponse.class)
                    .block();
        } catch (WebClientResponseException ex) {
            if (ex.getStatusCode().value() == 429) {
                throw new RateLimitException("CoinGecko API rate limit exceeded");
            }
            throw new CoinGeckoApiException("Failed to fetch global data: " + ex.getMessage(), ex);
        } catch (Exception ex) {
            throw new CoinGeckoApiException("Failed to fetch global data: " + ex.getMessage(), ex);
        }
    }

    /**
     * Returns OHLC candles: each element is [timestamp, open, high, low, close].
     * CoinGecko returns 1 candle per day for days <= 90.
     */
    @Retryable(retryFor = Exception.class, maxAttempts = 3, backoff = @Backoff(delay = 2000))
    public List<List<Double>> fetchOhlc(String coinId, int days) {
        try {
            log.debug("Fetching OHLC for: {} days={}", coinId, days);
            @SuppressWarnings("unchecked")
            List<List<Double>> response = webClient.get()
                    .uri("/coins/{coinId}/ohlc?vs_currency=usd&days={days}", coinId, days)
                    .retrieve()
                    .bodyToMono((Class<List<List<Double>>>) (Class<?>) List.class)
                    .block();
            return response != null ? response : new ArrayList<>();
        } catch (WebClientResponseException ex) {
            if (ex.getStatusCode().value() == 429) throw new RateLimitException("CoinGecko rate limit");
            throw new CoinGeckoApiException("Failed to fetch OHLC: " + ex.getMessage(), ex);
        } catch (Exception ex) {
            throw new CoinGeckoApiException("Failed to fetch OHLC: " + ex.getMessage(), ex);
        }
    }

    @Retryable(retryFor = Exception.class, maxAttempts = 3, backoff = @Backoff(delay = 2000))
    public List<CoinGeckoMarketResponse> fetchTopCoins(int limit) {
        try {
            log.debug("Fetching top {} coins", limit);
            CoinGeckoMarketResponse[] response = webClient.get()
                    .uri("/coins/markets?vs_currency=usd&order=market_cap_desc&per_page={limit}&page=1&sparkline=false", limit)
                    .retrieve()
                    .bodyToMono(CoinGeckoMarketResponse[].class)
                    .block();

            if (response != null) {
                return List.of(response);
            }
            return new ArrayList<>();
        } catch (WebClientResponseException ex) {
            if (ex.getStatusCode().value() == 429) {
                throw new RateLimitException("CoinGecko API rate limit exceeded");
            }
            throw new CoinGeckoApiException("Failed to fetch top coins: " + ex.getMessage(), ex);
        } catch (Exception ex) {
            throw new CoinGeckoApiException("Failed to fetch top coins: " + ex.getMessage(), ex);
        }
    }
}
