# FreeRTOS Task Design Template

This template should be completed for each task in the system before implementation begins. It serves as both a design document and a reference for code reviews.

---

## TASK DESIGN DOCUMENT

### Document Control

| Field            | Value                                           |
| ---------------- | ----------------------------------------------- |
| Task Name        | [e.g., SensorManager, MQTTPublisher]            |
| Document Version | [e.g., 1.0]                                     |
| Author           | [Name]                                          |
| Date Created     | [YYYY-MM-DD]                                    |
| Last Updated     | [YYYY-MM-DD]                                    |
| Reviewer(s)      | [Names]                                         |
| Status           | [Draft / Under Review / Approved / Implemented] |

---

## 1. TASK OVERVIEW

### 1.1 Purpose

**Brief description (1-2 sentences):**

> [What does this task do? Why does the system need it?]

> Example: "The SensorManager task is responsible for periodically sampling the temperature and pressure sensors, performing basic filtering, and publishing processed data to other tasks."

### 1.2 Functional Requirements

**List all functional requirements this task must fulfill:**

- [ ] REQ-001: Sample sensor every 100ms with ±5ms accuracy
- [ ] REQ-002: Apply moving average filter with window size of 10
- [ ] REQ-003: Publish filtered data to data queue
- [ ] REQ-004: Detect sensor fault conditions
- [ ] [Add more requirements...]

### 1.3 Safety/Critical Requirements

**For automotive/medical devices - list safety-critical aspects:**

- [ ] SAFE-001: Must detect sensor disconnect within 500ms
- [ ] SAFE-002: Must enter safe state if filtering fails
- [ ] SAFE-003: Must not block higher priority safety tasks
- [ ] [Add safety requirements...]

---

## 2. TASK CONFIGURATION

### 2.1 Basic Parameters

```c
/* Task Configuration */
#define TASK_[NAME]_PRIORITY        (tskIDLE_PRIORITY + X)  // Priority level (0-N)
#define TASK_[NAME]_STACK_SIZE      (configMINIMAL_STACK_SIZE * X)  // Words
#define TASK_[NAME]_NAME            "[TaskName]"
#define TASK_[NAME]_PERIOD_MS       (100)  // If periodic

/* Task Handle */
TaskHandle_t xTaskHandle[Name] = NULL;
```

### 2.2 Priority Justification

**Why this priority level?**

> [Explain priority choice relative to other tasks]
> Example: "Priority 3 (medium) because sensor sampling has real-time requirements but is less critical than safety watchdog (priority 5) and more critical than UI updates (priority 1)."

**Worst-case response time required:** [X ms]

**Measured/Expected response time:** [Y ms]

### 2.3 Stack Size Justification

**Calculation basis:**

- Local variables: [X bytes]
- Function call depth: [Y levels × Z bytes per level]
- Library calls: [Maximum stack usage]
- ISR nesting: [If applicable]
- **Total calculated:** [X bytes]
- **Allocated (with safety margin):** [X bytes × 1.5 = Y bytes]

**Stack monitoring during development:**

- [ ] Enabled `uxTaskGetStackHighWaterMark()`
- [ ] Maximum usage observed: [X bytes / Y bytes = Z%]

---

## 3. TASK BEHAVIOR

### 3.1 Task Type

**Select one:**

- [ ] **Periodic:** Runs at fixed intervals (e.g., every 100ms)
- [ ] **Event-driven:** Blocks waiting for events (queue, semaphore, notification)
- [ ] **Continuous:** Runs continuously with minimal blocking
- [ ] **Hybrid:** Combination of periodic and event-driven

### 3.2 State Machine

**Does this task implement a state machine?**

- [ ] Yes → Complete section 3.2.1
- [ ] No → Skip to section 3.3

#### 3.2.1 State Diagram

```
[Draw ASCII or reference external diagram]

Example:
    ┌─────────────┐
    │    INIT     │
    └──────┬──────┘
           │
           ↓
    ┌─────────────┐     Error      ┌─────────────┐
    │   RUNNING   │───────────────→│    ERROR    │
    └──────┬──────┘                └──────┬──────┘
           │                              │
           │ Suspend                      │ Reset
           ↓                              ↓
    ┌─────────────┐                ┌─────────────┐
    │  SUSPENDED  │                │    INIT     │
    └─────────────┘                └─────────────┘
```

#### 3.2.2 State Descriptions

| State     | Description           | Entry Condition | Exit Condition |
| --------- | --------------------- | --------------- | -------------- |
| INIT      | Initializing hardware | Task starts     | Hardware ready |
| RUNNING   | Normal operation      | Init complete   | Error detected |
| ERROR     | Fault condition       | Sensor failure  | Reset command  |
| SUSPENDED | Low power mode        | Suspend request | Resume request |

### 3.3 Task Pseudo-code

```c
void vTask[Name](void *pvParameters)
{
    /* Local variables */
    TickType_t xLastWakeTime;
    [DataType] xData;

    /* Initialization */
    xLastWakeTime = xTaskGetTickCount();
    [Initialize hardware/peripherals]
    [Initialize local state]

    /* Infinite loop */
    for(;;)
    {
        /* Wait for period/event */
        [vTaskDelayUntil() / xQueueReceive() / etc.]

        /* Main processing */
        [Step 1: Read inputs]
        [Step 2: Process data]
        [Step 3: Update outputs]
        [Step 4: Error checking]

        /* Health monitoring */
        [Update watchdog counter]
    }
}
```

### 3.4 Timing Analysis

| Metric                               | Value          | Notes                          |
| ------------------------------------ | -------------- | ------------------------------ |
| **Period (if periodic)**             | [X ms]         | Fixed interval                 |
| **Deadline**                         | [Y ms]         | Must complete within this time |
| **Worst-case execution time (WCET)** | [Z ms]         | Measured with profiling        |
| **Average execution time**           | [A ms]         | Typical case                   |
| **Jitter tolerance**                 | [±B ms]        | Acceptable timing variation    |
| **CPU utilization**                  | [(Z/X) × 100%] | Percentage of CPU time         |

**Timing verification method:**

- [ ] Logic analyzer measurements
- [ ] GPIO toggle + oscilloscope
- [ ] FreeRTOS runtime stats
- [ ] Segger SystemView

---

## 4. INTER-TASK COMMUNICATION

### 4.1 Input Interfaces

**What does this task receive from other tasks/ISRs?**

| Source       | Mechanism           | Data Type             | Max Rate  | Queue/Semaphore Handle |
| ------------ | ------------------- | --------------------- | --------- | ---------------------- |
| ISR_Timer    | Direct Notification | uint32_t notification | 100 Hz    | N/A                    |
| Task_Config  | Queue               | config_t struct       | On-demand | xQueueConfig           |
| Task_Control | Event Group         | Control flags         | As needed | xEventGroupControl     |

**Example detail for a queue input:**

```c
/* Queue: Sensor configuration updates */
QueueHandle_t xQueueSensorConfig;

typedef struct {
    uint8_t sensorID;
    uint16_t samplingRate;
    bool enableFilter;
} SensorConfig_t;

#define QUEUE_SENSOR_CONFIG_LENGTH    (5)
#define QUEUE_SENSOR_CONFIG_ITEM_SIZE (sizeof(SensorConfig_t))
```

### 4.2 Output Interfaces

**What does this task send to other tasks?**

| Destination   | Mechanism           | Data Type      | Max Rate | Queue/Semaphore Handle |
| ------------- | ------------------- | -------------- | -------- | ---------------------- |
| Task_MQTT     | Queue               | sensor_data_t  | 10 Hz    | xQueueSensorData       |
| Task_Display  | Queue               | display_msg_t  | 2 Hz     | xQueueDisplayUpdate    |
| Task_Watchdog | Direct Notification | Heartbeat flag | 1 Hz     | N/A                    |

**Example detail for a queue output:**

```c
/* Queue: Processed sensor data */
QueueHandle_t xQueueSensorData;

typedef struct {
    uint32_t timestamp;
    float temperature;
    float pressure;
    uint8_t status;
} SensorData_t;

#define QUEUE_SENSOR_DATA_LENGTH    (10)
#define QUEUE_SENSOR_DATA_ITEM_SIZE (sizeof(SensorData_t))

/* Blocking behavior */
#define SENSOR_DATA_QUEUE_SEND_TIMEOUT_MS    (100)
```

### 4.3 Shared Resources

**What shared resources does this task access?**

| Resource        | Type            | Protection Mechanism | Other Tasks Accessing | Max Hold Time |
| --------------- | --------------- | -------------------- | --------------------- | ------------- |
| SPI Bus 1       | Hardware        | Mutex: xMutexSPI1    | Task_TFT, Task_Flash  | 5 ms          |
| CalibrationData | Global struct   | Mutex: xMutexCalib   | Task_Config           | 1 ms          |
| ErrorLog        | Circular buffer | Semaphore: xSemLog   | Multiple tasks        | <1 ms         |

**Mutex usage example:**

```c
/* Accessing SPI bus */
if(xSemaphoreTake(xMutexSPI1, pdMS_TO_TICKS(SPI_MUTEX_TIMEOUT_MS)) == pdTRUE)
{
    /* Perform SPI transaction */
    [SPI read/write operations]

    xSemaphoreGive(xMutexSPI1);
}
else
{
    /* Handle timeout - mutex not acquired */
    [Error handling]
}
```

### 4.4 Synchronization Requirements

**Does this task need to synchronize with others?**

- [ ] Must wait for multiple events before proceeding
- [ ] Must signal multiple tasks simultaneously
- [ ] Must synchronize with ISR
- [ ] Other: [Describe]

**Synchronization mechanism:**

> [Describe event groups, barriers, or custom synchronization]

---

## 5. ERROR HANDLING

### 5.1 Error Scenarios

**List all possible error conditions:**

| Error Code         | Condition                | Detection Method   | Recovery Action       | Severity |
| ------------------ | ------------------------ | ------------------ | --------------------- | -------- |
| ERR_SENSOR_TIMEOUT | Sensor not responding    | I2C timeout        | Retry 3x, then report | High     |
| ERR_INVALID_DATA   | CRC check failed         | CRC mismatch       | Discard sample        | Medium   |
| ERR_QUEUE_FULL     | Output queue full        | xQueueSend() fails | Drop oldest data      | Low      |
| ERR_MEMORY         | Memory allocation failed | NULL pointer       | Enter safe state      | Critical |

### 5.2 Error Reporting

**How are errors reported?**

- [ ] Error logging to system log
- [ ] Error queue to monitoring task
- [ ] Direct notification to supervisor task
- [ ] LED indication
- [ ] MQTT alert message
- [ ] Other: [Specify]

**Error reporting code example:**

```c
typedef enum {
    ERROR_NONE = 0,
    ERROR_SENSOR_TIMEOUT,
    ERROR_INVALID_DATA,
    ERROR_QUEUE_FULL,
    ERROR_MEMORY
} ErrorCode_t;

void vReportError(ErrorCode_t eErrorCode, const char *pcDescription)
{
    ErrorReport_t xErrorReport;
    xErrorReport.eCode = eErrorCode;
    xErrorReport.ulTimestamp = xTaskGetTickCount();
    strncpy(xErrorReport.pcDescription, pcDescription, MAX_ERROR_DESC_LEN);

    xQueueSend(xQueueErrorLog, &xErrorReport, 0);
}
```

### 5.3 Watchdog Integration

**How does this task participate in system watchdog?**

- [ ] Sends periodic heartbeat (every [X] ms)
- [ ] Increments shared counter
- [ ] Direct notification to watchdog task
- [ ] Not monitored by watchdog

**Heartbeat implementation:**

```c
/* Every iteration or every N iterations */
[Task code]

/* Send heartbeat */
ulTaskNotifyGive(xTaskHandleWatchdog);
```

---

## 6. RESOURCE USAGE

### 6.1 Memory Footprint

| Resource               | Static  | Dynamic | Total           | Notes                      |
| ---------------------- | ------- | ------- | --------------- | -------------------------- |
| **Task stack**         | X bytes | -       | X bytes         | Allocated at creation      |
| **Task control block** | Y bytes | -       | Y bytes         | FreeRTOS overhead          |
| **Global variables**   | Z bytes | -       | Z bytes         | Shared data structures     |
| **Heap allocation**    | -       | A bytes | A bytes         | If dynamic allocation used |
| **Queue storage**      | B bytes | -       | B bytes         | Queue length × item size   |
| **Total**              | X+Y+Z+B | A       | **Total** bytes |                            |

### 6.2 CPU Utilization

**Expected CPU usage:**

- **Best case:** [X%] - Idle most of the time
- **Average case:** [Y%] - Normal operation
- **Worst case:** [Z%] - Maximum processing load

**Measurement method:**

```c
/* Using FreeRTOS runtime stats */
configGENERATE_RUN_TIME_STATS = 1

/* Calculated as: (Task runtime / Total runtime) × 100% */
```

### 6.3 Power Impact

**Power consumption characteristics:**

- [ ] Task can enter blocked state (allows CPU sleep)
- [ ] Task requires continuous peripheral operation
- [ ] Peripherals can be powered down during idle
- [ ] Estimated power contribution: [X mW]

---

## 7. DEPENDENCIES

### 7.1 Hardware Dependencies

**What hardware does this task interact with?**

- [ ] **GPIO:** [Pin numbers, purpose]
- [ ] **I2C:** [Bus number, slave addresses]
- [ ] **SPI:** [Bus number, CS pins]
- [ ] **UART:** [Port number, baud rate]
- [ ] **Timer:** [Timer instance, frequency]
- [ ] **ADC:** [Channel numbers]
- [ ] **DMA:** [Channel assignments]
- [ ] **Other:** [Specify]

### 7.2 Software Dependencies

**What software components does this task require?**

| Component      | Version | Purpose              |
| -------------- | ------- | -------------------- |
| FreeRTOS       | v10.x.x | RTOS kernel          |
| HAL Driver     | v1.x.x  | Hardware abstraction |
| Sensor Library | v2.x.x  | Sensor communication |
| Math Library   | v1.x.x  | Signal processing    |

### 7.3 Task Dependencies

**What other tasks must exist for this task to function?**

**Dependency graph:**

```
    Task_Init
        ↓
    Task_[This]  ←──→  Task_MQTT
        ↓
    Task_Display
```

**Startup sequence:**

1. Task_Init must complete initialization first
2. This task can start after [condition]
3. This task must be ready before Task_Display starts

---

## 8. TESTING STRATEGY

### 8.1 Unit Testing

**How will individual functions be tested?**

- [ ] **Test framework:** [Unity, CMock, CppUTest]
- [ ] **Mock dependencies:** [Which interfaces to mock]
- [ ] **Code coverage target:** [X%]

**Key test cases:**

```c
/* Example test cases */
void test_SensorRead_ValidData(void);
void test_SensorRead_Timeout(void);
void test_FilterAlgorithm_EdgeCases(void);
void test_QueueSend_FullQueue(void);
```

### 8.2 Integration Testing

**How will task integration be verified?**

- [ ] Verify queue communication with producer/consumer tasks
- [ ] Test mutex contention scenarios
- [ ] Validate timing under load
- [ ] Test error propagation

### 8.3 Performance Testing

**Performance benchmarks:**

- [ ] Measure worst-case execution time (WCET)
- [ ] Verify deadline compliance
- [ ] Stack usage high-water mark
- [ ] Queue utilization statistics

**Test tools:**

- [ ] Segger SystemView for visualization
- [ ] Logic analyzer for timing
- [ ] FreeRTOS trace hooks
- [ ] Custom profiling code

### 8.4 Stress Testing

**Stress test scenarios:**

- [ ] Continuous operation for [X] hours
- [ ] Maximum message rate on all queues
- [ ] Simulated error injection
- [ ] Low memory conditions
- [ ] Peripheral failures

---

## 9. CODE IMPLEMENTATION

### 9.1 File Structure

```
project/
├── tasks/
│   ├── task_[name].h          // Public interface
│   ├── task_[name].c          // Implementation
│   └── task_[name]_private.h  // Private definitions (if needed)
├── config/
│   └── task_config.h          // Task configuration parameters
```

### 9.2 Header File Template

```c
/**
 * @file task_[name].h
 * @brief [Brief description]
 * @author [Name]
 * @date [Date]
 */

#ifndef TASK_[NAME]_H
#define TASK_[NAME]_H

#include "FreeRTOS.h"
#include "task.h"
#include "queue.h"

/* Task Configuration */
#define TASK_[NAME]_PRIORITY        (tskIDLE_PRIORITY + X)
#define TASK_[NAME]_STACK_SIZE      (configMINIMAL_STACK_SIZE * X)
#define TASK_[NAME]_NAME            "[TaskName]"

/* Public Data Types */
typedef struct {
    /* Define task-specific data structures */
} [Name]Data_t;

/* Public Function Prototypes */
/**
 * @brief Creates and initializes the [Name] task
 * @return pdPASS if successful, pdFAIL otherwise
 */
BaseType_t xTask[Name]Create(void);

/**
 * @brief Task entry point function
 * @param pvParameters Pointer to task parameters
 */
void vTask[Name](void *pvParameters);

/* Public Queue/Semaphore Handles */
extern QueueHandle_t xQueue[Name]Input;
extern QueueHandle_t xQueue[Name]Output;

#endif /* TASK_[NAME]_H */
```

### 9.3 Implementation File Template

```c
/**
 * @file task_[name].c
 * @brief [Brief description]
 * @author [Name]
 * @date [Date]
 */

#include "task_[name].h"
#include "[other includes]"

/* Private Defines */
#define [NAME]_TIMEOUT_MS    (100)

/* Private Types */
typedef enum {
    STATE_INIT,
    STATE_RUNNING,
    STATE_ERROR
} [Name]State_t;

/* Private Variables */
static [Name]State_t eCurrentState = STATE_INIT;
static TaskHandle_t xTaskHandle[Name] = NULL;

/* Public Queue Handles */
QueueHandle_t xQueue[Name]Input = NULL;
QueueHandle_t xQueue[Name]Output = NULL;

/* Private Function Prototypes */
static void prvInitialize(void);
static void prvProcessData([Name]Data_t *pxData);
static void prvHandleError(ErrorCode_t eError);

/**
 * @brief Creates and initializes the [Name] task
 * @return pdPASS if successful, pdFAIL otherwise
 */
BaseType_t xTask[Name]Create(void)
{
    BaseType_t xReturn = pdFAIL;

    /* Create queues */
    xQueue[Name]Input = xQueueCreate(QUEUE_LENGTH, sizeof([Type]));
    xQueue[Name]Output = xQueueCreate(QUEUE_LENGTH, sizeof([Type]));

    if((xQueue[Name]Input != NULL) && (xQueue[Name]Output != NULL))
    {
        /* Create task */
        xReturn = xTaskCreate(
            vTask[Name],
            TASK_[NAME]_NAME,
            TASK_[NAME]_STACK_SIZE,
            NULL,
            TASK_[NAME]_PRIORITY,
            &xTaskHandle[Name]
        );
    }

    return xReturn;
}

/**
 * @brief Task entry point function
 * @param pvParameters Pointer to task parameters (unused)
 */
void vTask[Name](void *pvParameters)
{
    TickType_t xLastWakeTime;
    [Name]Data_t xData;

    /* Remove compiler warning about unused parameter */
    (void)pvParameters;

    /* Initialize */
    prvInitialize();
    xLastWakeTime = xTaskGetTickCount();

    /* Task infinite loop */
    for(;;)
    {
        /* Wait for period or event */
        vTaskDelayUntil(&xLastWakeTime, pdMS_TO_TICKS(TASK_PERIOD_MS));

        /* Receive input data */
        if(xQueueReceive(xQueue[Name]Input, &xData, 0) == pdTRUE)
        {
            /* Process data */
            prvProcessData(&xData);

            /* Send output */
            xQueueSend(xQueue[Name]Output, &xData, pdMS_TO_TICKS(100));
        }

        /* Health monitoring */
        [Watchdog update code]

        /* Stack usage check (debug only) */
        #if (configCHECK_FOR_STACK_OVERFLOW > 0)
        UBaseType_t uxHighWaterMark = uxTaskGetStackHighWaterMark(NULL);
        /* Log or assert if too low */
        #endif
    }
}

/**
 * @brief Initialize hardware and state
 */
static void prvInitialize(void)
{
    /* Hardware initialization */
    [Hardware setup code]

    /* State initialization */
    eCurrentState = STATE_RUNNING;
}

/**
 * @brief Process incoming data
 * @param pxData Pointer to data structure
 */
static void prvProcessData([Name]Data_t *pxData)
{
    /* Data processing logic */
    [Processing code]
}

/**
 * @brief Handle error conditions
 * @param eError Error code
 */
static void prvHandleError(ErrorCode_t eError)
{
    /* Error handling logic */
    [Error handling code]

    /* Report error */
    vReportError(eError, "Task [Name] error");
}
```

---

## 10. DOCUMENTATION & MAINTENANCE

### 10.1 Inline Documentation Requirements

- [ ] Doxygen comments for all public functions
- [ ] Complex algorithm explanations
- [ ] State machine documentation
- [ ] Timing-critical section annotations

### 10.2 External Documentation

**Additional documents to maintain:**

- [ ] Sequence diagrams for inter-task communication
- [ ] Timing diagrams for periodic operations
- [ ] State transition tables
- [ ] Test reports and coverage data

### 10.3 Known Issues / Limitations

**Document any known limitations:**

1. [Issue #1]: [Description and workaround]
2. [Issue #2]: [Description and planned fix]

### 10.4 Future Enhancements

**Planned improvements:**

1. [Enhancement #1]: [Description and priority]
2. [Enhancement #2]: [Description and priority]

---

## 11. REVIEW & APPROVAL

### 11.1 Design Review Checklist

- [ ] Task purpose and requirements clearly defined
- [ ] Priority and timing justified
- [ ] Stack size adequate with margin
- [ ] Inter-task communication mechanisms appropriate
- [ ] Error handling comprehensive
- [ ] Resource usage acceptable
- [ ] No potential deadlocks or priority inversions
- [ ] MISRA C compliance verified (if applicable)
- [ ] Safety requirements addressed
- [ ] Testing strategy defined

### 11.2 Code Review Checklist

- [ ] Code matches design document
- [ ] Naming conventions followed
- [ ] All error paths handled
- [ ] No blocking calls in critical sections
- [ ] Mutexes properly paired (take/give)
- [ ] No memory leaks
- [ ] Static analysis clean
- [ ] Unit tests pass
- [ ] Integration tests pass

### 11.3 Approval Signatures

| Role                              | Name | Signature | Date |
| --------------------------------- | ---- | --------- | ---- |
| **Designer**                      |      |           |      |
| **Code Reviewer**                 |      |           |      |
| **Team Lead**                     |      |           |      |
| **Safety Engineer** (if critical) |      |           |      |

---

## REVISION HISTORY

| Version | Date       | Author | Changes                  |
| ------- | ---------- | ------ | ------------------------ |
| 1.0     | YYYY-MM-DD | [Name] | Initial creation         |
| 1.1     | YYYY-MM-DD | [Name] | [Description of changes] |
