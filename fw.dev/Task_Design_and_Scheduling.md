[« Previous](./Resource_Budgets.md) | [Index](./index.md) | [Next »](./Task_Synchronization.md)

---

# Firmware Coding Standard — Task Design & Scheduling (FreeRTOS)

## 1) Purpose

Define enforceable rules for designing tasks, assigning priorities, and scheduling work so that timing is deterministic and failures are visible early.

---

## 2) Principles

* **One responsibility per task.** Each task owns a clear role and a narrow set of inputs/outputs.
* **Event-driven, not polling.** Tasks block on queues/notifications; no spin loops.
* **Priorities reflect deadlines.** Faster/harder-deadline work runs at higher priority.
* **Bounded everything.** Bounded execution time, bounded queue depth, bounded waits.

---

## 3) Task Lifecycle Rules

1. **Creation**

   * Use `xTaskCreateStatic()` (see Static Allocation standard).
   * Name required and descriptive: `task_sensor_reader`, `task_comm_tx`.
   * Creation happens during system init only.

2. **Startup & Warm-up**

   * Tasks must validate dependencies (drivers ready, queues created) before entering steady state.
   * Log readiness (single line at `INFO`).

3. **Shutdown**

   * Support a **cancel/stop signal** (notification bit or event flag).
   * Drain/flush with bounded timeout; log on forced termination.

---

## 4) Priority & Scheduling Policy

* **Priority assignment method**

  * Order tasks by **period** (shorter period → higher priority) and **deadline criticality**.
  * Document the final priority table in `SCHED.md` (module owner + rationale).
* **Priority inversion**

  * Protect shared resources with **mutexes** (priority inheritance enabled). Never hold a mutex across a blocking call.
* **Starvation prevention**

  * Long CPU work must be chunked or offloaded to a lower-priority worker; ensure the **Idle** task always runs.
* **SMP (if applicable)**

  * Use **affinity** only when required for cache/latency; document any pinning.

---

## 5) Periodic Work

* **Use `vTaskDelayUntil()`** for periodic tasks to minimize jitter.
* **Budgeting**

  * Define **WCET** (worst-case execution time) and verify during bring-up.
  * Rule of thumb: `WCET < 0.4 * period` (40% CPU budget ceiling per periodic task).
* **Overrun handling**

  * If an iteration overruns its period, log once (rate-limited) and skip catch-up loops.

**Template**

```c
static void task_comm_tick(void *arg)
{
    const TickType_t period = pdMS_TO_TICKS(5);
    TickType_t next = xTaskGetTickCount();

    for (;;) {
        next += period;
        do_comm_iteration();  // bounded; no blocking on mutexes here
        vTaskDelayUntil(&next, period);
    }
}
```

---

## 6) Blocking & Timeouts

* **All waits must be finite.** Use `pdMS_TO_TICKS(x)`. `portMAX_DELAY` requires explicit justification in code.
* **No blocking while holding a mutex.**
* **ISR rules** are covered in the ISR Standard; from tasks, prefer queue/notification waits over `vTaskDelay()`.

---

## 7) Stack Sizing & Telemetry

* Initial stack = measured need + safety margin (typically +20%).
* **Mandatory instrumentation**

  * Log `uxTaskGetStackHighWaterMark()` after system settles (burn-in scenario).
  * CI/HIL tests must assert **no stack watermark violations**.
* For large local buffers, prefer static or shared buffers to avoid deep stack bursts.

---

## 8) CPU Load, Jitter & Latency

* Measure **average and peak** CPU load; keep average <70%.
* Track per-task run time and worst scheduling latency (trace hooks/SystemView).
* Set jitter budgets for periodic tasks and verify during integration tests.

---

## 9) Communication & Ownership

* Each task’s inputs/outputs are defined and versioned:

  * **Inputs**: which queues/notifications event groups it waits on.
  * **Outputs**: which queues/notifications it signals.
* Ownership of each queue/semaphore is documented; producers/consumers listed.

---

## 10) Error Paths

* On any timeout, the task must choose one of: **retry**, **drop**, **escalate**, or **reset** (and log which).
* Repeated timeouts must trigger backoff or escalation (single place policy per subsystem).

---

## 11) Anti-Patterns (Do Not Do)

* Busy loops with `vTaskDelay(1)` as “scheduling.”
* Multi-purpose “god” tasks that do unrelated work.
* Deep call chains with hidden blocking while holding locks.
* Creating/destroying tasks at runtime for normal operations.
* Passing stack pointers through queues unless explicitly guaranteed safe.

---

## 12) Review Checklist (Scheduling)

* [ ] Task has single responsibility and clear IOs (queues/notifications)
* [ ] Priority set with documented rate/deadline rationale
* [ ] Uses `vTaskDelayUntil()` for periodic work (if periodic)
* [ ] All waits are bounded; no blocking while holding mutexes
* [ ] WCET measured; within budget; no catch-up loops
* [ ] Stack HWM measured and margins adjusted
* [ ] Idle task can run; no starvation observed
* [ ] Inputs/outputs and ownership documented in `SCHED.md`

---

## 13) CI/Lint Gates

* Fail build if:

  * Dynamic task creators appear (`xTaskCreate(` without `Static`).
  * Infinite waits detected on queues/semaphores (regex rules).
  * `vTaskDelay()` used in periodic tasks instead of `vTaskDelayUntil()`.
  * Mutex held across any blocking API (heuristic grep plus review tag).
* Size map diff check: reject PRs that inflate stacks >15% without rationale.

---

## 14) Helper Patterns

**Cooperative chunking for heavy work**

```c
while (work_left() && (ticks_elapsed(start) < budget_ticks)) {
    do_small_unit();
}
// If not finished, notify self/worker queue to continue next slice.
```

**Watchdog-friendly heartbeat**

```c
// Call at the end of each successful period or after N iterations
watchdog_kick();
```

---

[« Previous](./Resource_Budgets.md) | [Index](./index.md) | [Next »](./Task_Synchronization.md)
