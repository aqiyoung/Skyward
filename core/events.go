package core

import "sync"

// eventBus carries core events to the host without ever blocking the core's
// hot paths. A subscriber whose buffer is full is skipped, so a slow or
// disconnected host drops events instead of stalling a proxy dial or a parser.
//
// This is the delivery half of the core engine: the lifecycle half (single
// owner of start/stop) is wired into the engine in a later step; the bus is
// safe to land first because it only changes *when* the host callback runs, not
// *what* it receives.
type eventBus struct {
	mu     sync.RWMutex
	subs   map[int]chan []byte
	nextID int
}

const eventSubscriberBuf = 256

var bus = &eventBus{subs: make(map[int]chan []byte)}

func (b *eventBus) subscribe() (int, <-chan []byte) {
	b.mu.Lock()
	defer b.mu.Unlock()
	id := b.nextID
	b.nextID++
	ch := make(chan []byte, eventSubscriberBuf)
	b.subs[id] = ch
	return id, ch
}

// publish drops the event for any subscriber that cannot accept it right now.
// It never blocks the caller.
func (b *eventBus) publish(data []byte) {
	b.mu.RLock()
	defer b.mu.RUnlock()
	for _, ch := range b.subs {
		select {
		case ch <- data:
		default:
		}
	}
}
