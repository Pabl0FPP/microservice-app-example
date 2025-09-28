const redis = require("redis");
const { promisify } = require("util");

class CacheAsideService {
  constructor(redisClient, defaultTTL = 300) {
    this.redis = redisClient;
    this.defaultTTL = defaultTTL;

    // Promisify (node-redis v2.x)
    this._getAsync = promisify(this.redis.get).bind(this.redis);
    this._setAsync = promisify(this.redis.set).bind(this.redis);
    this._setexAsync = promisify(this.redis.setex).bind(this.redis);
    this._delAsync = promisify(this.redis.del).bind(this.redis);
  }

  async set(key, data, ttl = this.defaultTTL) {
    try {
      if (!this._isValidStructure(data)) {
        console.error(`[CacheAside:set] Invalid data structure for ${key}`, data);
        return;
      }
      const dataString = JSON.stringify(data);
      if (ttl > 0) {
        await this._setexAsync(key, ttl, dataString);
        console.log(`Cache actualizado para ${key} con TTL ${ttl}s`);
      } else {
        await this._setAsync(key, dataString);
        console.log(`Cache actualizado para ${key} sin expiración`);
      }
    } catch (e) {
      console.error(`Error actualizando cache para ${key}:`, e);
      throw e;
    }
  }

  async get(key, fetchFunction, ttl = this.defaultTTL) {
    try {
      let raw = null;
      try {
        raw = await this._getAsync(key);
      } catch (gErr) {
        console.warn(`[CacheAside:get] Error ejecutando GET para ${key}`, gErr.message);
      }

      if (raw !== null && raw !== undefined) {
        console.log(`Cache HIT para ${key}`);
        console.log(`[RAW ${key}] ${raw}`);
        try {
          const parsed = JSON.parse(raw);
            if (this._isValidStructure(parsed)) {
              return parsed;
            } else {
              console.warn(`[CacheAside:get] Invalid structure in cache for ${key}, deleting`);
              await this._delAsync(key);
            }
        } catch (parseErr) {
          console.warn(`[CacheAside:get] JSON parse error for ${key}, deleting`, parseErr.message);
          await this._delAsync(key);
        }
      } else {
        console.log(`Cache MISS para ${key}`);
      }

      // Regenerar desde origen (default/fuente)
      const fresh = await fetchFunction();
      if (this._isValidStructure(fresh)) {
        await this.set(key, fresh, ttl);
      } else {
        console.error(`[CacheAside:get] fetchFunction devolvió estructura inválida para ${key}`, fresh);
      }
      return fresh;
    } catch (e) {
      console.error(`[CacheAside:get] Error general para ${key}:`, e);
      return await fetchFunction();
    }
  }

  async invalidate(key) {
    try {
      await this._delAsync(key);
      console.log(`Cache invalidado para ${key}`);
    } catch (e) {
      console.error(`Error invalidando cache ${key}:`, e);
    }
  }

  _isValidStructure(obj) {
    return obj &&
      typeof obj === 'object' &&
      obj.items &&
      typeof obj.items === 'object' &&
      typeof obj.lastInsertedID === 'number' &&
      obj.lastInsertedID > 0;
  }
}

module.exports = CacheAsideService;