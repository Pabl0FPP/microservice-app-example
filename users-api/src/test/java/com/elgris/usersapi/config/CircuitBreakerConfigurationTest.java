package com.elgris.usersapi.config;

import io.github.resilience4j.circuitbreaker.CircuitBreaker;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.junit4.SpringRunner;

import static org.junit.Assert.*;

@RunWith(SpringRunner.class)
@SpringBootTest
public class CircuitBreakerConfigurationTest {

    @Autowired
    private CircuitBreaker databaseCircuitBreaker;

    @Test
    public void testCircuitBreakerConfiguration() {
        // Verificar que el Circuit Breaker se creó correctamente
        assertNotNull(databaseCircuitBreaker);
        assertEquals("database", databaseCircuitBreaker.getName());
        assertEquals(CircuitBreaker.State.CLOSED, databaseCircuitBreaker.getState());
        
        // Verificar configuración
        CircuitBreaker.Metrics metrics = databaseCircuitBreaker.getMetrics();
        assertNotNull(metrics);
        assertEquals(0, metrics.getNumberOfSuccessfulCalls());
    }
    
    @Test
    public void testCircuitBreakerInitialState() {
        // Verificar estado inicial
        assertEquals(CircuitBreaker.State.CLOSED, databaseCircuitBreaker.getState());
        
        // Verificar que las métricas iniciales son correctas
        CircuitBreaker.Metrics metrics = databaseCircuitBreaker.getMetrics();
        // ✅ CORREGIDO: failureRate inicial puede ser -1.0 cuando no hay llamadas
        assertEquals(-1.0F, metrics.getFailureRate(), 0.01F); // -1.0 significa "no hay datos suficientes"
        assertEquals(0, metrics.getNumberOfFailedCalls());
        assertEquals(0, metrics.getNumberOfSuccessfulCalls());
    }
}