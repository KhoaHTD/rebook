package com.rebook.common;

import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/** Đếm số lần theo khoá trong một khoảng thời gian. Giữ trong bộ nhớ, đủ cho backend chạy một instance. */
@Component
public class RateLimiter {

    private static final int CLEANUP_ABOVE = 10_000;

    private record Window(int count, Instant resetAt) {
    }

    private final Map<String, Window> windows = new ConcurrentHashMap<>();

    /** Tăng bộ đếm, trả về số lần trong khoảng hiện tại. */
    public int hit(String key, Duration window) {
        Instant now = Instant.now();
        if (windows.size() > CLEANUP_ABOVE) {
            windows.values().removeIf(w -> !w.resetAt().isAfter(now));
        }
        return windows.compute(key, (k, w) -> w == null || !w.resetAt().isAfter(now)
                ? new Window(1, now.plus(window))
                : new Window(w.count() + 1, w.resetAt())).count();
    }

    /** Số lần trong khoảng hiện tại, không tăng bộ đếm. */
    public int count(String key) {
        Window w = windows.get(key);
        return w == null || !w.resetAt().isAfter(Instant.now()) ? 0 : w.count();
    }

    public void reset(String key) {
        windows.remove(key);
    }
}
