package com.poc.graphql.transactions.entity;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "transactions")
public class Transaction {

    @Id
    private String id;
    private String accountId;
    private BigDecimal amount;
    private String description;
    private String merchant;
    private LocalDateTime txnDate;

    public String getId() { return id; }
    public String getAccountId() { return accountId; }
    public BigDecimal getAmount() { return amount; }
    public String getDescription() { return description; }
    public String getMerchant() { return merchant; }
    public LocalDateTime getTxnDate() { return txnDate; }
}
