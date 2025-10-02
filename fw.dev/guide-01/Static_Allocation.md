[« Previous](./README.md) | [Index](./README.md) | [Next »](./Memory_and_Linker_Sections.md)

---

# Firmware Coding Standard — Static Allocation (FreeRTOS)

## 1) Scope & Rationale

- **Scope:** All production firmware running FreeRTOS.
- **Goal:** Deterministic memory use, zero runtime heap dependence, avoidance of fragmentation and allocation jitter.
- **Policy:** Kernel objects **MUST** be created with static APIs unless an approved exception exists.

---

## 2) Configuration Requirements

- `configSUPPORT_STATIC_ALLOCATION` **= 1** (required).
- `configSUPPORT_DYNAMIC_ALLOCATION` **= 0** (preferred for fully heapless builds; set to 1 only if exceptions exist).
- Provide these hooks when fully static:

  - `vApplicationGetIdleTaskMemory()`
  - `vApplicationGetTimerTaskMemory()`

---

## 3) Approved APIs (MUST Use)

- **Tasks:** `xTaskCreateStatic()`
- **Queues:** `xQueueCreateStatic()`
- **Queue sets:** `xQueueCreateSetStatic()`
- **Event groups:** `xEventGroupCreateStatic()`
- **Semaphores/Mutexes:**
  `xSemaphoreCreateBinaryStatic()`, `xSemaphoreCreateCountingStatic()`,
  `xSemaphoreCreateMutexStatic()`, `xSemaphoreCreateRecursiveMutexStatic()`
- **Timers:** `xTimerCreateStatic()`
- **Stream/Message buffers:** `xStreamBufferCreateStatic()`, `xMessageBufferCreateStatic()`
- **Direct-to-task notifications:** Preferred over semaphores when 1:1 signaling suffices (no allocation needed).

---

## 4) Prohibited or Restricted

- **Prohibited:** `xTaskCreate`, `xQueueCreate`, `xEventGroupCreate`, `xTimerCreate`, non-static semaphore creators, and any `pvPortMalloc`/`free` in runtime paths.
- **Restricted (require exception):** Any dynamic allocation after system init. If allowed, it must be:

  - Performed **once** during init,
  - Bounded and checked,
  - Documented with rationale and rollback plan.

---

## 5) Lifetime & Placement Rules

- All `Static*` control blocks and data buffers **MUST** have static storage duration (file-scope `static` or global).
- **NEVER** pass stack-allocated buffers/`Static*` objects to creation APIs.
- Place performance-critical control blocks and queue storage in fast, non-cacheable or DMA-safe RAM as needed; document region/section.

---

## 6) Sizing & Alignment

- **Queues:** `uint8_t storage[uxLength * uxItemSize];` Ensure alignment appropriate for `uxItemSize` payload type.
- **Stacks:** Start from measured minima (see §8) and tune; no blanket oversizing.
- **Event groups:** Observe usable bit limits (24 bits with 32-bit ticks; 8 with 16-bit ticks). Split across groups if needed.

---

## 7) API Usage Rules

- **Timeouts:** Use bounded waits (`pdMS_TO_TICKS(x)`) instead of `portMAX_DELAY` unless justified.
- **ISRs:** Only `…FromISR()` variants; act on `xHigherPriorityTaskWoken`.
- **Mutexes:** Use for resource protection; **never** hold across blocking calls.
- **Binary semaphores:** For signaling; prefer direct task notifications when possible.

---

## 8) Verification & Instrumentation

- On creation, **MUST** check handles and wrap with `configASSERT()`.
- Enable and monitor:

  - `uxTaskGetStackHighWaterMark()` for each task (log during burn-in).
  - overflow/malloc-failed hooks (`vApplicationStackOverflowHook`, `vApplicationMallocFailedHook`).

- CI **MUST**:

  - Fail builds on dynamic API usage (regex/lint guard),
  - Treat compiler warnings as errors,
  - Run unit tests for modules that create kernel objects.

---

## 9) Documentation Requirements

For every kernel object, document in the module README or header:

- **Purpose**, **owner module**, **static lifetime**, **RAM section**, **priority/length/size**, and **interfaces** that use it.

---

## 10) Exceptions Process

- Submit a brief **Exception Record** stating:

  - Why static is infeasible,
  - Allocation site and bounds,
  - Failure handling and fallback,
  - Sunset plan to return to static.

- Approval required from Tech Lead + QA.

---

## 11) Reference Snippets

### Queue (static)

```c
static StaticQueue_t s_q_cb;
static uint8_t s_q_store[ QUEUE_LEN * ITEM_SIZE ];
static QueueHandle_t s_q;

void Q_Init(void) {
  s_q = xQueueCreateStatic(QUEUE_LEN, ITEM_SIZE, s_q_store, &s_q_cb);
  configASSERT(s_q);
}
```

### Task (static) + Idle/Timer hooks

```c
static StaticTask_t s_tcb;
static StackType_t s_stack[STACK_SZ];
static TaskHandle_t s_task;

void Tasks_Init(void) {
  s_task = xTaskCreateStatic(TaskFn, "worker", STACK_SZ, NULL, PRI, s_stack, &s_tcb);
  configASSERT(s_task);
}

/* Provide these when fully static */
void vApplicationGetIdleTaskMemory(StaticTask_t **tcb, StackType_t **stk, uint32_t *sz);
void vApplicationGetTimerTaskMemory(StaticTask_t **tcb, StackType_t **stk, uint32_t *sz);
```

### Event group (static)

```c
static StaticEventGroup_t s_evt_cb;
static EventGroupHandle_t s_evt;

void Evt_Init(void) {
  s_evt = xEventGroupCreateStatic(&s_evt_cb);
  configASSERT(s_evt);
}
```

---

## 12) Code Review Checklist (Static Focus)

- [ ] No dynamic creators or `pvPortMalloc` in runtime paths
- [ ] All kernel objects created via static APIs and checked with `configASSERT`
- [ ] Buffers/`Static*` objects are file-scope/static (not stack)
- [ ] Bounded timeouts; no blocking in ISRs
- [ ] Stack HWM measured and recorded; sizes updated accordingly
- [ ] Docs updated: purpose, owner, lifetime, RAM section

---

[« Previous](./README.md) | [Index](./README.md) | [Next »](./Memory_and_Linker_Sections.md)
