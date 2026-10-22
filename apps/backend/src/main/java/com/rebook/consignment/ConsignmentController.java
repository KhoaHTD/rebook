package com.rebook.consignment;

import com.rebook.common.PageResponse;
import com.rebook.consignment.ConsignmentDtos.AppointmentRequest;
import com.rebook.consignment.ConsignmentDtos.CheckInRequest;
import com.rebook.consignment.ConsignmentDtos.ConsignmentCreateRequest;
import com.rebook.consignment.ConsignmentDtos.ConsignmentResponse;
import com.rebook.consignment.ConsignmentDtos.InspectionRequest;
import com.rebook.consignment.ConsignmentDtos.ReviewRequest;
import com.rebook.consignment.ConsignmentDtos.SellerDecisionRequest;
import com.rebook.consignment.ConsignmentDtos.ShelfRequest;
import com.rebook.consignment.ConsignmentDtos.UnsoldDecisionRequest;
import com.rebook.consignment.ConsignmentDtos.WarehouseResponse;
import com.rebook.security.UserPrincipal;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.time.Duration;
import java.time.Instant;
import java.util.List;

@Tag(name = "Consignment")
@RestController
@RequiredArgsConstructor
public class ConsignmentController {

    private final ConsignmentService service;

    // ---- Người bán ----

    @Operation(summary = "Gửi yêu cầu ký gửi đấu giá (giá mong muốn ≥ 300.000đ)")
    @PostMapping("/consignments")
    @ResponseStatus(HttpStatus.CREATED)
    public ConsignmentResponse create(@AuthenticationPrincipal UserPrincipal me, @Valid @RequestBody ConsignmentCreateRequest req) {
        return service.create(me.id(), req);
    }

    @GetMapping("/consignments")
    public List<ConsignmentResponse> mine(@AuthenticationPrincipal UserPrincipal me) {
        return service.mine(me.id());
    }

    @Operation(summary = "Chi tiết ký gửi: kết quả kiểm định, lô, kho")
    @GetMapping("/consignments/{id}")
    public ConsignmentResponse detail(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id) {
        return service.detail(me.id(), me.isStaffOrAdmin(), id);
    }

    @Operation(summary = "Đặt / đổi lịch hẹn mang sách tới kho")
    @PostMapping("/consignments/{id}/appointment")
    public ConsignmentResponse appointment(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id,
                                           @Valid @RequestBody AppointmentRequest req) {
        return service.bookAppointment(me.id(), id, req);
    }

    @PostMapping("/consignments/{id}/withdraw")
    public ConsignmentResponse withdraw(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id) {
        return service.withdraw(me.id(), id);
    }

    @Operation(summary = "Chấp nhận / đề nghị giá sàn khác / rút sách sau kiểm định")
    @PostMapping("/consignments/{id}/decision")
    public ConsignmentResponse decision(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id,
                                        @Valid @RequestBody SellerDecisionRequest req) {
        return service.sellerDecision(me.id(), id, req);
    }

    @Operation(summary = "Lô không bán được: RELIST | CONVERT_TO_LISTING | RETURN")
    @PostMapping("/consignments/{id}/unsold-decision")
    public ConsignmentResponse unsoldDecision(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id,
                                              @Valid @RequestBody UnsoldDecisionRequest req) {
        return service.unsoldDecision(me.id(), id, req);
    }

    // ---- Staff ----

    @Operation(summary = "[Staff] Danh sách yêu cầu ký gửi")
    @GetMapping("/staff/consignments")
    public PageResponse<ConsignmentResponse> search(@RequestParam(required = false) ConsignmentStatus status,
                                                    @RequestParam(defaultValue = "0") int page,
                                                    @RequestParam(defaultValue = "20") int size) {
        return service.search(status, page, size);
    }

    @Operation(summary = "[Staff] Lịch hẹn nhận sách (mặc định 7 ngày tới)")
    @GetMapping("/staff/appointments")
    public List<ConsignmentResponse> appointments(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant to) {
        Instant f = from == null ? Instant.now().minus(Duration.ofDays(1)) : from;
        return service.appointments(f, to == null ? f.plus(Duration.ofDays(8)) : to);
    }

    @Operation(summary = "[Staff] Tra lịch hẹn theo mã QR")
    @GetMapping("/staff/appointments/{code}")
    public ConsignmentResponse byCode(@PathVariable String code) {
        return service.byAppointmentCode(code);
    }

    @Operation(summary = "[Staff] Sơ duyệt online")
    @PostMapping("/staff/consignments/{id}/review")
    public ConsignmentResponse review(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id,
                                      @Valid @RequestBody ReviewRequest req) {
        return service.review(me.id(), id, req.approve(), req.note());
    }

    @Operation(summary = "[Staff] Nhận sách tại kho, tạo phiếu nhập kho")
    @PostMapping("/staff/consignments/{id}/check-in")
    public ConsignmentResponse checkIn(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id,
                                       @Valid @RequestBody CheckInRequest req) {
        return service.checkIn(me.id(), id, req);
    }

    @Operation(summary = "[Staff] Phiếu kiểm định + đề xuất giá")
    @PostMapping("/staff/consignments/{id}/inspection")
    public ConsignmentResponse inspect(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id,
                                       @Valid @RequestBody InspectionRequest req) {
        return service.inspect(me.id(), id, req);
    }

    @Operation(summary = "[Staff] Sách trong kho")
    @GetMapping("/staff/warehouse")
    public PageResponse<WarehouseResponse> warehouse(@RequestParam(required = false) WarehouseItem.Status status,
                                                     @RequestParam(defaultValue = "0") int page,
                                                     @RequestParam(defaultValue = "20") int size) {
        return service.warehouse(status, page, size);
    }

    @Operation(summary = "[Staff] Cập nhật vị trí kệ")
    @PutMapping("/staff/warehouse/{id}")
    public WarehouseResponse shelf(@PathVariable Long id, @Valid @RequestBody ShelfRequest req) {
        return service.updateShelf(id, req.shelfCode());
    }

    @Operation(summary = "[Staff] Xuất kho trả sách cho người bán (thu phí lưu kho nếu quá hạn)")
    @PostMapping("/staff/warehouse/{id}/return")
    public WarehouseResponse returnToSeller(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id) {
        return service.returnToSeller(me.id(), id);
    }
}
