package com.rebook.audit;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ActivityLogRepository extends JpaRepository<ActivityLog, Long> {

    @Query("""
            select l from ActivityLog l
            where (:targetType is null or l.targetType = :targetType)
              and (:action is null or l.action = :action)
              and (:adminId is null or l.adminId = :adminId)
            order by l.id desc
            """)
    Page<ActivityLog> search(@Param("targetType") String targetType, @Param("action") String action,
                             @Param("adminId") Long adminId, Pageable pageable);
}
