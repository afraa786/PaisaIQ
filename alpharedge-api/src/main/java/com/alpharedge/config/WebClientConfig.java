package com.alpharedge.config;

import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.reactive.function.client.WebClient;

@Configuration
public class WebClientConfig {

    @Bean
    public WebClient webClient(WebClient.Builder builder) {
        return builder
                .baseUrl("https://api.coingecko.com/api/v3")
                .defaultHeader("User-Agent", "AlphaEdge/1.0")
                .build();
    }

    @Bean
    @Qualifier("exchangeRateWebClient")
    public WebClient exchangeRateWebClient(WebClient.Builder builder) {
        return builder
                .baseUrl("https://api.exchangerate-api.com/v4")
                .defaultHeader("User-Agent", "AlphaEdge/1.0")
                .build();
    }
}
