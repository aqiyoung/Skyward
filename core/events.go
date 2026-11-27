package core

import "sync"

// eventBus carries core events to the host without ever blocking the core's
// hot paths. A slow or paused host drops frames instead of stalling a proxy
// dial or a config parse. There is exactly one permanent subscriber: the
// listener installed at init, which lives as long as the process.
type eventBus struct {
	mu  sync.RWMutex
	sub chan []byte
}

const eventSubscriberBuf = 256

var bus = &eventBus{sub: make(chan []byte, eventSubscriberBuf)}

func (b *eventBus) subscribe() <-chan []byte {
	b.mu.RLock()
	defer b.mu.RUnlock()
	return b.sub
}

// publish drops the event when the listener cannot accept it right now.
// It never blocks the caller.
func (b *eventBus) publish(data []byte) {
	b.mu.RLock()
	defer b.mu.RUnlock()
	select {
	case b.sub <- data:
	default:
	}
}
