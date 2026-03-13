package com.poc.graphql.service;

import com.poc.graphql.accounts.entity.Account;
import com.poc.graphql.accounts.entity.Balance;
import com.poc.graphql.accounts.repository.AccountRepository;
import com.poc.graphql.accounts.repository.BalanceRepository;
import com.poc.graphql.transactions.entity.Transaction;
import com.poc.graphql.transactions.repository.TransactionRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class AccountService {

    private final AccountRepository accountRepository;
    private final BalanceRepository balanceRepository;
    private final TransactionRepository transactionRepository;

    public AccountService(AccountRepository accountRepository,
                          BalanceRepository balanceRepository,
                          TransactionRepository transactionRepository) {
        this.accountRepository = accountRepository;
        this.balanceRepository = balanceRepository;
        this.transactionRepository = transactionRepository;
    }

    public Optional<Account> getAccount(String id) {
        return accountRepository.findById(id);
    }

    public Balance getBalance(String accountId) {
        return balanceRepository.findByAccountId(accountId);
    }

    public List<Transaction> getTransactions(String accountId) {
        return transactionRepository.findByAccountIdOrderByTxnDateDesc(accountId);
    }
}
