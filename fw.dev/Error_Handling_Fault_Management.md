[« Previous](./Timing_Timebase.md) | [Index](./index.md) | [Next »](./Watchdog_Startup_and_Shutdown.md)

---

# Firmware Coding Standard — Error Handling & Fault Management (FreeRTOS)

## 1) Purpose

Define a consistent approach for detecting, reporting, and recovering from errors and faults. Ensure all failures are visible, bounded, and safely escalated.

---

## 2) Principles

* **Fail fast, fail safe**: Detect and handle errors immediately; do not silently ignore.
* **Deterministic recovery**: Recovery paths must be bounded in time and predictable.
* **Unified error model**: Use a consistent status type across drivers and modules.
* **Visibility**: Every fault must be observable via logs, counters, or telemetry.

---

## 3) Error Reporting & Status Codes

* Use a unified `drv_status_t` or `fw_status_t` enum:

  ```c
  typedef enum {
      FW_OK = 0,
      FW_ERR_TIMEOUT,
      FW_ERR_PARAM,
      FW_ERR_HW,
      FW_ERR_OVERFLOW,
      FW_ERR_FATAL
  } fw_status_t;
  ```
* Drivers and services return this type; tasks check and handle explicitly.
* No use of "magic values" or silent returns.

---

## 4) Fault Classes

* **Recoverable**: timeouts, retries, transient communication errors.
* **Non-recoverable**: memory corruption, stack overflow, watchdog reset, hardware lockups.
* **Escalation path**: Every error must map to either **retry**, **drop**, **report**, or **reset**.

---

## 5) Hooks & System-Level Faults

* Implement and enable:

  * `vApplicationStackOverflowHook()` → log task name, halt/reboot.
  * `vApplicationMallocFailedHook()` → log, halt, safe state.
  * `configASSERT()` → always enabled in debug builds, log failure site.
* HardFault & exception handlers must:

  * Capture registers, PC, LR, SP.
  * Store minimal crash dump (flash or retention RAM).
  * Trigger safe halt or system reset.

---

## 6) Watchdog Integration

* Each critical task must periodically "pet" the watchdog.
* Missed watchdog = escalation to reset with logged cause.
* Watchdog service task aggregates heartbeats from tasks.

---

## 7) Error Logging

* Use a structured logging macro:

  ```c
  LOG_ERROR(TAG, "I2C timeout, addr=0x%02X", addr);
  ```
* No direct `printf` in drivers or ISRs.
* Errors must increment counters (per-module) and feed telemetry.

---

## 8) Recovery & Escalation

* **Retry**: bounded attempts with backoff (e.g., exponential up to N).
* **Drop**: skip current transaction if higher-level retry exists.
* **Escalate**: notify supervisor task (via queue/event) for system-level action.
* **Reset**: last resort, triggered by watchdog or fault handler.

---

## 9) Testing & Validation

* Each driver must include **fault injection tests**: simulate NACK, timeout, DMA error.
* Stress tests must verify system continues operating under repeated transient faults.
* CI/HIL runs must verify stack overflow hook, malloc failed hook, and watchdog reset paths.

---

## 10) Anti-Patterns

* Ignoring return values.
* Using `while(1);` loops on error (deadlock).
* Silent error handling (drop without logging).
* Relying on debug prints as error detection.
* Disabling watchdog to mask errors.

---

## 11) Review Checklist (Errors)

* [ ] All APIs return `fw_status_t` or equivalent.
* [ ] Return values checked at all call sites.
* [ ] Hooks implemented: stack overflow, malloc fail, hard fault.
* [ ] Crash dump/logging enabled and bounded.
* [ ] Watchdog heartbeats integrated for all critical tasks.
* [ ] Recovery path documented for each fault: retry, drop, escalate, reset.
* [ ] Error counters feed into telemetry/logging system.

---

## 12) CI/Lint Gates

* Fail build if:

  * Return values ignored (regex for `(void)` casts on API returns).
  * Calls to `malloc`/`free` outside init modules.
  * `while(1);` loops appear without explicit reset/logging.
  * Watchdog disabled without documented exception.

---

## 13) Example Patterns

**Driver return check**

```c
fw_status_t st = drv_i2c_write(addr, buf, len, TIMEOUT_MS);
if (st != FW_OK) {
    LOG_ERROR("I2C", "write failed: %d", st);
    supervisor_notify(EVT_DRV_FAIL, st);
}
```

**Stack overflow hook**

```c
void vApplicationStackOverflowHook(TaskHandle_t t, char *name) {
    LOG_CRIT("RTOS", "Stack overflow in %s", name);
    system_reset(SYS_RST_STACK);
}
```

**Watchdog task**

```c
for (;;) {
    if (all_tasks_reported()) {
        watchdog_kick();
    } else {
        LOG_CRIT("WDT", "missed heartbeat");
        system_reset(SYS_RST_WATCHDOG);
    }
    vTaskDelay(pdMS_TO_TICKS(100));
}
```

---

[« Previous](./Timing_Timebase.md) | [Index](./index.md) | [Next »](./Watchdog_Startup_and_Shutdown.md)

