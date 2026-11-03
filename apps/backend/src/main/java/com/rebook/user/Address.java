package com.rebook.user;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.Instant;

@Entity
@Table(name = "addresses")
@Getter
@Setter
@NoArgsConstructor
public class Address {

    /** Loại địa chỉ giao hàng. */
    @Schema(name = "AddressType", enumAsRef = true)
    public enum Type { HOME, OFFICE }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long userId;
    private String receiverName;
    private String phone;
    private String province;
    private String district;
    private String ward;
    private String detail;

    /** Vị trí ghim trên bản đồ (null = chưa ghim). */
    private Double latitude;
    private Double longitude;

    @Enumerated(EnumType.STRING)
    private Type addressType = Type.HOME;

    @Column(name = "is_default")
    private boolean defaultAddress;

    @CreationTimestamp
    private Instant createdAt;

    @UpdateTimestamp
    private Instant updatedAt;
}
