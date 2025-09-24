package com.elgris.usersapi.service;

import com.elgris.usersapi.models.User;
import com.elgris.usersapi.models.UserRole;
import com.elgris.usersapi.repository.UserRepository;
import io.github.resilience4j.circuitbreaker.CircuitBreaker;
import io.github.resilience4j.circuitbreaker.CallNotPermittedException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.LinkedList;
import java.util.List;
import java.util.function.Supplier;

@Service
public class UserService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private CircuitBreaker databaseCircuitBreaker;

    /**
     * Obtener todos los usuarios con Circuit Breaker
     */
    public List<User> getAllUsers() {
        Supplier<List<User>> decoratedSupplier = databaseCircuitBreaker
                .decorateSupplier(() -> {
                    System.out.println("[UserService] Fetching all users from database...");
                    List<User> response = new LinkedList<>();
                    userRepository.findAll().forEach(response::add);
                    return response;
                });

        try {
            return decoratedSupplier.get();
        } catch (CallNotPermittedException e) {
            System.out.println("[UserService] Circuit Breaker is OPEN - returning fallback user list");
            return getFallbackUserList();
        } catch (Exception e) {
            System.err.println("[UserService] Error fetching users: " + e.getMessage());
            throw e;
        }
    }

    /**
     * Obtener usuario por username con Circuit Breaker
     */
    public User getUserByUsername(String username) {
        Supplier<User> decoratedSupplier = databaseCircuitBreaker
                .decorateSupplier(() -> {
                    System.out.println("[UserService] Fetching user: " + username + " from database...");
                    return userRepository.findOneByUsername(username);
                });

        try {
            return decoratedSupplier.get();
        } catch (CallNotPermittedException e) {
            System.out.println("[UserService] Circuit Breaker is OPEN - returning fallback user for: " + username);
            return getFallbackUser(username);
        } catch (Exception e) {
            System.err.println("[UserService] Error fetching user " + username + ": " + e.getMessage());
            throw e;
        }
    }

    /**
     * Verificar si existe un usuario con Circuit Breaker
     */
    public boolean userExists(String username) {
        Supplier<Boolean> decoratedSupplier = databaseCircuitBreaker
                .decorateSupplier(() -> {
                    System.out.println("[UserService] Checking if user exists: " + username);
                    return userRepository.findOneByUsername(username) != null;
                });

        try {
            return decoratedSupplier.get();
        } catch (CallNotPermittedException e) {
            System.out.println("[UserService] Circuit Breaker is OPEN - assuming user exists: " + username);
            return true; // Asumir que existe para no bloquear operaciones
        } catch (Exception e) {
            System.err.println("[UserService] Error checking user existence " + username + ": " + e.getMessage());
            return false;
        }
    }

    /**
     * Obtener métricas del Circuit Breaker
     */
    public CircuitBreaker.Metrics getCircuitBreakerMetrics() {
        return databaseCircuitBreaker.getMetrics();
    }

    /**
     * Obtener estado del Circuit Breaker
     */
    public CircuitBreaker.State getCircuitBreakerState() {
        return databaseCircuitBreaker.getState();
    }

    /**
     * Fallback: Lista de usuarios por defecto cuando la BD no está disponible
     */
    private List<User> getFallbackUserList() {
        List<User> fallbackUsers = new LinkedList<>();
        
        // Usuarios por defecto basados en los hash permitidos en Auth API
        User admin = new User();
        admin.setUsername("admin");
        admin.setFirstname("System");
        admin.setLastname("Administrator");
        admin.setRole(UserRole.ADMIN);
        fallbackUsers.add(admin);

        User johnd = new User();
        johnd.setUsername("johnd");
        johnd.setFirstname("John");
        johnd.setLastname("Doe");
        johnd.setRole(UserRole.USER);
        fallbackUsers.add(johnd);

        User janed = new User();
        janed.setUsername("janed");
        janed.setFirstname("Jane");
        janed.setLastname("Doe");
        janed.setRole(UserRole.USER);
        fallbackUsers.add(janed);

        return fallbackUsers;
    }

    /**
     * Fallback: Usuario por defecto cuando la BD no está disponible
     */
    private User getFallbackUser(String username) {
        User fallbackUser = new User();
        fallbackUser.setUsername(username);
        
        // Datos por defecto basados en el username
        switch (username.toLowerCase()) {
            case "admin":
                fallbackUser.setFirstname("System");
                fallbackUser.setLastname("Administrator");
                fallbackUser.setRole(UserRole.ADMIN);
                break;
            case "johnd":
                fallbackUser.setFirstname("John");
                fallbackUser.setLastname("Doe");
                fallbackUser.setRole(UserRole.USER);
                break;
            case "janed":
                fallbackUser.setFirstname("Jane");
                fallbackUser.setLastname("Doe");
                fallbackUser.setRole(UserRole.USER);
                break;
            default:
                fallbackUser.setFirstname("Unknown");
                fallbackUser.setLastname("User");
                fallbackUser.setRole(UserRole.USER);
                break;
        }
        
        return fallbackUser;
    }
}