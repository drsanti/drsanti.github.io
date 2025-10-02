[« Previous](./Style_Documentation.md) | [Index](./README.md) | [Next »](./Logging_Diagnostics_Telemetry.md)

---

# Firmware Coding Standard — Debug Interfaces (FreeRTOS)

## 1) Purpose

Provide clear rules for implementing and controlling debug interfaces in FreeRTOS-based firmware. Ensure visibility for developers while preventing performance hits or security risks in production builds.

---

## 2) Principles

- **Debug ≠ production**: All debug features must be controllable via build flags.
- **Non-intrusive**: Debug logging and instrumentation must not break real-time deadlines.
- **Secure**: Debug ports locked or restricted in release builds.
- **Unified**: One framework for debug across all modules (UART, RTT, SWO, etc.), not ad-hoc.

---

## 3) Debug Channels

- **UART/USB CDC**: Default channel for text logs. Must use non-blocking driver (queue or DMA).
- **SWO/ITM (Cortex-M)**: For high-speed trace and timing markers. Use for profiling.
- **Segger RTT**: Optional channel for PC tools. Must be guarded by build flag.
- **GPIO toggles**: For cycle-accurate instrumentation (scope/logic analyzer).

---

## 4) Rules for Debug Code

- All debug code wrapped in `#if DEBUG ... #endif`.
- Debug output always deferred (log task, DMA, or RTT buffer) — **never direct printf in task or ISR**.
- Debug GPIO toggles must use macros:

  ```c
  DBG_PIN_TOGGLE(DBG_COMMS_ISR);
  ```

- No debug logic changes system state (must be passive observer).

---

## 5) Instrumentation

- Use macros for instrumentation hooks:

  ```c
  TRACE_ISR_ENTRY("UART");
  TRACE_ISR_EXIT("UART");
  TRACE_TASK_START("comms");
  TRACE_TASK_END("comms");
  ```

- Instrument all critical ISRs and periodic tasks for profiling.
- Measure worst-case latency, jitter, and context-switch time in stress tests.

---

## 6) Build Configuration

- **Debug build**:

  - Logging default = DEBUG/INFO.
  - RTT/SWO enabled.
  - Assertions on (`configASSERT`).

- **Release build**:

  - Logging default = WARN/ERROR.
  - Debug interfaces (RTT, SWD) locked or disabled.
  - Assertions off or routed to reset handler.

---

## 7) Security Rules

- Debug ports (SWD/JTAG) must be disabled or password-protected in production firmware.
- UART/USB debug commands disabled in production unless explicitly whitelisted.
- OTA/DFU builds must exclude debug backdoors.

---

## 8) Anti-Patterns

- Using `printf` directly in ISR or hot path.
- Leaving RTT/SWO logging enabled in release builds.
- Hardcoding debug commands in UART shell without access control.
- Debug toggles changing timing in critical ISRs.
- Mixing debug and application logic.

---

## 9) Review Checklist

- [ ] Debug macros used instead of raw `printf`.
- [ ] Logging and trace wrapped with build flags.
- [ ] No blocking debug calls in ISR or task hot loops.
- [ ] Critical ISRs and tasks instrumented.
- [ ] Debug ports locked in release builds.
- [ ] Debug commands audited and access-controlled.

---

## 10) CI/Lint Gates

- Fail build if:

  - `printf`, `puts`, `sprintf` found in ISR/task files.
  - RTT/SWO symbols appear in release build.
  - Debug code lacks `#if DEBUG` guards.
  - Debug commands compiled into production images.

---

## 11) Example Patterns

**Debug macro**

```c
#if DEBUG
#define DBG_LOG(tag, fmt, ...) LOG_DEBUG(tag, fmt, ##__VA_ARGS__)
#else
#define DBG_LOG(tag, fmt, ...) ((void)0)
#endif
```

**Instrumentation macro**

```c
#define TRACE_ISR_ENTRY(name) GPIO_SET(DBG_##name##_PIN)
#define TRACE_ISR_EXIT(name)  GPIO_CLEAR(DBG_##name##_PIN)
```

**Task with instrumentation**

```c
void task_comms(void *arg) {
    for (;;) {
        TRACE_TASK_START(COMMS);
        comms_poll();
        TRACE_TASK_END(COMMS);
        vTaskDelayUntil(&next, pdMS_TO_TICKS(10));
    }
}
```

---

✅ With this, we’ve covered:

- Static Allocation
- Task Synchronization
- Task Design & Scheduling
- Interrupts (ISR)
- Inter-Task Communication (IPC)
- Memory & Linker Sections
- Driver & HAL Patterns
- Timing & Timebase
- Error Handling & Fault Management
- Watchdog, Startup & Shutdown
- Power Management
- Logging, Diagnostics & Telemetry
- Security, OTA/DFU & Versioning
- Testing & CI Gates
- Style & Documentation
- Resource Budgets
- Debug Interfaces

---

[« Previous](./Style_Documentation.md) | [Index](./README.md) | [Next »](./Logging_Diagnostics_Telemetry.md)
