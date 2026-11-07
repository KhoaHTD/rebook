-- Hàm unaccent (tìm kiếm không dấu, V18) phải nằm ở schema public: code gọi unaccent(...) không ghi schema.
-- Extension chỉ cài được MỘT lần cho mỗi database. Test backend chạy trên cùng database (schema rebook_test...);
-- nếu test chạy trước thì V18 gặp "IF NOT EXISTS" và bỏ qua, extension nằm ở schema test và tìm kiếm của app
-- báo lỗi 500 "function unaccent(character varying) does not exist". Đưa nó về public.
DO $$
DECLARE
    current_schema_name text;
BEGIN
    SELECT n.nspname INTO current_schema_name
    FROM pg_extension e JOIN pg_namespace n ON n.oid = e.extnamespace
    WHERE e.extname = 'unaccent';

    IF current_schema_name IS NULL THEN
        CREATE EXTENSION unaccent SCHEMA public;
    ELSIF current_schema_name <> 'public' THEN
        BEGIN
            ALTER EXTENSION unaccent SET SCHEMA public;
        EXCEPTION WHEN insufficient_privilege THEN
            -- Extension "trusted" do user thường cài: user đứng tên extension nhưng các hàm thuộc superuser, nên
            -- không chuyển schema được. Chủ extension vẫn xoá và cài lại được (không CASCADE: có gì phụ thuộc thì thôi).
            BEGIN
                DROP EXTENSION unaccent;
                CREATE EXTENSION unaccent SCHEMA public;
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Không đưa được extension unaccent từ schema % về public: %. Chạy bằng tài khoản chủ DB: DROP EXTENSION unaccent; CREATE EXTENSION unaccent SCHEMA public;', current_schema_name, SQLERRM;
            END;
        END;
    END IF;
END $$;
