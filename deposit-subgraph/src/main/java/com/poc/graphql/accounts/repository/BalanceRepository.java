package com.poc.graphql.accounts.repository;

import com.poc.graphql.accounts.entity.Balance;
import org.springframework.data.jpa.repository.JpaRepository;

public interface BalanceRepository extends JpaRepository<Balance, String> {
    Balance findByAccountId(String accountId);
}
