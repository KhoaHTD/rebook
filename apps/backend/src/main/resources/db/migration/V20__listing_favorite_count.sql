-- Số lượt yêu thích của tin đăng, lưu sẵn để sắp xếp "phổ biến" (sort=popular) mà không phải đếm mỗi lần.
-- ListingService.setFavorite giữ số này khớp với bảng listing_favorites.
ALTER TABLE listings ADD COLUMN favorite_count INT NOT NULL DEFAULT 0 CHECK (favorite_count >= 0);

UPDATE listings l
   SET favorite_count = (SELECT count(*) FROM listing_favorites f WHERE f.listing_id = l.id);

CREATE INDEX idx_listings_popular ON listings (favorite_count DESC, sold_count DESC);
