# FreeRTOS Static Objects Guide

This guide covers the implementation and best practices for using static FreeRTOS objects in medical device firmware. Static objects provide deterministic memory allocation, eliminate heap fragmentation, and ensure predictable behavior required for safety-critical applications.

## **📚 RELATED GUIDES**

For detailed implementation examples and usage patterns, see these specialized guides:

- **[FreeRTOS Queue Guide](freertos-queue-guide.md)** - Comprehensive queue implementation with producer-consumer patterns, ISR communication, and command-response patterns
- **[FreeRTOS Event Group Guide](freertos-event-group-guide.md)** - Event group usage patterns, task synchronization, and state management
- **[FreeRTOS Task Design Template](freertos-task-design-template.md)** - Task design patterns and templates
- **[FreeRTOS Naming Convention Guide](freertos-naming-convention-guide.md)** - Consistent naming conventions

---

## **1. OVERVIEW**

### 1.1 Why Use Static Objects?

**Benefits for Medical Devices:**

- ✅ **Deterministic Memory Usage:** No heap fragmentation or allocation failures
- ✅ **Predictable Timing:** No variable allocation delays
- ✅ **Memory Safety:** Bounded memory usage prevents stack overflow
- ✅ **MISRA C Compliance:** Avoids dynamic memory allocation (Rule 20.4)
- ✅ **IEC 62304 Compliance:** Required for Class C medical devices
- ✅ **Real-time Guarantees:** No garbage collection or heap management overhead

**When to Use Static Objects:**

- ✅ **Always** for safety-critical medical devices
- ✅ **Always** for real-time systems with timing constraints
- ✅ **Always** for systems with limited memory
- ✅ **Recommended** for all production firmware

---

## **2. STATIC OBJECT TYPES**

### 2.1 Static Queues

**Function:** `xQueueCreateStatic()`

```c
/* Static queue storage */
static uint8_t ucQueueStorage[QUEUE_LENGTH * sizeof(QueueItem_t)];
static StaticQueue_t xQueueBuffer;

/* Queue handle */
QueueHandle_t xQueueSensorData = NULL;

/**
 * @brief Create static queue for sensor data
 * @return pdPASS if successful, pdFAIL otherwise
 */
BaseType_t xCreateStaticQueue(void)
{
    xQueueSensorData = xQueueCreateStatic(
        QUEUE_LENGTH,                    // Queue length
        sizeof(SensorData_t),            // Item size
        ucQueueStorage,                  // Storage buffer
        &xQueueBuffer                    // Queue control block
    );
    
    return (xQueueSensorData != NULL) ? pdPASS : pdFAIL;
}
```

**📋 For comprehensive queue examples and usage patterns, see: [FreeRTOS Queue Guide](freertos-queue-guide.md)**

**Memory Layout:**
```c
/* Calculate required memory */
#define QUEUE_LENGTH                    (10)
#define QUEUE_ITEM_SIZE                (sizeof(SensorData_t))
#define QUEUE_STORAGE_SIZE             (QUEUE_LENGTH * QUEUE_ITEM_SIZE)
#define QUEUE_CONTROL_BLOCK_SIZE       (sizeof(StaticQueue_t))

/* Total memory per queue */
#define TOTAL_QUEUE_MEMORY             (QUEUE_STORAGE_SIZE + QUEUE_CONTROL_BLOCK_SIZE)
```

### 2.2 Static Semaphores

**Function:** `xSemaphoreCreateBinaryStatic()`, `xSemaphoreCreateMutexStatic()`, `xSemaphoreCreateCountingStatic()`

```c
/* Binary semaphore */
static StaticSemaphore_t xBinarySemBuffer;
SemaphoreHandle_t xSemaphoreDataReady = NULL;

/* Mutex semaphore */
static StaticSemaphore_t xMutexBuffer;
SemaphoreHandle_t xMutexSPI = NULL;

/* Counting semaphore */
static StaticSemaphore_t xCountingSemBuffer;
SemaphoreHandle_t xSemaphoreResourceCount = NULL;

/**
 * @brief Create all static semaphores
 * @return pdPASS if all successful, pdFAIL otherwise
 */
BaseType_t xCreateStaticSemaphores(void)
{
    BaseType_t xResult = pdPASS;
    
    /* Create binary semaphore */
    xSemaphoreDataReady = xSemaphoreCreateBinaryStatic(&xBinarySemBuffer);
    if(xSemaphoreDataReady == NULL) {
        xResult = pdFAIL;
    }
    
    /* Create mutex */
    xMutexSPI = xSemaphoreCreateMutexStatic(&xMutexBuffer);
    if(xMutexSPI == NULL) {
        xResult = pdFAIL;
    }
    
    /* Create counting semaphore (max 5 resources) */
    xSemaphoreResourceCount = xSemaphoreCreateCountingStatic(
        5,                              // Maximum count
        5,                              // Initial count
        &xCountingSemBuffer
    );
    if(xSemaphoreResourceCount == NULL) {
        xResult = pdFAIL;
    }
    
    return xResult;
}
```

### 2.3 Static Tasks

**Function:** `xTaskCreateStatic()`

```c
/* Task stack and control block */
static StackType_t ucTaskStack[TASK_STACK_SIZE];
static StaticTask_t xTaskBuffer;

/* Task handle */
TaskHandle_t xTaskHandleSensor = NULL;

/**
 * @brief Create static task for sensor management
 * @return pdPASS if successful, pdFAIL otherwise
 */
BaseType_t xCreateStaticTask(void)
{
    xTaskHandleSensor = xTaskCreateStatic(
        vTaskSensorManager,             // Task function
        "SensorMgr",                    // Task name
        TASK_STACK_SIZE,                // Stack size (words)
        NULL,                           // Parameters
        TASK_PRIORITY,                  // Priority
        ucTaskStack,                    // Stack buffer
        &xTaskBuffer                    // Task control block
    );
    
    return (xTaskHandleSensor != NULL) ? pdPASS : pdFAIL;
}
```

### 2.4 Static Timers

**Function:** `xTimerCreateStatic()`

```c
/* Timer control block */
static StaticTimer_t xTimerBuffer;

/* Timer handle */
TimerHandle_t xTimerHeartbeat = NULL;

/**
 * @brief Create static timer for heartbeat
 * @return pdPASS if successful, pdFAIL otherwise
 */
BaseType_t xCreateStaticTimer(void)
{
    xTimerHeartbeat = xTimerCreateStatic(
        "Heartbeat",                    // Timer name
        pdMS_TO_TICKS(1000),           // Period (1 second)
        pdTRUE,                         // Auto-reload
        NULL,                           // Timer ID
        vTimerHeartbeatCallback,        // Callback function
        &xTimerBuffer                   // Timer control block
    );
    
    return (xTimerHeartbeat != NULL) ? pdPASS : pdFAIL;
}
```

### 2.5 Static Event Groups

**Function:** `xEventGroupCreateStatic()`

```c
/* Event group control block */
static StaticEventGroup_t xEventGroupBuffer;

/* Event group handle */
EventGroupHandle_t xEventGroupSystem = NULL;

/**
 * @brief Create static event group
 * @return pdPASS if successful, pdFAIL otherwise
 */
BaseType_t xCreateStaticEventGroup(void)
{
    xEventGroupSystem = xEventGroupCreateStatic(&xEventGroupBuffer);
    
    return (xEventGroupSystem != NULL) ? pdPASS : pdFAIL;
}
```

**📋 For comprehensive event group examples and usage patterns, see: [FreeRTOS Event Group Guide](freertos-event-group-guide.md)**

---

## **3. MEMORY MANAGEMENT**

### 3.1 Memory Calculation

**Complete Memory Budget:**

```c
/* ========== QUEUE MEMORY ========== */
#define QUEUE_SENSOR_LENGTH             (10)
#define QUEUE_SENSOR_ITEM_SIZE          (sizeof(SensorData_t))
#define QUEUE_SENSOR_STORAGE_SIZE       (QUEUE_SENSOR_LENGTH * QUEUE_SENSOR_ITEM_SIZE)
#define QUEUE_SENSOR_CB_SIZE            (sizeof(StaticQueue_t))

#define QUEUE_CONFIG_LENGTH             (5)
#define QUEUE_CONFIG_ITEM_SIZE          (sizeof(ConfigData_t))
#define QUEUE_CONFIG_STORAGE_SIZE       (QUEUE_CONFIG_LENGTH * QUEUE_CONFIG_ITEM_SIZE)
#define QUEUE_CONFIG_CB_SIZE            (sizeof(StaticQueue_t))

/* ========== SEMAPHORE MEMORY ========== */
#define SEMAPHORE_BINARY_CB_SIZE        (sizeof(StaticSemaphore_t))
#define SEMAPHORE_MUTEX_CB_SIZE         (sizeof(StaticSemaphore_t))
#define SEMAPHORE_COUNTING_CB_SIZE      (sizeof(StaticSemaphore_t))

/* ========== TASK MEMORY ========== */
#define TASK_SENSOR_STACK_SIZE          (configMINIMAL_STACK_SIZE * 2)
#define TASK_SENSOR_CB_SIZE             (sizeof(StaticTask_t))

#define TASK_DISPLAY_STACK_SIZE         (configMINIMAL_STACK_SIZE * 3)
#define TASK_DISPLAY_CB_SIZE            (sizeof(StaticTask_t))

/* ========== TIMER MEMORY ========== */
#define TIMER_HEARTBEAT_CB_SIZE         (sizeof(StaticTimer_t))
#define TIMER_WATCHDOG_CB_SIZE          (sizeof(StaticTimer_t))

/* ========== EVENT GROUP MEMORY ========== */
#define EVENT_GROUP_SYSTEM_CB_SIZE      (sizeof(StaticEventGroup_t))

/* ========== TOTAL MEMORY CALCULATION ========== */
#define TOTAL_QUEUE_MEMORY              (QUEUE_SENSOR_STORAGE_SIZE + QUEUE_SENSOR_CB_SIZE + \
                                         QUEUE_CONFIG_STORAGE_SIZE + QUEUE_CONFIG_CB_SIZE)

#define TOTAL_SEMAPHORE_MEMORY          (SEMAPHORE_BINARY_CB_SIZE + \
                                         SEMAPHORE_MUTEX_CB_SIZE + \
                                         SEMAPHORE_COUNTING_CB_SIZE)

#define TOTAL_TASK_MEMORY               (TASK_SENSOR_STACK_SIZE + TASK_SENSOR_CB_SIZE + \
                                         TASK_DISPLAY_STACK_SIZE + TASK_DISPLAY_CB_SIZE)

#define TOTAL_TIMER_MEMORY              (TIMER_HEARTBEAT_CB_SIZE + TIMER_WATCHDOG_CB_SIZE)

#define TOTAL_EVENT_GROUP_MEMORY        (EVENT_GROUP_SYSTEM_CB_SIZE)

#define TOTAL_STATIC_OBJECTS_MEMORY     (TOTAL_QUEUE_MEMORY + TOTAL_SEMAPHORE_MEMORY + \
                                         TOTAL_TASK_MEMORY + TOTAL_TIMER_MEMORY + \
                                         TOTAL_EVENT_GROUP_MEMORY)
```

### 3.2 Memory Layout

**Static Memory Allocation:**

```c
/* ========== STATIC STORAGE ARRAYS ========== */

/* Queue storage */
static uint8_t ucQueueSensorStorage[QUEUE_SENSOR_STORAGE_SIZE];
static uint8_t ucQueueConfigStorage[QUEUE_CONFIG_STORAGE_SIZE];

/* Queue control blocks */
static StaticQueue_t xQueueSensorBuffer;
static StaticQueue_t xQueueConfigBuffer;

/* Semaphore control blocks */
static StaticSemaphore_t xBinarySemBuffer;
static StaticSemaphore_t xMutexBuffer;
static StaticSemaphore_t xCountingSemBuffer;

/* Task stacks */
static StackType_t ucTaskSensorStack[TASK_SENSOR_STACK_SIZE];
static StackType_t ucTaskDisplayStack[TASK_DISPLAY_STACK_SIZE];

/* Task control blocks */
static StaticTask_t xTaskSensorBuffer;
static StaticTask_t xTaskDisplayBuffer;

/* Timer control blocks */
static StaticTimer_t xTimerHeartbeatBuffer;
static StaticTimer_t xTimerWatchdogBuffer;

/* Event group control block */
static StaticEventGroup_t xEventGroupSystemBuffer;
```

### 3.3 Memory Verification

**Runtime Memory Verification:**

```c
/**
 * @brief Verify all static objects were created successfully
 * @return pdPASS if all objects valid, pdFAIL otherwise
 */
BaseType_t xVerifyStaticObjects(void)
{
    BaseType_t xResult = pdPASS;
    
    /* Verify queues */
    if(xQueueSensorData == NULL) {
        vLogError("Sensor queue creation failed");
        xResult = pdFAIL;
    }
    
    if(xQueueConfigData == NULL) {
        vLogError("Config queue creation failed");
        xResult = pdFAIL;
    }
    
    /* Verify semaphores */
    if(xSemaphoreDataReady == NULL) {
        vLogError("Data ready semaphore creation failed");
        xResult = pdFAIL;
    }
    
    if(xMutexSPI == NULL) {
        vLogError("SPI mutex creation failed");
        xResult = pdFAIL;
    }
    
    /* Verify tasks */
    if(xTaskHandleSensor == NULL) {
        vLogError("Sensor task creation failed");
        xResult = pdFAIL;
    }
    
    if(xTaskHandleDisplay == NULL) {
        vLogError("Display task creation failed");
        xResult = pdFAIL;
    }
    
    /* Verify timers */
    if(xTimerHeartbeat == NULL) {
        vLogError("Heartbeat timer creation failed");
        xResult = pdFAIL;
    }
    
    /* Verify event groups */
    if(xEventGroupSystem == NULL) {
        vLogError("System event group creation failed");
        xResult = pdFAIL;
    }
    
    return xResult;
}
```

---

## **4. INITIALIZATION SEQUENCE**

### 4.1 System Initialization

**Complete Initialization Function:**

```c
/**
 * @brief Initialize all static FreeRTOS objects
 * @return pdPASS if all successful, pdFAIL otherwise
 */
BaseType_t xInitializeStaticObjects(void)
{
    BaseType_t xResult = pdPASS;
    
    /* Step 1: Create semaphores first (needed by other objects) */
    if(xCreateStaticSemaphores() != pdPASS) {
        vLogError("Semaphore creation failed");
        xResult = pdFAIL;
    }
    
    /* Step 2: Create event groups */
    if(xCreateStaticEventGroup() != pdPASS) {
        vLogError("Event group creation failed");
        xResult = pdFAIL;
    }
    
    /* Step 3: Create queues */
    if(xCreateStaticQueues() != pdPASS) {
        vLogError("Queue creation failed");
        xResult = pdFAIL;
    }
    
    /* Step 4: Create timers */
    if(xCreateStaticTimers() != pdPASS) {
        vLogError("Timer creation failed");
        xResult = pdFAIL;
    }
    
    /* Step 5: Create tasks (last, as they may use other objects) */
    if(xCreateStaticTasks() != pdPASS) {
        vLogError("Task creation failed");
        xResult = pdFAIL;
    }
    
    /* Step 6: Verify all objects created successfully */
    if(xVerifyStaticObjects() != pdPASS) {
        vLogError("Static object verification failed");
        xResult = pdFAIL;
    }
    
    /* Step 7: Start timers */
    if(xResult == pdPASS) {
        if(xTimerStart(xTimerHeartbeat, 0) != pdPASS) {
            vLogError("Failed to start heartbeat timer");
            xResult = pdFAIL;
        }
    }
    
    return xResult;
}
```

### 4.2 Error Handling

**Robust Initialization with Cleanup:**

```c
/**
 * @brief Initialize static objects with proper error handling
 * @return pdPASS if successful, pdFAIL otherwise
 */
BaseType_t xInitializeStaticObjectsSafe(void)
{
    BaseType_t xResult = pdPASS;
    
    /* Initialize all objects */
    xResult = xInitializeStaticObjects();
    
    /* If initialization failed, perform cleanup */
    if(xResult != pdPASS) {
        vLogError("Static object initialization failed - performing cleanup");
        vCleanupStaticObjects();
    }
    
    return xResult;
}

/**
 * @brief Cleanup static objects (for error recovery)
 */
void vCleanupStaticObjects(void)
{
    /* Delete tasks */
    if(xTaskHandleSensor != NULL) {
        vTaskDelete(xTaskHandleSensor);
        xTaskHandleSensor = NULL;
    }
    
    if(xTaskHandleDisplay != NULL) {
        vTaskDelete(xTaskHandleDisplay);
        xTaskHandleDisplay = NULL;
    }
    
    /* Delete timers */
    if(xTimerHeartbeat != NULL) {
        xTimerDelete(xTimerHeartbeat, 0);
        xTimerHeartbeat = NULL;
    }
    
    /* Delete queues */
    if(xQueueSensorData != NULL) {
        vQueueDelete(xQueueSensorData);
        xQueueSensorData = NULL;
    }
    
    /* Delete semaphores */
    if(xSemaphoreDataReady != NULL) {
        vSemaphoreDelete(xSemaphoreDataReady);
        xSemaphoreDataReady = NULL;
    }
    
    if(xMutexSPI != NULL) {
        vSemaphoreDelete(xMutexSPI);
        xMutexSPI = NULL;
    }
    
    /* Delete event groups */
    if(xEventGroupSystem != NULL) {
        vEventGroupDelete(xEventGroupSystem);
        xEventGroupSystem = NULL;
    }
}
```

---

## **5. MEDICAL DEVICE CONSIDERATIONS**

### 5.1 Safety Requirements

**IEC 62304 Compliance:**

```c
/* ========== SAFETY-CRITICAL CONFIGURATION ========== */

/* Disable dynamic allocation completely */
#define configSUPPORT_STATIC_ALLOCATION     1
#define configSUPPORT_DYNAMIC_ALLOCATION    0

/* Enable stack overflow detection */
#define configCHECK_FOR_STACK_OVERFLOW      2

/* Enable memory allocation failure hooks */
#define configUSE_MALLOC_FAILED_HOOK        1

/* Enable idle hook for system monitoring */
#define configUSE_IDLE_HOOK                 1

/* Enable tick hook for timing verification */
#define configUSE_TICK_HOOK                 1

/* ========== STATIC ALLOCATION HOOKS ========== */

/**
 * @brief Hook called when malloc fails (should never happen with static allocation)
 */
void vApplicationMallocFailedHook(void)
{
    /* Log critical error */
    vLogCriticalError("Malloc failed - system compromised");
    
    /* Enter safe state */
    vEnterSafeState();
    
    /* Infinite loop to prevent further execution */
    for(;;) {
        vTaskDelay(pdMS_TO_TICKS(1000));
    }
}

/**
 * @brief Hook called on stack overflow
 */
void vApplicationStackOverflowHook(TaskHandle_t xTask, char *pcTaskName)
{
    /* Log critical error */
    vLogCriticalError("Stack overflow in task: %s", pcTaskName);
    
    /* Enter safe state */
    vEnterSafeState();
    
    /* Infinite loop to prevent further execution */
    for(;;) {
        vTaskDelay(pdMS_TO_TICKS(1000));
    }
}
```

### 5.2 Memory Protection

**Stack Monitoring:**

```c
/**
 * @brief Monitor task stack usage
 * @param xTaskHandle Task handle to monitor
 * @param pcTaskName Task name for logging
 */
void vMonitorTaskStack(TaskHandle_t xTaskHandle, const char *pcTaskName)
{
    UBaseType_t uxHighWaterMark;
    UBaseType_t uxStackSize;
    uint32_t ulStackUsagePercent;
    
    if(xTaskHandle != NULL) {
        uxHighWaterMark = uxTaskGetStackHighWaterMark(xTaskHandle);
        uxStackSize = uxTaskGetStackSize(xTaskHandle);
        
        /* Calculate usage percentage */
        ulStackUsagePercent = ((uxStackSize - uxHighWaterMark) * 100) / uxStackSize;
        
        /* Log stack usage */
        vLogInfo("Task %s: Stack usage %lu%% (%lu/%lu bytes)", 
                 pcTaskName, ulStackUsagePercent, 
                 (uxStackSize - uxHighWaterMark), uxStackSize);
        
        /* Warning if usage > 80% */
        if(ulStackUsagePercent > 80) {
            vLogWarning("Task %s: High stack usage %lu%%", pcTaskName, ulStackUsagePercent);
        }
        
        /* Critical if usage > 95% */
        if(ulStackUsagePercent > 95) {
            vLogCriticalError("Task %s: Critical stack usage %lu%%", pcTaskName, ulStackUsagePercent);
            vEnterSafeState();
        }
    }
}
```

### 5.3 Deterministic Behavior

**Timing Verification:**

```c
/**
 * @brief Verify system timing constraints
 */
void vVerifySystemTiming(void)
{
    TickType_t xCurrentTick;
    static TickType_t xLastTick = 0;
    TickType_t xTickDelta;
    
    xCurrentTick = xTaskGetTickCount();
    
    if(xLastTick != 0) {
        xTickDelta = xCurrentTick - xLastTick;
        
        /* Verify tick period is within expected range */
        if((xTickDelta < (configTICK_RATE_HZ - 1)) || 
           (xTickDelta > (configTICK_RATE_HZ + 1))) {
            vLogWarning("Tick timing deviation: %lu (expected: %d)", 
                        xTickDelta, configTICK_RATE_HZ);
        }
    }
    
    xLastTick = xCurrentTick;
}
```

---

## **6. COMPLETE EXAMPLE**

### 6.1 Medical Device Task Implementation

```c
/**
 * @file task_ecg_monitor.c
 * @brief ECG monitoring task with static allocation
 * @author Medical Device Team
 * @date 2024-01-15
 */

#include "FreeRTOS.h"
#include "task.h"
#include "queue.h"
#include "semphr.h"
#include "timers.h"
#include "event_groups.h"

/* ========== CONFIGURATION ========== */
#define TASK_ECG_PRIORITY               (tskIDLE_PRIORITY + 4)
#define TASK_ECG_STACK_SIZE             (configMINIMAL_STACK_SIZE * 3)
#define TASK_ECG_NAME                   "ECGMonitor"

#define ECG_QUEUE_LENGTH                (20)
#define ECG_SAMPLE_RATE_HZ              (500)
#define ECG_SAMPLE_PERIOD_MS            (1000 / ECG_SAMPLE_RATE_HZ)

/* ========== STATIC STORAGE ========== */
static uint8_t ucECGQueueStorage[ECG_QUEUE_LENGTH * sizeof(ECGData_t)];
static StaticQueue_t xECGQueueBuffer;
static StackType_t ucECGTaskStack[TASK_ECG_STACK_SIZE];
static StaticTask_t xECGTaskBuffer;

/* ========== HANDLES ========== */
static TaskHandle_t s_xTaskHandleECG = NULL;
QueueHandle_t xQueueECGData = NULL;

/* ========== PRIVATE FUNCTIONS ========== */
static void prvInitializeECGHardware(void);
static BaseType_t prvReadECGSample(ECGData_t *pxData);
static void prvProcessECGData(ECGData_t *pxData);
static void prvValidateECGData(ECGData_t *pxData);

/**
 * @brief Create ECG monitoring task with static allocation
 * @return pdPASS if successful, pdFAIL otherwise
 */
BaseType_t xTaskECGCreate(void)
{
    BaseType_t xResult = pdFAIL;
    
    /* Create static queue */
    xQueueECGData = xQueueCreateStatic(
        ECG_QUEUE_LENGTH,
        sizeof(ECGData_t),
        ucECGQueueStorage,
        &xECGQueueBuffer
    );
    
    if(xQueueECGData != NULL) {
        /* Create static task */
        s_xTaskHandleECG = xTaskCreateStatic(
            vTaskECGMonitor,
            TASK_ECG_NAME,
            TASK_ECG_STACK_SIZE,
            NULL,
            TASK_ECG_PRIORITY,
            ucECGTaskStack,
            &xECGTaskBuffer
        );
        
        if(s_xTaskHandleECG != NULL) {
            xResult = pdPASS;
        }
    }
    
    return xResult;
}

/**
 * @brief ECG monitoring task function
 * @param pvParameters Task parameters (unused)
 */
void vTaskECGMonitor(void *pvParameters)
{
    TickType_t xLastWakeTime;
    ECGData_t xECGData;
    BaseType_t xReadResult;
    
    /* Remove compiler warning */
    (void)pvParameters;
    
    /* Initialize hardware */
    prvInitializeECGHardware();
    
    /* Initialize timing */
    xLastWakeTime = xTaskGetTickCount();
    
    /* Main task loop */
    for(;;) {
        /* Wait for next sample period */
        vTaskDelayUntil(&xLastWakeTime, pdMS_TO_TICKS(ECG_SAMPLE_PERIOD_MS));
        
        /* Read ECG sample */
        xReadResult = prvReadECGSample(&xECGData);
        
        if(xReadResult == pdPASS) {
            /* Validate data */
            prvValidateECGData(&xECGData);
            
            /* Process data */
            prvProcessECGData(&xECGData);
            
            /* Send to queue */
            if(xQueueSend(xQueueECGData, &xECGData, 0) != pdPASS) {
                vLogError("ECG queue full - data lost");
            }
        }
        
        /* Monitor stack usage */
        vMonitorTaskStack(s_xTaskHandleECG, TASK_ECG_NAME);
    }
}

/**
 * @brief Initialize ECG hardware
 */
static void prvInitializeECGHardware(void)
{
    /* ADC configuration */
    /* Filter setup */
    /* Calibration */
    
    vLogInfo("ECG hardware initialized");
}

/**
 * @brief Read ECG sample from hardware
 * @param pxData Pointer to ECG data structure
 * @return pdPASS if successful, pdFAIL otherwise
 */
static BaseType_t prvReadECGSample(ECGData_t *pxData)
{
    BaseType_t xResult = pdPASS;
    
    /* Read from ADC */
    /* Apply hardware filtering */
    /* Timestamp data */
    
    pxData->ulTimestamp = xTaskGetTickCount();
    pxData->fVoltage = 1.2f;  /* Example value */
    pxData->ucQuality = ECG_QUALITY_GOOD;
    
    return xResult;
}

/**
 * @brief Process ECG data
 * @param pxData Pointer to ECG data structure
 */
static void prvProcessECGData(ECGData_t *pxData)
{
    /* Apply digital filters */
    /* Detect QRS complexes */
    /* Calculate heart rate */
    /* Detect arrhythmias */
}

/**
 * @brief Validate ECG data
 * @param pxData Pointer to ECG data structure
 */
static void prvValidateECGData(ECGData_t *pxData)
{
    /* Range checking */
    if((pxData->fVoltage < -5.0f) || (pxData->fVoltage > 5.0f)) {
        pxData->ucQuality = ECG_QUALITY_INVALID;
        vLogWarning("ECG voltage out of range: %f", pxData->fVoltage);
    }
    
    /* Rate of change checking */
    /* Noise detection */
}
```

---

## **7. TESTING & VALIDATION**

### 7.1 Memory Verification Tests

```c
/**
 * @brief Test static object memory allocation
 */
void vTestStaticObjectMemory(void)
{
    /* Verify all objects created */
    configASSERT(xQueueECGData != NULL);
    configASSERT(s_xTaskHandleECG != NULL);
    
    /* Verify memory addresses are in expected ranges */
    configASSERT((uintptr_t)ucECGQueueStorage >= (uintptr_t)&_sdata);
    configASSERT((uintptr_t)ucECGQueueStorage < (uintptr_t)&_edata);
    
    /* Verify no heap usage */
    size_t xFreeHeapSize = xPortGetFreeHeapSize();
    configASSERT(xFreeHeapSize == configTOTAL_HEAP_SIZE);
    
    vLogInfo("Static object memory test passed");
}
```

### 7.2 Timing Verification Tests

```c
/**
 * @brief Test task timing performance
 */
void vTestTaskTiming(void)
{
    TickType_t xStartTime, xEndTime, xExecutionTime;
    
    /* Measure task execution time */
    xStartTime = xTaskGetTickCount();
    
    /* Simulate task work */
    vTaskDelay(pdMS_TO_TICKS(1));
    
    xEndTime = xTaskGetTickCount();
    xExecutionTime = xEndTime - xStartTime;
    
    /* Verify timing is within expected range */
    configASSERT(xExecutionTime <= pdMS_TO_TICKS(2));
    
    vLogInfo("Task timing test passed: %lu ms", xExecutionTime);
}
```

---

## **8. BEST PRACTICES**

### 8.1 Design Guidelines

1. **Always use static allocation** for medical devices
2. **Calculate memory requirements** before implementation
3. **Verify all objects created** during initialization
4. **Monitor stack usage** continuously
5. **Use consistent naming** following FreeRTOS conventions
6. **Document memory layout** clearly
7. **Test memory boundaries** thoroughly

### 8.2 Common Pitfalls

❌ **Avoid:**
- Mixing static and dynamic allocation
- Insufficient stack size calculations
- Not verifying object creation
- Ignoring stack overflow detection
- Inadequate error handling

✅ **Do:**
- Use static allocation exclusively
- Add safety margins to stack sizes
- Verify all objects created successfully
- Enable stack overflow detection
- Implement comprehensive error handling

---

## **9. QUICK REFERENCE**

| Object Type | Static Create Function | Storage Required | Control Block |
|-------------|----------------------|------------------|---------------|
| **Queue** | `xQueueCreateStatic()` | `length × item_size` | `StaticQueue_t` |
| **Binary Semaphore** | `xSemaphoreCreateBinaryStatic()` | None | `StaticSemaphore_t` |
| **Mutex** | `xSemaphoreCreateMutexStatic()` | None | `StaticSemaphore_t` |
| **Counting Semaphore** | `xSemaphoreCreateCountingStatic()` | None | `StaticSemaphore_t` |
| **Task** | `xTaskCreateStatic()` | `stack_size × sizeof(StackType_t)` | `StaticTask_t` |
| **Timer** | `xTimerCreateStatic()` | None | `StaticTimer_t` |
| **Event Group** | `xEventGroupCreateStatic()` | None | `StaticEventGroup_t` |

---

## **10. MEDICAL DEVICE COMPLIANCE**

### 10.1 IEC 62304 Requirements

- ✅ **Class A:** Basic static allocation practices
- ✅ **Class B:** Comprehensive error handling and monitoring
- ✅ **Class C:** Full static allocation with safety mechanisms

### 10.2 FDA Guidance

- ✅ **Deterministic behavior** through static allocation
- ✅ **Predictable timing** without heap management
- ✅ **Memory safety** with bounded usage
- ✅ **Fault tolerance** with proper error handling

This guide ensures your medical device firmware meets the highest safety standards while maintaining optimal performance through static FreeRTOS object allocation.
