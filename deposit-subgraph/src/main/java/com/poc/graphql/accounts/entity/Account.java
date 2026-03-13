package com.poc.graphql.accounts.entity;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.LocalDateTime;

@Entity
@Table(name = "accounts")
public class Account {

    @Id
    private String id;
    private String customerId;
    private String accountNumber;
    private String status;
    private LocalDateTime createdAt;

    public String getId() { return id; }
    public String getCustomerId() { return customerId; }
    public String getAccountNumber() { return accountNumber; }
    public String getStatus() { return status; }
    public LocalDateTime getCreatedAt() { return createdAt; }
}
