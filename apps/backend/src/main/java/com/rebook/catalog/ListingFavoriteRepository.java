package com.rebook.catalog;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ListingFavoriteRepository extends JpaRepository<ListingFavorite, ListingFavorite.Key> {

    List<ListingFavorite> findByUserIdOrderByCreatedAtDesc(Long userId);
}
