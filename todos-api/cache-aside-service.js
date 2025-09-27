const redis = require("redis");

class CacheAsideService {
  constructor(redisClient, defaultTTL = 300) {
    this.redis = redisClient;
    this.defaultTTL = defaultTTL;
  }

  async set(key, data, ttl = this.defaultTTL) {
    try {
      if (!data || !data.items || typeof data.lastInsertedID !== 'number') {
        console.error(`Invalid data structure for ${key}`);
        return;
      }
      
      await this.redis.setex(key, ttl, JSON.stringify(data));
      console.log(`Cache actualizado para ${key} con ${Object.keys(data.items).length} items`);
    } catch (error) {
      console.error(`Error actualizando cache para ${key}:`, error);
      throw error;
    }
  }

  // Patrón Cache-Aside clásico
  async get(key, fetchFunction, ttl = this.defaultTTL) {
    try {
      // 1. Intentar obtener del caché
      const cached = await this.redis.get(key);
      if (cached) {
        console.log(`Cache HIT para ${key}`);
        
        try {
          const parsedData = JSON.parse(cached);
          
          // Validación simple pero efectiva
          if (parsedData && parsedData.items && typeof parsedData.lastInsertedID === 'number') {
            return parsedData;
          } else {
            console.warn(`Invalid cached data for ${key} - regenerating`);
            await this.redis.del(key);
          }
        } catch (parseError) {
          console.warn(`Parse error for ${key} - deleting corrupted cache`);
          await this.redis.del(key);
        }
      }

      console.log(`Cache MISS para ${key}`);
      
      // 2. Ejecutar función para obtener datos frescos
      const data = await fetchFunction();

      // 3. Validar y guardar en caché
      if (data && data.items && typeof data.lastInsertedID === 'number') {
        await this.redis.setex(key, ttl, JSON.stringify(data));
      }

      return data;
    } catch (error) {
      console.error("Error en cache-aside:", error);
      // Fallback: ejecutar función directamente
      return await fetchFunction();
    }
  }

  async invalidate(key) {
    try {
      await this.redis.del(key);
      console.log(`Cache invalidado para ${key}`);
    } catch (error) {
      console.error("Error invalidando caché:", error);
    }
  }
}

module.exports = CacheAsideService;
