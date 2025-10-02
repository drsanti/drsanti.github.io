[« Previous](./Watchdog_Startup_and_Shutdown.md) | [Index](./index.md) | [Next »](./Style_Documentation.md)

---

# Firmware Coding Standard — Testing & CI Gates (FreeRTOS)

## 1) Purpose

Define rules for testing FreeRTOS-based firmware and enforcing automated CI checks. Ensure regressions are caught early, code quality remains high, and releases are provably stable.

---

## 2) Principles

* **Test early, test often**: Unit tests at module level, integration tests at subsystem level, HIL (hardware-in-loop) for full validation.
* **Automate checks**: All commits must pass CI gates before merging.
* **Reproducibility**: Builds and tests must be deterministic across environments.
* **Shift-left**: Fault injection, watchdog, and resource stress tests done during development, not post-release.

---

## 3) Levels of Testing

* **Unit Tests** (PC-hosted or simulator):

  * Validate drivers, IPC primitives, math libraries.
  * Use mocks for hardware dependencies.
* **Integration Tests** (on hardware or simulator):

  * Validate RTOS + drivers interaction (queues, tasks, ISRs).
  * Include power cycles, reset recovery, OTA update simulation.
* **System/HIL Tests**:

  * Run full application on target hardware.
  * Verify performance, jitter, watchdog resets, telemetry integrity.

---

## 4) CI Gates

Every PR/build must pass these gates before merge/release:

1. **Build & Lint**

   * Build for all targets/configs.
   * Lint (MISRA-C or equivalent ruleset).
   * Check for forbidden APIs (`malloc`, `printf`, non-ISR-safe RTOS calls).

2. **Unit Test Execution**

   * Run on PC-hosted test framework.
   * Must achieve coverage target (e.g., 80% line coverage).

3. **Static Analysis**

   * Run tools like Cppcheck, Clang Static Analyzer.
   * No unreviewed warnings allowed.

4. **Resource Budget Checks**

   * Enforce max flash/RAM usage.
   * Verify stack sizes and heap usage.

5. **Runtime Sim Tests**

   * Run app in QEMU/simulator with scripted events.
   * Verify system boots, tasks start, watchdog kicks.

6. **HIL Smoke Tests** (nightly or gated):

   * Deploy to real hardware, run basic comms, logging, and OTA cycle.
   * Capture power consumption, jitter, reset cause logs.

---

## 5) Fault Injection Testing

* Simulate memory alloc failures (`pvPortMalloc` returns NULL).
* Inject ISR storm (high-frequency interrupts).
* Induce task starvation (lock up queue).
* Test watchdog expiry and reset recovery.

---

## 6) Code Coverage & Metrics

* Unit tests: ≥80% line coverage, ≥70% branch coverage.
* Critical modules (schedulers, IPC, safety drivers): aim for 100%.
* CI reports coverage deltas per PR.

---

## 7) Anti-Patterns

* Manual-only testing without automation.
* Ignoring failed unit tests.
* Allowing warnings in CI “just this time”.
* Relying on debug builds for release testing.
* Skipping watchdog/fault handling tests.

---

## 8) Review Checklist (Testing/CI)

* [ ] Unit tests exist for all drivers and RTOS wrappers.
* [ ] Integration tests cover IPC, timing, power, OTA, reset.
* [ ] Fault injection tests simulate errors (alloc, ISR storm, watchdog).
* [ ] All CI gates enabled and enforced (no bypass).
* [ ] Coverage reports reviewed for critical modules.
* [ ] HIL tests verify watchdog, logging, OTA on hardware.

---

## 9) CI/Lint Gates

* Fail build if:

  * Coverage regression below threshold.
  * Lint/static analysis warnings not whitelisted.
  * Forbidden functions used (`malloc`, `printf`, blocking in ISR).
  * Flash/RAM usage exceeds budget.
  * No unit test results uploaded.

---

## 10) Example CI Pipeline

```yaml
stages:
  - build
  - lint
  - unit-test
  - analysis
  - sim
  - hil

build:
  script: make all

lint:
  script: make lint

unit-test:
  script: make test

analysis:
  script: make static-analysis

sim:
  script: make run-sim

hil:
  script: make hil-smoke
  when: nightly
```

---

[« Previous](./Watchdog_Startup_and_Shutdown.md) | [Index](./index.md) | [Next »](./Style_Documentation.md)

