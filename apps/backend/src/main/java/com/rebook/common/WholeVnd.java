package com.rebook.common;

import jakarta.validation.Constraint;
import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;
import jakarta.validation.Payload;

import java.lang.annotation.Documented;
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;
import java.math.BigDecimal;

/**
 * Số tiền VNĐ phải là số nguyên (cột NUMERIC(15,0)): {@code 50000} và {@code 50000.0} được nhận, {@code 50000.4} thì không;
 * tối đa 15 chữ số để không tràn cột. Giá trị null do {@code @NotNull} xử lý.
 */
@Documented
@Constraint(validatedBy = WholeVnd.Validator.class)
@Target({ElementType.FIELD, ElementType.PARAMETER, ElementType.RECORD_COMPONENT})
@Retention(RetentionPolicy.RUNTIME)
public @interface WholeVnd {

    String message() default "Số tiền phải là số nguyên đồng, tối đa 15 chữ số";

    Class<?>[] groups() default {};

    Class<? extends Payload>[] payload() default {};

    class Validator implements ConstraintValidator<WholeVnd, BigDecimal> {
        @Override
        public boolean isValid(BigDecimal value, ConstraintValidatorContext context) {
            if (value == null) {
                return true;
            }
            BigDecimal v = value.stripTrailingZeros();
            return v.scale() <= 0 && v.precision() - v.scale() <= 15;
        }
    }
}
