package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"

	jwt "github.com/dgrijalva/jwt-go"
)

var allowedUserHashes = map[string]interface{}{
	"admin_admin": nil,
	"johnd_foo":   nil,
	"janed_ddd":   nil,
}

type User struct {
	Username  string `json:"username"`
	FirstName string `json:"firstname"`
	LastName  string `json:"lastname"`
	Role      string `json:"role"`
}

type HTTPDoer interface {
	Do(req *http.Request) (*http.Response, error)
}

type UserService struct {
	Client            HTTPDoer
	UserAPIAddress    string
	AllowedUserHashes map[string]interface{}
	CircuitBreaker    *CircuitBreaker
}

func (h *UserService) Login(ctx context.Context, username, password string) (User, error) {
	user, err := h.getUser(ctx, username)
	if err != nil {
		return user, err
	}

	userKey := fmt.Sprintf("%s_%s", username, password)

	if _, ok := h.AllowedUserHashes[userKey]; !ok {
		return user, ErrWrongCredentials // this is BAD, business logic layer must not return HTTP-specific errors
	}

	return user, nil
}

func (h *UserService) getUser(ctx context.Context, username string) (User, error) {
	var user User

	// Usar Circuit Breaker para proteger la llamada al Users API
	result, err := h.CircuitBreaker.Execute(func() (interface{}, error) {
		return h.fetchUserFromAPI(ctx, username)
	})

	if err != nil {
		// Si el Circuit Breaker está abierto, devolver usuario por defecto o error
		if err == ErrCircuitBreakerOpen {
			fmt.Printf("Circuit Breaker OPEN for user %s - using fallback\n", username)
			// Fallback: devolver usuario básico o usar caché local
			return h.getUserFallback(username), nil
		}
		return user, err
	}

	user = result.(User)
	return user, nil
}

// Nueva función que hace la llamada real al API
func (h *UserService) fetchUserFromAPI(ctx context.Context, username string) (User, error) {
	var user User

	token, err := h.getUserAPIToken(username)
	if err != nil {
		return user, err
	}
	
	url := fmt.Sprintf("%s/users/%s", h.UserAPIAddress, username)
	req, _ := http.NewRequest("GET", url, nil)
	req.Header.Add("Authorization", "Bearer "+token)
	req = req.WithContext(ctx)

	resp, err := h.Client.Do(req)
	if err != nil {
		return user, err
	}

	defer resp.Body.Close()
	bodyBytes, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return user, err
	}

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return user, fmt.Errorf("could not get user data: %s", string(bodyBytes))
	}

	err = json.Unmarshal(bodyBytes, &user)

	return user, err
}

func (h *UserService) getUserAPIToken(username string) (string, error) {
	token := jwt.New(jwt.SigningMethodHS256)
	claims := token.Claims.(jwt.MapClaims)
	claims["username"] = username
	claims["scope"] = "read"
	return token.SignedString([]byte(jwtSecret))
}

// Fallback cuando el Circuit Breaker está abierto
func (h *UserService) getUserFallback(username string) User {
	// Devolver datos básicos del usuario cuando el servicio no está disponible
	// En un caso real, esto podría venir de un caché local o datos estáticos
	return User{
		Username:  username,
		FirstName: "Unknown",
		LastName:  "User",
		Role:      "user", // rol por defecto
	}
}
