[« Previous](./Driver_HAL_Patterns.md) | [Index](./index.md) | [Next »](./Timing_Timebase.md)

---

# Firmware Coding Standard — Power Management (FreeRTOS)

## 1) Purpose

Define how firmware manages power consumption using FreeRTOS and hardware features. Ensure predictable entry/exit from low-power states, no data loss, and consistent wakeup behavior.

---

## 2) Principles

* **Idle = sleep**: The system must automatically reduce power in idle periods.
* **Deterministic wakeup**: Resume must be fast, bounded, and consistent.
* **State retention**: Critical state must survive suspend/resume cycles.
* **Granularity**: Match power mode depth to idle duration (tickless idle, STOP, STANDBY).

---

## 3) FreeRTOS Integration

* Enable **tickless idle** (`configUSE_TICKLESS_IDLE = 1`) to allow long sleep when tasks are blocked.
* Application must implement `vPortSuppressTicksAndSleep()` (or vendor HAL equivalent) to enter MCU sleep modes.
* All sleep entry/exit paths must be bounded and ISR-safe.

---

## 4) Task & Driver Rules

* Tasks must **block** on IPC (queue, semaphore, event group), never spin.
* Drivers must:

  * Support suspend/resume APIs (`drv_suspend()`, `drv_resume()`).
  * Ensure DMA transfers complete before entering deep sleep.
  * Disable unused peripherals and clocks when not in use.
* ISR wakeup sources must be documented (GPIO, RTC, timers).

---

## 5) Power Modes

* **Idle/Sleep**: CPU stopped, peripherals on. Entry: automatic with tickless idle.
* **Stop/Standby**: Most peripherals off, SRAM partially retained. Entry: via PM manager task, requires app approval.
* **Shutdown**: Minimal state retention, only RTC/backup. Must store reset cause.

---

## 6) Retention & State Saving

* All critical state (system counters, last error, watchdog marks) saved in:

  * Retention RAM, or
  * Backup registers.
* Buffers in volatile RAM must be flushed (e.g., log ring to flash).
* DMA-in-progress must be aborted or safely resumed.

---

## 7) Time & Tick Handling

* On wake, update tick count to account for time spent in sleep.
* Use RTC as reference clock for deep sleep modes.
* Periodic tasks using `vTaskDelayUntil()` remain aligned across sleep/wake cycles.

---

## 8) Testing & Measurement

* Measure average current for:

  * Active (CPU busy).
  * Idle (RTOS tickless sleep).
  * Stop/Standby (deep sleep).
* Validate wake sources and latency under stress (e.g., burst GPIO interrupts).
* Ensure watchdog continues running in sleep if configured.

---

## 9) Anti-Patterns

* Busy-wait loops in tasks (prevents sleep).
* Leaving unused peripherals powered.
* Entering deep sleep with DMA or peripheral transaction in flight.
* Failing to log wake source (debug nightmare).
* Using sleep APIs directly in random tasks (must be centralized).

---

## 10) Review Checklist (Power)

* [ ] Tickless idle enabled and tested.
* [ ] Tasks block properly; no spin loops.
* [ ] Drivers implement suspend/resume.
* [ ] Deep sleep only entered after confirming no active DMA/critical tasks.
* [ ] Wake sources documented and verified.
* [ ] Reset cause and wake source logged on startup.
* [ ] Average current measured in all power modes.

---

## 11) CI/Lint Gates

* Fail build if:

  * Calls to vendor `HAL_Delay()` or busy loops found.
  * Direct sleep API calls from tasks (must go through PM manager).
  * Tickless idle disabled in release config.

---

## 12) Example Patterns

**PM manager task**

```c
void pm_task(void *arg) {
    for (;;) {
        EventBits_t sys_state = xEventGroupWaitBits(sysEvt, EVT_IDLE, pdTRUE, pdTRUE, portMAX_DELAY);

        if (sys_state & EVT_IDLE) {
            if (can_enter_stop_mode()) {
                enter_stop_mode();
            }
        }
    }
}
```

**Tickless idle override**

```c
void vPortSuppressTicksAndSleep(TickType_t expectedIdleTime) {
    if (expectedIdleTime > MIN_SLEEP_TICKS) {
        prepare_for_sleep();
        enter_sleep_mode();   // WFI/WFE or vendor HAL
        restore_after_sleep();
    }
}
```

**Wake source logging**

```c
uint32_t src = hw_get_wakeup_source();
LOG_INFO("PM", "Wake from source=0x%08X", src);
```

---

[« Previous](./Driver_HAL_Patterns.md) | [Index](./index.md) | [Next »](./Timing_Timebase.md)
