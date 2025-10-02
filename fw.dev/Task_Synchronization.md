[« Previous](./Task_Design_and_Scheduling.md) | [Index](./index.md) | [Next »](<./Inter-Task_Communication_(IPC).md>)

---

# Firmware Coding Standard — Task Synchronization (FreeRTOS)

>It focuses on determinism, safety, and clarity.

## 1) Principles

* **Message > Mutex:** Prefer **message passing** (queues, stream/message buffers, task notifications) over shared-memory locking.
* **Bounded waits:** All blocking operations **must** use finite timeouts (`pdMS_TO_TICKS(x)`), not infinite waits, unless justified.
* **Determinism first:** Keep critical sections short; avoid unbounded contention and hidden priority inversions.
* **One responsibility per primitive:** Pick the right tool for the job; don’t overload primitives.

---

## 2) Primitive Selection (Use This Guide)

* **One-to-one signaling (no payload):**
  → **Direct-to-Task Notifications** (`xTaskNotifyGive`, `xTaskNotify`, `xTaskNotifyWait`).
  *Zero allocation, fastest path. Consider `xTaskNotifyIndexed` if using multiple channels.*
* **One-to-one with small payloads (fixed size):**
  → **Queue** (item = struct or pointer).
* **Variable-length bytes (UART, sockets):**
  → **Stream Buffer** (byte stream) or **Message Buffer** (framed messages).
* **One-to-many or barrier (“ANY/ALL ready”):**
  → **Event Group**.
* **Mutual exclusion for shared resource (driver/state):**
  → **Mutex** (priority inheritance).
  *Binary semaphore is **not** a mutex.*
* **Counting permits (N concurrent uses) or ISR→task ping:**
  → **Counting/Binary Semaphore**.
* **Wait on multiple producers:**
  → **Queue Set** (select-like behavior across queues/semaphores).

---

## 3) Rules by Primitive

### A. Direct-to-Task Notifications

* Use for **1:1** signaling; prefer over binary semaphores when possible.
* Decide mode per use:

  * **Counting**: `xTaskNotifyGive()` / `ulTaskNotifyTake()` (acts like a counting semaphore).
  * **Event bits**: `xTaskNotify()` + `xTaskNotifyWait()` with bitmasks.
* Each task has 32 notification bits; document the bit allocation in the module header.
* Never block on notifications in ISR; use `...FromISR` variants to send only.

### B. Queues

* Payloads should be **small**; for big data, pass **pointers** (zero-copy).
* Size = **measured** depth (use telemetry; don’t guess). Tune to avoid starvation/backpressure.
* On send/receive **always** check return codes; on timeout, log and handle (retry, drop, or escalate).
* From ISR: only `xQueueSendFromISR`/`xQueueReceiveFromISR`; handle `xHigherPriorityTaskWoken`.

### C. Stream/Message Buffers

* Stream = raw bytes; Message = length-framed messages. Choose appropriately.
* Always use timeouts; on overflow/underflow, define behavior (drop oldest, signal backpressure).
* For ISR producers, prefer **message buffers** (single writer/reader assumptions apply).

### D. Event Groups

* Use for **state flags** and **barriers**:

  * ANY vs ALL; **auto-clear** only when the waiter has consumed the event.
* Respect the **bit budget** (24 bits if 32-bit ticks; 8 bits if 16-bit ticks). Document bit maps.
* Set/clear from ISR only with `...FromISR` APIs; keep ISR short.

### E. Mutexes & Semaphores

* **Mutex** for ownership protection; **never** hold a mutex across a blocking call or for long CPU work.
* Avoid **recursive mutexes** unless necessary; document rationale.
* **Binary semaphore** for signaling, **not** for mutual exclusion (no priority inheritance).
* For ISR→task signaling use **binary/ counting semaphores** or **notifications** (preferred).

---

## 4) ISR & Critical Sections

* ISRs must be **short and bounded**; do minimal work, defer to a task.
* In ISRs: only call `...FromISR` APIs; check `xHigherPriorityTaskWoken` and `portYIELD_FROM_ISR`.
* Use `taskENTER_CRITICAL()`/`taskEXIT_CRITICAL()` **sparingly** and keep windows minimal.
  From ISR, use the `*_FROM_ISR` variants. Never perform lengthy operations inside critical sections.

---

## 5) Deadlock, Priority Inversion, and Contention

* **Priority inheritance:** Use FreeRTOS **mutexes** for shared resources accessed by mixed priorities.
* **Lock order rule:** If you must take multiple locks, define and document a **global acquisition order**; never violate it.
* **No nested blocking waits:** Don’t block while holding a mutex. If unavoidable, redesign.
* **Detect & log contention:** On timeouts, log task name, waited object, and wait time. Consider exponential backoff or fail-fast paths.

---

## 6) Time & Units

* Convert all timeouts via `pdMS_TO_TICKS(ms)`; do not hardcode ticks.
* Define module-level constants for time budgets (e.g., `UART_RX_WAIT_MS`).
* For periodic tasks, use **`vTaskDelayUntil`** for jitter control (not `vTaskDelay`).

---

## 7) Memory Visibility & “volatile”

* **Do not** use `volatile` as a synchronization mechanism. Use proper primitives (queues, semaphores, notifications, event groups).
* Shared flags without primitives are forbidden unless protected by **critical sections** and accompanied by clear memory-ordering reasoning.

---

## 8) Startup, Shutdown, and Errors

* On startup, create and validate all synchronization objects; `configASSERT` on failure.
* On shutdown, **signal cancellation** (e.g., notification bit or event flag), then:

  * Drain queues if required,
  * Join/await task completion with bounded timeouts,
  * Log any forced termination.
* Every wait with a timeout must have a **defined policy**: retry, drop, escalate, or reset.

---

## 9) Observability & Tuning

* Instrument: record queue high/low watermarks, average wait times, and timeout counts.
* Use `uxTaskGetStackHighWaterMark()` to ensure sync paths don’t exhaust stack.
* Enable tracing (e.g., Segger SystemView or trace macros) for barrier waits and ISR wakeups during bring-up.

---

## 10) Anti-Patterns (Do Not Do)

* Busy-loops/spin waits for synchronization.
* Using `vTaskDelay(1)` as a “synchronization” mechanism.
* Passing stack pointers through queues (unless producer outlives consumer usage and it’s intentional/documented).
* Using binary semaphores as mutexes.
* Long computations inside critical sections or while holding a mutex.

---

## 11) Review Checklist (Sync-Focused)

* [ ] Correct primitive chosen (per §2).
* [ ] All waits have **finite timeouts** and error handling.
* [ ] No blocking while holding a mutex.
* [ ] ISR paths use `...FromISR` and yield when needed.
* [ ] Lock acquisition order documented; no nesting violations.
* [ ] Queue/buffer sizing based on measurements (not guesswork).
* [ ] Event/notification bit maps documented.
* [ ] No misuse of `volatile` for synchronization.

---

### Quick Patterns (snippets)

**Notify (counting)**

```c
// ISR
vTaskNotifyGiveFromISR(taskH, &hpw); portYIELD_FROM_ISR(hpw);

// Task
ulTaskNotifyTake(pdTRUE, pdMS_TO_TICKS(50));
```

**Queue (pointer payload, zero-copy)**

```c
typedef struct { uint8_t *buf; size_t len; } msg_t;
xQueueSend(q, &msg, pdMS_TO_TICKS(10));
```

**Event barrier (ALL, auto-clear)**

```c
xEventGroupWaitBits(eg, A|B|C, pdTRUE, pdTRUE, pdMS_TO_TICKS(100));
```

**Mutex (no blocking inside critical section)**

```c
xSemaphoreTake(mtx, pdMS_TO_TICKS(5));
do_work_quickly();
xSemaphoreGive(mtx);
```

---

[« Previous](./Task_Design_and_Scheduling.md) | [Index](./index.md) | [Next »](<./Inter-Task_Communication_(IPC).md>)
