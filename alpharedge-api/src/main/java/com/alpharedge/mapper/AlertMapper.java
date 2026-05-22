package com.alpharedge.mapper;

import com.alpharedge.document.PriceAlert;
import com.alpharedge.dto.request.CreateAlertRequest;
import com.alpharedge.dto.response.AlertDTO;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public interface AlertMapper {

    AlertMapper INSTANCE = org.mapstruct.factory.Mappers.getMapper(AlertMapper.class);

    AlertDTO toDTO(PriceAlert priceAlert);

    PriceAlert toEntity(AlertDTO alertDTO);

    PriceAlert toEntity(CreateAlertRequest createAlertRequest);
}
