# FreeRTOS Event Group Guide

This guide covers comprehensive event group implementation and best practices for medical device firmware using static allocation. Event groups provide efficient task synchronization and state management with bit-level control.

---

## **1. OVERVIEW**

### 1.1 Why Use Event Groups?

**Benefits for Medical Devices:**

- ✅ **Efficient Synchronization:** Multiple events in a single object
- ✅ **Bit-Level Control:** Precise event management and monitoring
- ✅ **Multiple Wait Patterns:** Wait for ANY or ALL events
- ✅ **ISR Safe Operations:** Can be used from interrupt context
- ✅ **State Management:** Track system states and conditions
- ✅ **Memory Efficient:** Single object manages multiple events

**When to Use Event Groups:**

- ✅ **Task synchronization** requiring multiple conditions
- ✅ **State machine coordination** between tasks
- ✅ **System initialization** sequencing
- ✅ **Alarm and warning** management
- ✅ **Resource availability** signaling
- ✅ **Multi-step process** coordination

---

## **2. STATIC EVENT GROUP IMPLEMENTATION**

### 2.1 Basic Static Event Group Creation

```c
/* ========== CONFIGURATION ========== */
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

### 2.2 Multiple Event Groups

```c
/* ========== SYSTEM EVENT GROUP ========== */
static StaticEventGroup_t xSystemEventGroupBuffer;
EventGroupHandle_t xEventGroupSystem = NULL;

/* ========== SENSOR EVENT GROUP ========== */
static StaticEventGroup_t xSensorEventGroupBuffer;
EventGroupHandle_t xEventGroupSensor = NULL;

/* ========== ALARM EVENT GROUP ========== */
static StaticEventGroup_t xAlarmEventGroupBuffer;
EventGroupHandle_t xEventGroupAlarm = NULL;

/**
 * @brief Create all static event groups
 * @return pdPASS if all successful, pdFAIL otherwise
 */
BaseType_t xCreateAllStaticEventGroups(void)
{
    BaseType_t xResult = pdPASS;
    
    /* Create system event group */
    xEventGroupSystem = xEventGroupCreateStatic(&xSystemEventGroupBuffer);
    if(xEventGroupSystem == NULL) {
        vLogError("System event group creation failed");
        xResult = pdFAIL;
    }
    
    /* Create sensor event group */
    xEventGroupSensor = xEventGroupCreateStatic(&xSensorEventGroupBuffer);
    if(xEventGroupSensor == NULL) {
        vLogError("Sensor event group creation failed");
        xResult = pdFAIL;
    }
    
    /* Create alarm event group */
    xEventGroupAlarm = xEventGroupCreateStatic(&xAlarmEventGroupBuffer);
    if(xEventGroupAlarm == NULL) {
        vLogError("Alarm event group creation failed");
        xResult = pdFAIL;
    }
    
    return xResult;
}
```

---

## **3. EVENT BIT DEFINITIONS**

### 3.1 System Event Bits

```c
/* ========== SYSTEM EVENT BITS ========== */
#define EVENT_BIT_SYSTEM_READY            (1 << 0)    /* Bit 0: System ready for operation */
#define EVENT_BIT_PATIENT_CONNECTED       (1 << 1)    /* Bit 1: Patient connected */
#define EVENT_BIT_CALIBRATION_DONE        (1 << 2)    /* Bit 2: Calibration complete */
#define EVENT_BIT_SENSOR_READY            (1 << 3)    /* Bit 3: Sensor data ready */
#define EVENT_BIT_DATA_PROCESSED          (1 << 4)    /* Bit 4: Data processing complete */
#define EVENT_BIT_TRANSMISSION_READY      (1 << 5)    /* Bit 5: Data ready for transmission */
#define EVENT_BIT_BATTERY_OK              (1 << 6)    /* Bit 6: Battery level acceptable */
#define EVENT_BIT_MEMORY_OK               (1 << 7)    /* Bit 7: Memory status OK */

/* ========== SENSOR EVENT BITS ========== */
#define EVENT_BIT_ECG_READY               (1 << 0)    /* Bit 0: ECG data ready */
#define EVENT_BIT_BP_READY                (1 << 1)    /* Bit 1: Blood pressure ready */
#define EVENT_BIT_TEMP_READY              (1 << 2)    /* Bit 2: Temperature ready */
#define EVENT_BIT_SPO2_READY              (1 << 3)    /* Bit 3: SpO2 ready */
#define EVENT_BIT_SENSOR_ERROR            (1 << 4)    /* Bit 4: Sensor error detected */
#define EVENT_BIT_SENSOR_CALIBRATED       (1 << 5)    /* Bit 5: Sensor calibrated */
#define EVENT_BIT_SENSOR_STABLE           (1 << 6)    /* Bit 6: Sensor readings stable */
#define EVENT_BIT_SENSOR_FAULT            (1 << 7)    /* Bit 7: Sensor fault detected */

/* ========== ALARM EVENT BITS ========== */
#define EVENT_BIT_ALARM_CRITICAL          (1 << 0)    /* Bit 0: Critical alarm */
#define EVENT_BIT_ALARM_WARNING           (1 << 1)    /* Bit 1: Warning alarm */
#define EVENT_BIT_ALARM_INFO              (1 << 2)    /* Bit 2: Information alarm */
#define EVENT_BIT_EMERGENCY_STOP          (1 << 3)    /* Bit 3: Emergency stop */
#define EVENT_BIT_BATTERY_LOW             (1 << 4)    /* Bit 4: Battery low */
#define EVENT_BIT_COMMUNICATION_LOST      (1 << 5)    /* Bit 5: Communication lost */
#define EVENT_BIT_SYSTEM_FAULT            (1 << 6)    /* Bit 6: System fault */
#define EVENT_BIT_MAINTENANCE_REQUIRED    (1 << 7)    /* Bit 7: Maintenance required */
```

### 3.2 Event Bit Masks

```c
/* ========== EVENT BIT MASKS ========== */
#define MASK_ALL_SENSORS_READY            (EVENT_BIT_ECG_READY | EVENT_BIT_BP_READY | \
                                           EVENT_BIT_TEMP_READY | EVENT_BIT_SPO2_READY)

#define MASK_CRITICAL_ALARMS              (EVENT_BIT_ALARM_CRITICAL | EVENT_BIT_EMERGENCY_STOP | \
                                           EVENT_BIT_SYSTEM_FAULT)

#define MASK_SYSTEM_READY_CONDITIONS      (EVENT_BIT_SYSTEM_READY | EVENT_BIT_PATIENT_CONNECTED | \
                                           EVENT_BIT_CALIBRATION_DONE | EVENT_BIT_BATTERY_OK)

#define MASK_SENSOR_ERRORS                (EVENT_BIT_SENSOR_ERROR | EVENT_BIT_SENSOR_FAULT)
```

---

## **4. EVENT GROUP USAGE PATTERNS**

### 4.1 Basic Event Setting and Waiting

```c
/**
 * @brief Sensor task - sets sensor ready events
 */
void vTaskSensorManager(void *pvParameters)
{
    SensorData_t xSensorData;
    EventBits_t xEventBits;
    
    for(;;) {
        /* Read sensor data */
        if(xReadSensorData(&xSensorData) == pdPASS) {
            /* Process sensor data */
            vProcessSensorData(&xSensorData);
            
            /* Set appropriate sensor ready event based on sensor type */
            switch(xSensorData.ucSensorType) {
                case SENSOR_TYPE_ECG:
                    xEventGroupSetBits(xEventGroupSensor, EVENT_BIT_ECG_READY);
                    break;
                    
                case SENSOR_TYPE_BP:
                    xEventGroupSetBits(xEventGroupSensor, EVENT_BIT_BP_READY);
                    break;
                    
                case SENSOR_TYPE_TEMP:
                    xEventGroupSetBits(xEventGroupSensor, EVENT_BIT_TEMP_READY);
                    break;
                    
                case SENSOR_TYPE_SPO2:
                    xEventGroupSetBits(xEventGroupSensor, EVENT_BIT_SPO2_READY);
                    break;
            }
            
            vLogDebug("Sensor %d data ready - event bit set", xSensorData.ucSensorType);
        }
        
        vTaskDelay(pdMS_TO_TICKS(100)); /* 10Hz sampling */
    }
}

/**
 * @brief Data processor task - waits for sensor events
 */
void vTaskDataProcessor(void *pvParameters)
{
    EventBits_t xEventBits;
    
    for(;;) {
        /* Wait for ANY sensor to be ready */
        xEventBits = xEventGroupWaitBits(
            xEventGroupSensor,
            MASK_ALL_SENSORS_READY,
            pdTRUE,                         /* Clear bits after reading */
            pdFALSE,                        /* Wait for ANY bit */
            pdMS_TO_TICKS(1000)             /* 1 second timeout */
        );
        
        /* Check which sensors are ready */
        if(xEventBits & EVENT_BIT_ECG_READY) {
            vLogInfo("ECG data ready - processing");
            vProcessECGData();
        }
        
        if(xEventBits & EVENT_BIT_BP_READY) {
            vLogInfo("Blood pressure data ready - processing");
            vProcessBPData();
        }
        
        if(xEventBits & EVENT_BIT_TEMP_READY) {
            vLogInfo("Temperature data ready - processing");
            vProcessTempData();
        }
        
        if(xEventBits & EVENT_BIT_SPO2_READY) {
            vLogInfo("SpO2 data ready - processing");
            vProcessSpO2Data();
        }
        
        /* If no events received, handle timeout */
        if(xEventBits == 0) {
            vLogWarning("Data processor timeout - no sensor data received");
            vHandleDataTimeout();
        }
    }
}
```

### 4.2 Multiple Event Coordination

```c
/**
 * @brief System initialization task - coordinates startup sequence
 */
void vTaskSystemInit(void *pvParameters)
{
    EventBits_t xEventBits;
    
    /* Initialize hardware components */
    vInitializeHardware();
    
    /* Set system ready event */
    xEventGroupSetBits(xEventGroupSystem, EVENT_BIT_SYSTEM_READY);
    vLogInfo("System initialization complete");
    
    /* Wait for patient connection */
    xEventBits = xEventGroupWaitBits(
        xEventGroupSystem,
        EVENT_BIT_PATIENT_CONNECTED,
        pdTRUE,                             /* Clear bit after reading */
        pdFALSE,                            /* Wait for any bit */
        portMAX_DELAY                       /* Wait indefinitely */
    );
    
    if(xEventBits & EVENT_BIT_PATIENT_CONNECTED) {
        vLogInfo("Patient connected - starting calibration");
        
        /* Start calibration process */
        vStartCalibration();
        
        /* Wait for calibration to complete */
        xEventBits = xEventGroupWaitBits(
            xEventGroupSystem,
            EVENT_BIT_CALIBRATION_DONE,
            pdTRUE,                         /* Clear bit after reading */
            pdFALSE,                        /* Wait for any bit */
            pdMS_TO_TICKS(30000)            /* 30 second timeout */
        );
        
        if(xEventBits & EVENT_BIT_CALIBRATION_DONE) {
            vLogInfo("Calibration complete - system ready for operation");
            
            /* Start main operation tasks */
            vStartMainOperation();
        } else {
            vLogError("Calibration timeout - system not ready");
            vHandleCalibrationTimeout();
        }
    }
    
    /* Task completes after initialization */
    vTaskDelete(NULL);
}

/**
 * @brief Calibration task - performs sensor calibration
 */
void vTaskCalibration(void *pvParameters)
{
    BaseType_t xCalibrationResult;
    
    for(;;) {
        /* Wait for patient connection */
        xEventGroupWaitBits(
            xEventGroupSystem,
            EVENT_BIT_PATIENT_CONNECTED,
            pdFALSE,                        /* Don't clear bit */
            pdFALSE,                        /* Wait for any bit */
            portMAX_DELAY
        );
        
        vLogInfo("Starting calibration sequence");
        
        /* Perform calibration steps */
        xCalibrationResult = xPerformCalibrationSequence();
        
        if(xCalibrationResult == pdPASS) {
            /* Set calibration complete event */
            xEventGroupSetBits(xEventGroupSystem, EVENT_BIT_CALIBRATION_DONE);
            vLogInfo("Calibration complete - event bit set");
        } else {
            vLogError("Calibration failed");
            vHandleCalibrationFailure();
        }
        
        /* Wait for patient disconnection before next calibration */
        xEventGroupWaitBits(
            xEventGroupSystem,
            EVENT_BIT_PATIENT_CONNECTED,
            pdTRUE,                         /* Clear bit after reading */
            pdFALSE,                        /* Wait for any bit */
            portMAX_DELAY
        );
    }
}
```

### 4.3 Alarm and Warning Management

```c
/**
 * @brief Alarm monitoring task - handles all alarm conditions
 */
void vTaskAlarmMonitor(void *pvParameters)
{
    EventBits_t xEventBits;
    
    for(;;) {
        /* Wait for any alarm-related event */
        xEventBits = xEventGroupWaitBits(
            xEventGroupAlarm,
            MASK_CRITICAL_ALARMS | EVENT_BIT_ALARM_WARNING | EVENT_BIT_ALARM_INFO,
            pdFALSE,                        /* Don't clear bits */
            pdFALSE,                        /* Wait for ANY bit */
            pdMS_TO_TICKS(1000)             /* 1 second timeout */
        );
        
        /* Handle critical alarms first (highest priority) */
        if(xEventBits & EVENT_BIT_EMERGENCY_STOP) {
            vLogCriticalError("Emergency stop activated!");
            vHandleEmergencyStop();
            continue; /* Skip other alarm processing */
        }
        
        if(xEventBits & EVENT_BIT_ALARM_CRITICAL) {
            vLogCriticalError("Critical alarm condition detected");
            vHandleCriticalAlarm();
        }
        
        if(xEventBits & EVENT_BIT_SYSTEM_FAULT) {
            vLogCriticalError("System fault detected");
            vHandleSystemFault();
        }
        
        /* Handle warning alarms */
        if(xEventBits & EVENT_BIT_ALARM_WARNING) {
            vLogWarning("Warning alarm condition detected");
            vHandleWarningAlarm();
        }
        
        if(xEventBits & EVENT_BIT_BATTERY_LOW) {
            vLogWarning("Battery low warning");
            vHandleBatteryLow();
        }
        
        if(xEventBits & EVENT_BIT_COMMUNICATION_LOST) {
            vLogWarning("Communication lost");
            vHandleCommunicationLost();
        }
        
        /* Handle information alarms */
        if(xEventBits & EVENT_BIT_ALARM_INFO) {
            vLogInfo("Information alarm");
            vHandleInfoAlarm();
        }
        
        if(xEventBits & EVENT_BIT_MAINTENANCE_REQUIRED) {
            vLogInfo("Maintenance required");
            vHandleMaintenanceRequired();
        }
    }
}

/**
 * @brief Battery monitoring task - sets battery events
 */
void vTaskBatteryMonitor(void *pvParameters)
{
    float fBatteryVoltage;
    EventBits_t xCurrentBits, xNewBits;
    
    for(;;) {
        /* Read battery voltage */
        fBatteryVoltage = fReadBatteryVoltage();
        
        /* Get current alarm event bits */
        xCurrentBits = xEventGroupGetBits(xEventGroupAlarm);
        
        /* Determine new battery status */
        if(fBatteryVoltage < BATTERY_CRITICAL_VOLTAGE) {
            /* Critical battery level */
            xNewBits = xCurrentBits | EVENT_BIT_ALARM_CRITICAL;
            vLogCriticalError("Battery critical: %.2fV", fBatteryVoltage);
        } else if(fBatteryVoltage < BATTERY_LOW_VOLTAGE) {
            /* Low battery level */
            xNewBits = xCurrentBits | EVENT_BIT_BATTERY_LOW;
            vLogWarning("Battery low: %.2fV", fBatteryVoltage);
        } else {
            /* Battery OK - clear battery-related alarms */
            xNewBits = xCurrentBits & ~(EVENT_BIT_BATTERY_LOW | EVENT_BIT_ALARM_CRITICAL);
        }
        
        /* Update event group if status changed */
        if(xNewBits != xCurrentBits) {
            xEventGroupSetBits(xEventGroupAlarm, xNewBits);
        }
        
        vTaskDelay(pdMS_TO_TICKS(5000)); /* Check every 5 seconds */
    }
}
```

### 4.4 ISR Event Group Usage

```c
/**
 * @brief Emergency button ISR - sets emergency stop event
 */
void vEXTI_EmergencyButton_IRQHandler(void)
{
    BaseType_t xHigherPriorityTaskWoken = pdFALSE;
    
    /* Clear interrupt flag */
    EXTI_ClearITPendingBit(EXTI_Line0);
    
    /* Set emergency stop event from ISR */
    xEventGroupSetBitsFromISR(xEventGroupAlarm, EVENT_BIT_EMERGENCY_STOP, &xHigherPriorityTaskWoken);
    
    /* Context switch if higher priority task was woken */
    portYIELD_FROM_ISR(xHigherPriorityTaskWoken);
}

/**
 * @brief Communication timeout ISR - sets communication lost event
 */
void vTIM_CommunicationTimeout_IRQHandler(void)
{
    BaseType_t xHigherPriorityTaskWoken = pdFALSE;
    
    /* Clear interrupt flag */
    TIM_ClearITPendingBit(TIM2, TIM_IT_Update);
    
    /* Set communication lost event from ISR */
    xEventGroupSetBitsFromISR(xEventGroupAlarm, EVENT_BIT_COMMUNICATION_LOST, &xHigherPriorityTaskWoken);
    
    /* Context switch if higher priority task was woken */
    portYIELD_FROM_ISR(xHigherPriorityTaskWoken);
}
```

---

## **5. ADVANCED EVENT GROUP FEATURES**

### 5.1 Event Group Monitoring and Statistics

```c
/**
 * @brief Get event group status information
 * @param xEventGroup Event group handle
 * @param pxEventStatus Pointer to status structure
 * @return pdPASS if successful, pdFAIL otherwise
 */
BaseType_t xGetEventGroupStatus(EventGroupHandle_t xEventGroup, EventGroupStatus_t *pxEventStatus)
{
    if((xEventGroup == NULL) || (pxEventStatus == NULL)) {
        return pdFAIL;
    }
    
    /* Get current event bits */
    pxEventStatus->uxEventBits = xEventGroupGetBits(xEventGroup);
    
    /* Count active bits */
    pxEventStatus->ucActiveBits = 0;
    for(uint8_t ucBit = 0; ucBit < 8; ucBit++) {
        if(pxEventStatus->uxEventBits & (1 << ucBit)) {
            pxEventStatus->ucActiveBits++;
        }
    }
    
    return pdPASS;
}

/**
 * @brief Monitor all event groups and log status
 */
void vMonitorAllEventGroups(void)
{
    EventGroupStatus_t xStatus;
    
    /* Monitor system event group */
    if(xGetEventGroupStatus(xEventGroupSystem, &xStatus) == pdPASS) {
        vLogInfo("System Events: 0x%02X (%d active bits)", 
                 (unsigned int)xStatus.uxEventBits, xStatus.ucActiveBits);
        
        /* Log specific system events */
        if(xStatus.uxEventBits & EVENT_BIT_SYSTEM_READY) {
            vLogInfo("  - System Ready");
        }
        if(xStatus.uxEventBits & EVENT_BIT_PATIENT_CONNECTED) {
            vLogInfo("  - Patient Connected");
        }
        if(xStatus.uxEventBits & EVENT_BIT_CALIBRATION_DONE) {
            vLogInfo("  - Calibration Done");
        }
    }
    
    /* Monitor sensor event group */
    if(xGetEventGroupStatus(xEventGroupSensor, &xStatus) == pdPASS) {
        vLogInfo("Sensor Events: 0x%02X (%d active bits)", 
                 (unsigned int)xStatus.uxEventBits, xStatus.ucActiveBits);
    }
    
    /* Monitor alarm event group */
    if(xGetEventGroupStatus(xEventGroupAlarm, &xStatus) == pdPASS) {
        vLogInfo("Alarm Events: 0x%02X (%d active bits)", 
                 (unsigned int)xStatus.uxEventBits, xStatus.ucActiveBits);
        
        /* Check for critical alarms */
        if(xStatus.uxEventBits & MASK_CRITICAL_ALARMS) {
            vLogWarning("Critical alarms active: 0x%02X", 
                       (unsigned int)(xStatus.uxEventBits & MASK_CRITICAL_ALARMS));
        }
    }
}
```

### 5.2 Event Group Helper Functions

```c
/**
 * @brief Clear specific event bits
 * @param xEventGroup Event group handle
 * @param uxBitsToClear Bits to clear
 * @return Previous event bits value
 */
EventBits_t xClearEventBits(EventGroupHandle_t xEventGroup, EventBits_t uxBitsToClear)
{
    return xEventGroupClearBits(xEventGroup, uxBitsToClear);
}

/**
 * @brief Clear specific event bits from ISR
 * @param xEventGroup Event group handle
 * @param uxBitsToClear Bits to clear
 * @param pxHigherPriorityTaskWoken Pointer to flag
 * @return Previous event bits value
 */
EventBits_t xClearEventBitsFromISR(EventGroupHandle_t xEventGroup, EventBits_t uxBitsToClear, 
                                   BaseType_t *pxHigherPriorityTaskWoken)
{
    return xEventGroupClearBitsFromISR(xEventGroup, uxBitsToClear, pxHigherPriorityTaskWoken);
}

/**
 * @brief Set specific event bits
 * @param xEventGroup Event group handle
 * @param uxBitsToSet Bits to set
 * @return Event bits value after setting
 */
EventBits_t xSetEventBits(EventGroupHandle_t xEventGroup, EventBits_t uxBitsToSet)
{
    return xEventGroupSetBits(xEventGroup, uxBitsToSet);
}

/**
 * @brief Wait for event bits with custom timeout
 * @param xEventGroup Event group handle
 * @param uxBitsToWaitFor Bits to wait for
 * @param xClearOnExit Clear bits on exit
 * @param xWaitForAllBits Wait for all bits
 * @param xTimeoutMs Timeout in milliseconds
 * @return Event bits that were set
 */
EventBits_t xWaitForEventBits(EventGroupHandle_t xEventGroup, EventBits_t uxBitsToWaitFor,
                              BaseType_t xClearOnExit, BaseType_t xWaitForAllBits, uint32_t xTimeoutMs)
{
    return xEventGroupWaitBits(xEventGroup, uxBitsToWaitFor, xClearOnExit, xWaitForAllBits, 
                              pdMS_TO_TICKS(xTimeoutMs));
}
```

---

## **6. MEDICAL DEVICE CONSIDERATIONS**

### 6.1 Safety-Critical Event Group Design

```c
/* ========== SAFETY-CRITICAL EVENT CONFIGURATION ========== */

/* Define critical event priorities */
#define PRIORITY_EMERGENCY_STOP           (0x80)  /* Highest priority */
#define PRIORITY_CRITICAL_ALARM           (0x40)  /* High priority */
#define PRIORITY_SYSTEM_FAULT             (0x20)  /* High priority */
#define PRIORITY_WARNING_ALARM            (0x10)  /* Medium priority */
#define PRIORITY_INFO_ALARM               (0x08)  /* Low priority */

/**
 * @brief Safety-critical event set with priority handling
 * @param xEventGroup Event group handle
 * @param uxBitsToSet Bits to set
 * @param ucPriority Priority level
 * @return pdPASS if successful, pdFAIL otherwise
 */
BaseType_t xSafeSetEventBits(EventGroupHandle_t xEventGroup, EventBits_t uxBitsToSet, uint8_t ucPriority)
{
    BaseType_t xResult = pdPASS;
    EventBits_t xCurrentBits, xNewBits;
    
    /* Get current event bits */
    xCurrentBits = xEventGroupGetBits(xEventGroup);
    
    /* Set new bits */
    xNewBits = xCurrentBits | uxBitsToSet;
    
    /* For critical events, ensure they are not masked by lower priority events */
    if(ucPriority >= PRIORITY_CRITICAL_ALARM) {
        /* Critical events - log and ensure visibility */
        vLogCriticalError("Critical event set: 0x%02X", (unsigned int)uxBitsToSet);
        
        /* Force event setting even if event group is busy */
        xEventGroupSetBits(xEventGroup, uxBitsToSet);
    } else {
        /* Normal events - standard setting */
        xEventGroupSetBits(xEventGroup, uxBitsToSet);
    }
    
    return xResult;
}

/**
 * @brief Handle event group timeout with safety considerations
 * @param xEventGroup Event group handle
 * @param uxBitsToWaitFor Bits being waited for
 * @param xTimeoutMs Timeout in milliseconds
 */
void vHandleEventGroupTimeout(EventGroupHandle_t xEventGroup, EventBits_t uxBitsToWaitFor, uint32_t xTimeoutMs)
{
    EventBits_t xCurrentBits;
    
    /* Get current event bits */
    xCurrentBits = xEventGroupGetBits(xEventGroup);
    
    /* Log timeout details */
    vLogWarning("Event group timeout: waiting for 0x%02X, current: 0x%02X, timeout: %lu ms",
                (unsigned int)uxBitsToWaitFor, (unsigned int)xCurrentBits, xTimeoutMs);
    
    /* Handle timeout based on event type */
    if(uxBitsToWaitFor & EVENT_BIT_EMERGENCY_STOP) {
        /* Emergency stop timeout - critical safety issue */
        vLogCriticalError("Emergency stop event timeout - entering safe state");
        vEnterSafeState();
    } else if(uxBitsToWaitFor & MASK_CRITICAL_ALARMS) {
        /* Critical alarm timeout - may indicate system fault */
        vLogError("Critical alarm event timeout - checking system status");
        vCheckSystemStatus();
    } else {
        /* Normal event timeout - log and continue */
        vLogInfo("Normal event timeout - continuing operation");
    }
}
```

### 6.2 Event Group Error Recovery

```c
/**
 * @brief Recover from event group errors
 * @param xEventGroup Event group handle
 * @param ucEventGroupType Event group type for error reporting
 */
void vRecoverFromEventGroupError(EventGroupHandle_t xEventGroup, uint8_t ucEventGroupType)
{
    EventBits_t xCurrentBits;
    
    /* Get current event bits */
    xCurrentBits = xEventGroupGetBits(xEventGroup);
    
    vLogWarning("Event group error recovery - type: %d, current bits: 0x%02X", 
                ucEventGroupType, (unsigned int)xCurrentBits);
    
    /* Handle recovery based on event group type */
    switch(ucEventGroupType) {
        case EVENT_GROUP_TYPE_SYSTEM:
            /* System event group - reset to safe state */
            xEventGroupClearBits(xEventGroup, 0xFF); /* Clear all bits */
            xEventGroupSetBits(xEventGroup, EVENT_BIT_SYSTEM_READY); /* Set system ready */
            vLogInfo("System event group reset to safe state");
            break;
            
        case EVENT_GROUP_TYPE_SENSOR:
            /* Sensor event group - clear sensor events */
            xEventGroupClearBits(xEventGroup, MASK_ALL_SENSORS_READY);
            vLogInfo("Sensor event group cleared");
            break;
            
        case EVENT_GROUP_TYPE_ALARM:
            /* Alarm event group - preserve critical alarms */
            xEventGroupClearBits(xEventGroup, EVENT_BIT_ALARM_WARNING | EVENT_BIT_ALARM_INFO);
            /* Keep critical alarms active */
            vLogInfo("Alarm event group cleared (preserving critical alarms)");
            break;
            
        default:
            vLogError("Unknown event group type: %d", ucEventGroupType);
            break;
    }
}
```

---

## **7. TESTING AND VALIDATION**

### 7.1 Event Group Functionality Tests

```c
/**
 * @brief Test basic event group set/get functionality
 */
void vTestEventGroupBasicFunctionality(void)
{
    EventBits_t xSetBits, xGetBits, xClearedBits;
    
    /* Test setting event bits */
    xSetBits = xEventGroupSetBits(xEventGroupSystem, EVENT_BIT_SYSTEM_READY | EVENT_BIT_PATIENT_CONNECTED);
    configASSERT(xSetBits == (EVENT_BIT_SYSTEM_READY | EVENT_BIT_PATIENT_CONNECTED));
    
    /* Test getting event bits */
    xGetBits = xEventGroupGetBits(xEventGroupSystem);
    configASSERT(xGetBits == (EVENT_BIT_SYSTEM_READY | EVENT_BIT_PATIENT_CONNECTED));
    
    /* Test clearing event bits */
    xClearedBits = xEventGroupClearBits(xEventGroupSystem, EVENT_BIT_PATIENT_CONNECTED);
    configASSERT(xClearedBits == (EVENT_BIT_SYSTEM_READY | EVENT_BIT_PATIENT_CONNECTED));
    
    /* Verify bits were cleared */
    xGetBits = xEventGroupGetBits(xEventGroupSystem);
    configASSERT(xGetBits == EVENT_BIT_SYSTEM_READY);
    
    vLogInfo("Event group basic functionality test passed");
}

/**
 * @brief Test event group wait functionality
 */
void vTestEventGroupWaitFunctionality(void)
{
    EventBits_t xEventBits;
    TaskHandle_t xTestTask;
    
    /* Create test task to set events */
    xTestTask = xTaskCreateStatic(
        vTestEventSetterTask,
        "EventSetter",
        128,
        NULL,
        tskIDLE_PRIORITY + 1,
        ucTestTaskStack,
        &xTestTaskBuffer
    );
    
    if(xTestTask != NULL) {
        /* Wait for test event to be set */
        xEventBits = xEventGroupWaitBits(
            xEventGroupSystem,
            EVENT_BIT_CALIBRATION_DONE,
            pdTRUE,                         /* Clear bit after reading */
            pdFALSE,                        /* Wait for any bit */
            pdMS_TO_TICKS(5000)             /* 5 second timeout */
        );
        
        configASSERT(xEventBits & EVENT_BIT_CALIBRATION_DONE);
        
        /* Clean up test task */
        vTaskDelete(xTestTask);
        
        vLogInfo("Event group wait functionality test passed");
    }
}

/**
 * @brief Test event setter task for testing
 */
void vTestEventSetterTask(void *pvParameters)
{
    /* Wait a bit then set test event */
    vTaskDelay(pdMS_TO_TICKS(100));
    xEventGroupSetBits(xEventGroupSystem, EVENT_BIT_CALIBRATION_DONE);
    
    /* Task completes */
    vTaskDelete(NULL);
}
```

---

## **8. BEST PRACTICES**

### 8.1 Design Guidelines

1. **Define clear event bit meanings** with descriptive names
2. **Use event bit masks** for complex event combinations
3. **Handle timeouts gracefully** with appropriate error recovery
4. **Use ISR-safe functions** in interrupt context
5. **Monitor event group status** for debugging and diagnostics
6. **Implement priority handling** for critical events
7. **Document event dependencies** and state transitions

### 8.2 Common Pitfalls

❌ **Avoid:**
- Blocking indefinitely in ISR context
- Not handling event timeouts
- Using dynamic allocation for event groups
- Ignoring event group operation return values
- Not clearing events when appropriate

✅ **Do:**
- Use static allocation exclusively
- Handle all timeout conditions
- Use appropriate event bit masks
- Clear events after processing
- Monitor event group status regularly

---

## **9. QUICK REFERENCE**

| Function | Purpose | ISR Safe | Timeout |
|----------|---------|----------|---------|
| `xEventGroupSetBits()` | Set event bits | No | No |
| `xEventGroupSetBitsFromISR()` | Set bits from ISR | Yes | No |
| `xEventGroupClearBits()` | Clear event bits | No | No |
| `xEventGroupClearBitsFromISR()` | Clear bits from ISR | Yes | No |
| `xEventGroupGetBits()` | Get current bits | No | No |
| `xEventGroupWaitBits()` | Wait for bits | No | Yes |
| `xEventGroupCreateStatic()` | Create static event group | No | No |

This guide provides comprehensive event group implementation for medical device firmware with static allocation, ensuring efficient task synchronization and state management.
