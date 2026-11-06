-- Hạn người bán quyết định sau kiểm định, thanh lý sách vô chủ, báo kho quá hạn xử lý hoá đơn đấu giá
-- (docs/DANH_GIA_BA_TESTER_2026-11-06.md mục 11, 12, 13).
INSERT INTO system_configs (key, value, description) VALUES
    ('consignment.seller_decision_days', '7',  'Kiểm định đạt mà người bán không chấp nhận hay rút sau bấy nhiêu ngày thì coi như rút'),
    ('warehouse.abandon_days',           '60', 'Sách chờ người bán nhận lại quá bấy nhiêu ngày thì sàn thanh lý (nhắc trước 7 ngày)');

ALTER TABLE warehouse_items ADD COLUMN abandon_warned_at TIMESTAMPTZ;
ALTER TABLE orders ADD COLUMN sla_alerted_at TIMESTAMPTZ;
