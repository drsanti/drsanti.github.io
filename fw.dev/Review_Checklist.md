[« Previous](./index.md) | [Index](./index.md) | [Next »](./index.md)

---

# ✅ Review Checklist & CI Gates

This page contains checklists, common mistakes, and CI gate rules extracted from all standards. Use during code reviews and CI setup. For quick rules and snippets, see [Quick Reference](./Quick_Reference.md).

---

## Common Mistakes

- **Dynamic allocation after init** - using `malloc/free` or dynamic RTOS APIs in runtime
- **Infinite waits or blocking in ISR** - `portMAX_DELAY` without justification, blocking calls in ISR context
- **Not checking return values** - ignoring queue full/empty, timeout, or error status codes
- **Oversized stacks/queues without measurement** - guessing sizes instead of using telemetry/HWM
- **Logging/printing in ISR or hot path** - direct `printf` calls that break real-time deadlines
- **Skipping watchdog, missing reset cause log** - disabled watchdog or no post-mortem logging
- **Failing to document section placement, priorities, or error handling** - missing `TASKS.md`, `ISR_PRIORITIES.md`, etc.
- **Using binary semaphore as mutex** - no priority inheritance, potential inversion
- **Stack arrays >1KB in tasks** - should use static global or shared buffers instead
- **DMA buffers in wrong sections** - not aligned, not in `.dma_buf`, cache issues

---

## CI/Lint Gates (Fail Build If)

### Memory & Resources
- Dynamic alloc APIs (`malloc`, `free`, `xTaskCreate`, `xQueueCreate`) in runtime code
- No stack watermark checks in tests
- Flash/RAM usage exceeds configured budget
- Local arrays >1KB detected in tasks

### RTOS & Timing
- Raw constants in delays (`vTaskDelay(100)`) without `pdMS_TO_TICKS`
- Direct tick comparisons (`if (now > expiry)`) instead of wrap-safe subtraction
- `portMAX_DELAY` without exception tag/justification
- Dynamic timers (`xTimerCreate`) instead of static

### ISR & Drivers
- Non-`FromISR` RTOS APIs in ISR functions
- Calls to `printf`, `malloc`, logging macros in ISR (unless flagged ISR-safe)
- ISR source exceeds line limit or contains unbounded loops
- Direct watchdog kick from tasks (must go through supervisor)

### Logging & Debug
- `printf`, `puts`, `sprintf` outside logging framework
- DEBUG logging enabled in release configuration
- RTT/SWO symbols in release builds
- Debug code lacks `#if DEBUG` guards

### Documentation & Style
- Missing Doxygen comments on public functions
- Naming convention violations (`task_`, `q_`, etc.)
- Lines >100 characters
- TODOs without issue reference
- Tabs instead of spaces

### Security & Versioning
- Version string missing or set to placeholder
- Build from dirty Git tree
- DFU image generated without signature
- Crypto functions called directly instead of wrapper API

---

## Pull Request (PR) Review Checklist

### Memory & Allocation
- [ ] All RTOS objects created with static APIs (`...CreateStatic`)
- [ ] No dynamic allocation after system init
- [ ] DMA buffers aligned and placed in `.dma_buf` (or cache maintenance added)
- [ ] Task stacks measured and sized with appropriate margin
- [ ] No large local buffers on task stacks

### RTOS & Synchronization
- [ ] All waits have finite timeouts and error handling
- [ ] No blocking while holding a mutex
- [ ] Correct primitive chosen for use case (notification vs queue vs semaphore)
- [ ] ISR paths use only `...FromISR` APIs and handle `xHigherPriorityTaskWoken`
- [ ] Event/notification bit maps documented

### Timing & Scheduling
- [ ] Periodic tasks use `vTaskDelayUntil()` for jitter control
- [ ] Wrap-safe arithmetic used for timeouts
- [ ] Timer callbacks short, non-blocking, and statically created
- [ ] WCET measured and within budget for critical tasks

### Error Handling & Safety
- [ ] Return values checked at all call sites
- [ ] Hooks implemented: stack overflow, malloc fail, hard fault
- [ ] Watchdog heartbeats integrated for all critical tasks
- [ ] Recovery path documented for each fault type
- [ ] Error counters feed into telemetry/logging system

### Logging & Diagnostics
- [ ] Logging uses macros, not raw `printf`
- [ ] No blocking debug calls in ISR or task hot loops
- [ ] Drop counts reported when log buffer overflows
- [ ] Telemetry rate-limited and aggregated

### Power & Performance
- [ ] Tasks block properly on IPC; no spin loops
- [ ] Drivers implement suspend/resume
- [ ] Tickless idle enabled and tested
- [ ] Average current measured in all power modes

### Documentation & Style
- [ ] Task headers include period, priority, stack, description
- [ ] Functions documented with Doxygen
- [ ] Naming conventions followed
- [ ] Module documentation updated (`TASKS.md`, `ISR_PRIORITIES.md`, etc.)

### Security & Lifecycle
- [ ] Version metadata embedded and accessible at runtime
- [ ] OTA/DFU process tested with power loss simulation
- [ ] Debug ports locked in production builds
- [ ] Reset cause stored and logged on startup

---

## Module-Specific Checklists

### Static Allocation
- [ ] `configSUPPORT_STATIC_ALLOCATION = 1`
- [ ] All kernel objects use static APIs
- [ ] Buffers/TCBs have static storage duration (not stack-allocated)
- [ ] Idle/Timer task memory hooks provided when fully static

### Task Design
- [ ] One responsibility per task
- [ ] Priority assigned based on rate/deadline
- [ ] No blocking while holding mutex
- [ ] Stack HWM measured and documented

### IPC
- [ ] Correct primitive selection per use case table
- [ ] Queue/buffer lengths based on measurements
- [ ] All waits bounded with timeouts
- [ ] Error handling for full/empty/timeout cases

### ISR
- [ ] Minimal work: ack, buffer, notify
- [ ] NVIC priority compliant with `configMAX_SYSCALL_INTERRUPT_PRIORITY`
- [ ] No dynamic memory, prints, or blocking
- [ ] Deferred handler task exists and is bounded

### Drivers
- [ ] APIs non-blocking, async, event-driven
- [ ] DMA buffers aligned and in correct memory region
- [ ] Error codes unified across modules
- [ ] Concurrency model documented

### Memory & Linker
- [ ] Section placement documented in `MEMORY_MAP.md`
- [ ] DMA buffers in `.dma_buf` with proper alignment
- [ ] No heap usage >80% (or static-only enforced)
- [ ] Cache maintenance policy validated

### Testing
- [ ] Unit tests for all drivers and RTOS wrappers
- [ ] Fault injection tests (malloc fail, ISR storm, timeouts)
- [ ] Coverage targets met for critical modules
- [ ] HIL tests verify watchdog, OTA, reset recovery

---

**For quick rules and code snippets, see [Quick Reference](./Quick_Reference.md).**

---

[« Previous](./index.md) | [Index](./index.md) | [Next »](./index.md)