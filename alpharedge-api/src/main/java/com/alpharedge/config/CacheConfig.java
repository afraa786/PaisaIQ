package com.alpharedge.config;

import com.github.benmanes.caffeine.cache.Caffeine;
import org.springframework.cache.CacheManager;
import org.springframework.cache.caffeine.CaffeineCacheManager;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.concurrent.TimeUnit;

@Configuration
public class CacheConfig {

    @Bean
    public CacheManager cacheManager() {
        CaffeineCacheManager manager = new CaffeineCacheManager() {
            @Override
            protected com.github.benmanes.caffeine.cache.Cache<Object, Object> createNativeCaffeineCache(String name) {
                Caffeine<Object, Object> builder = Caffeine.newBuilder().maximumSize(200);
                if ("coinSignals".equals(name)) {
                    builder.expireAfterWrite(1, TimeUnit.HOURS);
                } else {
                    builder.expireAfterWrite(5, TimeUnit.MINUTES);
                }
                return builder.build();
            }
        };
        manager.setCacheNames(java.util.List.of("coinPrices", "exchangeRates", "coinSignals"));
        return manager;
    }
}
