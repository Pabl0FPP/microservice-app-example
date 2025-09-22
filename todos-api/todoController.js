'use strict';
const {Annotation, 
    jsonEncoder: {JSON_V2}} = require('zipkin');

const OPERATION_CREATE = 'CREATE',
      OPERATION_DELETE = 'DELETE';

class TodoController {
    constructor({tracer, redisClient, logChannel}) {
        this._tracer = tracer;
        this._redisClient = redisClient;
        this._logChannel = logChannel;
        this._cachePrefix = 'todos:';
        this._cacheTTL = 900; // 15 minutes
    }

    // Cache Aside Pattern: Try Redis cache first, then fallback to default data
    async list (req, res) {
        try {
            const data = await this._getTodoData(req.user.username);
            res.json(data.items);
        } catch (error) {
            console.error('Error in list todos:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }

    async create (req, res) {
        try {
            // TODO: must be transactional and protected for concurrent access, but
            // the purpose of the whole example app it's enough
            const data = await this._getTodoData(req.user.username);
            const todo = {
                content: req.body.content,
                id: data.lastInsertedID
            };
            data.items[data.lastInsertedID] = todo;

            data.lastInsertedID++;
            await this._setTodoData(req.user.username, data);

            this._logOperation(OPERATION_CREATE, req.user.username, todo.id);

            res.json(todo);
        } catch (error) {
            console.error('Error in create todo:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }

    async delete (req, res) {
        try {
            const data = await this._getTodoData(req.user.username);
            const id = req.params.taskId;
            delete data.items[id];
            await this._setTodoData(req.user.username, data);

            this._logOperation(OPERATION_DELETE, req.user.username, id);

            res.status(204).send();
        } catch (error) {
            console.error('Error in delete todo:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }

    _logOperation (opName, username, todoId) {
        this._tracer.scoped(() => {
            const traceId = this._tracer.id;
            this._redisClient.publish(this._logChannel, JSON.stringify({
                zipkinSpan: traceId,
                opName: opName,
                username: username,
                todoId: todoId,
            }))
        })
    }

    // Cache Aside Pattern: Try cache first, then fallback to default data
    async _getTodoData(userID) {
        const cacheKey = this._cachePrefix + userID;
        
        try {
            // Try to get from Redis cache first
            const cachedData = await this._getFromCache(cacheKey);
            if (cachedData) {
                console.log(`Cache HIT for todos: ${userID}`);
                return JSON.parse(cachedData);
            }
            
            console.log(`Cache MISS for todos: ${userID}`);
            
            // Cache miss: create default data
            const data = {
                items: {
                    '1': {
                        id: 1,
                        content: "Create new todo",
                    },
                    '2': {
                        id: 2,
                        content: "Update me",
                    },
                    '3': {
                        id: 3,
                        content: "Delete example ones",
                    }
                },
                lastInsertedID: 4
            };

            // Store in cache
            await this._setTodoData(userID, data);
            return data;
            
        } catch (error) {
            console.error('Error in _getTodoData:', error);
            // Graceful degradation: return default data without caching
            return {
                items: {
                    '1': { id: 1, content: "Create new todo" },
                    '2': { id: 2, content: "Update me" },
                    '3': { id: 3, content: "Delete example ones" }
                },
                lastInsertedID: 4
            };
        }
    }

    async _setTodoData(userID, data) {
        const cacheKey = this._cachePrefix + userID;
        try {
            await this._setInCache(cacheKey, JSON.stringify(data));
            console.log(`Todos cached for user: ${userID}`);
        } catch (error) {
            console.error('Error caching todos data:', error);
        }
    }

    // Redis cache operations with Promise wrapper
    _getFromCache(key) {
        return new Promise((resolve, reject) => {
            this._redisClient.get(key, (err, result) => {
                if (err) {
                    reject(err);
                } else {
                    resolve(result);
                }
            });
        });
    }

    _setInCache(key, value) {
        return new Promise((resolve, reject) => {
            this._redisClient.setex(key, this._cacheTTL, value, (err, result) => {
                if (err) {
                    reject(err);
                } else {
                    resolve(result);
                }
            });
        });
    }
}

module.exports = TodoController