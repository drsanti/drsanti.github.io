# FreeRTOS Queue Guide

This guide covers comprehensive queue implementation and best practices for medical device firmware using static allocation. Queues provide reliable inter-task communication with deterministic memory usage and thread safety.

## **📚 RELATED GUIDES**

For detailed implementation examples and usage patterns, see these specialized guides:

- **[FreeRTOS Static Objects Guide](FreeRTOS%20Static%20Objects%20Guide.md)** - Static allocation patterns, memory management, and safety-critical considerations
- **[FreeRTOS Event Group Guide](FreeRTOS%20Event%20Group%20Guide.md)** - Event group usage patterns, task synchronization, and state management
- **[FreeRTOS Task Design Template](FreeRTOS%20Task%20Design%20Template.md)** - Task design patterns and templates
- **[FreeRTOS Naming Convention Guide](FreeRTOS%20Naming%20Convention%20Guide.md)** - Consistent naming conventions

---

## **1. OVERVIEW**

### 1.1 Why Use Queues?

**Benefits for Medical Devices:**

- ✅ **Reliable Communication:** Guaranteed message delivery between tasks
- ✅ **Thread Safety:** Built-in synchronization and mutual exclusion
- ✅ **Buffer Management:** Automatic handling of full/empty conditions
- ✅ **Priority Support:** High-priority messages can be prioritized
- ✅ **Timeout Control:** Configurable wait times for operations
- ✅ **Memory Safety:** Static allocation prevents heap fragmentation
- ✅ **Data Integrity:** Ensures no data loss between tasks
- ✅ **Real-time Communication:** Predictable message delivery timing
- ✅ **System Reliability:** Robust error handling and recovery
- ✅ **MISRA C Compliance:** Structured communication patterns

**When to Use Queues:**

- ✅ **Inter-task communication** (most common use case)
- ✅ **ISR to task communication** (using ISR-safe functions)
- ✅ **Task to ISR communication** (limited scenarios)
- ✅ **Data buffering** between different processing stages
- ✅ **Command/response patterns** between tasks
- ✅ **Sensor data collection** and processing
- ✅ **Alarm and warning** message handling
- ✅ **Configuration updates** and system commands

---

## **2. STATIC QUEUE IMPLEMENTATION**

### 2.1 Basic Static Queue Creation

```c
/* ========== CONFIGURATION ========== */
#define QUEUE_LENGTH                    (10)
#define QUEUE_ITEM_SIZE                (sizeof(SensorData_t))

/* ========== STATIC STORAGE ========== */
static uint8_t ucQueueStorage[QUEUE_LENGTH * QUEUE_ITEM_SIZE];
static StaticQueue_t xQueueBuffer;

/* ========== QUEUE HANDLE ========== */
QueueHandle_t xQueueSensorData = NULL;

/**
 * @brief Create static queue for sensor data
 * @return pdPASS if successful, pdFAIL otherwise
 */
BaseType_t xCreateStaticQueue(void)
{
    xQueueSensorData = xQueueCreateStatic(
        QUEUE_LENGTH,                    // Queue length
        QUEUE_ITEM_SIZE,                 // Item size
        ucQueueStorage,                  // Storage buffer
        &xQueueBuffer                    // Queue control block
    );
    
    return (xQueueSensorData != NULL) ? pdPASS : pdFAIL;
}
```

### 2.2 Multiple Queue Types

```c
/* ========== SENSOR DATA QUEUE ========== */
#define SENSOR_QUEUE_LENGTH             (20)
#define SENSOR_QUEUE_ITEM_SIZE          (sizeof(SensorData_t))

static uint8_t ucSensorQueueStorage[SENSOR_QUEUE_LENGTH * SENSOR_QUEUE_ITEM_SIZE];
static StaticQueue_t xSensorQueueBuffer;
QueueHandle_t xQueueSensorData = NULL;

/* ========== CONFIGURATION QUEUE ========== */
#define CONFIG_QUEUE_LENGTH             (5)
#define CONFIG_QUEUE_ITEM_SIZE          (sizeof(ConfigData_t))

static uint8_t ucConfigQueueStorage[CONFIG_QUEUE_LENGTH * CONFIG_QUEUE_ITEM_SIZE];
static StaticQueue_t xConfigQueueBuffer;
QueueHandle_t xQueueConfigData = NULL;

/* ========== ALARM QUEUE ========== */
#define ALARM_QUEUE_LENGTH              (10)
#define ALARM_QUEUE_ITEM_SIZE           (sizeof(AlarmData_t))

static uint8_t ucAlarmQueueStorage[ALARM_QUEUE_LENGTH * ALARM_QUEUE_ITEM_SIZE];
static StaticQueue_t xAlarmQueueBuffer;
QueueHandle_t xQueueAlarmData = NULL;

/**
 * @brief Create all static queues
 * @return pdPASS if all successful, pdFAIL otherwise
 */
BaseType_t xCreateAllStaticQueues(void)
{
    BaseType_t xResult = pdPASS;
    
    /* Create sensor data queue */
    xQueueSensorData = xQueueCreateStatic(
        SENSOR_QUEUE_LENGTH,
        SENSOR_QUEUE_ITEM_SIZE,
        ucSensorQueueStorage,
        &xSensorQueueBuffer
    );
    if(xQueueSensorData == NULL) {
        vLogError("Sensor queue creation failed");
        xResult = pdFAIL;
    }
    
    /* Create configuration queue */
    xQueueConfigData = xQueueCreateStatic(
        CONFIG_QUEUE_LENGTH,
        CONFIG_QUEUE_ITEM_SIZE,
        ucConfigQueueStorage,
        &xConfigQueueBuffer
    );
    if(xQueueConfigData == NULL) {
        vLogError("Config queue creation failed");
        xResult = pdFAIL;
    }
    
    /* Create alarm queue */
    xQueueAlarmData = xQueueCreateStatic(
        ALARM_QUEUE_LENGTH,
        ALARM_QUEUE_ITEM_SIZE,
        ucAlarmQueueStorage,
        &xAlarmQueueBuffer
    );
    if(xQueueAlarmData == NULL) {
        vLogError("Alarm queue creation failed");
        xResult = pdFAIL;
    }
    
    return xResult;
}
```

---

## **3. QUEUE CONFIGURATION AND SIZING**

### 3.1 Queue Length Sizing

**Proper Sizing Strategy:**

```c
/* ========== QUEUE LENGTH CALCULATION ========== */

/* Method 1: Based on data rate and processing time */
#define SENSOR_SAMPLE_RATE_HZ           (100)   // 100 samples/second
#define PROCESSING_TIME_MS              (50)    // 50ms processing time
#define QUEUE_SENSOR_LENGTH             (SENSOR_SAMPLE_RATE_HZ * PROCESSING_TIME_MS / 1000)

/* Method 2: Based on burst handling */
#define MAX_BURST_SIZE                  (20)    // Maximum burst of samples
#define QUEUE_SENSOR_LENGTH             (MAX_BURST_SIZE * 2)  // 2x safety margin

/* Method 3: Based on system requirements */
#define QUEUE_CRITICAL_ALARMS_LENGTH    (5)     // Critical alarms - small buffer
#define QUEUE_SENSOR_DATA_LENGTH        (10)    // Sensor data - medium buffer
#define QUEUE_LOG_MESSAGES_LENGTH       (20)    // Log messages - large buffer
```

**Sizing Guidelines:**

| Queue Type | Recommended Length | Reasoning |
|------------|-------------------|-----------|
| **Critical Alarms** | 3-5 items | Must not block, small buffer |
| **Sensor Data** | 10-20 items | Handle burst data, medium buffer |
| **Configuration** | 3-5 items | Infrequent updates, small buffer |
| **Log Messages** | 20-50 items | Non-critical, large buffer |

### 3.2 Item Size Optimization

**Memory-Efficient Structures:**

```c
/* ========== OPTIMIZED DATA STRUCTURES ========== */

/* Good: Packed structure */
typedef struct {
    uint32_t ulTimestamp;
    float fTemperature;
    float fPressure;
    uint8_t ucStatus;
    uint8_t ucSensorID;
} __attribute__((packed)) SensorData_t;  // 14 bytes

/* Good: Bit fields for flags */
typedef struct {
    uint32_t ulTimestamp;
    float fValue;
    uint8_t ucSensorID;
    uint8_t ucStatus : 4;      // 4-bit status
    uint8_t ucQuality : 2;     // 2-bit quality
    uint8_t ucReserved : 2;    // 2-bit reserved
} __attribute__((packed)) OptimizedSensorData_t;  // 12 bytes

/* Bad: Unnecessary padding */
typedef struct {
    uint32_t ulTimestamp;
    float fTemperature;
    float fPressure;
    uint8_t ucStatus;
    uint8_t ucSensorID;
    uint8_t ucPadding[2];      // Wastes 2 bytes per item
} SensorData_t;  // 16 bytes
```

**Memory Calculation:**

```c
/* ========== MEMORY REQUIREMENTS ========== */
#define QUEUE_LENGTH                    (10)
#define QUEUE_ITEM_SIZE                 (sizeof(SensorData_t))
#define QUEUE_STORAGE_SIZE              (QUEUE_LENGTH * QUEUE_ITEM_SIZE)
#define QUEUE_CB_SIZE                   (sizeof(StaticQueue_t))
#define TOTAL_QUEUE_MEMORY              (QUEUE_STORAGE_SIZE + QUEUE_CB_SIZE)

/* Example: 10 items × 14 bytes = 140 bytes storage + 80 bytes CB = 220 bytes total */
```

---

## **4. QUEUE USAGE PATTERNS**

### 4.1 Producer-Consumer Pattern

```c
/**
 * @brief Sensor data producer task
 */
void vTaskSensorProducer(void *pvParameters)
{
    SensorData_t xSensorData;
    TickType_t xLastWakeTime;
    
    /* Initialize timing */
    xLastWakeTime = xTaskGetTickCount();
    
    for(;;) {
        /* Read sensor data */
        if(xReadSensorHardware(&xSensorData) == pdPASS) {
            /* Add timestamp */
            xSensorData.ulTimestamp = xTaskGetTickCount();
            xSensorData.ucQuality = xValidateSensorData(&xSensorData);
            
            /* Send to queue with timeout */
            if(xQueueSend(xQueueSensorData, &xSensorData, pdMS_TO_TICKS(100)) != pdPASS) {
                vLogWarning("Sensor queue full - data lost");
                /* Handle queue full condition */
                vHandleQueueFull();
            } else {
                vLogDebug("Sensor data queued successfully");
            }
        }
        
        /* Wait for next sample period */
        vTaskDelayUntil(&xLastWakeTime, pdMS_TO_TICKS(10)); /* 100Hz sampling */
    }
}

/**
 * @brief Sensor data consumer task
 */
void vTaskSensorConsumer(void *pvParameters)
{
    SensorData_t xSensorData;
    
    for(;;) {
        /* Receive data from queue */
        if(xQueueReceive(xQueueSensorData, &xSensorData, pdMS_TO_TICKS(1000)) == pdPASS) {
            /* Process the sensor data */
            vProcessSensorData(&xSensorData);
            
            /* Check data quality */
            if(xSensorData.ucQuality == SENSOR_QUALITY_GOOD) {
                /* Send to processing pipeline */
                vSendToProcessingPipeline(&xSensorData);
            } else {
                vLogWarning("Poor quality sensor data received");
                vHandlePoorQualityData(&xSensorData);
            }
        } else {
            /* Timeout - no data received */
            vLogWarning("Sensor data timeout - no data received");
            vHandleDataTimeout();
        }
    }
}
```

### 4.2 ISR to Task Communication

```c
/**
 * @brief ADC conversion complete ISR
 */
void vADC_IRQHandler(void)
{
    BaseType_t xHigherPriorityTaskWoken = pdFALSE;
    SensorData_t xSensorData;
    
    /* Clear interrupt flag */
    ADC_ClearITPendingBit(ADC_IT_EOC);
    
    /* Read ADC value */
    xSensorData.fVoltage = ADC_GetConversionValue() * ADC_VOLTAGE_SCALE;
    xSensorData.ulTimestamp = xTaskGetTickCountFromISR();
    xSensorData.ucChannel = ADC_CHANNEL;
    
    /* Send to queue from ISR */
    if(xQueueSendFromISR(xQueueSensorData, &xSensorData, &xHigherPriorityTaskWoken) != pdPASS) {
        /* Queue full - handle in ISR context */
        vHandleQueueFullFromISR();
    }
    
    /* Context switch if higher priority task was woken */
    portYIELD_FROM_ISR(xHigherPriorityTaskWoken);
}

/**
 * @brief Emergency button ISR
 */
void vEXTI_IRQHandler(void)
{
    BaseType_t xHigherPriorityTaskWoken = pdFALSE;
    AlarmData_t xAlarmData;
    
    /* Clear interrupt flag */
    EXTI_ClearITPendingBit(EXTI_Line0);
    
    /* Prepare alarm data */
    xAlarmData.ucAlarmType = ALARM_EMERGENCY_BUTTON;
    xAlarmData.ulTimestamp = xTaskGetTickCountFromISR();
    xAlarmData.ucPriority = ALARM_PRIORITY_CRITICAL;
    
    /* Send alarm to queue from ISR */
    if(xQueueSendFromISR(xQueueAlarmData, &xAlarmData, &xHigherPriorityTaskWoken) != pdPASS) {
        /* Critical alarm - force queue send */
        vForceAlarmQueueSend(&xAlarmData);
    }
    
    /* Context switch if higher priority task was woken */
    portYIELD_FROM_ISR(xHigherPriorityTaskWoken);
}
```

### 4.3 Command-Response Pattern

```c
/* ========== COMMAND QUEUE ========== */
#define CMD_QUEUE_LENGTH                (8)
#define CMD_QUEUE_ITEM_SIZE             (sizeof(Command_t))

static uint8_t ucCmdQueueStorage[CMD_QUEUE_LENGTH * CMD_QUEUE_ITEM_SIZE];
static StaticQueue_t xCmdQueueBuffer;
QueueHandle_t xQueueCommands = NULL;

/* ========== RESPONSE QUEUE ========== */
#define RESP_QUEUE_LENGTH               (8)
#define RESP_QUEUE_ITEM_SIZE            (sizeof(Response_t))

static uint8_t ucRespQueueStorage[RESP_QUEUE_LENGTH * RESP_QUEUE_ITEM_SIZE];
static StaticQueue_t xRespQueueBuffer;
QueueHandle_t xQueueResponses = NULL;

/**
 * @brief Command processor task
 */
void vTaskCommandProcessor(void *pvParameters)
{
    Command_t xCommand;
    Response_t xResponse;
    
    for(;;) {
        /* Wait for command */
        if(xQueueReceive(xQueueCommands, &xCommand, portMAX_DELAY) == pdPASS) {
            /* Process command based on type */
            switch(xCommand.ucCommandType) {
                case CMD_GET_SENSOR_DATA:
                    xResponse = xProcessGetSensorData(&xCommand);
                    break;
                    
                case CMD_SET_CALIBRATION:
                    xResponse = xProcessSetCalibration(&xCommand);
                    break;
                    
                case CMD_EMERGENCY_STOP:
                    xResponse = xProcessEmergencyStop(&xCommand);
                    break;
                    
                default:
                    xResponse.ucStatus = RESP_STATUS_INVALID_CMD;
                    xResponse.ulErrorCode = ERROR_UNKNOWN_COMMAND;
                    break;
            }
            
            /* Send response back */
            if(xQueueSend(xQueueResponses, &xResponse, pdMS_TO_TICKS(100)) != pdPASS) {
                vLogError("Response queue full - command response lost");
            }
        }
    }
}

/**
 * @brief Send command and wait for response
 * @param pxCommand Command to send
 * @param pxResponse Response received
 * @param xTimeoutMs Timeout in milliseconds
 * @return pdPASS if successful, pdFAIL otherwise
 */
BaseType_t xSendCommandAndWaitResponse(Command_t *pxCommand, Response_t *pxResponse, uint32_t xTimeoutMs)
{
    BaseType_t xResult = pdFAIL;
    
    /* Send command */
    if(xQueueSend(xQueueCommands, pxCommand, pdMS_TO_TICKS(xTimeoutMs)) == pdPASS) {
        /* Wait for response */
        if(xQueueReceive(xQueueResponses, pxResponse, pdMS_TO_TICKS(xTimeoutMs)) == pdPASS) {
            xResult = pdPASS;
        } else {
            vLogError("Command response timeout");
        }
    } else {
        vLogError("Command send timeout");
    }
    
    return xResult;
}
```

---

## **5. QUEUE OPERATIONS**

### 5.1 Send Operations

**Robust Send Implementation:**

```c
/**
 * @brief Safe queue send with error handling
 * @param xQueue Queue handle
 * @param pvData Pointer to data
 * @param xTimeout Timeout in ticks
 * @return pdPASS if successful, pdFAIL otherwise
 */
BaseType_t xSafeQueueSend(QueueHandle_t xQueue, const void *pvData, TickType_t xTimeout)
{
    BaseType_t xResult;
    
    /* Parameter validation */
    if(xQueue == NULL) {
        vLogError("Queue handle is NULL");
        return pdFAIL;
    }
    
    if(pvData == NULL) {
        vLogError("Data pointer is NULL");
        return pdFAIL;
    }
    
    /* Send with timeout */
    xResult = xQueueSend(xQueue, pvData, xTimeout);
    
    /* Handle result */
    if(xResult != pdPASS) {
        vLogError("Queue send failed: timeout=%lu", xTimeout);
    }
    
    return xResult;
}
```

**Timeout Selection:**

```c
/* ========== TIMEOUT STRATEGIES ========== */

/* Critical data - block until sent */
xQueueSend(xQueueCritical, &xData, portMAX_DELAY);

/* Important data - reasonable timeout */
xQueueSend(xQueueSensor, &xData, pdMS_TO_TICKS(100));

/* Non-critical data - short timeout */
xQueueSend(xQueueLog, &xData, pdMS_TO_TICKS(10));

/* Real-time data - non-blocking */
xQueueSend(xQueueRealTime, &xData, 0);
```

### 5.2 Receive Operations

**Robust Receive Implementation:**

```c
/**
 * @brief Safe queue receive with error handling
 * @param xQueue Queue handle
 * @param pvData Pointer to receive buffer
 * @param xTimeout Timeout in ticks
 * @return pdPASS if successful, pdFAIL otherwise
 */
BaseType_t xSafeQueueReceive(QueueHandle_t xQueue, void *pvData, TickType_t xTimeout)
{
    BaseType_t xResult;
    
    /* Parameter validation */
    if(xQueue == NULL) {
        vLogError("Queue handle is NULL");
        return pdFAIL;
    }
    
    if(pvData == NULL) {
        vLogError("Receive buffer is NULL");
        return pdFAIL;
    }
    
    /* Receive with timeout */
    xResult = xQueueReceive(xQueue, pvData, xTimeout);
    
    /* Handle result */
    if(xResult != pdPASS) {
        vLogWarning("Queue receive timeout: %lu", xTimeout);
    }
    
    return xResult;
}
```

**Receive Strategies:**

```c
/* ========== RECEIVE PATTERNS ========== */

/* Pattern 1: Blocking receive for critical data */
BaseType_t xResult = xQueueReceive(xQueueCritical, &xData, portMAX_DELAY);
if(xResult == pdPASS) {
    prvProcessCriticalData(&xData);
}

/* Pattern 2: Timeout receive for sensor data */
BaseType_t xResult = xQueueReceive(xQueueSensor, &xData, pdMS_TO_TICKS(1000));
if(xResult == pdPASS) {
    prvProcessSensorData(&xData);
} else {
    vLogWarning("No sensor data received in 1 second");
}

/* Pattern 3: Non-blocking receive for optional data */
BaseType_t xResult = xQueueReceive(xQueueLog, &xData, 0);
if(xResult == pdPASS) {
    prvProcessLogMessage(&xData);
}
```

---

## **6. ADVANCED QUEUE FEATURES**

### 6.1 Queue Peek and Overwrite

```c
/**
 * @brief Peek at queue data without removing it
 * @param xQueue Queue handle
 * @param pvBuffer Buffer to receive data
 * @param xTicksToWait Timeout
 * @return pdPASS if successful, pdFAIL otherwise
 */
BaseType_t xQueuePeekData(QueueHandle_t xQueue, void *pvBuffer, TickType_t xTicksToWait)
{
    return xQueuePeek(xQueue, pvBuffer, xTicksToWait);
}

/**
 * @brief Overwrite queue data (for latest data only scenarios)
 * @param xQueue Queue handle
 * @param pvItemToQueue Data to queue
 * @return pdPASS if successful, pdFAIL otherwise
 */
BaseType_t xQueueOverwriteData(QueueHandle_t xQueue, const void *pvItemToQueue)
{
    return xQueueOverwrite(xQueue, pvItemToQueue);
}

/**
 * @brief Send data to front of queue (priority insertion)
 * @param xQueue Queue handle
 * @param pvItemToQueue Data to queue
 * @param xTicksToWait Timeout
 * @return pdPASS if successful, pdFAIL otherwise
 */
BaseType_t xQueueSendToFront(QueueHandle_t xQueue, const void *pvItemToQueue, TickType_t xTicksToWait)
{
    return xQueueSendToFront(xQueue, pvItemToQueue, xTicksToWait);
}
```

### 6.2 Queue Monitoring and Statistics

```c
/**
 * @brief Get queue status information
 * @param xQueue Queue handle
 * @param pxQueueStatus Pointer to status structure
 * @return pdPASS if successful, pdFAIL otherwise
 */
BaseType_t xGetQueueStatus(QueueHandle_t xQueue, QueueStatus_t *pxQueueStatus)
{
    if((xQueue == NULL) || (pxQueueStatus == NULL)) {
        return pdFAIL;
    }
    
    /* Get queue information */
    pxQueueStatus->uxMessagesWaiting = uxQueueMessagesWaiting(xQueue);
    pxQueueStatus->uxSpacesAvailable = uxQueueSpacesAvailable(xQueue);
    pxQueueStatus->uxQueueLength = uxQueueMessagesWaiting(xQueue) + uxQueueSpacesAvailable(xQueue);
    
    /* Calculate usage percentage */
    pxQueueStatus->ucUsagePercent = (pxQueueStatus->uxMessagesWaiting * 100) / pxQueueStatus->uxQueueLength;
    
    return pdPASS;
}

/**
 * @brief Monitor all queues and log status
 */
void vMonitorAllQueues(void)
{
    QueueStatus_t xStatus;
    
    /* Monitor sensor queue */
    if(xGetQueueStatus(xQueueSensorData, &xStatus) == pdPASS) {
        vLogInfo("Sensor Queue: %lu/%lu messages (%d%% full)", 
                 xStatus.uxMessagesWaiting, xStatus.uxQueueLength, xStatus.ucUsagePercent);
        
        if(xStatus.ucUsagePercent > 80) {
            vLogWarning("Sensor queue high usage: %d%%", xStatus.ucUsagePercent);
        }
    }
    
    /* Monitor config queue */
    if(xGetQueueStatus(xQueueConfigData, &xStatus) == pdPASS) {
        vLogInfo("Config Queue: %lu/%lu messages (%d%% full)", 
                 xStatus.uxMessagesWaiting, xStatus.uxQueueLength, xStatus.ucUsagePercent);
    }
    
    /* Monitor alarm queue */
    if(xGetQueueStatus(xQueueAlarmData, &xStatus) == pdPASS) {
        vLogInfo("Alarm Queue: %lu/%lu messages (%d%% full)", 
                 xStatus.uxMessagesWaiting, xStatus.uxQueueLength, xStatus.ucUsagePercent);
        
        if(xStatus.ucUsagePercent > 50) {
            vLogWarning("Alarm queue usage high: %d%%", xStatus.ucUsagePercent);
        }
    }
}
```

---

## **7. QUEUE MANAGEMENT**

### 7.1 Queue Full Handling

**Queue Full Strategies:**

```c
/* ========== QUEUE FULL STRATEGIES ========== */

typedef enum {
    QUEUE_FULL_DROP_OLDEST,
    QUEUE_FULL_DROP_NEWEST,
    QUEUE_FULL_BLOCK,
    QUEUE_FULL_ERROR
} QueueFullStrategy_t;

/**
 * @brief Send to queue with full queue handling
 * @param xQueue Queue handle
 * @param pvData Data to send
 * @param eStrategy Strategy for full queue
 * @return pdPASS if successful, pdFAIL otherwise
 */
BaseType_t xSendToQueueWithStrategy(QueueHandle_t xQueue, const void *pvData, QueueFullStrategy_t eStrategy)
{
    BaseType_t xResult = xQueueSend(xQueue, pvData, 0);
    
    if(xResult != pdPASS) {
        /* Queue full - implement strategy */
        switch(eStrategy) {
            case QUEUE_FULL_DROP_OLDEST:
                /* Remove oldest item and add new one */
                xQueueReceive(xQueue, NULL, 0);
                xResult = xQueueSend(xQueue, pvData, 0);
                vLogWarning("Queue full - dropped oldest item");
                break;
                
            case QUEUE_FULL_DROP_NEWEST:
                /* Keep existing data, discard new */
                vLogWarning("Queue full - dropped newest item");
                break;
                
            case QUEUE_FULL_BLOCK:
                /* Block until space available */
                xResult = xQueueSend(xQueue, pvData, portMAX_DELAY);
                break;
                
            case QUEUE_FULL_ERROR:
                /* Report error */
                vLogError("Queue full - data lost");
                break;
        }
    }
    
    return xResult;
}
```

### 7.2 Queue Health Monitoring

**Health Monitoring:**

```c
/**
 * @brief Monitor queue health and usage
 * @param xQueue Queue handle
 * @param pcQueueName Queue name for logging
 */
void vMonitorQueueHealth(QueueHandle_t xQueue, const char *pcQueueName)
{
    UBaseType_t uxMessagesWaiting;
    UBaseType_t uxSpacesAvailable;
    UBaseType_t uxQueueLength;
    uint32_t ulUsagePercent;
    
    if(xQueue == NULL) {
        return;
    }
    
    /* Get queue statistics */
    uxMessagesWaiting = uxQueueMessagesWaiting(xQueue);
    uxSpacesAvailable = uxQueueSpacesAvailable(xQueue);
    uxQueueLength = uxQueueGetQueueLength(xQueue);
    
    /* Calculate usage percentage */
    ulUsagePercent = (uxMessagesWaiting * 100) / uxQueueLength;
    
    /* Log queue status */
    vLogInfo("Queue %s: %lu/%lu items (%lu%% used)", 
             pcQueueName, uxMessagesWaiting, uxQueueLength, ulUsagePercent);
    
    /* Check for high usage */
    if(ulUsagePercent > 80) {
        vLogWarning("Queue %s: High usage %lu%%", pcQueueName, ulUsagePercent);
    }
    
    /* Check for full queue */
    if(uxSpacesAvailable == 0) {
        vLogError("Queue %s: Full!", pcQueueName);
    }
    
    /* Check for empty queue */
    if(uxMessagesWaiting == 0) {
        vLogInfo("Queue %s: Empty", pcQueueName);
    }
}
```

---

## **8. ERROR HANDLING**

### 8.1 Comprehensive Error Handling

**Error Types and Responses:**

```c
/* ========== QUEUE ERROR HANDLING ========== */

typedef enum {
    QUEUE_ERROR_NONE = 0,
    QUEUE_ERROR_NULL_HANDLE,
    QUEUE_ERROR_NULL_DATA,
    QUEUE_ERROR_SEND_TIMEOUT,
    QUEUE_ERROR_RECEIVE_TIMEOUT,
    QUEUE_ERROR_QUEUE_FULL,
    QUEUE_ERROR_QUEUE_EMPTY,
    QUEUE_ERROR_INVALID_SIZE
} QueueError_t;

/**
 * @brief Handle queue errors
 * @param eError Error type
 * @param pcContext Error context
 */
void vHandleQueueError(QueueError_t eError, const char *pcContext)
{
    switch(eError) {
        case QUEUE_ERROR_NULL_HANDLE:
            vLogCriticalError("Queue handle is NULL in %s", pcContext);
            vEnterSafeState();
            break;
            
        case QUEUE_ERROR_NULL_DATA:
            vLogError("Data pointer is NULL in %s", pcContext);
            break;
            
        case QUEUE_ERROR_SEND_TIMEOUT:
            vLogWarning("Queue send timeout in %s", pcContext);
            break;
            
        case QUEUE_ERROR_RECEIVE_TIMEOUT:
            vLogWarning("Queue receive timeout in %s", pcContext);
            break;
            
        case QUEUE_ERROR_QUEUE_FULL:
            vLogError("Queue full in %s", pcContext);
            break;
            
        case QUEUE_ERROR_QUEUE_EMPTY:
            vLogInfo("Queue empty in %s", pcContext);
            break;
            
        default:
            vLogError("Unknown queue error %d in %s", eError, pcContext);
            break;
    }
}
```

### 8.2 Recovery Strategies

**Queue Recovery:**

```c
/**
 * @brief Recover from queue errors
 * @param xQueue Queue handle
 * @param eError Error type
 * @return pdPASS if recovered, pdFAIL otherwise
 */
BaseType_t xRecoverFromQueueError(QueueHandle_t xQueue, QueueError_t eError)
{
    BaseType_t xResult = pdPASS;
    
    switch(eError) {
        case QUEUE_ERROR_QUEUE_FULL:
            /* Clear queue and reset */
            while(xQueueReceive(xQueue, NULL, 0) == pdPASS) {
                /* Clear all items */
            }
            vLogInfo("Queue cleared due to full condition");
            break;
            
        case QUEUE_ERROR_SEND_TIMEOUT:
            /* Retry with longer timeout */
            vTaskDelay(pdMS_TO_TICKS(10));
            break;
            
        case QUEUE_ERROR_RECEIVE_TIMEOUT:
            /* Continue with default processing */
            break;
            
        default:
            xResult = pdFAIL;
            break;
    }
    
    return xResult;
}
```

---

## **9. MEDICAL DEVICE CONSIDERATIONS**

### 9.1 Safety-Critical Queue Design

```c
/* ========== SAFETY-CRITICAL QUEUE CONFIGURATION ========== */

/* Ensure adequate queue sizes for worst-case scenarios */
#define SENSOR_QUEUE_LENGTH             (50)    /* 5 seconds at 10Hz */
#define ALARM_QUEUE_LENGTH              (20)    /* Multiple alarms can occur rapidly */
#define CONFIG_QUEUE_LENGTH             (10)    /* Configuration changes are infrequent */

/* Timeout values for safety-critical operations */
#define QUEUE_SEND_TIMEOUT_MS           (100)   /* Short timeout for real-time data */
#define QUEUE_RECEIVE_TIMEOUT_MS        (1000)  /* Longer timeout for processing */
#define QUEUE_ISR_TIMEOUT_MS            (0)     /* No timeout in ISR context */

/**
 * @brief Safety-critical queue send with error handling
 * @param xQueue Queue handle
 * @param pvItemToQueue Data to send
 * @param ucQueueType Queue type for error reporting
 * @return pdPASS if successful, pdFAIL otherwise
 */
BaseType_t xSafeQueueSend(QueueHandle_t xQueue, const void *pvItemToQueue, uint8_t ucQueueType)
{
    BaseType_t xResult;
    
    xResult = xQueueSend(xQueue, pvItemToQueue, pdMS_TO_TICKS(QUEUE_SEND_TIMEOUT_MS));
    
    if(xResult != pdPASS) {
        /* Log critical error */
        vLogCriticalError("Queue send failed - type: %d", ucQueueType);
        
        /* Handle queue full condition based on queue type */
        switch(ucQueueType) {
            case QUEUE_TYPE_SENSOR:
                /* Sensor data loss - may require recalibration */
                vHandleSensorDataLoss();
                break;
                
            case QUEUE_TYPE_ALARM:
                /* Alarm data loss - critical safety issue */
                vHandleAlarmDataLoss();
                vEnterSafeState();
                break;
                
            case QUEUE_TYPE_CONFIG:
                /* Config data loss - may require user intervention */
                vHandleConfigDataLoss();
                break;
                
            default:
                vLogError("Unknown queue type: %d", ucQueueType);
                break;
        }
    }
    
    return xResult;
}
```

### 9.2 Data Integrity

**Checksum Validation:**

```c
/* ========== DATA INTEGRITY ========== */

typedef struct {
    uint32_t ulTimestamp;
    float fValue;
    uint8_t ucStatus;
    uint16_t usChecksum;
} SensorDataWithChecksum_t;

/**
 * @brief Calculate checksum for sensor data
 * @param pxData Pointer to sensor data
 * @return Calculated checksum
 */
uint16_t usCalculateChecksum(const SensorDataWithChecksum_t *pxData)
{
    uint16_t usChecksum = 0;
    
    usChecksum ^= (uint16_t)(pxData->ulTimestamp & 0xFFFF);
    usChecksum ^= (uint16_t)((pxData->ulTimestamp >> 16) & 0xFFFF);
    usChecksum ^= (uint16_t)(*(uint32_t*)&pxData->fValue & 0xFFFF);
    usChecksum ^= (uint16_t)((*(uint32_t*)&pxData->fValue >> 16) & 0xFFFF);
    usChecksum ^= pxData->ucStatus;
    
    return usChecksum;
}

/**
 * @brief Validate sensor data integrity
 * @param pxData Pointer to sensor data
 * @return pdTRUE if valid, pdFALSE otherwise
 */
BaseType_t xValidateSensorData(const SensorDataWithChecksum_t *pxData)
{
    uint16_t usCalculatedChecksum = usCalculateChecksum(pxData);
    
    if(usCalculatedChecksum != pxData->usChecksum) {
        vLogError("Sensor data checksum mismatch");
        return pdFALSE;
    }
    
    return pdTRUE;
}
```

### 9.3 Priority-Based Queues

**Queue Priority Management:**

```c
/* ========== PRIORITY QUEUES ========== */

/* High priority queues */
QueueHandle_t xQueueCriticalAlarms;    // Safety alarms
QueueHandle_t xQueueEmergencyStop;     // Emergency stop commands

/* Medium priority queues */
QueueHandle_t xQueueSensorData;        // Sensor readings
QueueHandle_t xQueueControlCommands;   // Control commands

/* Low priority queues */
QueueHandle_t xQueueLogMessages;       // Log messages
QueueHandle_t xQueueStatusUpdates;     // Status updates

/**
 * @brief Send data to appropriate priority queue
 * @param ePriority Data priority
 * @param pvData Data to send
 * @return pdPASS if successful, pdFAIL otherwise
 */
BaseType_t xSendToPriorityQueue(DataPriority_t ePriority, const void *pvData)
{
    QueueHandle_t xQueue;
    TickType_t xTimeout;
    
    switch(ePriority) {
        case PRIORITY_CRITICAL:
            xQueue = xQueueCriticalAlarms;
            xTimeout = portMAX_DELAY;  // Block until sent
            break;
            
        case PRIORITY_HIGH:
            xQueue = xQueueSensorData;
            xTimeout = pdMS_TO_TICKS(100);
            break;
            
        case PRIORITY_MEDIUM:
            xQueue = xQueueControlCommands;
            xTimeout = pdMS_TO_TICKS(50);
            break;
            
        case PRIORITY_LOW:
            xQueue = xQueueLogMessages;
            xTimeout = 0;  // Non-blocking
            break;
            
        default:
            return pdFAIL;
    }
    
    return xQueueSend(xQueue, pvData, xTimeout);
}
```

---

## **10. PERFORMANCE OPTIMIZATION**

### 10.1 ISR-Safe Operations

**ISR Queue Operations:**

```c
/**
 * @brief Send to queue from ISR
 * @param xQueue Queue handle
 * @param pvData Data to send
 * @return pdPASS if successful, pdFAIL otherwise
 */
BaseType_t xQueueSendFromISRSafe(QueueHandle_t xQueue, const void *pvData)
{
    BaseType_t xResult;
    BaseType_t xHigherPriorityTaskWoken = pdFALSE;
    
    if(xQueue == NULL || pvData == NULL) {
        return pdFAIL;
    }
    
    xResult = xQueueSendFromISR(xQueue, pvData, &xHigherPriorityTaskWoken);
    
    if(xHigherPriorityTaskWoken == pdTRUE) {
        portYIELD_FROM_ISR(xHigherPriorityTaskWoken);
    }
    
    return xResult;
}
```

### 10.2 Batch Operations

**Efficient Batch Processing:**

```c
/**
 * @brief Process multiple queue items in batch
 * @param xQueue Queue handle
 * @param pxProcessFunction Processing function
 * @param ucMaxBatchSize Maximum batch size
 */
void vProcessQueueBatch(QueueHandle_t xQueue, void (*pxProcessFunction)(void*), uint8_t ucMaxBatchSize)
{
    void *pvData;
    uint8_t ucCount = 0;
    
    while(ucCount < ucMaxBatchSize) {
        if(xQueueReceive(xQueue, &pvData, 0) == pdPASS) {
            pxProcessFunction(pvData);
            ucCount++;
        } else {
            break;
        }
    }
    
    if(ucCount > 0) {
        vLogInfo("Processed %d items in batch", ucCount);
    }
}
```

---

## **11. TESTING AND VALIDATION**

### 11.1 Queue Functionality Tests

```c
/**
 * @brief Test basic queue send/receive functionality
 */
void vTestQueueBasicFunctionality(void)
{
    SensorData_t xTestData, xReceivedData;
    BaseType_t xResult;
    
    /* Prepare test data */
    xTestData.fVoltage = 1.5f;
    xTestData.ulTimestamp = xTaskGetTickCount();
    xTestData.ucQuality = SENSOR_QUALITY_GOOD;
    
    /* Test send */
    xResult = xQueueSend(xQueueSensorData, &xTestData, pdMS_TO_TICKS(100));
    configASSERT(xResult == pdPASS);
    
    /* Test receive */
    xResult = xQueueReceive(xQueueSensorData, &xReceivedData, pdMS_TO_TICKS(100));
    configASSERT(xResult == pdPASS);
    
    /* Verify data integrity */
    configASSERT(xReceivedData.fVoltage == xTestData.fVoltage);
    configASSERT(xReceivedData.ulTimestamp == xTestData.ulTimestamp);
    configASSERT(xReceivedData.ucQuality == xTestData.ucQuality);
    
    vLogInfo("Queue basic functionality test passed");
}

/**
 * @brief Test queue full condition
 */
void vTestQueueFullCondition(void)
{
    SensorData_t xTestData;
    BaseType_t xResult;
    uint32_t ulSentCount = 0;
    
    /* Fill queue to capacity */
    while(ulSentCount < SENSOR_QUEUE_LENGTH) {
        xTestData.fVoltage = (float)ulSentCount;
        xTestData.ulTimestamp = xTaskGetTickCount();
        xTestData.ucQuality = SENSOR_QUALITY_GOOD;
        
        xResult = xQueueSend(xQueueSensorData, &xTestData, 0);
        if(xResult == pdPASS) {
            ulSentCount++;
        } else {
            break;
        }
    }
    
    /* Verify queue is full */
    configASSERT(uxQueueMessagesWaiting(xQueueSensorData) == SENSOR_QUEUE_LENGTH);
    configASSERT(uxQueueSpacesAvailable(xQueueSensorData) == 0);
    
    /* Test send to full queue should fail */
    xTestData.fVoltage = 999.0f;
    xResult = xQueueSend(xQueueSensorData, &xTestData, 0);
    configASSERT(xResult == pdFAIL);
    
    vLogInfo("Queue full condition test passed");
}
```

### 11.2 Stress Testing

**Queue Stress Test:**

```c
/**
 * @brief Stress test queue operations
 * @param xQueue Queue handle
 * @param ulTestDuration Test duration in ms
 */
void vStressTestQueue(QueueHandle_t xQueue, uint32_t ulTestDuration)
{
    TickType_t xStartTime = xTaskGetTickCount();
    TickType_t xEndTime = xStartTime + pdMS_TO_TICKS(ulTestDuration);
    uint32_t ulSendCount = 0;
    uint32_t ulReceiveCount = 0;
    TestData_t xData;
    
    while(xTaskGetTickCount() < xEndTime) {
        /* Send data */
        if(xQueueSend(xQueue, &xData, 0) == pdPASS) {
            ulSendCount++;
        }
        
        /* Receive data */
        if(xQueueReceive(xQueue, &xData, 0) == pdPASS) {
            ulReceiveCount++;
        }
    }
    
    vLogInfo("Queue stress test: %lu sends, %lu receives", ulSendCount, ulReceiveCount);
}
```

---

## **12. BEST PRACTICES**

### 12.1 Design Guidelines

1. **Size queues appropriately** for worst-case scenarios
2. **Use timeouts** for all queue operations
3. **Handle queue full conditions** gracefully
4. **Monitor queue usage** continuously
5. **Use ISR-safe functions** in interrupt context
6. **Validate data** before and after queue operations
7. **Log queue errors** for debugging and monitoring
8. **Use static allocation** exclusively for medical devices
9. **Implement data integrity** checks for critical data
10. **Test thoroughly** with stress tests and edge cases

### 12.2 Common Pitfalls

❌ **Avoid:**
- Ignoring return values from queue operations
- Using regular queue functions in ISRs
- Not handling queue full conditions
- Oversizing or undersizing queues
- Not validating data integrity
- Blocking indefinitely without timeout
- Not monitoring queue health
- Using dynamic allocation in safety-critical systems

✅ **Do:**
- Always check return values
- Use ISR-safe functions in interrupts
- Implement queue full handling strategies
- Size queues based on actual requirements
- Add checksums for critical data
- Use appropriate timeouts
- Monitor queue usage regularly
- Use static allocation for medical devices

---

## **13. QUICK REFERENCE**

### 13.1 Queue Operations Summary

| Operation | Function | Timeout | Use Case |
|-----------|----------|---------|----------|
| **Send** | `xQueueSend()` | `0` to `portMAX_DELAY` | Task to task |
| **Send ISR** | `xQueueSendFromISR()` | `0` only | ISR to task |
| **Receive** | `xQueueReceive()` | `0` to `portMAX_DELAY` | Task from task |
| **Receive ISR** | `xQueueReceiveFromISR()` | `0` only | ISR from task |
| **Peek** | `xQueuePeek()` | `0` to `portMAX_DELAY` | Look without remove |
| **Overwrite** | `xQueueOverwrite()` | N/A | Latest data only |
| **Send to Front** | `xQueueSendToFront()` | `0` to `portMAX_DELAY` | Priority insertion |
| **Reset** | `xQueueReset()` | N/A | Clear all items |

### 13.2 Best Practices Checklist

- ✅ **Always check return values** from queue operations
- ✅ **Use appropriate timeouts** based on data criticality
- ✅ **Implement queue full strategies** for robust operation
- ✅ **Monitor queue health** regularly
- ✅ **Use ISR-safe functions** in interrupt context
- ✅ **Validate data integrity** for critical data
- ✅ **Size queues appropriately** based on system requirements
- ✅ **Handle errors gracefully** with recovery strategies
- ✅ **Use static allocation** for deterministic memory usage
- ✅ **Test thoroughly** with stress tests and edge cases

This guide provides comprehensive queue implementation for medical device firmware with static allocation, ensuring reliable, efficient, and safe inter-task communication.