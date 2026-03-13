package com.poc.graphql.accounts.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "balances")
public class Balance {

    @Id
    private String id;
    private String accountId;
    private BigDecimal available;

    @Column(name = "current_bal")
    private BigDecimal current;

    private String currency;
    private LocalDateTime updatedAt;

    public String getId() { return id; }
    public String getAccountId() { return accountId; }
    public BigDecimal getAvailable() { return available; }
    public BigDecimal getCurrent() { return current; }
    public String getCurrency() { return currency; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}
