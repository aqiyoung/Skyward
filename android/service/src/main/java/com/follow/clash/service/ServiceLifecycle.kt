package com.follow.clash.service

import android.os.Handler
import android.os.Looper
import kotlinx.coroutines.CompletableDeferred

object ServiceLifecycle {
    private val lock = Any()
    private val activeServices = mutableSetOf<ManagedService>()
    private val destroyWaiters = mutableMapOf<ManagedService, CompletableDeferred<Unit>>()

    fun notifyCreated(service: ManagedService) {
        synchronized(lock) {
            activeServices += service
        }
    }

    fun activeServices(): Set<ManagedService> = synchronized(lock) {
        activeServices.toSet()
    }

    suspend fun awaitDestroyed(services: Set<ManagedService>) {
        services.forEach { service ->
            val pending = synchronized(lock) {
                if (service in activeServices) {
                    destroyWaiters.getOrPut(service) { CompletableDeferred() }
                } else {
                    null
                }
            }
            pending?.await()
        }
    }

    fun notifyDestroyed(service: ManagedService) {
        Handler(Looper.getMainLooper()).post {
            completeDestroyed(service)
        }
    }

    internal fun completeDestroyed(service: ManagedService) {
        synchronized(lock) {
            activeServices.remove(service)
            destroyWaiters.remove(service)?.complete(Unit)
        }
    }
}
