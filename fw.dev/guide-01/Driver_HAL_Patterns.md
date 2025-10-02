[« Previous](<./Interrupts_(ISR).md>) | [Index](./README.md) | [Next »](./Power_Management.md)

---

# Firmware Coding Standard — Driver & HAL Patterns (FreeRTOS)

## 1) Purpose

Define rules for building firmware drivers and hardware abstraction layers (HAL) that are deterministic, non-blocking, and consistent across the codebase.

---

## 2) Principles

- **Interrupt-driven or DMA-first**: ISRs and DMA handle data movement, tasks handle processing.
- **Non-blocking APIs**: Drivers never stall tasks; always async or event-driven.
- **Ownership clear**: Each driver owns its hardware and defines clear interfaces for users.
- **Separation of concerns**: Driver = hardware interaction; upper layers = protocol/state machine.

---

## 3) Driver Architecture

- **ISR Layer**:

  - Acknowledge interrupts, move data (to ring buffer or mark DMA done), defer to task.
  - No parsing or protocol logic in ISR.

- **Driver Task (if needed)**:

  - Processes events signaled by ISR (via queue/notify).
  - Implements state machine, error recovery, retries.

- **HAL API**:

  - Asynchronous, event-driven interface (e.g., `uart_write_async`, `i2c_request`).
  - Provides completion/error callbacks via queue/notify/event group.

---

## 4) API Rules

- **Naming**:

  - Low-level (ISR/HAL) APIs prefixed with `hal_`.
  - Driver-level APIs prefixed with `drv_`.

- **Non-blocking**:

  - No `while()` loops waiting on flags.
  - Return immediately with status code (OK, BUSY, ERROR).

- **Events**:

  - Define `enum` event IDs and deliver through queue or notification.
  - Document which events may fire in each state.

---

## 5) Error Handling

- **Error codes**: Unified `drv_status_t` (e.g., `DRV_OK`, `DRV_ERR_TIMEOUT`, `DRV_ERR_HW`).
- **Retry policy**: Implemented in driver task, not ISR.
- **Fatal errors**: Logged, flagged to supervisor task (via queue/event).
- **Timeouts**: All async calls have defined timeout behavior.

---

## 6) DMA Usage

- Prefer DMA over CPU-driven transfers.
- Buffers must follow memory rules (see Memory & DMA standard):

  - Aligned to cache line.
  - Placed in `.dma_buf` or with flush/invalidate.

- ISR: only mark transfer complete/error and signal driver task.

---

## 7) Concurrency & Ownership

- Drivers must be **reentrant-safe** when accessed from multiple tasks.
- Use **mutex** to serialize access if hardware is single-client.
- Document:

  - Can multiple tasks access concurrently?
  - Which API calls are allowed from ISR vs task context?

---

## 8) Testing

- Provide **loopback tests** (UART, SPI) or mock drivers (I²C, sensors) for unit testing.
- All drivers must have:

  - Init self-test.
  - Fault-injection path (simulate NACK, timeout, DMA error).
  - Stress test with burst traffic.

---

## 9) Anti-Patterns

- Blocking in driver APIs (e.g., “wait until TX complete”).
- Mixing protocol logic (e.g., Modbus, CANopen) into the hardware driver.
- Allocating buffers dynamically inside driver (must be passed in).
- ISR printing/logging directly.
- Hidden busy-wait loops.

---

## 10) Review Checklist (Drivers)

- [ ] APIs are non-blocking, async, event-driven.
- [ ] ISR minimal; defers work via queue/notify.
- [ ] DMA buffers aligned & placed in `.dma_buf`.
- [ ] Error codes unified; retries in task context, not ISR.
- [ ] Access serialized with mutex (if required).
- [ ] Event enum documented; all states covered.
- [ ] Driver README includes init, usage, error handling, concurrency model.
- [ ] Tests include loopback, fault injection, stress.

---

## 11) CI/Lint Gates

- Fail build if:

  - Blocking calls (`while(!flag);`) appear in drivers.
  - Dynamic alloc (`malloc`, `free`) used inside driver.
  - `printf`/logging macros appear in ISR functions.
  - Driver files exceed max ISR time budget (measured by trace).

---

## 12) Example Pattern

**UART TX (async)**

```c
// Application code
drv_uart_write_async(UART1, buf, len, DRV_TIMEOUT_MS);

// ISR
void UART1_IRQHandler(void) {
    BaseType_t hpw = pdFALSE;
    if (LL_USART_IsActiveFlag_TC(UART1)) {
        LL_USART_ClearFlag_TC(UART1);
        xTaskNotifyFromISR(uart_task_h, EVT_UART_TX_DONE, eSetBits, &hpw);
    }
    portYIELD_FROM_ISR(hpw);
}

// Driver task
static void uart_task(void *arg) {
    for (;;) {
        uint32_t ev;
        xTaskNotifyWait(0, UINT32_MAX, &ev, portMAX_DELAY);
        if (ev & EVT_UART_TX_DONE) handle_tx_done();
        if (ev & EVT_UART_RX_READY) handle_rx_ready();
    }
}
```

---

[« Previous](<./Interrupts_(ISR).md>) | [Index](./README.md) | [Next »](./Power_Management.md)
