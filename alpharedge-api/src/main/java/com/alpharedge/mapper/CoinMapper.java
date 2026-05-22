package com.alpharedge.mapper;

import com.alpharedge.document.CoinSignal;
import com.alpharedge.document.PriceSnapshot;
import com.alpharedge.document.TrackedCoin;
import com.alpharedge.dto.coingecko.CoinGeckoDetailResponse;
import com.alpharedge.dto.response.CoinSignalDTO;
import com.alpharedge.dto.response.PriceSnapshotDTO;
import com.alpharedge.dto.response.TrackedCoinDTO;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public interface CoinMapper {

    CoinMapper INSTANCE = org.mapstruct.factory.Mappers.getMapper(CoinMapper.class);

    TrackedCoinDTO toDTO(TrackedCoin trackedCoin);

    TrackedCoin toEntity(TrackedCoinDTO trackedCoinDTO);

    PriceSnapshotDTO toDTO(PriceSnapshot priceSnapshot);

    PriceSnapshot toEntity(PriceSnapshotDTO priceSnapshotDTO);

    CoinSignalDTO toDTO(CoinSignal coinSignal);

    CoinSignal toEntity(CoinSignalDTO coinSignalDTO);
}
