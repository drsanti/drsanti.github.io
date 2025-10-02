[« Previous](./Memory_and_Linker_Sections.md) | [Index](./index.md) | [Next »](./Task_Design_and_Scheduling.md)

---

# Firmware Coding Standard — Resource Budgets (FreeRTOS)

## 1) Purpose

Define strict budgeting rules for CPU, memory, stack, and peripheral resources in FreeRTOS-based firmware. Prevent unbounded growth, enforce predictability, and ensure the system fits within target hardware limits.

---

## 2) Principles

* **Budgets are contracts**: Every task, queue, and buffer has defined limits.
* **Measure, then size**: No guesswork — use telemetry and stack watermarks.
* **Fail safe on overflow**: Never silently drop data or exceed allocation.
* **Balance across system**: Budgets reviewed against CPU load, memory map, and watchdog window.

---

## 3) CPU Time Budget

* Each task must declare:

  * **Period** (ms)
  * **WCET** (worst-case execution time, µs)
  * **Jitter tolerance** (ms)
* Total CPU utilization across periodic tasks must stay < 70% of available budget.
* Interrupt load must be < 20% of CPU time under peak conditions.
* Validate with trace profiling (SEGGER SystemView, FreeRTOS trace macros).

---

## 4) Task Stack Budget

* All stacks sized with **measured watermark + 20% margin**.
* Stack allocations placed in `.rtos_stacks` section.
* Large buffers (>1 KB) forbidden on stack.
* CI gate enforces `uxTaskGetStackHighWaterMark()` checks in HIL tests.

---

## 5) Heap & Memory Budget

* If static allocation only: total RAM usage defined in linker map.
* If heap enabled:

  * `configTOTAL_HEAP_SIZE` set and documented.
  * No more than 80% heap usage at runtime.
* DMA buffers pre-allocated; aligned and accounted separately in `.dma_buf`.

---

## 6) IPC Budgets (Queues, Buffers)

* Queue length = measured peak + margin.
* Message sizes must be minimal; pass pointers not large structs.
* Queue overflows must be logged (increment counter, report via telemetry).
* Stream/message buffers sized for worst-case burst; monitor drop counts.

---

## 7) Peripheral & Timer Budgets

* Software timers limited to N per project (documented in `TIMERS.md`).
* NVIC priorities allocated and documented in `ISR_PRIORITIES.md`.
* DMA channels mapped centrally — no dynamic allocation.

---

## 8) Telemetry & Monitoring

* Periodic telemetry packet includes:

  * Free heap
  * Max stack usage per task
  * Queue usage (high-water marks)
  * CPU load estimate
* Budgets reviewed during stress test and updated if exceeded.

---

## 9) Anti-Patterns

* Oversizing stacks “just in case” (wastes RAM).
* Dynamic allocation in steady state.
* Queues with excessive length (masking flow-control problems).
* Ignoring queue full/empty return codes.
* CPU load measured only in idle state (misses peak).

---

## 10) Review Checklist

* [ ] CPU utilization measured, under 70%.
* [ ] Each task declares WCET, period, and jitter budget.
* [ ] All stacks measured, margin documented.
* [ ] Heap usage capped <80% (or static-only).
* [ ] DMA buffers accounted separately.
* [ ] Queue/buffer high-water marks reviewed.
* [ ] Telemetry includes resource metrics.

---

## 11) CI/Lint Gates

* Fail build if:

  * No stack watermark checks in tests.
  * Queue/stack/buffer allocated dynamically at runtime.
  * Configured heap size exceeded.
  * Telemetry packet missing resource metrics.

---

## 12) Example Patterns

**Task declaration in TASKS.md**

```
Task: comms
Period: 10 ms
WCET: 1.2 ms
Stack: 768 words (measured 600, margin 20%)
Priority: High
```

**Queue with monitoring**

```c
if (xQueueSend(q_comms, &msg, 0) != pdPASS) {
    LOG_WARN("COMMS", "Queue full, msg dropped");
    comms_stats.dropped++;
}
```

**Telemetry snippet**

```c
void telemetry_report(void) {
    sys_metrics_t m = {
        .heap_free = xPortGetFreeHeapSize(),
        .cpu_load  = get_cpu_load(),
        .stack_comms = uxTaskGetStackHighWaterMark(task_comms_h),
        .queue_comms = uxQueueSpacesAvailable(q_comms),
    };
    send_metrics(&m);
}
```

---

[« Previous](./Memory_and_Linker_Sections.md) | [Index](./index.md) | [Next »](./Task_Design_and_Scheduling.md)
