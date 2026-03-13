package com.poc.graphql.config;

import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.autoconfigure.jdbc.DataSourceProperties;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.orm.jpa.EntityManagerFactoryBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.orm.jpa.JpaTransactionManager;
import org.springframework.orm.jpa.JpaVendorAdapter;
import org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean;
import org.springframework.orm.jpa.vendor.HibernateJpaVendorAdapter;
import org.springframework.transaction.PlatformTransactionManager;

import jakarta.persistence.EntityManagerFactory;
import javax.sql.DataSource;
import java.util.Map;

@Configuration
@EnableJpaRepositories(
        basePackages = "com.poc.graphql.accounts.repository",
        entityManagerFactoryRef = "accountsEntityManagerFactory",
        transactionManagerRef = "accountsTransactionManager"
)
public class AccountsDbConfig {

    @Primary
    @Bean
    @ConfigurationProperties("app.datasource.accounts")
    public DataSourceProperties accountsDataSourceProperties() {
        return new DataSourceProperties();
    }

    @Primary
    @Bean
    public JpaVendorAdapter jpaVendorAdapter() {
        return new HibernateJpaVendorAdapter();
    }

    @Primary
    @Bean
    public EntityManagerFactoryBuilder entityManagerFactoryBuilder(JpaVendorAdapter jpaVendorAdapter) {
        return new EntityManagerFactoryBuilder(jpaVendorAdapter, Map.of(), null);
    }

    @Primary
    @Bean
    public DataSource accountsDataSource() {
        return accountsDataSourceProperties()
                .initializeDataSourceBuilder()
                .build();
    }

    @Primary
    @Bean
    public LocalContainerEntityManagerFactoryBean accountsEntityManagerFactory(
            EntityManagerFactoryBuilder builder) {
        return builder
                .dataSource(accountsDataSource())
                .packages("com.poc.graphql.accounts.entity")
                .persistenceUnit("accounts")
                .properties(Map.of(
                        "hibernate.hbm2ddl.auto", "none",
                        "hibernate.show_sql", "true"
                ))
                .build();
    }

    @Primary
    @Bean
    public PlatformTransactionManager accountsTransactionManager(
            @Qualifier("accountsEntityManagerFactory") EntityManagerFactory emf) {
        return new JpaTransactionManager(emf);
    }
}
