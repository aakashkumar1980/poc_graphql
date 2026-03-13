package com.poc.graphql.transactions.repository;

import com.poc.graphql.transactions.entity.Transaction;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface TransactionRepository extends JpaRepository<Transaction, String> {
    List<Transaction> findByAccountIdOrderByTxnDateDesc(String accountId);
}
