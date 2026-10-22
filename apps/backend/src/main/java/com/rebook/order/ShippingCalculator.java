package com.rebook.order;

import com.rebook.system.SystemConfigService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.text.Normalizer;

/**
 * Phí ship theo bảng cố định: nội tỉnh / liên tỉnh cho gói ≤ 1kg,
 * cộng thêm mỗi 500g vượt 1kg. (Vận chuyển là giả lập.)
 */
@Component
@RequiredArgsConstructor
public class ShippingCalculator {

    private final SystemConfigService config;

    public BigDecimal fee(String fromProvince, String toProvince, int totalWeightGram) {
        boolean same = normalize(fromProvince).equals(normalize(toProvince));
        BigDecimal base = config.decimal(same ? SystemConfigService.SHIP_SAME_PROVINCE : SystemConfigService.SHIP_OTHER_PROVINCE);
        int extraSteps = totalWeightGram <= 1000 ? 0 : (int) Math.ceil((totalWeightGram - 1000) / 500.0);
        return base.add(config.decimal(SystemConfigService.SHIP_EXTRA_PER_500G).multiply(BigDecimal.valueOf(extraSteps)));
    }

    public String warehouseProvince() {
        return config.get(SystemConfigService.WAREHOUSE_PROVINCE);
    }

    /** "TP. Hồ Chí Minh" và "Hồ Chí Minh" coi là một tỉnh. */
    static String normalize(String province) {
        if (province == null) {
            return "";
        }
        String s = Normalizer.normalize(province, Normalizer.Form.NFD).replaceAll("\\p{M}", "")
                .replace('đ', 'd').replace('Đ', 'D').toLowerCase()
                .replaceAll("^(tp\\.?|thanh pho|tinh)\\s*", "").replaceAll("[^a-z0-9]", "");
        return s;
    }
}
