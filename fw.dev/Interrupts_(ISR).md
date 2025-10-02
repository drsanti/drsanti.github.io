[« Previous](<./Inter-Task_Communication_(IPC).md>) | [Index](./index.md) | [Next »](./Driver_HAL_Patterns.md)

---

# Firmware Coding Standard — Interrupts (ISR) (FreeRTOS)

## 1) Purpose

Define strict rules for writing, configuring, and reviewing ISRs so latency is bounded, work is deterministic, and all heavy lifting happens in tasks.

---

## 2) Principles

* **Do the minimum in the ISR**: acknowledge, timestamp, buffer, and **defer**.
* **Never block**: only use `…FromISR` APIs; no waits, no loops that depend on other threads.
* **Bounded latency**: every ISR has a measured and documented max execution time.
* **Single source of truth**: ISR hands off to a task that owns the state machine.

---

## 3) Allowed Operations Inside ISRs

* Read/clear peripheral status flags; write to clear interrupt.
* Copy small amounts of data to **pre-allocated** buffers (ring/DMAs).
* Post to RTOS via ISR-safe APIs:

  * `xTaskNotifyGiveFromISR`, `xTaskNotifyFromISR`
  * `xQueueSendFromISR`
  * `xSemaphoreGiveFromISR` / counting/binary
  * `xEventGroupSetBitsFromISR` / `xEventGroupClearBitsFromISR`
* Set a local `BaseType_t xHigherPriorityTaskWoken` and call `portYIELD_FROM_ISR(xHigherPriorityTaskWoken)` when needed.
* **Forbidden**: dynamic memory, printf/formatting, blocking, long loops, mutex take/give, any non-`FromISR` RTOS call.

---

## 4) Deferral Pattern (ISR → Task)

**Always** use a deferred handler task for non-trivial work (parsing, protocol, math, file I/O, logging).

```c
void ISR_Handler(void)
{
    BaseType_t hpw = pdFALSE;

    // 1) Latch/clear cause
    const uint32_t status = PERIPH->STATUS; PERIPH->STATUS = status;

    // 2) Move minimal data (or mark DMA done)
    push_ring_isr(rx_byte());

    // 3) Notify handler task
    vTaskNotifyGiveFromISR(g_handlerTask, &hpw);

    // 4) Yield if a higher-priority task was woken
    portYIELD_FROM_ISR(hpw);
}
```

Handler task (high priority, short):

```c
void task_handler(void *arg)
{
    for(;;) {
        ulTaskNotifyTake(pdTRUE, portMAX_DELAY); // unblock when ISR posts
        drain_ring_and_process();                // bounded, no long loops
    }
}
```

---

## 5) Priority, Preemption & Nesting

* **NVIC priorities**: Assign based on urgency and service time; reserve the top priority for **time-critical** sources (e.g., motor control, high-rate timers).
* **configMAX_SYSCALL_INTERRUPT_PRIORITY** (Cortex-M): Any ISR that calls `…FromISR` must run at **equal or lower** priority (numerically **higher**) than this threshold.
* Disable interrupt **groups** only for the minimum critical window; avoid global `__disable_irq()` unless absolutely required.
* **Nesting allowed** only if it reduces worst-case latency and does not create reentrancy hazards.

---

## 6) Critical Sections vs. Interrupt Masking

* In ISRs, use port-safe primitives (`portSET_INTERRUPT_MASK_FROM_ISR` / `portCLEAR_INTERRUPT_MASK_FROM_ISR`) if you must guard a tiny region.
* Keep masked windows **short (< 2–5 µs typical)**; document rationale if longer.

---

## 7) DMA, Cache & Memory Safety

* Prefer DMA for bulk transfers; ISR just signals **DMA complete/error**.
* Place DMA buffers in proper memory (non-cacheable or with cache maintenance). If cacheable:

  * **Before DMA out**: clean (writeback) caches for the buffer.
  * **After DMA in**: invalidate caches for the buffer before reading.
* Buffers must be **statically allocated or pre-allocated**; never allocate in ISR.

---

## 8) Reentrancy & Shared State

* ISRs must **not** call non-reentrant code unless guarded by hardware or lock-free techniques.
* Shared variables between ISR and tasks:

  * Prefer RTOS primitives; if you must share raw flags/counters, make them `volatile` **and** protect access (critical sections or atomic ops).
  * Use **index + length** patterns for rings; updates must be atomic on target width.

---

## 9) Timing & Measurement

* Each ISR shall have:

  * **Max execution time** (µs) under worst-case conditions.
  * **Max frequency** (Hz) and burst behavior documented.
* Instrument during bring-up (GPIO toggle, cycle counters, trace hooks). Keep headroom for coincident interrupts.

---

## 10) Logging & Diagnostics

* No string formatting in ISR. If absolutely required, use **lock-free, pre-allocated** binary trace records.
* For debugging, use lightweight markers (e.g., ITM/RTT single-word writes), gated behind compile-time flags.

---

## 11) Error Handling in ISR Context

* Clear error flags; store minimal error code in a ring or status word.
* Notify a handler task for recovery.
* Avoid retry loops in ISR; recovery must happen in the task.

---

## 12) Template Snippets

**Queue from ISR**

```c
void ISR_Handler(void)
{
    BaseType_t hpw = pdFALSE;
    isr_msg_t msg = { .id = EVT_RX, .ts = get_time() };
    xQueueSendFromISR(g_evtQ, &msg, &hpw);
    portYIELD_FROM_ISR(hpw);
}
```

**Counting semaphore from ISR**

```c
void ISR_Timer(void)
{
    BaseType_t hpw = pdFALSE;
    xSemaphoreGiveFromISR(g_tickSem, &hpw);
    portYIELD_FROM_ISR(hpw);
}
```

**Event bits from ISR**

```c
void ISR_DMA(void)
{
    BaseType_t hpw = pdFALSE;
    xEventGroupSetBitsFromISR(g_evt, EVT_DMA_DONE, &hpw);
    portYIELD_FROM_ISR(hpw);
}
```

---

## 13) Configuration Rules (FreeRTOS + Cortex-M)

* Set `configLIBRARY_MAX_SYSCALL_INTERRUPT_PRIORITY` (CMSIS) and align NVIC priorities accordingly.
* Any ISR that uses `…FromISR` **must** have a priority numerically **>=** `configLIBRARY_MAX_SYSCALL_INTERRUPT_PRIORITY`.
* Document the **priority map** (table) in `ISR_PRIORITIES.md`.

---

## 14) Anti-Patterns (Do Not Do)

* Calling non-`FromISR` RTOS APIs from an ISR.
* Printing/formatting strings in ISR.
* Dynamic allocation or freeing in ISR.
* Long computation, parsing, or protocol handling in ISR.
* Busy-waiting for hardware flags when a second interrupt or DMA completion exists.
* Holding a mutex or attempting to take one in ISR.

---

## 15) Review Checklist (ISR)

* [ ] ISR does minimal work: ack, buffer, notify
* [ ] Uses only `…FromISR` calls; checks and yields on `xHigherPriorityTaskWoken`
* [ ] Measured max execution time and burst behavior documented
* [ ] NVIC priority compliant with `configMAX_SYSCALL_INTERRUPT_PRIORITY`
* [ ] No dynamic memory, no prints, no blocking
* [ ] DMA/cache handling correct for buffers
* [ ] Shared state is atomic or protected; no reentrancy issues
* [ ] Deferred handler task exists and is bounded

---

## 16) CI/Lint Gates

* Reject if:

  * Non-`FromISR` RTOS API appears in `*_IRQHandler`/ISR files.
  * Calls to `printf`, `malloc`, `free`, `new`, logging macros (unless flagged ISR-safe) inside ISR regions.
  * NVIC priority misconfig detected (script cross-checks vector table vs config).
  * ISR source exceeds N lines or contains loops without an explicit **bounded count**.

---

## 17) Documentation Deliverables

* `ISR_PRIORITIES.md` — table of sources, priority, max time, deferral target.
* `DMA_BUFFERS.md` — memory regions, cache policy, alignment, and flushing rules.
* Per-driver README: ISR cause map, error flags, and handler task interface.

---

[« Previous](<./Inter-Task_Communication_(IPC).md>) | [Index](./index.md) | [Next »](./Driver_HAL_Patterns.md)
