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
    this._cacheTTL = 900; // 15 minutes
    // Initialize Cache-Aside Service
    this._cacheService = new CacheAsideService(redisClient, this._cacheTTL);
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

      // Get current data using Cache-Aside
      let data = await this._cacheService.get(cacheKey, async () => {
        return this._getDefaultTodoData();
      });

      if (!data || typeof data !== 'object' || 
          !data.items || typeof data.items !== 'object' || 
          typeof data.lastInsertedID !== 'number') {
        
        console.warn(`Invalid data structure for ${username}, using default`);
        data = this._getDefaultTodoData();
      }

      const newId = data.lastInsertedID;
      
      const todo = {
        content: req.body.content,
        id: newId,
      };
      
      const updatedData = {
        items: { ...data.items }, 
        lastInsertedID: newId + 1
      };
      
      updatedData.items[newId] = todo;

      // Update cache with new data
      await this._updateCacheData(cacheKey, updatedData);

      this._logOperation(OPERATION_CREATE, username, todo.id);

      res.json(todo);
    } catch (error) {
      console.error("Error in create todo:", error);
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
        console.error(`Invalid data structure for ${cacheKey}:`, data);
        return;
      }
      
      await this._cacheService.set(cacheKey, data, this._cacheTTL);
      console.log(`Cache actualizado para ${cacheKey} con ${Object.keys(data.items).length} items`);
    } catch (error) {
      console.error("Error updating cache data:", error);
      throw error;
    }
  }
}

module.exports = TodoController;
