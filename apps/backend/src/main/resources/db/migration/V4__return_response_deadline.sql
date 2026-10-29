-- Người bán (hoặc kho) phải trả lời yêu cầu trả hàng trong hạn này, quá hạn thì tự chuyển Admin phân xử.
INSERT INTO system_configs (key, value, description)
VALUES ('order.return_response_days', '2', 'Số ngày người bán phải trả lời yêu cầu trả hàng, quá hạn thì chuyển Admin phân xử')
ON CONFLICT (key) DO NOTHING;
