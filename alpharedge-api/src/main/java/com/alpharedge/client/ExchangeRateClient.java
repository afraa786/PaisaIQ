package com.alpharedge.client;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;

import java.math.BigDecimal;
import java.util.Map;

@Slf4j
@Component
public class ExchangeRateClient {

    private final WebClient webClient;

    public ExchangeRateClient(@Qualifier("exchangeRateWebClient") WebClient webClient) {
        this.webClient = webClient;
    }

    @Cacheable(value = "exchangeRates", key = "'USD_INR'")
    public BigDecimal fetchUsdToInrRate() {
        try {
            log.debug("Fetching USD/INR exchange rate");
            @SuppressWarnings("unchecked")
            Map<String, Object> response = webClient.get()
                    .uri("/latest/USD")
                    .retrieve()
                    .bodyToMono(Map.class)
                    .block();

            if (response != null && response.containsKey("rates")) {
                @SuppressWarnings("unchecked")
                Map<String, Object> rates = (Map<String, Object>) response.get("rates");
                Object inrRate = rates.get("INR");
                if (inrRate != null) {
                    return new BigDecimal(inrRate.toString());
                }
            }
            log.warn("Could not parse INR rate from exchange rate API, using fallback");
            return BigDecimal.valueOf(83.5);
        } catch (Exception ex) {
            log.error("Failed to fetch exchange rate, using fallback: {}", ex.getMessage());
            return BigDecimal.valueOf(83.5);
        }
    }
}
