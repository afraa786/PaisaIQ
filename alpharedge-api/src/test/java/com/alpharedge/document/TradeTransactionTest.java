package com.alpharedge.document;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.assertEquals;

class TradeTransactionTest {

    @ParameterizedTest(name = "{0}-{1} -> {2}")
    @CsvSource({
        "2025, 4,  2025-26",   // April  → new FY starts
        "2025, 5,  2025-26",   // May
        "2025, 12, 2025-26",   // December
        "2026, 1,  2025-26",   // January → still previous FY
        "2026, 2,  2025-26",   // February
        "2026, 3,  2025-26",   // March → last month of FY
        "2026, 4,  2026-27",   // April  → new FY starts
        "2024, 4,  2024-25",   // boundary: 2024 April
        "2025, 1,  2024-25",   // January before April
        "2000, 4,  2000-01",   // year-end rollover (short year = 01)
        "1999, 12, 1999-00",   // short year = 00
    })
    void computeFinancialYear_returnsCorrectFY(int year, int month, String expected) {
        LocalDateTime ts = LocalDateTime.of(year, month, 15, 10, 0);
        assertEquals(expected, TradeTransaction.computeFinancialYear(ts));
    }

    @Test
    void computeFinancialYear_marchIsEndOfFY() {
        LocalDateTime march = LocalDateTime.of(2026, 3, 31, 23, 59);
        assertEquals("2025-26", TradeTransaction.computeFinancialYear(march));
    }

    @Test
    void computeFinancialYear_aprilStartsNewFY() {
        LocalDateTime april = LocalDateTime.of(2026, 4, 1, 0, 0);
        assertEquals("2026-27", TradeTransaction.computeFinancialYear(april));
    }
}
