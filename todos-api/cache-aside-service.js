const redis = require("redis");

class CacheAsideService {
  constructor(redisClient, defaultTTL = 300) {
    this.redis = redisClient;
    this.defaultTTL = defaultTTL;
  }

  // Patrón Cache-Aside clásico
  async get(key, fetchFunction, ttl = this.defaultTTL) {
    try {
      // 1. Intentar obtener del caché
      const cached = await this.redis.get(key);
      if (cached) {
        console.log(`Cache HIT para ${key}`);
        return JSON.parse(cached);
      }

      console.log(`Cache MISS para ${key}`);

      // 2. Cache miss - ejecutar función de obtención
      const data = await fetchFunction();

      // 3. Guardar en caché para próximas consultas
      await this.redis.setex(key, ttl, JSON.stringify(data));

      return data;
    } catch (error) {
      console.error("Error en cache-aside:", error);
      // En caso de error de Redis, ejecutar función directamente
      return await fetchFunction();
    }
  }

  // Invalidar caché cuando hay actualizaciones
  async invalidate(key) {
    try {
      await this.redis.del(key);
      console.log(`Cache invalidado para ${key}`);
    } catch (error) {
      console.error("Error invalidando caché:", error);
    }
  }

  // Invalidar múltiples claves con patrón
  async invalidatePattern(pattern) {
    try {
      const keys = await this.redis.keys(pattern);
      if (keys.length > 0) {
        await this.redis.del(...keys);
        console.log(`Invalidadas ${keys.length} claves con patrón ${pattern}`);
      }
    } catch (error) {
      console.error("Error invalidando patrón:", error);
    }
  }
}

module.exports = CacheAsideService;
