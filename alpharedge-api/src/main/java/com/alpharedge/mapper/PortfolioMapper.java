package com.alpharedge.mapper;

import com.alpharedge.document.Holding;
import com.alpharedge.document.Portfolio;
import com.alpharedge.dto.response.HoldingSummaryDTO;
import com.alpharedge.dto.response.PortfolioDTO;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

@Mapper(componentModel = "spring")
public interface PortfolioMapper {

    PortfolioMapper INSTANCE = Mappers.getMapper(PortfolioMapper.class);

    PortfolioDTO toDTO(Portfolio portfolio);

    Portfolio toEntity(PortfolioDTO portfolioDTO);

    HoldingSummaryDTO toDTO(Holding holding);

    Holding toEntity(HoldingSummaryDTO holdingSummaryDTO);
}
