package com.elgris.usersapi.api;

import com.elgris.usersapi.models.User;
import com.elgris.usersapi.repository.UserRepository;
import com.elgris.usersapi.service.UserService;
import io.jsonwebtoken.Claims;
import io.github.resilience4j.circuitbreaker.CircuitBreaker;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.web.bind.annotation.*;
import org.springframework.http.ResponseEntity;

import javax.servlet.http.HttpServletRequest;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;

@RestController()
@RequestMapping("/users")
public class UsersController {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private UserService userService;

    @RequestMapping(value = "/", method = RequestMethod.GET)
    public List<User> getUsers() {
        // Usar el servicio con Circuit Breaker
        return userService.getAllUsers();
    }

    @RequestMapping(value = "/{username}",  method = RequestMethod.GET)
    public User getUser(HttpServletRequest request, @PathVariable("username") String username) {

        Object requestAttribute = request.getAttribute("claims");
        if((requestAttribute == null) || !(requestAttribute instanceof Claims)){
            throw new RuntimeException("Did not receive required data from JWT token");
        }

        Claims claims = (Claims) requestAttribute;

        if (!username.equalsIgnoreCase((String)claims.get("username"))) {
            throw new AccessDeniedException("No access for requested entity");
        }

        // Usar el servicio con Circuit Breaker
        return userService.getUserByUsername(username);
    }

    /**
     * Endpoint para monitorear el estado del Circuit Breaker
     */
    @RequestMapping(value = "/health/circuit-breaker", method = RequestMethod.GET)
    public ResponseEntity<Map<String, Object>> getCircuitBreakerStatus() {
        Map<String, Object> status = new HashMap<>();
        
        CircuitBreaker.State state = userService.getCircuitBreakerState();
        CircuitBreaker.Metrics metrics = userService.getCircuitBreakerMetrics();
        
        status.put("state", state.toString());
        status.put("failureRate", metrics.getFailureRate());
        status.put("slowCallRate", metrics.getSlowCallRate());
        status.put("numberOfCalls", metrics.getNumberOfBufferedCalls());
        status.put("numberOfFailedCalls", metrics.getNumberOfFailedCalls());
        status.put("numberOfSlowCalls", metrics.getNumberOfSlowCalls());
        status.put("numberOfSuccessfulCalls", metrics.getNumberOfSuccessfulCalls());
        
        return ResponseEntity.ok(status);
    }

}
