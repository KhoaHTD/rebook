package com.rebook.auction;

import com.rebook.auction.AuctionDtos.AddDepositRequest;
import com.rebook.auction.AuctionDtos.AssignLotsRequest;
import com.rebook.auction.AuctionDtos.BidRequest;
import com.rebook.auction.AuctionDtos.BidResponse;
import com.rebook.auction.AuctionDtos.DeliveryOptionRequest;
import com.rebook.auction.AuctionDtos.LotDetail;
import com.rebook.auction.AuctionDtos.LotPublic;
import com.rebook.auction.AuctionDtos.LotResult;
import com.rebook.auction.AuctionDtos.ProxyBidRequest;
import com.rebook.auction.AuctionDtos.RegisterRequest;
import com.rebook.auction.AuctionDtos.RegistrationResponse;
import com.rebook.auction.AuctionDtos.SessionDetail;
import com.rebook.auction.AuctionDtos.SessionRequest;
import com.rebook.auction.AuctionDtos.SessionState;
import com.rebook.auction.AuctionDtos.SessionSummary;
import com.rebook.common.PageResponse;
import com.rebook.order.OrderDtos.CancelRequest;
import com.rebook.order.OrderDtos.OrderDetail;
import com.rebook.security.UserPrincipal;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@Tag(name = "Auction")
@RestController
@RequiredArgsConstructor
public class AuctionController {

    private final AuctionService auctionService;
    private final AuctionAdminService adminService;
    private final AuctionRunner runner;
    private final BidService bidService;
    private final AuctionSettlement settlement;

    // =====================================================================
    // Công khai (Guest xem được)
    // =====================================================================

    @Operation(summary = "Lịch phiên đấu giá")
    @GetMapping("/sessions")
    public PageResponse<SessionSummary> sessions(@RequestParam(required = false) SessionStatus status,
                                                 @RequestParam(defaultValue = "0") int page,
                                                 @RequestParam(defaultValue = "20") int size) {
        return auctionService.sessions(status, page, size);
    }

    @Operation(summary = "Catalogue phiên: danh sách lô, ảnh, giá ước tính")
    @GetMapping("/sessions/{id}")
    public SessionDetail session(@PathVariable Long id, @AuthenticationPrincipal UserPrincipal me) {
        return auctionService.session(id, me == null ? null : me.id());
    }

    @Operation(summary = "Ảnh chụp trạng thái phòng đấu giá (gọi khi vào phòng / kết nối lại WebSocket)",
            description = "Sau đó nghe ws://<host>/ws/sessions/{id} để nhận LOT_OPENED, BID_PLACED, LOT_CLOSED, SESSION_*")
    @GetMapping("/sessions/{id}/state")
    public SessionState state(@PathVariable Long id, @AuthenticationPrincipal UserPrincipal me) {
        return auctionService.state(id, me == null ? null : me.id());
    }

    @Operation(summary = "Bảng kết quả phiên (số bài + giá)")
    @GetMapping("/sessions/{id}/results")
    public List<LotResult> results(@PathVariable Long id) {
        return auctionService.results(id);
    }

    @Operation(summary = "Chi tiết lô + báo cáo tình trạng")
    @GetMapping("/lots/{id}")
    public LotDetail lot(@PathVariable Long id, @AuthenticationPrincipal UserPrincipal me) {
        return auctionService.lot(id, me == null ? null : me.id());
    }

    // =====================================================================
    // Người mua
    // =====================================================================

    @Operation(summary = "Đăng ký tham gia + đặt cọc (khoá tiền trong ví), nhận số bài")
    @PostMapping("/sessions/{id}/register")
    @ResponseStatus(HttpStatus.CREATED)
    public RegistrationResponse register(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id,
                                         @RequestBody RegisterRequest req) {
        return auctionService.register(me.id(), id, req.agreeRules());
    }

    @Operation(summary = "Cọc thêm để nâng hạn mức trả giá")
    @PostMapping("/sessions/{id}/deposit")
    public RegistrationResponse addDeposit(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id,
                                           @Valid @RequestBody AddDepositRequest req) {
        return auctionService.addDeposit(me.id(), id, req.amount());
    }

    @GetMapping("/me/registrations")
    public List<RegistrationResponse> myRegistrations(@AuthenticationPrincipal UserPrincipal me) {
        return auctionService.myRegistrations(me.id());
    }

    @Operation(summary = "Trả giá. 409 PRICE_CHANGED nếu người khác vừa trả trước")
    @PostMapping("/lots/{id}/bids")
    public BidResponse bid(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id, @Valid @RequestBody BidRequest req) {
        return bidService.placeBid(me.id(), id, req.amount());
    }

    @Operation(summary = "Đặt giá tối đa tự động (proxy bid) — đặt trước khi lô mở cũng được")
    @PutMapping("/lots/{id}/proxy-bid")
    public Map<String, BigDecimal> proxy(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id,
                                         @Valid @RequestBody ProxyBidRequest req) {
        return Map.of("maxAmount", bidService.setProxy(me.id(), id, req.maxAmount()));
    }

    @DeleteMapping("/lots/{id}/proxy-bid")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void cancelProxy(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id) {
        bidService.cancelProxy(me.id(), id);
    }

    @Operation(summary = "Theo dõi lô (nhận nhắc trước phiên)")
    @PostMapping("/lots/{id}/watch")
    public Map<String, Boolean> watch(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id) {
        return Map.of("watching", auctionService.watch(me.id(), id, true));
    }

    @DeleteMapping("/lots/{id}/watch")
    public Map<String, Boolean> unwatch(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id) {
        return Map.of("watching", auctionService.watch(me.id(), id, false));
    }

    @GetMapping("/me/watching")
    public List<LotPublic> watching(@AuthenticationPrincipal UserPrincipal me) {
        return auctionService.watchedLots(me.id());
    }

    @Operation(summary = "Hoá đơn lô thắng: giao tận nơi hoặc nhận tại kho")
    @PostMapping("/orders/{id}/delivery-option")
    public OrderDetail deliveryOption(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id,
                                      @RequestBody DeliveryOptionRequest req) {
        return settlement.updateDelivery(me.id(), id, req.addressId(), req.pickupAtWarehouse());
    }

    @Operation(summary = "Từ chối lời mời mua lần hai (second chance offer)")
    @PostMapping("/orders/{id}/decline-second-chance")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void declineSecondChance(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id) {
        settlement.declineSecondChance(me.id(), id);
    }

    // =====================================================================
    // Admin: tạo phiên, xếp lô, công bố
    // =====================================================================

    @GetMapping("/admin/sessions")
    public PageResponse<SessionSummary> allSessions(@RequestParam(defaultValue = "0") int page,
                                                    @RequestParam(defaultValue = "20") int size) {
        return adminService.all(page, size);
    }

    @GetMapping("/admin/sessions/{id}")
    public SessionDetail adminSession(@PathVariable Long id) {
        return adminService.detail(id);
    }

    @Operation(summary = "[Admin] Lô chờ xếp phiên")
    @GetMapping("/admin/lots/ready")
    public PageResponse<LotPublic> readyLots(@RequestParam(defaultValue = "0") int page,
                                             @RequestParam(defaultValue = "50") int size) {
        return adminService.readyLots(page, size);
    }

    @PostMapping("/admin/sessions")
    @ResponseStatus(HttpStatus.CREATED)
    public SessionSummary create(@AuthenticationPrincipal UserPrincipal me, @Valid @RequestBody SessionRequest req) {
        return adminService.create(me.id(), req);
    }

    @PutMapping("/admin/sessions/{id}")
    public SessionSummary update(@PathVariable Long id, @Valid @RequestBody SessionRequest req) {
        return adminService.update(id, req);
    }

    @Operation(summary = "[Admin] Xếp lô vào phiên theo thứ tự chạy")
    @PutMapping("/admin/sessions/{id}/lots")
    public SessionDetail assignLots(@PathVariable Long id, @Valid @RequestBody AssignLotsRequest req) {
        return adminService.assignLots(id, req.lotIds());
    }

    @Operation(summary = "[Admin] Công bố catalogue, mở đăng ký")
    @PostMapping("/admin/sessions/{id}/publish")
    public SessionSummary publish(@PathVariable Long id) {
        return adminService.publish(id);
    }

    @Operation(summary = "[Admin] Mở phiên ngay (demo) — phiên tự mở đúng giờ nên bình thường không cần")
    @PostMapping("/admin/sessions/{id}/start")
    public SessionSummary startNow(@PathVariable Long id) {
        return summaryOf(runner.startNow(id));
    }

    @PostMapping("/admin/sessions/{id}/cancel")
    public SessionSummary cancel(@PathVariable Long id, @Valid @RequestBody CancelRequest req) {
        return summaryOf(runner.cancelSession(id, req.reason()));
    }

    // =====================================================================
    // Staff: giám sát phiên tự động, can thiệp khi có sự cố
    // =====================================================================

    @Operation(summary = "[Staff] Tạm dừng phiên")
    @PostMapping("/staff/sessions/{id}/pause")
    public SessionSummary pause(@PathVariable Long id) {
        return summaryOf(runner.pause(id));
    }

    @Operation(summary = "[Staff] Tiếp tục phiên")
    @PostMapping("/staff/sessions/{id}/resume")
    public SessionSummary resume(@PathVariable Long id) {
        return summaryOf(runner.resume(id));
    }

    @Operation(summary = "[Staff] Huỷ một lô khi có sự cố")
    @PostMapping("/staff/lots/{id}/cancel")
    public Map<String, Object> cancelLot(@PathVariable Long id, @Valid @RequestBody CancelRequest req) {
        Lot lot = runner.cancelLot(id, req.reason());
        return Map.of("lotId", lot.getId(), "status", lot.getStatus());
    }

    private SessionSummary summaryOf(AuctionSession s) {
        return adminService.detail(s.getId()).session();
    }
}
