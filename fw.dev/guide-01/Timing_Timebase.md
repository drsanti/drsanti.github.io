[« Previous](./Power_Management.md) | [Index](./README.md) | [Next »](./Error_Handling_Fault_Management.md)

---

# Firmware Coding Standard — Timing & Timebase (FreeRTOS)

## 1) Purpose

Define strict rules for using time in firmware: system tick, delays, scheduling, and handling overflow. Ensure timing is deterministic, portable, and free from hidden jitter.

---

## 2) Principles

- **One source of truth**: The FreeRTOS tick count (`xTaskGetTickCount()`) is the only timebase for relative timing.
- **Convert all timeouts**: Use `pdMS_TO_TICKS(ms)`; never hardcode ticks.
- **Jitter control**: Periodic tasks use `vTaskDelayUntil()`.
- **Overflow-safe**: Tick counters wrap; design all comparisons to be wrap-safe.

---

## 3) Tick Configuration

- **configTICK_RATE_HZ**:

  - Default = 1000 Hz (1 ms).
  - For ultra-low-power systems, consider 100 Hz (10 ms), but validate jitter budgets.

- **Tickless idle**: Allowed if power policy requires; ensure wakeup jitter is measured.
- **Timer granularity**: All software timers and delays inherit tick resolution.

---

## 4) Task Timing Rules

- **Periodic tasks**:

  - Must use `vTaskDelayUntil()` to minimize drift.
  - Document period in task header (e.g., `/* 5 ms periodic comms */`).

- **One-shot delays**:

  - Use `vTaskDelay(pdMS_TO_TICKS(x))` only for simple waits, not periodic loops.

- **Absolute time checks**:

  - Always compare with wrap-safe subtraction:

    ```c
    if ((TickType_t)(xTaskGetTickCount() - start) > timeout) { ... }
    ```

---

## 5) Timer Services

- Use `xTimerCreateStatic()` for software timers; no dynamic timers.
- Timer callbacks:

  - Run in the **timer service task** context.
  - Must be short and non-blocking.
  - Defer heavy work to worker tasks.

- Document all timers in `TIMERS.md` (purpose, period, callback).

---

## 6) ISRs & Time

- ISRs must not busy-wait for timeouts.
- If time measurement needed: use cycle counters (DWT, SysTick) for sub-tick resolution.
- For timestamping:

  - Use `xTaskGetTickCountFromISR()` for system ticks.
  - For high-res logging, pair tick count with hardware cycle counter.

---

## 7) Overflow Handling

- **32-bit ticks**: overflow every ~49 days at 1 kHz.
- **16-bit ticks** (if configured): overflow every ~65 s at 1 kHz.
- Always use wrap-safe arithmetic (never `if (now > expiry)`).

---

## 8) Jitter & Latency Budgets

- Document jitter budget for periodic tasks (e.g., ±2 ms at 10 ms period).
- Measure with trace hooks or GPIO toggles.
- For real-time loops (motor control, audio): tasks or ISRs must prove < jitter budget in stress testing.

---

## 9) Anti-Patterns

- Using `vTaskDelay(1)` as a "yield" → use `taskYIELD()`.
- Mixing raw hardware timers and RTOS ticks without synchronization.
- Using blocking delays (e.g., `HAL_Delay()`) inside tasks.
- Comparing tick values directly (`if (now > expiry)`) instead of wrap-safe subtraction.
- Logging timestamps with `xTaskGetTickCount()` only (coarse resolution).

---

## 10) Review Checklist (Timing)

- [ ] All delays converted with `pdMS_TO_TICKS()`.
- [ ] Periodic tasks use `vTaskDelayUntil()`.
- [ ] No `HAL_Delay()` or busy loops inside tasks.
- [ ] Wrap-safe arithmetic used for timeouts.
- [ ] Timer callbacks short, non-blocking, and static-created.
- [ ] Jitter budgets documented and verified.

---

## 11) CI/Lint Gates

- Fail build if:

  - Raw constants (`vTaskDelay(100)`) without `pdMS_TO_TICKS`.
  - Calls to `HAL_Delay` inside task context.
  - Direct tick comparisons (`if (now > expiry)`).
  - Dynamic timers (`xTimerCreate`) used instead of static.

---

## 12) Example Patterns

**Periodic task with jitter control**

```c
static void task_comms(void *arg)
{
    const TickType_t period = pdMS_TO_TICKS(10);
    TickType_t next = xTaskGetTickCount();

    for (;;) {
        next += period;
        comms_poll();  // bounded < 2ms
        vTaskDelayUntil(&next, period);
    }
}
```

**Timeout check (wrap-safe)**

```c
TickType_t start = xTaskGetTickCount();
while ((TickType_t)(xTaskGetTickCount() - start) < pdMS_TO_TICKS(200)) {
    if (is_ready()) break;
}
```

**Static timer**

```c
static StaticTimer_t ledTimerCb;
static TimerHandle_t ledTimerH;

ledTimerH = xTimerCreateStatic(
    "ledBlink",
    pdMS_TO_TICKS(500),
    pdTRUE,        // auto-reload
    NULL,
    led_blink_cb,
    &ledTimerCb
);
```

---

[« Previous](./Power_Management.md) | [Index](./README.md) | [Next »](./Error_Handling_Fault_Management.md)
