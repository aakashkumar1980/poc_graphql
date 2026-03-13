package com.poc.graphql.resolver;

import com.poc.graphql.accounts.entity.Account;
import com.poc.graphql.accounts.entity.Balance;
import com.poc.graphql.service.AccountService;
import com.poc.graphql.transactions.entity.Transaction;
import org.springframework.graphql.data.method.annotation.Argument;
import org.springframework.graphql.data.method.annotation.QueryMapping;
import org.springframework.graphql.data.method.annotation.SchemaMapping;
import org.springframework.stereotype.Controller;

import java.util.List;

@Controller
public class AccountResolver {

    private final AccountService accountService;

    public AccountResolver(AccountService accountService) {
        this.accountService = accountService;
    }

    @QueryMapping
    public Account getAccount(@Argument String id) {
        return accountService.getAccount(id).orElse(null);
    }

    @SchemaMapping(typeName = "Account", field = "balance")
    public Balance balance(Account account) {
        return accountService.getBalance(account.getId());
    }

    @SchemaMapping(typeName = "Account", field = "transactions")
    public List<Transaction> transactions(Account account) {
        return accountService.getTransactions(account.getId());
    }
}
