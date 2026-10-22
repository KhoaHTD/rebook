package com.rebook.order;

import com.rebook.catalog.Listing;
import com.rebook.catalog.ListingRepository;
import com.rebook.catalog.ListingStatus;
import com.rebook.common.ApiException;
import com.rebook.order.OrderDtos.CartLine;
import com.rebook.order.OrderDtos.CartResponse;
import com.rebook.order.OrderDtos.CartShopGroup;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

/** Giỏ hàng có thể chứa sách của nhiều shop. */
@Service
@RequiredArgsConstructor
public class CartService {

    private final CartItemRepository cartRepository;
    private final ListingRepository listingRepository;

    @Transactional(readOnly = true)
    public CartResponse get(Long userId) {
        List<CartItem> items = cartRepository.findByUserIdOrderByIdDesc(userId);
        Map<Long, Listing> listings = listingRepository.findAllById(items.stream().map(CartItem::getListingId).toList())
                .stream().collect(Collectors.toMap(Listing::getId, Function.identity()));

        Map<Long, List<CartLine>> lines = new LinkedHashMap<>();
        Map<Long, Listing> shopSample = new LinkedHashMap<>();
        for (CartItem item : items) {
            Listing l = listings.get(item.getListingId());
            if (l == null) {
                continue;
            }
            boolean available = l.getStatus() == ListingStatus.ACTIVE && l.getStock() >= item.getQuantity();
            lines.computeIfAbsent(l.getShop().getId(), k -> new ArrayList<>()).add(new CartLine(
                    l.getId(), l.getBook().getTitle(), l.getBook().getAuthor(), l.getBook().coverUrl(), l.getPrice(),
                    item.getQuantity(), l.getStock(), available,
                    l.getPrice().multiply(BigDecimal.valueOf(item.getQuantity()))));
            shopSample.putIfAbsent(l.getShop().getId(), l);
        }

        List<CartShopGroup> groups = new ArrayList<>();
        BigDecimal total = BigDecimal.ZERO;
        int qty = 0;
        for (var e : lines.entrySet()) {
            var shop = shopSample.get(e.getKey()).getShop();
            BigDecimal sub = e.getValue().stream().filter(CartLine::available)
                    .map(CartLine::lineTotal).reduce(BigDecimal.ZERO, BigDecimal::add);
            groups.add(new CartShopGroup(shop.getId(), shop.getName(), shop.getPickupProvince(), e.getValue(), sub));
            total = total.add(sub);
            qty += e.getValue().stream().mapToInt(CartLine::quantity).sum();
        }
        return new CartResponse(groups, qty, total);
    }

    @Transactional
    public CartResponse add(Long userId, Long listingId, int quantity) {
        Listing l = listingRepository.findById(listingId).orElseThrow(() -> ApiException.notFound("tin đăng"));
        if (l.getStatus() != ListingStatus.ACTIVE) {
            throw ApiException.conflict("LISTING_NOT_AVAILABLE", "Sách này hiện không bán");
        }
        if (l.getShop().getUserId().equals(userId)) {
            throw ApiException.badRequest("OWN_LISTING", "Không thể mua sách của chính shop mình");
        }
        CartItem item = cartRepository.findByUserIdAndListingId(userId, listingId).orElseGet(() -> {
            CartItem c = new CartItem();
            c.setUserId(userId);
            c.setListingId(listingId);
            return c;
        });
        int newQty = item.getQuantity() + quantity;
        if (newQty > l.getStock()) {
            throw ApiException.conflict("OUT_OF_STOCK", "Chỉ còn " + l.getStock() + " cuốn");
        }
        item.setQuantity(newQty);
        cartRepository.save(item);
        return get(userId);
    }

    @Transactional
    public CartResponse update(Long userId, Long listingId, int quantity) {
        CartItem item = cartRepository.findByUserIdAndListingId(userId, listingId)
                .orElseThrow(() -> ApiException.notFound("sách trong giỏ"));
        Listing l = listingRepository.findById(listingId).orElseThrow(() -> ApiException.notFound("tin đăng"));
        if (quantity > l.getStock()) {
            throw ApiException.conflict("OUT_OF_STOCK", "Chỉ còn " + l.getStock() + " cuốn");
        }
        item.setQuantity(quantity);
        return get(userId);
    }

    @Transactional
    public CartResponse remove(Long userId, Long listingId) {
        cartRepository.findByUserIdAndListingId(userId, listingId).ifPresent(cartRepository::delete);
        return get(userId);
    }

    @Transactional
    public void clear(Long userId) {
        cartRepository.deleteByUserId(userId);
    }
}
