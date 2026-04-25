package com.alpharedge.dto.coingecko;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class CoinGeckoGlobalResponse {
    @JsonProperty("data")
    private GlobalData globalData;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class GlobalData {
        @JsonProperty("total_market_cap")
        private MarketCap totalMarketCap;

        @JsonProperty("total_volume")
        private Volume totalVolume;

        @JsonProperty("market_cap_percentage")
        private MarketCapPercentage marketCapPercentage;

        @JsonProperty("active_cryptocurrencies")
        private Integer activeCryptocurrencies;

        @Data
        @NoArgsConstructor
        @AllArgsConstructor
        @JsonIgnoreProperties(ignoreUnknown = true)
        public static class MarketCap {
            private BigDecimal usd;
            private BigDecimal inr;
        }

        @Data
        @NoArgsConstructor
        @AllArgsConstructor
        @JsonIgnoreProperties(ignoreUnknown = true)
        public static class Volume {
            private BigDecimal usd;
            private BigDecimal inr;
        }

        @Data
        @NoArgsConstructor
        @AllArgsConstructor
        @JsonIgnoreProperties(ignoreUnknown = true)
        public static class MarketCapPercentage {
            private BigDecimal btc;
            private BigDecimal eth;
        }
    }
}
