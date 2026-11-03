package com.rebook.auction;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SessionWatcherRepository extends JpaRepository<SessionWatcher, SessionWatcher.Key> {

    List<SessionWatcher> findByUserIdOrderByCreatedAtDesc(Long userId);
}
