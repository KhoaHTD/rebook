package com.rebook.user;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {

    Optional<User> findByEmailIgnoreCase(String email);

    boolean existsByEmailIgnoreCase(String email);

    boolean existsByPhone(String phone);

    @Query("select u.status from User u where u.id = :id")
    Optional<UserStatus> findStatusById(@Param("id") Long id);

    /** Trạng thái + vai trò hiện tại trong DB (JWT chỉ dùng để nhận diện, quyền luôn lấy từ DB). */
    @Query("select u.status as status, u.role as role from User u where u.id = :id")
    Optional<StatusRole> findStatusRoleById(@Param("id") Long id);

    interface StatusRole {
        UserStatus getStatus();

        Role getRole();
    }

    @Query("""
            select u from User u
            where (:q = '' or lower(u.email) like lower(concat('%', :q, '%'))
                   or lower(u.fullName) like lower(concat('%', :q, '%')))
              and (:role is null or u.role = :role)
              and (:status is null or u.status = :status)
            """)
    Page<User> search(@Param("q") String q, @Param("role") Role role, @Param("status") UserStatus status, Pageable pageable);
}
