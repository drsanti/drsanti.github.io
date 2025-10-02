[« Previous](./index.md) | [Index](./index.md) | [Next »](./index.md)

---

# 🛠 Firmware Coding Quick Reference

This page distills key rules and patterns from the full standards. For checklists and CI gates, see [Review Checklist](./Review_Checklist.md).

---

## 1. Memory & Resource Management
- **Static allocation only** after init (`...CreateStatic()` APIs, no `malloc/free` in runtime).
- DMA buffers: align, place in `.dma_buf`, clean/invalidate if cacheable.
- Stacks: measured HWM + 20% margin, in `.rtos_stacks`.
- [Static Allocation](./Static_Allocation.md) · [Memory & Linker Sections](./Memory_and_Linker_Sections.md) · [Resource Budgets](./Resource_Budgets.md)

**Anti-patterns:** dynamic alloc after init, stack arrays >1KB, DMA in `.bss`.

---

## 2. Tasking & Scheduling
- One responsibility per task; block on queues, not polling.
- Use `vTaskDelayUntil()` for periodic; WCET < 40% of period.
- Never block while holding mutex; Idle must always run.
- [Task Design & Scheduling](./Task_Design_and_Scheduling.md) · [Task Synchronization](./Task_Synchronization.md)

**Anti-patterns:** polling loops, multi-purpose tasks, blocking in critical section.

---

## 3. Inter-Task Communication (IPC)
- Choose primitive: 1:1 signal → notification, payload → queue, barrier → event group, byte stream → stream buffer, mutex for ownership.
- All waits bounded; from ISR use only `...FromISR` APIs.
- [IPC Quick Guide](<./Inter-Task_Communication_(IPC).md>)

**Anti-patterns:** infinite waits, binary semaphore as mutex, busy-loop polling.

---

## 4. Drivers & Hardware
- ISRs: minimal work, defer to task, no blocking, no dynamic alloc.
- Drivers: non-blocking, async/event-driven, DMA preferred, error codes unified.
- [Interrupts (ISR)](<./Interrupts_(ISR).md>) · [Driver & HAL Patterns](./Driver_HAL_Patterns.md)

**Anti-patterns:** blocking in ISR/driver, protocol logic in ISR, dynamic alloc in driver.

---

## 5. Timing & Reliability
- All waits: `pdMS_TO_TICKS(ms)`, wrap-safe comparisons.
- Timer callbacks: short, non-blocking, static-created.
- Watchdog: single supervisor task, all critical tasks report.
- [Timing & Timebase](./Timing_Timebase.md) · [Error Handling & Fault Management](./Error_Handling_Fault_Management.md) · [Watchdog, Startup & Shutdown](./Watchdog_Startup_and_Shutdown.md)

**Anti-patterns:** direct tick compares, busy-wait, direct watchdog kick from tasks.

---

## 6. Quality, Process & Safety
- CI: build+lint, unit/integration/HIL tests, static analysis, resource checks.
- Fault injection: malloc fail, ISR storm, queue overflow, watchdog expiry.
- [Testing & CI Gates](./Testing_CI_Gates.md) · [Style & Documentation](./Style_Documentation.md) · [Debug Interfaces](./Debug_Interfaces.md)

**Anti-patterns:** manual-only testing, ignoring failed tests, missing Doxygen/comments.

---

## 7. Logging, Security & Lifecycle
- Logging: macros only, static ring buffer, log task, no prints in ISR/hot path.
- Security: signed images, rollback, version metadata, debug ports locked in prod.
- [Logging, Diagnostics & Telemetry](./Logging_Diagnostics_Telemetry.md) · [Security, OTA/DFU & Versioning](./Security_OTA_DFU_Versioning.md)

**Anti-patterns:** direct printf, debug in prod, hardcoded credentials, missing version info.

---

## Handy Snippets

**Static queue:**
```c
static StaticQueue_t qcb; static uint8_t qstore[LEN*ITEM];
static QueueHandle_t q;
q = xQueueCreateStatic(LEN, ITEM, qstore, &qcb); configASSERT(q);
```

**Periodic task:**
```c
const TickType_t T = pdMS_TO_TICKS(10); TickType_t next = xTaskGetTickCount();
for (;;) { next += T; do_work(); vTaskDelayUntil(&next, T); }
```

**Notify from ISR:**
```c
BaseType_t hpw = pdFALSE; vTaskNotifyGiveFromISR(taskH, &hpw); portYIELD_FROM_ISR(hpw);
```

**Wrap-safe timeout:**
```c
TickType_t start = xTaskGetTickCount();
while ((TickType_t)(xTaskGetTickCount() - start) < pdMS_TO_TICKS(200)) { if (ready()) break; }
```

**Doxygen function header:**
```c
/**
 * @brief Send data over UART
 * @param buf   Pointer to TX buffer
 * @param len   Number of bytes
 * @return FW_OK on success, FW_ERR_TIMEOUT on timeout
 */
fw_status_t drv_uart_send(const uint8_t *buf, size_t len);
```

---

**Rule of thumb:** Deterministic, event-driven, measured, and documented.

**For review checklists, CI gates, and common mistakes, see [Review Checklist](./Review_Checklist.md).**

---

[« Previous](./index.md) | [Index](./index.md) | [Next »](./index.md)



---

# 📋 Firmware Coding Standards — Quick Reference (FreeRTOS)

*(Keep this laminated card at your bench. For full detail, see the Standards Index.)*

---

## 🔹 Memory & Resources

* Use **static allocation** (`xTaskCreateStatic`, `xQueueCreateStatic`, etc.).
* No `malloc`/`free` in runtime.
* Track **stack watermarks** and add 20% margin.
* DMA buffers aligned, placed in `.dma_buf`.
* Telemetry must report heap, stack, and queue usage.

---

## 🔹 Tasks & Scheduling

* Each task defines **period, WCET, stack, priority**.
* Block on queues/events — never busy-wait.
* Priorities: document & review, no starvation.
* Use `vTaskDelayUntil()` for periodic timing.

---

## 🔹 Synchronization & IPC

* Use FreeRTOS primitives: **queues, semaphores, event groups, mutexes**.
* Never block indefinitely in ISRs.
* Always check return codes (queue full/empty).
* Mutex only for shared resources, never in ISRs.

---

## 🔹 ISRs

* Keep ISRs ≤ 50 µs.
* Use `_FromISR()` APIs only.
* Set NVIC priorities explicitly and document.
* Defer work to tasks via queue/notify.

---

## 🔹 Drivers & Power

* Drivers expose **init, suspend, resume, ISR** APIs.
* All peripherals powered down when idle.
* Tickless idle enabled.
* Deep sleep only if DMA/critical tasks inactive.
* Always log wake source.

---

## 🔹 Timing & Reliability

* Use FreeRTOS tick (`xTaskGetTickCount()`) as system clock.
* Guard against tick overflows.
* Watchdog: kicked only from watchdog task.
* On startup, log reset cause.

---

## 🔹 Logging & Debug

* Use macros: `LOG_INFO`, `LOG_WARN`, `LOG_ERROR`.
* No `printf` in tasks or ISRs.
* Log buffer = static ring, drained by log task.
* Debug ports (SWD/JTAG) locked in release builds.
* Trace ISRs/tasks with GPIO toggles or RTT (debug builds only).

---

## 🔹 Security & Updates

* Bootloader validates firmware signature + hash.
* Dual-bank OTA with rollback.
* Mark image valid only after first boot.
* No hardcoded secrets.
* Version info = semantic version + Git hash + build date.

---

## 🔹 Testing & CI

* CI gates: build, lint, unit tests, static analysis, sim run.
* Coverage: ≥80% line, ≥70% branch.
* Fault injection: alloc fail, ISR storm, watchdog reset.
* HIL nightly: OTA, logging, power tests.

---

## 🔹 Style & Docs

* Tasks: `task_name`, Queues: `q_name`, Mutex: `mtx_name`.
* Doxygen for all public APIs.
* Task headers include: **period, priority, stack, desc**.
* Docs: `TASKS.md`, `ISR_PRIORITIES.md`, `TIMERS.md`.

---

# ✅ Code Review Top-10 Checklist

1. Static allocation only.
2. Tasks declare WCET/stack/priority.
3. Block, don’t busy-wait.
4. ISR short + `_FromISR()` only.
5. Mutex never in ISR.
6. Watchdog properly fed.
7. Logging via macros, no raw `printf`.
8. OTA signed + rollback-safe.
9. CI gates passed, coverage OK.
10. Style, docs, and naming conventions followed.

---

[« Previous](./index.md) | [Index](./index.md) | [Next »](./index.md)