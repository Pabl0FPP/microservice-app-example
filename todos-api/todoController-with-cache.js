"use strict";
const CacheAsideService = require("./cache-aside-service");
const {
  Annotation,
  jsonEncoder: { JSON_V2 },
} = require("zipkin");

const OPERATION_CREATE = "CREATE",
  OPERATION_DELETE = "DELETE";

class TodoControllerWithCache {
  constructor({ tracer, redisClient, logChannel }) {
    this._tracer = tracer;
    this._redisClient = redisClient;
    this._logChannel = logChannel;
    this._cache = new CacheAsideService(redisClient, 300); // 5 minutos TTL
  }

  async list(req, res) {
    try {
      const username = req.user.username;
      const cacheKey = `todos:${username}`;

      // Usar Cache-Aside para obtener TODOs
      const data = await this._cache.get(cacheKey, async () => {
        return this._getDefaultTodoData();
      });

      res.json(data.items);
    } catch (error) {
      console.error("Error obteniendo TODOs:", error);
      res.status(500).json({ error: "Error interno del servidor" });
    }
  }

  async create(req, res) {
    try {
      const username = req.user.username;
      const cacheKey = `todos:${username}`;

      // Obtener datos actuales
      const data = await this._cache.get(cacheKey, async () => {
        return this._getDefaultTodoData();
      });

      // Crear nuevo TODO
      const todo = {
        content: req.body.content,
        id: data.lastInsertedID,
      };

      data.items[data.lastInsertedID] = todo;
      data.lastInsertedID++;

      // Actualizar caché con nuevos datos
      await this._redisClient.setex(cacheKey, 300, JSON.stringify(data));

      this._logOperation(OPERATION_CREATE, username, todo.id);

      res.json(todo);
    } catch (error) {
      console.error("Error creando TODO:", error);
      res.status(500).json({ error: "Error interno del servidor" });
    }
  }

  async delete(req, res) {
    try {
      const username = req.user.username;
      const cacheKey = `todos:${username}`;
      const id = req.params.taskId;

      // Obtener datos actuales
      const data = await this._cache.get(cacheKey, async () => {
        return this._getDefaultTodoData();
      });

      delete data.items[id];

      // Actualizar caché
      await this._redisClient.setex(cacheKey, 300, JSON.stringify(data));

      this._logOperation(OPERATION_DELETE, username, id);

      res.status(204).send();
    } catch (error) {
      console.error("Error eliminando TODO:", error);
      res.status(500).json({ error: "Error interno del servidor" });
    }
  }

  _logOperation(opName, username, todoId) {
    this._tracer.scoped(() => {
      const traceId = this._tracer.id;
      this._redisClient.publish(
        this._logChannel,
        JSON.stringify({
          zipkinSpan: traceId,
          opName: opName,
          username: username,
          todoId: todoId,
        })
      );
    });
  }

  _getDefaultTodoData() {
    return {
      items: {
        1: {
          id: 1,
          content: "Create new todo",
        },
        2: {
          id: 2,
          content: "Update me",
        },
        3: {
          id: 3,
          content: "Delete example ones",
        },
      },
      lastInsertedID: 4,
    };
  }
}

module.exports = TodoControllerWithCache;
