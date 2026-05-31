package com.alpharedge.dto.response;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class OhlcDTO {
    private long timestamp;
    private double open;
    private double high;
    private double low;
    private double close;
}
