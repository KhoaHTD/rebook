package com.rebook.common;

import java.util.Set;

/**
 * Enum trạng thái cài interface này để khai báo các bước chuyển hợp lệ.
 * Chuyển sai → 409 INVALID_STATUS_TRANSITION.
 */
public interface StatusFlow<E extends Enum<E> & StatusFlow<E>> {

    Set<E> nextStates();

    default E moveTo(E target) {
        if (!nextStates().contains(target)) {
            throw ApiException.conflict("INVALID_STATUS_TRANSITION",
                    "Không thể chuyển trạng thái từ " + this + " sang " + target);
        }
        return target;
    }
}
