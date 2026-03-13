package com.poc.graphql.repository;

import com.poc.graphql.entity.Hello;
import org.springframework.data.jpa.repository.JpaRepository;

public interface HelloRepository extends JpaRepository<Hello, Long> {
}
