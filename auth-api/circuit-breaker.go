package main

import (
	"errors"
	"fmt"
	"sync"
	"time"
)

// Estados del Circuit Breaker
type State int

const (
	StateClosed State = iota
	StateOpen
	StateHalfOpen
)

func (s State) String() string {
	switch s {
	case StateClosed:
		return "CLOSED"
	case StateOpen:
		return "OPEN"
	case StateHalfOpen:
		return "HALF_OPEN"
	default:
		return "UNKNOWN"
	}
}

// Errores específicos del Circuit Breaker
var (
	ErrCircuitBreakerOpen = errors.New("circuit breaker is open")
	ErrTooManyRequests    = errors.New("too many requests in half-open state")
)

// Configuración del Circuit Breaker
type Settings struct {
	Name                string        // Nombre para logging
	MaxRequests         uint32        // Máximo de requests en HALF_OPEN
	Interval            time.Duration // Ventana de tiempo para contar fallos
	Timeout             time.Duration // Tiempo que permanece OPEN
	ReadyToTrip         func(counts Counts) bool // Función para determinar cuándo abrir
	OnStateChange       func(name string, from State, to State) // Callback de cambios de estado
	IsSuccessful        func(err error) bool // Función para determinar si una respuesta es exitosa
}

// Contadores del Circuit Breaker
type Counts struct {
	Requests         uint32    // Total de requests
	TotalSuccesses   uint32    // Total de éxitos
	TotalFailures    uint32    // Total de fallos
	ConsecutiveSuccesses uint32 // Éxitos consecutivos
	ConsecutiveFailures  uint32 // Fallos consecutivos
}

// Estructura principal del Circuit Breaker
type CircuitBreaker struct {
	name          string
	maxRequests   uint32
	interval      time.Duration
	timeout       time.Duration
	readyToTrip   func(counts Counts) bool
	isSuccessful  func(err error) bool
	onStateChange func(name string, from State, to State)

	mutex      sync.Mutex
	state      State
	generation uint64
	counts     Counts
	expiry     time.Time
}

// Crear nuevo Circuit Breaker
func NewCircuitBreaker(st Settings) *CircuitBreaker {
	cb := &CircuitBreaker{
		name:        st.Name,
		maxRequests: st.MaxRequests,
		interval:    st.Interval,
		timeout:     st.Timeout,
		readyToTrip: st.ReadyToTrip,
		isSuccessful: st.IsSuccessful,
		onStateChange: st.OnStateChange,
	}

	if cb.name == "" {
		cb.name = "CircuitBreaker"
	}

	if cb.maxRequests == 0 {
		cb.maxRequests = 1
	}

	if cb.interval <= 0 {
		cb.interval = time.Duration(0)
	}

	if cb.timeout <= 0 {
		cb.timeout = 60 * time.Second
	}

	if cb.readyToTrip == nil {
		cb.readyToTrip = func(counts Counts) bool {
			return counts.ConsecutiveFailures > 5
		}
	}

	if cb.isSuccessful == nil {
		cb.isSuccessful = func(err error) bool {
			return err == nil
		}
	}

	cb.toNewGeneration(time.Now())

	return cb
}

// Ejecutar función protegida por Circuit Breaker
func (cb *CircuitBreaker) Execute(req func() (interface{}, error)) (interface{}, error) {
	generation, err := cb.beforeRequest()
	if err != nil {
		return nil, err
	}

	defer func() {
		e := recover()
		if e != nil {
			cb.afterRequest(generation, false)
			panic(e)
		}
	}()

	result, err := req()
	cb.afterRequest(generation, cb.isSuccessful(err))
	return result, err
}

// Verificaciones antes de ejecutar request
func (cb *CircuitBreaker) beforeRequest() (uint64, error) {
	cb.mutex.Lock()
	defer cb.mutex.Unlock()

	now := time.Now()
	state, generation := cb.currentState(now)

	if state == StateOpen {
		return generation, ErrCircuitBreakerOpen
	} else if state == StateHalfOpen && cb.counts.Requests >= cb.maxRequests {
		return generation, ErrTooManyRequests
	}

	cb.counts.onRequest()
	return generation, nil
}

// Procesamiento después del request
func (cb *CircuitBreaker) afterRequest(before uint64, success bool) {
	cb.mutex.Lock()
	defer cb.mutex.Unlock()

	now := time.Now()
	state, generation := cb.currentState(now)
	if generation != before {
		return
	}

	if success {
		cb.onSuccess(state, now)
	} else {
		cb.onFailure(state, now)
	}
}

// Manejar éxito
func (cb *CircuitBreaker) onSuccess(state State, now time.Time) {
	switch state {
	case StateClosed:
		cb.counts.onSuccess()
	case StateHalfOpen:
		cb.counts.onSuccess()
		if cb.counts.ConsecutiveSuccesses >= cb.maxRequests {
			cb.setState(StateClosed, now)
		}
	}
}

// Manejar fallo
func (cb *CircuitBreaker) onFailure(state State, now time.Time) {
	switch state {
	case StateClosed:
		cb.counts.onFailure()
		if cb.readyToTrip(cb.counts) {
			cb.setState(StateOpen, now)
		}
	case StateHalfOpen:
		cb.setState(StateOpen, now)
	}
}

// Obtener estado actual
func (cb *CircuitBreaker) currentState(now time.Time) (State, uint64) {
	switch cb.state {
	case StateClosed:
		if !cb.expiry.IsZero() && cb.expiry.Before(now) {
			cb.toNewGeneration(now)
		}
	case StateOpen:
		if cb.expiry.Before(now) {
			cb.setState(StateHalfOpen, now)
		}
	}
	return cb.state, cb.generation
}

// Cambiar estado
func (cb *CircuitBreaker) setState(state State, now time.Time) {
	if cb.state == state {
		return
	}

	prev := cb.state
	cb.state = state

	cb.toNewGeneration(now)

	if cb.onStateChange != nil {
		cb.onStateChange(cb.name, prev, state)
	}
}

// Nueva generación
func (cb *CircuitBreaker) toNewGeneration(now time.Time) {
	cb.generation++
	cb.counts = Counts{}

	var zero time.Time
	switch cb.state {
	case StateClosed:
		if cb.interval == 0 {
			cb.expiry = zero
		} else {
			cb.expiry = now.Add(cb.interval)
		}
	case StateOpen:
		cb.expiry = now.Add(cb.timeout)
	default:
		cb.expiry = zero
	}
}

// Obtener estado para debugging
func (cb *CircuitBreaker) State() State {
	cb.mutex.Lock()
	defer cb.mutex.Unlock()

	now := time.Now()
	state, _ := cb.currentState(now)
	return state
}

// Obtener contadores
func (cb *CircuitBreaker) Counts() Counts {
	cb.mutex.Lock()
	defer cb.mutex.Unlock()

	return cb.counts
}

// Métodos de los contadores
func (c *Counts) onRequest() {
	c.Requests++
}

func (c *Counts) onSuccess() {
	c.TotalSuccesses++
	c.ConsecutiveSuccesses++
	c.ConsecutiveFailures = 0
}

func (c *Counts) onFailure() {
	c.TotalFailures++
	c.ConsecutiveFailures++
	c.ConsecutiveSuccesses = 0
}

// Factory para crear Circuit Breaker con configuración por defecto
func NewDefaultCircuitBreaker(name string) *CircuitBreaker {
	return NewCircuitBreaker(Settings{
		Name:        name,
		MaxRequests: 3,
		Interval:    30 * time.Second,
		Timeout:     60 * time.Second,
		ReadyToTrip: func(counts Counts) bool {
			failureRatio := float64(counts.TotalFailures) / float64(counts.Requests)
			return counts.Requests >= 3 && failureRatio >= 0.6
		},
		OnStateChange: func(name string, from State, to State) {
			fmt.Printf("[Circuit Breaker] %s: %s -> %s\n", name, from, to)
		},
	})
}