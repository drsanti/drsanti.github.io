[« Previous](./Static_Allocation.md) | [Index](./index.md) | [Next »](./Resource_Budgets.md)

---

# Firmware Coding Standard — Memory & Linker Sections (FreeRTOS)

## 1) Purpose

Define enforceable rules for memory usage, section placement, DMA/cache safety, and stack/heap policies to ensure determinism and hardware compatibility.

---

## 2) Principles

* **Predictable layout**: Every buffer, stack, and control block has a known address range.
* **Static > dynamic**: Prefer static allocation (see Static Allocation standard).
* **Right RAM for the job**: Place objects in the memory region that matches latency, retention, and DMA needs.
* **Cache-safe design**: Always consider CPU cache vs. DMA coherence.

---

## 3) Memory Segments & Usage Rules

* **ITCM/DTCM (tightly coupled RAM)**

  * Code/data that must run at low latency.
  * ISR data structures, real-time task stacks, scheduler structures.
* **SRAM (general purpose)**

  * Most control blocks, queues, application data.
* **AXI/External RAM**

  * Large buffers (e.g., video, audio, file caches).
  * Must measure latency if used in RT-critical path.
* **Retention RAM / Backup domain**

  * Critical state for low-power resume (RTC state, small logs).

---

## 4) Linker & Section Rules

* Maintain a single **linker script under version control**.
* Define named sections for critical objects:

  * `.rtos_tasks`, `.rtos_queues`, `.rtos_buffers` → all RTOS control blocks.
  * `.dma_buf` → DMA-safe buffers (non-cacheable).
  * `.noinit` → variables that survive reset.
* Document section purpose in `MEMORY_MAP.md`.

---

## 5) DMA & Cache Safety

* DMA buffers must be **aligned to cache line size** (commonly 32/64 bytes).
* Allocate DMA buffers in dedicated section (`.dma_buf`) mapped to non-cacheable memory.
* If cacheable memory is used:

  * **Before DMA TX**: clean (writeback) cache lines.
  * **After DMA RX**: invalidate cache lines before reading.
* Never pass stack-allocated buffers to DMA (stack reuse risk).

---

## 6) Stacks

* **Per-task stacks** created with `xTaskCreateStatic()` and placed in `.rtos_stacks`.
* Stack size = measured minimum + 20% margin.
* Monitor with `uxTaskGetStackHighWaterMark()` during bring-up.
* Large local buffers **forbidden** on task stack; use static global/shared buffers instead.

---

## 7) Heaps

* If `configSUPPORT_DYNAMIC_ALLOCATION = 0` → no heap at runtime (preferred).
* If dynamic alloc allowed (init only):

  * Use a **single FreeRTOS heap scheme** (heap_4.c or heap_5.c).
  * Define heap region(s) in `.heap`.
  * All `pvPortMalloc` failures must trigger `vApplicationMallocFailedHook()`.

---

## 8) Alignment & Types

* All shared structs must be aligned to natural width of largest member.
* Use `__attribute__((aligned(N)))` or compiler pragmas as needed.
* For cross-task or DMA-shared buffers, add `volatile` to signal memory visibility.

---

## 9) Memory Protection (if MPU present)

* Define separate MPU regions for:

  * Code (read/exec),
  * RTOS kernel data (read-only for tasks),
  * Task stacks (no exec, task-private).
* Deny access to unused regions to catch wild pointers.

---

## 10) Anti-Patterns

* Placing DMA buffers in default `.bss` or `.data` without cache policy.
* Using stack buffers for DMA or IPC.
* Mixing heap schemes or dynamic alloc in ISR.
* Overprovisioning stacks/queues without measurement.
* Hardcoding addresses instead of linker symbols.

---

## 11) Review Checklist (Memory)

* [ ] All RTOS objects created with static APIs.
* [ ] Task stacks measured and placed in `.rtos_stacks`.
* [ ] DMA buffers aligned and in `.dma_buf` (non-cacheable or flush/invalidate added).
* [ ] No large local buffers on task stacks.
* [ ] No `malloc/free` in steady-state; if init-only, justification logged.
* [ ] Section placement documented in `MEMORY_MAP.md`.
* [ ] Cache maintenance policy validated for each DMA driver.

---

## 12) CI/Lint Gates

* Fail build if:

  * Dynamic alloc APIs (`malloc`, `free`, `xTaskCreate`) appear outside init modules.
  * `DMA_…` functions called with non-aligned buffers.
  * Symbols in `.bss` exceed threshold (indicates misplaced buffers).
  * Local arrays >1 KB detected in tasks (stack bloat).

---

## 13) Example Snippets

**DMA-safe buffer (non-cacheable)**

```c
__attribute__((section(".dma_buf"), aligned(32)))
static uint8_t dma_rx_buf[DMA_RX_LEN];
```

**Static task stack in dedicated section**

```c
__attribute__((section(".rtos_stacks")))
static StackType_t task_stack[STACK_SZ];
static StaticTask_t task_tcb;
```

**Linker fragment**

```ld
.dma_buf (NOLOAD) : ALIGN(32) {
    *(.dma_buf)
} >RAM_D1
```

---

[« Previous](./Static_Allocation.md) | [Index](./index.md) | [Next »](./Resource_Budgets.md)

