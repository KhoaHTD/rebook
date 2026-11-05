package com.rebook.catalog;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;

class SearchFoldTest {

    @Test
    void foldsVietnameseAccentsAndCase() {
        assertEquals("so do", ListingService.fold("Sổ Đỏ"));
        assertEquals("tat den", ListingService.fold("  TẮT ĐÈN "));
        assertEquals("nhan tam", ListingService.fold("nhân tâm"));
    }
}
