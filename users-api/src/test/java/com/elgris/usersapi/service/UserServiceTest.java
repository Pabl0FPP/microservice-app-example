package com.elgris.usersapi.service;

import com.elgris.usersapi.models.User;
import com.elgris.usersapi.models.UserRole;
import com.elgris.usersapi.repository.UserRepository;
import io.github.resilience4j.circuitbreaker.CircuitBreaker;
import io.github.resilience4j.circuitbreaker.CallNotPermittedException;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.runners.MockitoJUnitRunner;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.Arrays;
import java.util.List;
import java.util.function.Supplier;

import static org.junit.Assert.*;
import static org.mockito.Mockito.*;

@RunWith(MockitoJUnitRunner.class)
public class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private CircuitBreaker databaseCircuitBreaker;

    @InjectMocks
    private UserService userService;

    private User testUser;

    @Before
    public void setUp() {
        testUser = new User();
        testUser.setUsername("testuser");
        testUser.setFirstname("Test");
        testUser.setLastname("User");
        testUser.setRole(UserRole.USER);

        // Inyectar el CircuitBreaker mock
        ReflectionTestUtils.setField(userService, "databaseCircuitBreaker", databaseCircuitBreaker);
    }

    @Test
    public void testGetAllUsers_Success() {
        // Arrange
        List<User> expectedUsers = Arrays.asList(testUser);
        when(userRepository.findAll()).thenReturn(expectedUsers);

        // Mock del Circuit Breaker para permitir la llamada
        when(databaseCircuitBreaker.decorateSupplier(any())).thenAnswer(invocation -> {
            return invocation.getArguments()[0];
        });

        // Act
        List<User> actualUsers = userService.getAllUsers();

        // Assert
        assertNotNull(actualUsers);
        assertEquals(1, actualUsers.size());
        assertEquals("testuser", actualUsers.get(0).getUsername());
        verify(userRepository, times(1)).findAll();
    }

    @Test
    public void testGetUserByUsername_Success() {
        // Arrange
        String username = "testuser";
        when(userRepository.findOneByUsername(username)).thenReturn(testUser);

        // Mock del Circuit Breaker para permitir la llamada
        when(databaseCircuitBreaker.decorateSupplier(any())).thenAnswer(invocation -> {
            return invocation.getArguments()[0];
        });

        // Act
        User actualUser = userService.getUserByUsername(username);

        // Assert
        assertNotNull(actualUser);
        assertEquals(username, actualUser.getUsername());
        verify(userRepository, times(1)).findOneByUsername(username);
    }

    @Test
    public void testGetUserByUsername_CircuitBreakerOpen_ReturnsFallback() {
        // Arrange
        String username = "testuser";

        // Mock del Circuit Breaker para simular estado abierto
        // Cuando se decora el supplier, devolver uno que tire la excepción
        when(databaseCircuitBreaker.decorateSupplier(any())).thenAnswer(invocation -> {
            return (Supplier<Object>) () -> {
                throw CallNotPermittedException.createCallNotPermittedException(databaseCircuitBreaker);
            };
        });

        // Act
        User actualUser = userService.getUserByUsername(username);

        // Assert
        assertNotNull(actualUser);
        assertEquals(username, actualUser.getUsername());
        assertEquals("Unknown", actualUser.getFirstname());
        assertEquals("User", actualUser.getLastname());
        assertEquals(UserRole.USER, actualUser.getRole());
        
        // Verificar que NO se llamó al repositorio
        verify(userRepository, never()).findOneByUsername(username);
    }

    @Test
    public void testGetUserByUsername_KnownUser_ReturnsFallback() {
        // Arrange
        String username = "admin";

        // Mock del Circuit Breaker para simular estado abierto
        when(databaseCircuitBreaker.decorateSupplier(any())).thenAnswer(invocation -> {
            return (Supplier<Object>) () -> {
                throw CallNotPermittedException.createCallNotPermittedException(databaseCircuitBreaker);
            };
        });

        // Act
        User actualUser = userService.getUserByUsername(username);

        // Assert
        assertNotNull(actualUser);
        assertEquals("admin", actualUser.getUsername());
        assertEquals("System", actualUser.getFirstname());
        assertEquals("Administrator", actualUser.getLastname());
        assertEquals(UserRole.ADMIN, actualUser.getRole());
    }

    @Test
    public void testUserExists_Success() {
        // Arrange
        String username = "testuser";
        when(userRepository.findOneByUsername(username)).thenReturn(testUser);

        // Mock del Circuit Breaker para permitir la llamada
        when(databaseCircuitBreaker.decorateSupplier(any())).thenAnswer(invocation -> {
            return invocation.getArguments()[0];
        });

        // Act
        boolean exists = userService.userExists(username);

        // Assert
        assertTrue(exists);
        verify(userRepository, times(1)).findOneByUsername(username);
    }

    @Test
    public void testUserExists_CircuitBreakerOpen_ReturnsTrue() {
        // Arrange
        String username = "testuser";

        // Mock del Circuit Breaker para simular estado abierto
        when(databaseCircuitBreaker.decorateSupplier(any())).thenAnswer(invocation -> {
            return (Supplier<Object>) () -> {
                throw CallNotPermittedException.createCallNotPermittedException(databaseCircuitBreaker);
            };
        });

        // Act
        boolean exists = userService.userExists(username);

        // Assert
        assertTrue(exists); // Debe asumir que existe cuando CB está abierto
        verify(userRepository, never()).findOneByUsername(username);
    }
}