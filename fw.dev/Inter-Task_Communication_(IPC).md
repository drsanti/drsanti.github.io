[« Previous](./Task_Synchronization.md) | [Index](./index.md) | [Next »](./Interrupts_(ISR).md)

---

# Firmware Coding Standard — Inter-Task Communication (IPC) (FreeRTOS)

## 1) Purpose

Define safe, deterministic, and efficient usage of FreeRTOS IPC primitives. Ensure developers always choose the **right tool for the job**, size resources correctly, and avoid deadlocks or starvation.

---

## 2) Principles

* **Message passing > shared state** → prefer queues, buffers, or notifications over shared global variables.
* **One tool, one purpose** → don’t misuse primitives (e.g., binary semaphore as a mutex).
* **Bounded waits** → every IPC wait must have a timeout.
* **Measure, then size** → queue lengths, buffer sizes tuned by telemetry, not guesswork.

---

## 3) Primitive Selection

| Use Case                        | Best Primitive                           |
| ------------------------------- | ---------------------------------------- |
| 1:1 signaling (no payload)      | **Direct-to-Task Notifications**         |
| 1:1 small payloads (fixed size) | **Queue**                                |
| 1:N signaling / barrier         | **Event Group**                          |
| ISR → Task signaling            | **Notification** or **Binary Semaphore** |
| Counting permits                | **Counting Semaphore**                   |
| Shared resource ownership       | **Mutex** (priority inheritance)         |
| Byte stream (UART, audio)       | **Stream Buffer**                        |
| Framed messages (variable size) | **Message Buffer**                       |
| Wait on multiple sources        | **Queue Set**                            |

---

## 4) Rules by Primitive

### Direct-to-Task Notifications

* Fastest and zero-alloc → **preferred for 1:1 signals**.
* Two modes:

  * **Counting**: `xTaskNotifyGive` / `ulTaskNotifyTake`.
  * **Bitmask events**: `xTaskNotify` / `xTaskNotifyWait`.
* Each task has 32 slots; document bit allocation.

### Queues

* Payload must be **small** (structs, pointers). For big data, send pointer to pre-allocated buffer.
* Use `xQueueCreateStatic` with `StaticQueue_t` + storage buffer.
* Always check return code on `xQueueSend`/`xQueueReceive`.
* From ISR: only `xQueueSendFromISR` / `xQueueReceiveFromISR`.

### Stream/Message Buffers

* **Stream** = raw bytes; **Message** = length-framed messages.
* Good for UART, network frames, logging.
* Always set bounded timeouts.
* Only one reader + one writer per buffer (document assumption).

### Event Groups

* Use for **multi-task sync** (e.g., “ALL ready” or “ANY ready”).
* Remember bit limits (24 usable bits w/32-bit ticks; 8 with 16-bit ticks).
* From ISR: `xEventGroupSetBitsFromISR`.

### Semaphores & Mutexes

* **Mutex** = protect shared resource; **priority inheritance enabled**.
* **Binary Semaphore** = ISR → task or external event.
* **Counting Semaphore** = N-permit resource or multiple ISR events.
* **Rules:** never block while holding a mutex; never use binary semaphore as a mutex.

### Queue Sets

* Use when one task must listen to **multiple queues/semaphores**.
* Tasks block on the set, then check which object woke them.
* Keep set membership static; don’t add/remove at runtime.

---

## 5) Timeouts & Blocking

* All IPC waits must be **finite** (`pdMS_TO_TICKS(x)`), except in init tasks.
* No infinite waits (`portMAX_DELAY`) unless documented and justified.
* Log on timeout with context: task, primitive, duration waited.

---

## 6) ISR Rules

* ISRs may only call `…FromISR` APIs.
* Always use `BaseType_t xHigherPriorityTaskWoken` → `portYIELD_FROM_ISR`.
* ISR should signal and exit; handler task owns heavy work.

---

## 7) Anti-Patterns

* Busy-loop polling instead of blocking on IPC.
* Using binary semaphores for mutual exclusion.
* Passing stack pointers through queues (unless explicitly safe).
* Multiple writers/readers on stream/message buffer (not supported).
* Infinite waits without error path.

---

## 8) Review Checklist (IPC)

* [ ] Correct primitive chosen (see table).
* [ ] All IPC created statically (`…CreateStatic`).
* [ ] All waits bounded with timeouts.
* [ ] No blocking inside ISR.
* [ ] No mutex held during blocking wait.
* [ ] Event group bitmaps documented.
* [ ] Queue/buffer lengths measured and tuned.
* [ ] Error handling defined for timeout/full/empty cases.

---

## 9) CI/Lint Gates

* Fail build if:

  * Dynamic IPC creation APIs used (`xQueueCreate`, `xEventGroupCreate`, etc.).
  * `portMAX_DELAY` found in IPC waits without exception tag.
  * Mutex used inside ISR.
  * Binary semaphore created and later used as mutex.

---

## 10) Example Patterns

**Notify from ISR → task:**

```c
// ISR
vTaskNotifyGiveFromISR(taskH, &hpw); portYIELD_FROM_ISR(hpw);

// Task
ulTaskNotifyTake(pdTRUE, pdMS_TO_TICKS(50));
```

**Queue passing pointer:**

```c
typedef struct { uint8_t *buf; size_t len; } msg_t;
xQueueSend(qH, &msg, pdMS_TO_TICKS(5));
```

**Event group ALL barrier:**

```c
xEventGroupWaitBits(evH, EVT_A|EVT_B, pdTRUE, pdTRUE, pdMS_TO_TICKS(100));
```

---

[« Previous](./Task_Synchronization.md) | [Index](./index.md) | [Next »](./Interrupts_(ISR).md)