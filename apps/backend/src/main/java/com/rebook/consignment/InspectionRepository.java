package com.rebook.consignment;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface InspectionRepository extends JpaRepository<Inspection, Long> {

    Optional<Inspection> findByConsignmentId(Long consignmentId);
}
