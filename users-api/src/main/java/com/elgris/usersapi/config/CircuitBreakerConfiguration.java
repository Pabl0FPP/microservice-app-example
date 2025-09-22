package com.elgris.usersapi.config;

import io.github.resilience4j.circuitbreaker.CircuitBreaker;
import io.github.resilience4j.circuitbreaker.CircuitBreakerConfig;
import io.github.resilience4j.circuitbreaker.CircuitBreakerRegistry;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.time.Duration;

@Configuration
public class CircuitBreakerConfiguration {

    /**
     * Configuración personalizada del Circuit Breaker para operaciones de base de datos
     */
    @Bean
    public CircuitBreakerConfig databaseCircuitBreakerConfig() {
        return CircuitBreakerConfig.custom()
                .failureRateThreshold(50)                    // 50% de fallos para abrir
                .waitDurationInOpenState(Duration.ofSeconds(30))  // 30 segundos abierto
                .slidingWindowSize(10)                       // Ventana de 10 requests
                .minimumNumberOfCalls(5)                     // Mínimo 5 calls para evaluar
                .slowCallRateThreshold(50)                   // 50% de calls lentas
                .slowCallDurationThreshold(Duration.ofSeconds(2)) // >2s es lenta
                .permittedNumberOfCallsInHalfOpenState(3)    // 3 calls en half-open
                .automaticTransitionFromOpenToHalfOpenEnabled(true)
                .build();
    }

    /**
     * Configuración para operaciones externas (APIs externas)
     */
    @Bean
    public CircuitBreakerConfig externalApiCircuitBreakerConfig() {
        return CircuitBreakerConfig.custom()
                .failureRateThreshold(60)                    // 60% de fallos (más tolerante)
                .waitDurationInOpenState(Duration.ofSeconds(60))  // 1 minuto abierto
                .slidingWindowSize(5)                        // Ventana más pequeña
                .minimumNumberOfCalls(3)                     // Mínimo 3 calls
                .slowCallRateThreshold(70)                   // 70% de calls lentas
                .slowCallDurationThreshold(Duration.ofSeconds(5)) // >5s es lenta para APIs externas
                .permittedNumberOfCallsInHalfOpenState(2)    // 2 calls en half-open
                .automaticTransitionFromOpenToHalfOpenEnabled(true)
                .build();
    }

    /**
     * Registry de Circuit Breakers
     */
    @Bean
    public CircuitBreakerRegistry circuitBreakerRegistry() {
        return CircuitBreakerRegistry.of(databaseCircuitBreakerConfig());
    }

    /**
     * Circuit Breaker específico para operaciones de base de datos
     */
    @Bean
    public CircuitBreaker databaseCircuitBreaker(CircuitBreakerRegistry registry) {
        CircuitBreaker circuitBreaker = registry.circuitBreaker("database", databaseCircuitBreakerConfig());
        
        // Event listeners para logging
        circuitBreaker.getEventPublisher()
                .onStateTransition(event -> 
                    System.out.printf("[Circuit Breaker] Database CB: %s -> %s%n", 
                        event.getStateTransition().getFromState(), 
                        event.getStateTransition().getToState()));
        
        circuitBreaker.getEventPublisher()
                .onCallNotPermitted(event -> 
                    System.out.println("[Circuit Breaker] Database CB: Call not permitted - Circuit is OPEN"));
        
        circuitBreaker.getEventPublisher()
                .onFailureRateExceeded(event -> 
                    System.out.printf("[Circuit Breaker] Database CB: Failure rate exceeded: %.2f%%%n", 
                        event.getFailureRate()));

        return circuitBreaker;
    }

    /**
     * Circuit Breaker para APIs externas
     */
    @Bean
    public CircuitBreaker externalApiCircuitBreaker(CircuitBreakerRegistry registry) {
        CircuitBreaker circuitBreaker = registry.circuitBreaker("externalApi", externalApiCircuitBreakerConfig());
        
        // Event listeners para logging
        circuitBreaker.getEventPublisher()
                .onStateTransition(event -> 
                    System.out.printf("[Circuit Breaker] External API CB: %s -> %s%n", 
                        event.getStateTransition().getFromState(), 
                        event.getStateTransition().getToState()));

        return circuitBreaker;
    }
}