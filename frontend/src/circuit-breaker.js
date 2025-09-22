// Circuit Breaker para Frontend (JavaScript)
class CircuitBreaker {
  constructor(options = {}) {
    this.name = options.name || "CircuitBreaker";
    this.failureThreshold = options.failureThreshold || 5;
    this.timeout = options.timeout || 60000; // 1 minuto
    this.monitor = options.monitor || false;

    this.state = "CLOSED"; // CLOSED, OPEN, HALF_OPEN
    this.failureCount = 0;
    this.nextAttempt = Date.now();
    this.successCount = 0;

    if (this.monitor) {
      console.log(`[Circuit Breaker] ${this.name} initialized`);
    }
  }

  async call(fn, fallback = null) {
    if (this.state === "OPEN") {
      if (Date.now() < this.nextAttempt) {
        if (this.monitor) {
          console.log(
            `[Circuit Breaker] ${this.name} is OPEN - using fallback`
          );
        }
        return fallback
          ? fallback()
          : Promise.reject(new Error("Circuit breaker is OPEN"));
      } else {
        this.state = "HALF_OPEN";
        this.successCount = 0;
        if (this.monitor) {
          console.log(
            `[Circuit Breaker] ${this.name} entering HALF_OPEN state`
          );
        }
      }
    }

    try {
      const result = await fn();
      this.onSuccess();
      return result;
    } catch (error) {
      this.onFailure();

      // Si tenemos fallback, usarlo, sino propagar error
      if (fallback && this.state === "OPEN") {
        if (this.monitor) {
          console.log(`[Circuit Breaker] ${this.name} failed - using fallback`);
        }
        return fallback();
      }

      throw error;
    }
  }

  onSuccess() {
    this.failureCount = 0;

    if (this.state === "HALF_OPEN") {
      this.successCount++;
      if (this.successCount >= 3) {
        // 3 éxitos consecutivos
        this.state = "CLOSED";
        if (this.monitor) {
          console.log(`[Circuit Breaker] ${this.name} entering CLOSED state`);
        }
      }
    }
  }

  onFailure() {
    this.failureCount++;

    if (
      this.state === "HALF_OPEN" ||
      this.failureCount >= this.failureThreshold
    ) {
      this.state = "OPEN";
      this.nextAttempt = Date.now() + this.timeout;
      if (this.monitor) {
        console.log(
          `[Circuit Breaker] ${this.name} entering OPEN state for ${this.timeout}ms`
        );
      }
    }
  }

  getStats() {
    return {
      state: this.state,
      failureCount: this.failureCount,
      successCount: this.successCount,
      nextAttempt: this.nextAttempt,
    };
  }
}

// Factory para crear Circuit Breakers configurados
export function createAPICircuitBreaker(apiName) {
  return new CircuitBreaker({
    name: `${apiName}-API`,
    failureThreshold: 3,
    timeout: 30000, // 30 segundos para APIs
    monitor: process.env.NODE_ENV === "development",
  });
}

export default CircuitBreaker;
