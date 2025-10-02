[« Previous](./Testing_CI_Gates.md) | [Index](./README.md) | [Next »](./Debug_Interfaces.md)

---

# Firmware Coding Standard — Style & Documentation (FreeRTOS)

## 1) Purpose

Ensure all firmware code is consistent, readable, and maintainable. Define conventions for naming, formatting, and documenting FreeRTOS-based firmware so developers can quickly understand and modify the system.

---

## 2) Principles

- **Consistency beats cleverness**: Follow the standard, not personal preference.
- **Self-documenting code**: Names should describe purpose; comments explain why, not what.
- **One style across all modules**: Tasks, ISRs, drivers, and HALs follow the same rules.

---

## 3) Naming Conventions

- **Tasks**: `task_<name>` (e.g., `task_comms`, `task_logger`).
- **ISRs**: `<Peripheral>_IRQHandler` or `ISR_<name>` (aligned with vendor HAL).
- **Queues/Semaphores/Event Groups**: `q_<name>`, `sem_<name>`, `evt_<name>`.
- **Mutexes**: `mtx_<name>`.
- **Static buffers/TCBs**: `<name>_stack`, `<name>_tcb`.
- **Enums**: `ENUM_TYPE_VALUE` (all caps for values).
- **Constants**: `kConstantName`.
- **Macros**: `MACRO_NAME` (all caps).
- **Files**: `module_subsystem.c`, `module_subsystem.h`.

---

## 4) Formatting

- Indentation: 4 spaces, no tabs.
- Line length: ≤ 100 chars.
- Braces:

  ```c
  if (x) {
      do_something();
  } else {
      handle_error();
  }
  ```

- Functions:

  - One purpose per function, ≤ 80 lines.
  - Parameter list split if long.

---

## 5) Comments & Documentation

- **Task headers**: Each task must have a header comment block:

  ```c
  /**
   * @brief   Communication task
   * @period  10 ms
   * @prio    High
   * @stack   512 words
   * @desc    Handles UART comms with external device.
   */
  ```

- **Functions**: Use Doxygen style:

  ```c
  /**
   * @brief Send data over UART
   * @param buf   Pointer to TX buffer
   * @param len   Number of bytes
   * @return FW_OK on success, FW_ERR_TIMEOUT on timeout
   */
  fw_status_t drv_uart_send(const uint8_t *buf, size_t len);
  ```

- **Files**: Top-of-file block describing module purpose and dependencies.

---

## 6) Documentation Deliverables

- **MEMORY_MAP.md**: RAM/Flash layout, DMA buffers, retention regions.
- **TASKS.md**: List of all tasks, stack size, priority, purpose.
- **ISR_PRIORITIES.md**: Table of NVIC priorities, sources, timing budgets.
- **TIMERS.md**: All FreeRTOS software timers with purpose and period.
- **ERRORS.md**: Error codes and their meaning.
- **README per driver/module**: Init, API, concurrency model, error handling.

---

## 7) Doxygen & API Docs

- Doxygen configuration checked into repo.
- All public APIs must be documented with parameters and return values.
- Generate HTML/PDF docs as part of CI pipeline.

---

## 8) Anti-Patterns

- Abbreviated names without context (`t1`, `x`, `data123`).
- Comments that just repeat code (`i++ // increment i`).
- TODOs without issue IDs.
- Mixing camelCase and snake_case.
- No header comment for tasks or ISRs.

---

## 9) Review Checklist (Style & Docs)

- [ ] Naming conventions followed for tasks, ISRs, IPC objects.
- [ ] Task headers include period, priority, stack, description.
- [ ] Functions documented with Doxygen.
- [ ] Files have module-level description.
- [ ] Docs updated (`TASKS.md`, `ISR_PRIORITIES.md`, etc.).
- [ ] Line length, indent, brace style consistent.

---

## 10) CI/Lint Gates

- Fail build if:

  - Naming convention mismatch (`task_`, `q_`, etc.).
  - Missing Doxygen comments on public functions.
  - Lines > 100 chars.
  - TODO without issue reference.
  - Tabs instead of spaces.

---

## 11) Example Patterns

**Task header**

```c
/**
 * @brief   Logger task
 * @period  100 ms
 * @prio    Low
 * @stack   512 words
 * @desc    Periodically flushes logs to UART.
 */
static void task_logger(void *arg);
```

**Queue declaration**

```c
static StaticQueue_t q_comms_tcb;
static uint8_t q_comms_storage[QUEUE_LEN * sizeof(msg_t)];
static QueueHandle_t q_comms;
```

**Driver README excerpt**

```
Driver: UART
Provides async RX/TX with DMA and ISR fallback.
Concurrency: Single writer, single reader.
Error handling: Returns FW_ERR_TIMEOUT on TX timeout, FW_ERR_HW on DMA error.
```

---

[« Previous](./Testing_CI_Gates.md) | [Index](./README.md) | [Next »](./Debug_Interfaces.md)
