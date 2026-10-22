package com.rebook.user;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface ShopRepository extends JpaRepository<Shop, Long> {

    Optional<Shop> findByUserId(Long userId);

    boolean existsByNameIgnoreCase(String name);
}
