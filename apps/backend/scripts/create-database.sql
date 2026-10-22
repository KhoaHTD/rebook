-- Tạo user + database cho ReBook (chạy một lần bằng tài khoản superuser postgres):
--   psql -U postgres -h localhost -f scripts/create-database.sql
-- Bảng và dữ liệu mẫu do Flyway tạo tự động khi backend khởi động.
-- Tên DB là rebook_dev (khớp application.yml); đổi bằng biến môi trường DB_URL nếu cần.

CREATE ROLE rebook WITH LOGIN PASSWORD 'rebook';
CREATE DATABASE rebook_dev OWNER rebook ENCODING 'UTF8' TEMPLATE template0;
