package com.rebook.system;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.Instant;

@Entity
@Table(name = "system_configs")
@Getter
@Setter
@NoArgsConstructor
public class SystemConfig {

    @Id
    @Column(name = "key")
    private String key;

    private String value;

    private String description;

    @UpdateTimestamp
    private Instant updatedAt;
}
