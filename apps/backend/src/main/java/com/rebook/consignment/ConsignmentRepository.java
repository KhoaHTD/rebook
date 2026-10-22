package com.rebook.consignment;

import jakarta.persistence.LockModeType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

public interface ConsignmentRepository extends JpaRepository<Consignment, Long> {

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select c from Consignment c where c.id = :id")
    Optional<Consignment> lockById(@Param("id") Long id);

    Optional<Consignment> findByAppointmentCode(String appointmentCode);

    List<Consignment> findBySellerIdOrderByIdDesc(Long sellerId);

    @Query("""
            select c from Consignment c where (:status is null or c.status = :status) order by c.updatedAt desc
            """)
    Page<Consignment> search(@Param("status") ConsignmentStatus status, Pageable pageable);

    /** Lịch hẹn trong khoảng thời gian (màn "Lịch hẹn" của Staff). */
    @Query("""
            select c from Consignment c where c.status = com.rebook.consignment.ConsignmentStatus.APPOINTMENT_BOOKED
              and c.appointmentAt between :from and :to order by c.appointmentAt
            """)
    List<Consignment> appointmentsBetween(@Param("from") Instant from, @Param("to") Instant to);

    @Query("""
            select c.id from Consignment c
            where c.status in (com.rebook.consignment.ConsignmentStatus.APPROVED, com.rebook.consignment.ConsignmentStatus.APPOINTMENT_BOOKED)
              and c.approvedAt < :approvedBefore
              and (c.appointmentAt is null or c.appointmentAt < :now)
            """)
    List<Long> findExpiredAppointments(@Param("approvedBefore") Instant approvedBefore, @Param("now") Instant now);
}
