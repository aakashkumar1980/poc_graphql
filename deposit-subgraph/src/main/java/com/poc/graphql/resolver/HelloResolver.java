package com.poc.graphql.resolver;

import com.poc.graphql.repository.HelloRepository;
import org.springframework.graphql.data.method.annotation.QueryMapping;
import org.springframework.stereotype.Controller;

@Controller
public class HelloResolver {

    private final HelloRepository helloRepository;

    public HelloResolver(HelloRepository helloRepository) {
        this.helloRepository = helloRepository;
    }

    @QueryMapping
    public String hello() {
        return helloRepository.findAll()
                .stream()
                .findFirst()
                .map(h -> h.getMessage())
                .orElse("No message found");
    }
}
