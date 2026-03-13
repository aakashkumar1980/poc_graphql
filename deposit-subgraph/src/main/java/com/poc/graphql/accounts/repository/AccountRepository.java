package com.poc.graphql.accounts.repository;

import com.poc.graphql.accounts.entity.Account;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AccountRepository extends JpaRepository<Account, String> {
}
