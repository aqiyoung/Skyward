package com.follow.clash.service

import kotlinx.coroutines.async
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ServiceLifecycleTest {
    @Test
    fun `awaitDestroyed waits for the tracked service instance`() = runTest {
        val service = FakeManagedService()
        ServiceLifecycle.notifyCreated(service)
        val stopping = setOf(service)
        val waiter = backgroundScope.async {
            ServiceLifecycle.awaitDestroyed(stopping)
        }

        try {
            assertTrue(service in ServiceLifecycle.activeServices())
            runCurrent()
            assertFalse(waiter.isCompleted)

            ServiceLifecycle.completeDestroyed(service)
            runCurrent()
            assertTrue(waiter.isCompleted)
        } finally {
            ServiceLifecycle.completeDestroyed(service)
        }
    }
}

private class FakeManagedService : ManagedService {
    override fun start() = Unit

    override fun stop() = Unit
}
