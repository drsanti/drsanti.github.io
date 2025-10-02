[« Previous](./Error_Handling_Fault_Management.md) | [Index](./README.md) | [Next »](./Testing_CI_Gates.md)

---

# Firmware Coding Standard — Watchdog, Startup & Shutdown (FreeRTOS)

## 1) Purpose

Establish robust patterns for system startup, watchdog servicing, and controlled shutdown/reset. Prevent undefined states, guarantee safe recovery, and ensure fault causes are observable.

---

## 2) Principles

- **Watchdog always active**: Never ship code with watchdog disabled.
- **Startup deterministic**: All tasks, drivers, and services must initialize in a known sequence.
- **Graceful shutdown**: If reset/shutdown is required, log root cause and safe state before executing.
- **Never mask faults**: Watchdog resets and crash resets must leave a trace.

---

## 3) Startup Rules

- Startup must be **multi-phase**:

  1. **Minimal HW bring-up** (clock, memory, early console, watchdog enable).
  2. **Driver init** (GPIO, UART, I²C, SPI, timers).
  3. **RTOS objects** (queues, semaphores, tasks).
  4. **Application init** (protocols, services).

- All tasks created via `xTaskCreateStatic()` before `vTaskStartScheduler()`.
- No blocking delays (`HAL_Delay()`) during startup. Use bounded waits with timeouts.
- Failures at startup must be logged and escalated:

  - **Retry limited times** (e.g., 3 attempts).
  - If unrecoverable → safe state + reset.

---

## 4) Watchdog Rules

- **Early enable**: Watchdog configured as soon as clocks are stable.
- **Supervised mode**: A single “watchdog supervisor task” kicks the hardware watchdog.
- Each critical task must periodically report to the supervisor (via event bits or notify).
- If any critical task fails to report within its window → supervisor logs and triggers reset.
- Watchdog timeout must be **< worst-case lockup** but **> longest critical task cycle**.
- Disable watchdog **only** in bootloader or debug builds, never in production firmware.

---

## 5) Shutdown & Reset Rules

- **Orderly shutdown sequence**:

  1. Notify tasks of shutdown event.
  2. Stop accepting new external inputs.
  3. Flush logs/telemetry (bounded, e.g., <50 ms).
  4. Put peripherals into safe state (motors off, GPIOs safe).
  5. Reset or enter low-power state.

- **Reset causes**: Always log reset reason (power-on, watchdog, software request, brown-out).
- Place reset cause in retention RAM or backup registers for post-mortem.

---

## 6) Fault Escalation

- If startup or runtime fault cannot be resolved:

  - Log minimal error state.
  - Put system in safe mode (peripherals disabled).
  - Trigger watchdog or software reset.

- Never spin in `while(1)` without watchdog → leads to silent hang.

---

## 7) Anti-Patterns

- Disabling watchdog to "fix" false resets.
- Direct kicking of watchdog from multiple tasks (must go through supervisor).
- Skipping reset cause logging.
- Using infinite retries on startup failures.
- Blocking indefinitely during shutdown (hangs reset).

---

## 8) Review Checklist

- [ ] Watchdog enabled in startup, never disabled in production.
- [ ] Supervisor task aggregates heartbeats; no task directly kicks WDT.
- [ ] Startup sequence documented, deterministic, and bounded.
- [ ] All resets/shutdowns log root cause.
- [ ] Reset cause stored in retention memory/backup registers.
- [ ] No infinite loops or busy waits in startup/shutdown.
- [ ] Safe state entry defined for all critical peripherals.

---

## 9) CI/Lint Gates

- Fail build if:

  - Direct `watchdog_kick()` found in tasks (must go through supervisor).
  - `while(1)` present in startup/shutdown without watchdog/reset call.
  - Watchdog disable/stop APIs found in production config.

---

## 10) Example Patterns

**Watchdog supervisor task**

```c
static EventGroupHandle_t wdEvt;
#define WD_TASK_A (1<<0)
#define WD_TASK_B (1<<1)

void wd_task(void *arg) {
    for (;;) {
        EventBits_t bits = xEventGroupWaitBits(
            wdEvt, WD_TASK_A | WD_TASK_B,
            pdTRUE, pdTRUE,
            pdMS_TO_TICKS(WD_TIMEOUT_MS)
        );

        if ((bits & (WD_TASK_A | WD_TASK_B)) == (WD_TASK_A | WD_TASK_B)) {
            watchdog_kick_hw();   // all tasks reported
        } else {
            LOG_CRIT("WDT", "Missed heartbeat, bits=0x%X", bits);
            system_reset(SYS_RST_WATCHDOG);
        }
    }
}
```

**Startup sequence**

```c
void system_init(void) {
    hw_init_clocks();
    hw_init_watchdog();   // enable early
    hw_init_uart();
    drv_init_all();

    create_rtos_objects();
    start_application();

    vTaskStartScheduler();
}
```

**Logging reset cause**

```c
uint32_t cause = hw_read_reset_cause();
store_retention_reg(RESET_CAUSE, cause);
LOG_INFO("SYS", "Reset cause=0x%08X", cause);
```

---

[« Previous](./Error_Handling_Fault_Management.md) | [Index](./README.md) | [Next »](./Testing_CI_Gates.md)
