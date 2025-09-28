"use strict";
const CacheAsideService = require("./cache-aside-service");
const {
  Annotation,
  jsonEncoder: { JSON_V2 },
} = require("zipkin");

const OPERATION_CREATE = "CREATE",
  OPERATION_DELETE = "DELETE";

class TodoController {
  constructor({ tracer, redisClient, logChannel }) {
    this._tracer = tracer;
    this._redisClient = redisClient;
    this._logChannel = logChannel;
    this._cachePrefix = "todos:";
    this._cacheService = new CacheAsideService(redisClient, 0);
  }

  // Cache Aside Pattern: Try Redis cache first, then fallback to default data
  async list(req, res) {
    try {
      const username = req.user.username;
      const cacheKey = this._cachePrefix + username;

      // Use Cache-Aside Service to get todos
      const data = await this._cacheService.get(cacheKey, async () => {
        console.log(`Generating default todos for user: ${username}`);
        return this._getDefaultTodoData();
      });

      console.log(`[DEBUG] Data for ${username}:`, {
        hasItems: !!data.items,
        itemsType: typeof data.items,
        itemCount: data.items ? Object.keys(data.items).length : 0,
        lastInsertedID: data.lastInsertedID
      });

      res.json(data.items);
    } catch (error) {
      console.error("Error in list todos:", error);
      res.status(500).json({ error: "Internal server error" });
    }
  }

  async create(req, res) {
    try {
      const username = req.user.username;
      const cacheKey = this._cachePrefix + username;

      let data = await this._cacheService.get(cacheKey, async () => {
        console.log(`Generating default todos for user: ${username}`);
        return this._getDefaultTodoData();
      });

      if (!data || !data.items || typeof data.lastInsertedID !== 'number') {
        console.warn(`[create] Invalid in-memory data for ${username}, regenerating defaults`);
        data = this._getDefaultTodoData();
      }

      const newId = data.lastInsertedID;
      const todo = { id: newId, content: req.body.content };

      data.items[newId] = todo;
      data.lastInsertedID = newId + 1;

      await this._updateCacheData(cacheKey, data);

      this._logOperation(OPERATION_CREATE, username, todo.id);
      res.json(todo);
    } catch (e) {
      console.error("Error in create todo:", e);
      res.status(500).json({ error: "Internal server error" });
    }
  }

  async delete(req, res) {
    try {
      const username = req.user.username;
      const cacheKey = this._cachePrefix + username;
      const id = req.params.taskId;

      // Get current data using Cache-Aside
      const data = await this._cacheService.get(cacheKey, async () => {
        return this._getDefaultTodoData();
      });

      delete data.items[id];

      // Update cache with modified data
      await this._updateCacheData(cacheKey, data);

      this._logOperation(OPERATION_DELETE, username, id);

      res.status(204).send();
    } catch (error) {
      console.error("Error in delete todo:", error);
      res.status(500).json({ error: "Internal server error" });
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

  async _updateCacheData(cacheKey, data) {
    try {
      if (!data || !data.items || typeof data.lastInsertedID !== 'number') {
        console.error(`[updateCache] Invalid data (won't write) for ${cacheKey}`, data);
        return;
      }
      await this._cacheService.set(cacheKey, data, 0);
      console.log(`Cache actualizado para ${cacheKey} con ${Object.keys(data.items).length} items (lastInsertedID=${data.lastInsertedID})`);
    } catch (e) {
      console.error("Error updating cache data:", e);
    }
  }
}

module.exports = TodoController;
