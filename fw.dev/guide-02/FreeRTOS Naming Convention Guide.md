# FreeRTOS Naming Convention Guide

The naming conventions in FreeRTOS follow a systematic prefix scheme to indicate the **scope**, **type**, and **purpose** of variables and functions. This makes code more readable and helps prevent naming conflicts.

---

## **1. FUNCTION PREFIXES**

### 1.1 `v` - Void Return Type

Functions that return `void` (no return value).

```c
void vTaskStartScheduler(void);
void vTaskDelay(TickType_t xTicksToDelay);
void vQueueDelete(QueueHandle_t xQueue);

/* Your application functions */
void vTaskSensorManager(void *pvParameters);
void vInitializeHardware(void);
void vProcessData(SensorData_t *pxData);
```

**Usage Rule:** Use `v` prefix for ALL functions returning void, including task functions and utility functions.

---

### 1.2 `x` - Non-Void Return Type

Functions that return a value (not void). The `x` indicates a generic return type.

```c
BaseType_t xTaskCreate(...);           // Returns BaseType_t (success/fail)
BaseType_t xQueueSend(...);            // Returns BaseType_t
TickType_t xTaskGetTickCount(void);    // Returns TickType_t
QueueHandle_t xQueueCreate(...);       // Returns handle

/* Your application functions */
BaseType_t xValidateData(uint8_t *pucData);
uint32_t xCalculateChecksum(uint8_t *pucBuffer, size_t xLength);
SensorStatus_t xReadTemperature(float *pfTemperature);
```

**Usage Rule:** Use `x` prefix for functions that return ANY type except void.

---

### 1.3 `prv` - Private/Static Functions

Static (private) functions that are only visible within the current source file.

```c
/* In task_sensor.c */
static void prvInitializeSensor(void);
static void prvProcessSensorData(SensorData_t *pxData);
static BaseType_t prvValidateReading(float fValue);
static void prvHandleError(ErrorCode_t eError);

/* These functions cannot be called from other files */
```

**Usage Rule:**

- Use `prv` prefix for ALL static functions
- Combine with return type: `prvV...` for void, or just `prv...` for other returns
- Common pattern in FreeRTOS source code

**Why use `prv`?**

- Clearly indicates internal implementation details
- Prevents accidental external linkage
- Makes code reviews easier (reviewers know it's not part of public API)

---

### 1.4 `px` - Pointer Return Type

Functions that return a pointer.

```c
TaskHandle_t *pxTaskGetHandle(const char *pcName);
uint8_t *pxGetBuffer(void);
SensorData_t *pxGetNextSample(void);

/* Less common in FreeRTOS API, but useful in application code */
```

**Note:** In FreeRTOS API, handles (like `QueueHandle_t`) are opaque pointers, so they use `x` prefix even though they're technically pointers.

---

## **2. VARIABLE PREFIXES**

### 2.1 Type-Based Prefixes

Variables are prefixed based on their **data type**:

| Prefix | Type                            | Example                                     |
| ------ | ------------------------------- | ------------------------------------------- |
| `c`    | char (8-bit)                    | `char cMyChar;`                             |
| `s`    | short (16-bit)                  | `short sCounter;`                           |
| `l`    | long (32-bit)                   | `long lTimestamp;`                          |
| `x`    | BaseType_t, TickType_t, handles | `BaseType_t xResult;`                       |
| `u`    | unsigned                        | Combined with above: `uc`, `us`, `ul`, `ux` |
| `p`    | pointer                         | `char *pcString;`                           |
| `f`    | float                           | `float fTemperature;`                       |
| `d`    | double                          | `double dPreciseValue;`                     |
| `e`    | enum                            | `State_t eCurrentState;`                    |

### 2.2 Detailed Examples by Type

#### **Characters (8-bit)**

```c
char cMyChar = 'A';
unsigned char ucByte = 0xFF;
char *pcString = "Hello";              // Pointer to char
const char *pccConstString = "World";  // Pointer to const char
```

#### **Integers (16-bit, 32-bit)**

```c
short sSmallNumber = 100;
unsigned short usCount = 500;

long lBigNumber = 1000000L;
unsigned long ulTimestamp = 0xFFFFFFFF;

int32_t lSigned32 = -12345;
uint32_t ulUnsigned32 = 54321;
```

#### **FreeRTOS Types**

```c
BaseType_t xResult;              // pdPASS, pdFAIL, pdTRUE, pdFALSE
TickType_t xTickCount;           // System tick count
TickType_t xLastWakeTime;        // For vTaskDelayUntil()

UBaseType_t uxPriority;          // Unsigned base type
UBaseType_t uxHighWaterMark;     // Stack usage
```

#### **Handles**

```c
TaskHandle_t xTaskHandle;
QueueHandle_t xQueueSensorData;
SemaphoreHandle_t xMutexSPI;
TimerHandle_t xTimerBlink;
EventGroupHandle_t xEventGroupSystem;
```

#### **Pointers**

```c
uint8_t *pucBuffer;                    // Pointer to unsigned char
uint8_t * const pucConstPointer;       // Const pointer to unsigned char
const uint8_t *pucPointerToConst;      // Pointer to const unsigned char

SensorData_t *pxSensorData;            // Pointer to struct
void *pvParameters;                    // Void pointer (generic)
```

#### **Floating Point**

```c
float fTemperature = 25.5f;
float fPressure = 101.3f;

double dHighPrecision = 3.14159265359;
```

#### **Enumerations**

```c
typedef enum {
    STATE_INIT,
    STATE_RUNNING,
    STATE_ERROR
} TaskState_t;

TaskState_t eCurrentState = STATE_INIT;
TaskState_t ePreviousState;
```

#### **Structures**

```c
typedef struct {
    uint32_t ulTimestamp;
    float fTemperature;
    float fPressure;
} SensorData_t;

SensorData_t xData;              // Structure variable
SensorData_t *pxData;            // Pointer to structure
```

---

### 2.3 Scope Prefixes

Variables can also have scope indicators:

| Prefix | Scope               | Example                          |
| ------ | ------------------- | -------------------------------- |
| (none) | Local variable      | `uint32_t ulCounter;`            |
| `s_`   | Static (file scope) | `static uint32_t s_ulInitCount;` |
| `g_`   | Global (optional)   | `uint32_t g_ulSystemFlags;`      |

**Example:**

```c
/* File: task_sensor.c */

/* Static (file scope) variables */
static TaskHandle_t s_xTaskHandle = NULL;
static SensorConfig_t s_xConfig;
static uint32_t s_ulSampleCount = 0;

/* Global variables (avoid when possible) */
uint32_t g_ulSystemErrorCount = 0;  // Used across multiple files

void vTaskSensor(void *pvParameters)
{
    /* Local variables */
    TickType_t xLastWakeTime;
    SensorData_t xData;
    uint8_t ucRetryCount = 0;

    /* ... */
}
```

---

### 2.4 Combined Prefixes

When combining type and pointer prefixes, pointer comes AFTER type:

```c
/* Correct */
char *pcString;                  // Pointer to char
unsigned char *pucBuffer;        // Pointer to unsigned char
const char *pccMessage;          // Pointer to const char

uint32_t *pulValues;             // Pointer to unsigned long
SensorData_t *pxData;            // Pointer to structure

/* Pointer to pointer */
char **ppcStringArray;           // Pointer to pointer to char
uint8_t **ppucBufferArray;       // Pointer to pointer to unsigned char

/* Array of pointers */
char *apcStrings[10];            // Array of char pointers
```

---

## **3. MACRO & CONSTANT NAMING**

### 3.1 Preprocessor Definitions

```c
/* ALL CAPS with underscores */
#define TASK_SENSOR_PRIORITY        (tskIDLE_PRIORITY + 3)
#define TASK_SENSOR_STACK_SIZE      (configMINIMAL_STACK_SIZE * 2)
#define SENSOR_SAMPLING_RATE_HZ     (100)
#define MAX_RETRY_COUNT             (3)

/* Configuration constants */
#define configUSE_PREEMPTION        1
#define configTICK_RATE_HZ          1000
#define configMAX_PRIORITIES        7
```

### 3.2 FreeRTOS-Specific Prefixes for Macros

```c
/* FreeRTOS configuration macros start with 'config' */
#define configCPU_CLOCK_HZ          ...
#define configTOTAL_HEAP_SIZE       ...

/* FreeRTOS API macros */
#define portMAX_DELAY               ...
#define portTICK_PERIOD_MS          ...

/* Task macros start with 'task' */
#define taskENTER_CRITICAL()        ...
#define taskEXIT_CRITICAL()         ...
```

### 3.3 Enumeration Constants

```c
/* FreeRTOS standard values */
typedef enum {
    pdFALSE = 0,
    pdTRUE = 1
} pdBoolean_t;

typedef enum {
    pdFAIL = 0,
    pdPASS = 1
} pdResult_t;

/* Your application enums - use UPPER_CASE or PascalCase */
typedef enum {
    SENSOR_OK = 0,
    SENSOR_TIMEOUT,
    SENSOR_CRC_ERROR,
    SENSOR_DISCONNECTED
} SensorStatus_t;

/* Or with prefix */
typedef enum {
    STATE_INIT,
    STATE_RUNNING,
    STATE_SUSPENDED,
    STATE_ERROR
} TaskState_t;
```

---

## **4. TYPE NAMING**

### 4.1 Type Definitions

```c
/* Suffix with '_t' */
typedef uint32_t TickType_t;
typedef long BaseType_t;
typedef unsigned long UBaseType_t;

/* Application types */
typedef struct SensorData SensorData_t;
typedef enum TaskState TaskState_t;
typedef void (*CallbackFunction_t)(void);

/* Handle types (FreeRTOS convention) */
typedef void* TaskHandle_t;
typedef void* QueueHandle_t;
typedef void* SemaphoreHandle_t;
```

### 4.2 Structure Naming

```c
/* Method 1: Direct typedef */
typedef struct {
    uint32_t ulTimestamp;
    float fTemperature;
    uint8_t ucStatus;
} SensorData_t;

/* Method 2: Named struct with typedef */
typedef struct SensorConfig {
    uint16_t usSamplingRate;
    bool bEnableFilter;
    uint8_t ucFilterWindow;
} SensorConfig_t;

/* Method 3: Forward declaration (for linked structures) */
typedef struct ListItem ListItem_t;
struct ListItem {
    TickType_t xItemValue;
    struct ListItem *pxNext;
    struct ListItem *pxPrevious;
};
```

---

## **5. COMPLETE EXAMPLE**

Here's a complete example showing all naming conventions:

```c
/**
 * @file task_temperature.c
 * @brief Temperature monitoring task implementation
 */

#include "FreeRTOS.h"
#include "task.h"
#include "queue.h"

/* ========== MACROS & CONSTANTS ========== */
#define TASK_TEMP_PRIORITY              (tskIDLE_PRIORITY + 2)
#define TASK_TEMP_STACK_SIZE            (configMINIMAL_STACK_SIZE * 2)
#define TASK_TEMP_NAME                  "TempMonitor"
#define TEMP_SAMPLE_PERIOD_MS           (100)
#define TEMP_QUEUE_LENGTH               (10)
#define MAX_TEMPERATURE_C               (85.0f)
#define MIN_TEMPERATURE_C               (-40.0f)

/* ========== TYPE DEFINITIONS ========== */
typedef enum {
    TEMP_STATE_INIT,
    TEMP_STATE_RUNNING,
    TEMP_STATE_ERROR,
    TEMP_STATE_SUSPENDED
} TempState_t;

typedef struct {
    uint32_t ulTimestamp;
    float fTemperature;
    uint8_t ucSensorID;
    bool bValid;
} TempData_t;

typedef enum {
    TEMP_OK = 0,
    TEMP_OUT_OF_RANGE,
    TEMP_SENSOR_FAULT,
    TEMP_TIMEOUT
} TempStatus_t;

/* ========== PRIVATE VARIABLES ========== */
static TaskHandle_t s_xTaskHandleTemp = NULL;
static QueueHandle_t s_xQueueTempData = NULL;
static TempState_t s_eCurrentState = TEMP_STATE_INIT;
static uint32_t s_ulSampleCount = 0;
static float s_fLastValidTemp = 25.0f;

/* ========== PUBLIC VARIABLES ========== */
QueueHandle_t xQueueTempOutput = NULL;

/* ========== PRIVATE FUNCTION PROTOTYPES ========== */
static void prvInitializeTempSensor(void);
static TempStatus_t prvReadTemperature(float *pfTemperature);
static BaseType_t prvValidateTemperature(float fTemperature);
static void prvProcessTemperature(TempData_t *pxData);
static void prvHandleError(TempStatus_t eError);

/* ========== PUBLIC FUNCTIONS ========== */

/**
 * @brief Creates the temperature monitoring task
 * @return pdPASS if successful, pdFAIL otherwise
 */
BaseType_t xTaskTemperatureCreate(void)
{
    BaseType_t xReturn = pdFAIL;

    /* Create output queue */
    s_xQueueTempData = xQueueCreate(TEMP_QUEUE_LENGTH, sizeof(TempData_t));
    xQueueTempOutput = xQueueCreate(TEMP_QUEUE_LENGTH, sizeof(TempData_t));

    if((s_xQueueTempData != NULL) && (xQueueTempOutput != NULL))
    {
        /* Create task */
        xReturn = xTaskCreate(
            vTaskTemperature,           // Task function
            TASK_TEMP_NAME,             // Task name
            TASK_TEMP_STACK_SIZE,       // Stack size
            NULL,                       // Parameters
            TASK_TEMP_PRIORITY,         // Priority
            &s_xTaskHandleTemp          // Task handle
        );
    }

    return xReturn;
}

/**
 * @brief Temperature monitoring task function
 * @param pvParameters Task parameters (unused)
 */
void vTaskTemperature(void *pvParameters)
{
    TickType_t xLastWakeTime;
    TempData_t xTempData;
    float fTemperature;
    TempStatus_t eStatus;
    uint8_t ucRetryCount;

    /* Remove compiler warning */
    (void)pvParameters;

    /* Initialize hardware */
    prvInitializeTempSensor();

    /* Initialize timing */
    xLastWakeTime = xTaskGetTickCount();
    s_eCurrentState = TEMP_STATE_RUNNING;

    /* Main task loop */
    for(;;)
    {
        /* Wait for next sample period */
        vTaskDelayUntil(&xLastWakeTime, pdMS_TO_TICKS(TEMP_SAMPLE_PERIOD_MS));

        /* Read temperature with retry */
        ucRetryCount = 0;
        do {
            eStatus = prvReadTemperature(&fTemperature);
            if(eStatus == TEMP_OK) {
                break;
            }
            ucRetryCount++;
            vTaskDelay(pdMS_TO_TICKS(10));
        } while(ucRetryCount < 3);

        if(eStatus == TEMP_OK)
        {
            /* Validate reading */
            if(prvValidateTemperature(fTemperature) == pdTRUE)
            {
                /* Prepare data structure */
                xTempData.ulTimestamp = xTaskGetTickCount();
                xTempData.fTemperature = fTemperature;
                xTempData.ucSensorID = 0;
                xTempData.bValid = true;

                /* Process data */
                prvProcessTemperature(&xTempData);

                /* Send to output queue */
                xQueueSend(xQueueTempOutput, &xTempData, pdMS_TO_TICKS(100));

                /* Update statistics */
                s_ulSampleCount++;
                s_fLastValidTemp = fTemperature;
            }
            else
            {
                prvHandleError(TEMP_OUT_OF_RANGE);
            }
        }
        else
        {
            prvHandleError(eStatus);
        }

        /* Stack monitoring (debug build only) */
        #ifdef DEBUG
        UBaseType_t uxHighWaterMark = uxTaskGetStackHighWaterMark(NULL);
        if(uxHighWaterMark < 100)
        {
            /* Log warning - stack usage high */
        }
        #endif
    }
}

/* ========== PRIVATE FUNCTIONS ========== */

/**
 * @brief Initialize temperature sensor hardware
 */
static void prvInitializeTempSensor(void)
{
    /* I2C initialization */
    /* Sensor configuration */
    /* Self-test */

    s_eCurrentState = TEMP_STATE_INIT;
}

/**
 * @brief Read temperature from sensor
 * @param pfTemperature Pointer to store temperature value
 * @return TEMP_OK if successful, error code otherwise
 */
static TempStatus_t prvReadTemperature(float *pfTemperature)
{
    TempStatus_t eStatus = TEMP_OK;
    uint16_t usRawValue;
    const float fConversionFactor = 0.0625f;

    /* Read raw value from sensor */
    /* ... hardware-specific code ... */

    /* Convert to temperature */
    *pfTemperature = (float)usRawValue * fConversionFactor;

    return eStatus;
}

/**
 * @brief Validate temperature reading
 * @param fTemperature Temperature value to validate
 * @return pdTRUE if valid, pdFALSE otherwise
 */
static BaseType_t prvValidateTemperature(float fTemperature)
{
    BaseType_t xIsValid = pdFALSE;
    const float fMaxDelta = 10.0f;  // Maximum change per sample

    /* Range check */
    if((fTemperature >= MIN_TEMPERATURE_C) &&
       (fTemperature <= MAX_TEMPERATURE_C))
    {
        /* Rate of change check */
        float fDelta = fTemperature - s_fLastValidTemp;
        if((fDelta > -fMaxDelta) && (fDelta < fMaxDelta))
        {
            xIsValid = pdTRUE;
        }
    }

    return xIsValid;
}

/**
 * @brief Process temperature data (filtering, etc.)
 * @param pxData Pointer to temperature data structure
 */
static void prvProcessTemperature(TempData_t *pxData)
{
    /* Apply moving average filter */
    /* Detect trends */
    /* Trigger alarms if needed */
}

/**
 * @brief Handle error conditions
 * @param eError Error code
 */
static void prvHandleError(TempStatus_t eError)
{
    const char *pccErrorMsg;

    switch(eError)
    {
        case TEMP_OUT_OF_RANGE:
            pccErrorMsg = "Temperature out of range";
            break;
        case TEMP_SENSOR_FAULT:
            pccErrorMsg = "Sensor fault detected";
            s_eCurrentState = TEMP_STATE_ERROR;
            break;
        case TEMP_TIMEOUT:
            pccErrorMsg = "Sensor read timeout";
            break;
        default:
            pccErrorMsg = "Unknown error";
            break;
    }

    /* Log error */
    /* Send error notification */
}
```

---

## **6. QUICK REFERENCE TABLE**

| Item                          | Prefix      | Example               | Notes               |
| ----------------------------- | ----------- | --------------------- | ------------------- |
| **Functions returning void**  | `v`         | `vTaskDelay()`        | All void functions  |
| **Functions returning value** | `x`         | `xQueueSend()`        | Any non-void return |
| **Private/static functions**  | `prv`       | `prvInitialize()`     | File-scope only     |
| **Pointer return functions**  | `px`        | `pxGetBuffer()`       | Less common         |
| **char variable**             | `c`         | `cMyChar`             | 8-bit character     |
| **unsigned char**             | `uc`        | `ucByte`              | 8-bit unsigned      |
| **short**                     | `s`         | `sCounter`            | 16-bit signed       |
| **unsigned short**            | `us`        | `usValue`             | 16-bit unsigned     |
| **long**                      | `l`         | `lBigNumber`          | 32-bit signed       |
| **unsigned long**             | `ul`        | `ulTimestamp`         | 32-bit unsigned     |
| **float**                     | `f`         | `fTemperature`        | Single precision    |
| **double**                    | `d`         | `dPrecision`          | Double precision    |
| **enum**                      | `e`         | `eCurrentState`       | Enumeration         |
| **BaseType_t, handles**       | `x`         | `xResult`, `xQueue`   | FreeRTOS types      |
| **UBaseType_t**               | `ux`        | `uxPriority`          | Unsigned base       |
| **Pointer to type**           | `p` + type  | `pucBuffer`, `pxData` | Type + pointer      |
| **Pointer to const**          | `pc` + type | `pccString`           | Const pointer       |
| **Static variable**           | `s_`        | `s_ulCount`           | File scope          |
| **Global variable**           | `g_`        | `g_ulFlags`           | Global scope        |
| **Macros/constants**          | ALL_CAPS    | `MAX_SIZE`            | Preprocessor        |
| **Types**                     | suffix `_t` | `SensorData_t`        | Type definitions    |

---

## **7. COMMON MISTAKES TO AVOID**

❌ **Wrong:**

```c
void TaskSensor(void *params);           // Missing 'v' prefix
int readSensor(void);                    // Missing 'x' prefix
static void InitHardware(void);          // Missing 'prv' prefix
uint32_t counter;                        // Missing 'ul' prefix
float *temp;                             // Missing 'pf' prefix
```

✅ **Correct:**

```c
void vTaskSensor(void *pvParams);
BaseType_t xReadSensor(void);
static void prvInitHardware(void);
uint32_t ulCounter;
float *pfTemp;
```

---

## **8. WHY USE THESE CONVENTIONS?**

### Benefits:

1. **Type Safety:** Immediately know variable type without looking at declaration
2. **Scope Clarity:** Distinguish local, static, and global variables
3. **API Consistency:** All FreeRTOS APIs follow same pattern
4. **Code Reviews:** Easier to spot type mismatches and scope violations
5. **Portability:** Clear indication of data sizes (important for embedded systems)
6. **Standards Compliance:** Aligns with MISRA C guidelines for automotive/medical

### When to be strict:

- ✅ **Always** use for FreeRTOS API calls and task functions
- ✅ **Always** use for public interfaces
- ✅ **Recommended** for all application code in safety-critical projects
- ⚠️ **Optional** for very simple local variables in small functions
