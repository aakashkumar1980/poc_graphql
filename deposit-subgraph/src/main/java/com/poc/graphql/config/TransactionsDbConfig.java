package com.poc.graphql.config;

import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.autoconfigure.jdbc.DataSourceProperties;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.orm.jpa.EntityManagerFactoryBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.orm.jpa.JpaTransactionManager;
import org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean;
import org.springframework.transaction.PlatformTransactionManager;

import jakarta.persistence.EntityManagerFactory;
import javax.sql.DataSource;
import java.util.Map;

@Configuration
@EnableJpaRepositories(
        basePackages = "com.poc.graphql.transactions.repository",
        entityManagerFactoryRef = "transactionsEntityManagerFactory",
        transactionManagerRef = "transactionsTransactionManager"
)
public class TransactionsDbConfig {

    @Bean
    @ConfigurationProperties("app.datasource.transactions")
    public DataSourceProperties transactionsDataSourceProperties() {
        return new DataSourceProperties();
    }

    @Bean
    public DataSource transactionsDataSource() {
        return transactionsDataSourceProperties()
                .initializeDataSourceBuilder()
                .build();
    }

    @Bean
    public LocalContainerEntityManagerFactoryBean transactionsEntityManagerFactory(
            EntityManagerFactoryBuilder builder) {
        return builder
                .dataSource(transactionsDataSource())
                .packages("com.poc.graphql.transactions.entity")
                .persistenceUnit("transactions")
                .properties(Map.of(
                        "hibernate.hbm2ddl.auto", "none",
                        "hibernate.show_sql", "true",
                        "hibernate.physical_naming_strategy",
                            "org.hibernate.boot.model.naming.CamelCaseToUnderscoresNamingStrategy"
                ))
                .build();
    }

    @Bean
    public PlatformTransactionManager transactionsTransactionManager(
            @Qualifier("transactionsEntityManagerFactory") EntityManagerFactory emf) {
        return new JpaTransactionManager(emf);
    }
}
