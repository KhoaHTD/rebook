-- Chỉ chạy ở profile dev (db/seed): demo được tạo phiên, công bố và mở ngay, không phải chờ 72 giờ / 24 giờ (BR-5.4).
UPDATE system_configs SET value = '0' WHERE key IN ('auction.min_publish_lead_hours', 'auction.min_registration_close_hours');
