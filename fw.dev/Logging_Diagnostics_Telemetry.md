[« Previous](./Debug_Interfaces.md) | [Index](./index.md) | [Next »](./Security_OTA_DFU_Versioning.md)

---

# Firmware Coding Standard — Logging, Diagnostics & Telemetry (FreeRTOS)

## 1) Purpose

Define how firmware logs, reports, and exposes diagnostics in a FreeRTOS environment. Ensure visibility into system health without breaking real-time guarantees.

---

## 2) Principles

* **Non-blocking always**: Logging must never stall ISRs or tasks.
* **Structured over ad-hoc**: Use structured, leveled logs instead of raw `printf()`.
* **Telemetry minimalism**: Only send meaningful, bounded metrics.
* **Cost awareness**: Logging must be low-overhead in time, memory, and bandwidth.

---

## 3) Logging Framework

* Provide central logging macros:

  ```c
  LOG_DEBUG(tag, fmt, ...)
  LOG_INFO(tag, fmt, ...)
  LOG_WARN(tag, fmt, ...)
  LOG_ERROR(tag, fmt, ...)
  LOG_CRIT(tag, fmt, ...)
  ```
* Logging implementation must:

  * Buffer logs in **static ring buffer** (lock-free).
  * Defer formatting/transmission to a dedicated logging task.
  * Support log-level filtering at compile and runtime.

---

## 4) Rules for Usage

* **Never call `printf` directly** in tasks or ISRs.
* From ISRs: only push preformatted or small binary records into log buffer (`LOG_ISR_EVENT`).
* Logging in **critical tasks** must be bounded (< few µs).
* Logs must include **timestamp** (`xTaskGetTickCount()`) and **tag**.

---

## 5) Diagnostics & Health Monitoring

* Maintain system-level counters:

  * Task restarts
  * IPC queue overflows
  * Memory alloc failures
  * Watchdog resets
* Provide API for tasks to register health metrics (e.g., heartbeat counter).
* Collect metrics periodically in a **diagnostics task**.

---

## 6) Telemetry

* Export logs and metrics via one of:

  * UART/USB CDC
  * CAN
  * Network (MQTT, CoAP, custom)
* Telemetry must be **rate-limited** and compress/aggregate data if bandwidth is constrained.
* Raw logs must not exceed N% CPU or link utilization (set per project).

---

## 7) Crash & Fault Dumps

* On hard faults, watchdog resets, or fatal errors:

  * Capture reset cause, task name, PC/LR/SP, last error codes.
  * Store in retention RAM or reserved flash sector.
  * Emit on next boot as part of startup logs.

---

## 8) Testing & Validation

* CI test verifies:

  * Logging macros compile out at disabled levels.
  * Log buffer does not overflow silently (must report drop count).
  * Telemetry task runs at bounded duty cycle.
* HIL test verifies:

  * Logs can be collected at sustained rates.
  * Fault dumps appear correctly after simulated crash/reset.

---

## 9) Anti-Patterns

* Direct `printf` inside ISR or task hot loops.
* Logging without tags (impossible to parse later).
* Flooding logs in release builds (must default to WARN/ERROR only).
* Using logs as synchronization mechanism.
* Telemetry without bandwidth guardrails.

---

## 10) Review Checklist (Logging)

* [ ] All logs use macros, not raw `printf`.
* [ ] ISR logs push only binary/preformatted data.
* [ ] Logging task exists and is bounded.
* [ ] Log levels documented (DEBUG stripped in release).
* [ ] Drop counts reported when log buffer overflows.
* [ ] Telemetry rate-limited and aggregated.
* [ ] Crash dumps include reset cause and task info.

---

## 11) CI/Lint Gates

* Fail build if:

  * `printf`, `puts`, or `sprintf` appear outside logging framework.
  * Logging calls inside ISR without `_ISR` tag.
  * DEBUG logging enabled in release configuration.

---

## 12) Example Patterns

**Logging macro**

```c
#define LOG_INFO(tag, fmt, ...) \
    log_write(LOG_LEVEL_INFO, tag, fmt, ##__VA_ARGS__)
```

**ISR log**

```c
void DMA_IRQHandler(void) {
    BaseType_t hpw = pdFALSE;
    log_isr_event(DMA_EVT_DONE, dma_id);
    xTaskNotifyFromISR(dmaTask, EVT_DMA_DONE, eSetBits, &hpw);
    portYIELD_FROM_ISR(hpw);
}
```

**Logging task**

```c
void log_task(void *arg) {
    for (;;) {
        log_record_t rec;
        if (xQueueReceive(logQ, &rec, portMAX_DELAY)) {
            format_and_output(&rec);
        }
    }
}
```

**Crash dump on reboot**

```c
void system_boot(void) {
    reset_cause_t cause = get_reset_cause();
    if (cause != RESET_POWER_ON) {
        dump_last_crash();
    }
}
```

---

[« Previous](./Debug_Interfaces.md) | [Index](./index.md) | [Next »](./Security_OTA_DFU_Versioning.md)


