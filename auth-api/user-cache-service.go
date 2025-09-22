package main

import (
    "context"
    "encoding/json"
    "fmt"
    "time"
    "github.com/go-redis/redis/v8"
)

type UserCacheService struct {
    redisClient   *redis.Client
    userService   *UserService
    defaultTTL    time.Duration
}

func NewUserCacheService(redisClient *redis.Client, userService *UserService) *UserCacheService {
    return &UserCacheService{
        redisClient: redisClient,
        userService: userService,
        defaultTTL:  5 * time.Minute, // 5 minutos por defecto
    }
}

// Implementación Cache-Aside para usuarios
func (c *UserCacheService) GetUserWithCache(ctx context.Context, username string) (User, error) {
    cacheKey := fmt.Sprintf("user:%s", username)
    
    // 1. Intentar obtener del caché
    cached, err := c.redisClient.Get(ctx, cacheKey).Result()
    if err == nil {
        fmt.Printf("Cache HIT para usuario %s\n", username)
        var user User
        if err := json.Unmarshal([]byte(cached), &user); err == nil {
            return user, nil
        }
    }
    
    fmt.Printf("Cache MISS para usuario %s\n", username)
    
    // 2. Cache miss - obtener del servicio original
    user, err := c.userService.getUser(ctx, username)
    if err != nil {
        return user, err
    }
    
    // 3. Guardar en caché para próximas consultas
    go c.cacheUser(context.Background(), cacheKey, user)
    
    return user, nil
}

// Guardar usuario en caché (async)
func (c *UserCacheService) cacheUser(ctx context.Context, cacheKey string, user User) {
    userJSON, err := json.Marshal(user)
    if err != nil {
        fmt.Printf("Error serializando usuario para caché: %v\n", err)
        return
    }
    
    err = c.redisClient.Set(ctx, cacheKey, userJSON, c.defaultTTL).Err()
    if err != nil {
        fmt.Printf("Error guardando en caché: %v\n", err)
    }
}

// Invalidar caché de usuario
func (c *UserCacheService) InvalidateUser(ctx context.Context, username string) error {
    cacheKey := fmt.Sprintf("user:%s", username)
    return c.redisClient.Del(ctx, cacheKey).Err()
}

// Login con caché
func (c *UserCacheService) LoginWithCache(ctx context.Context, username, password string) (User, error) {
    user, err := c.GetUserWithCache(ctx, username)
    if err != nil {
        return user, err
    }

    userKey := fmt.Sprintf("%s_%s", username, password)
    if _, ok := allowedUserHashes[userKey]; !ok {
        return user, ErrWrongCredentials
    }

    return user, nil
}