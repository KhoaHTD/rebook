package com.rebook.order;

import com.rebook.common.PageResponse;
import com.rebook.order.CodService.CodPendingResponse;
import com.rebook.order.OrderDtos.OrderDetail;
import com.rebook.security.UserPrincipal;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigDecimal;

/** [Admin] Đối soát COD với hãng vận chuyển. */
@Tag(name = "COD")
@RestController
@RequiredArgsConstructor
public class CodController {

    private final CodService codService;

    public record CodRemitRequest(@NotNull BigDecimal amount, @Size(max = 100) String reference) {
    }

    @Operation(summary = "[Admin] Đơn COD đã giao nhưng sàn chưa nhận tiền đối soát")
    @GetMapping("/admin/cod/pending")
    public PageResponse<CodPendingResponse> pending(@RequestParam(defaultValue = "0") int page,
                                                    @RequestParam(defaultValue = "20") int size) {
        return codService.pending(page, size);
    }

    @Operation(summary = "[Admin] Xác nhận sàn đã nhận đúng số tiền COD của đơn (rồi mới trả shop / hoàn người mua)")
    @PostMapping("/admin/cod/{orderId}/remit")
    public OrderDetail remit(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long orderId,
                             @Valid @RequestBody CodRemitRequest req) {
        return codService.remit(me.id(), orderId, req.amount(), req.reference());
    }
}
