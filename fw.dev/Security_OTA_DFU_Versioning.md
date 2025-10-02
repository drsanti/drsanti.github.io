[« Previous](./Logging_Diagnostics_Telemetry.md) | [Index](./index.md) | [Next »](./index.md)

---

# Firmware Coding Standard — Security, OTA/DFU & Versioning (FreeRTOS)

## 1) Purpose

Define best practices for secure firmware operation, over-the-air updates (OTA) or device firmware upgrades (DFU), and versioning strategy. Ensure devices are updatable, traceable, and protected against tampering.

---

## 2) Principles

* **Security first**: All update paths must be authenticated and integrity-protected.
* **Never brick**: OTA/DFU must always have a safe rollback path.
* **Deterministic versioning**: Every binary has a unique version, reproducible build ID, and changelog reference.
* **Minimal trust**: Device trusts only signed firmware from authorized keys.

---

## 3) Secure Boot & Verification

* Bootloader validates firmware image before execution:

  * **Cryptographic signature check** (ECDSA, Ed25519, or RSA).
  * **Hash validation** (SHA-256).
* Bootloader must reject unsigned/invalid firmware.
* Public keys stored in ROM, OTP fuses, or protected flash.

---

## 4) OTA/DFU Rules

* **Dual-bank or A/B scheme**: Always keep a fallback image in case update fails.
* **Atomic commit**: New firmware marked "valid" only after first successful boot.
* **Power failure resilience**: Updates must tolerate reset during transfer.
* **Transport security**:

  * Use TLS or encrypted/authenticated channels for OTA.
  * If OTA via UART/USB (DFU), require signed image.

---

## 5) Versioning & Build Metadata

* Every build must embed:

  * Semantic version: `MAJOR.MINOR.PATCH`.
  * Git commit hash or equivalent build ID.
  * Build timestamp (UTC).
  * Hardware target ID.
* Version info accessible at runtime (e.g., via CLI, telemetry).
* Strict policy: **never release "dirty" builds** (uncommitted changes).

---

## 6) Rollback & Recovery

* Bootloader keeps track of:

  * Active image (A or B).
  * Last known good image.
  * Failure counters (boot loops trigger fallback).
* If system crashes repeatedly after new firmware → auto-rollback.
* Firmware can request rollback explicitly if self-test fails.

---

## 7) Security Rules

* All sensitive keys stored in secure elements, OTP, or encrypted storage.
* Debug interfaces (SWD, JTAG) locked in production builds.
* Firmware must wipe RAM with secrets on reset/shutdown.
* Cryptographic libraries must come from audited sources, never “homegrown crypto”.

---

## 8) Anti-Patterns

* Single-bank OTA with no fallback → risk of bricking.
* Updates without integrity/signature check.
* Hardcoded credentials in firmware image.
* Relying on debug builds for production deployment.
* Version strings manually edited instead of auto-generated.

---

## 9) Review Checklist

* [ ] Firmware image signed and validated at boot.
* [ ] Dual-bank update scheme implemented (rollback possible).
* [ ] OTA/DFU transfer is authenticated and integrity-checked.
* [ ] Update process tested with power loss mid-transfer.
* [ ] Version metadata embedded and accessible at runtime.
* [ ] Rollback policy tested (boot loop, self-test failure).
* [ ] Debug ports locked in production.
* [ ] Secrets stored only in secure regions.

---

## 10) CI/Lint Gates

* Fail build if:

  * Version string missing or set to placeholder.
  * Build made from dirty Git tree.
  * Crypto functions called directly instead of wrapper API.
  * DFU image generated without signature.

---

## 11) Example Patterns

**Version info in firmware**

```c
const fw_version_t fw_version __attribute__((section(".version"))) = {
    .major = 1,
    .minor = 4,
    .patch = 2,
    .git_hash = GIT_HASH,
    .build_date = __DATE__,
    .build_time = __TIME__,
};
```

**Bootloader validation**

```c
if (!verify_signature(image_addr, image_len, public_key)) {
    LOG_CRIT("BOOT", "Signature check failed, reverting...");
    boot_select_backup();
}
```

**OTA commit flag**

```c
void ota_commit_success(void) {
    storage_write_flag(OTA_VALID_IMAGE, 1);
}
```

---

[« Previous](./Logging_Diagnostics_Telemetry.md) | [Index](./index.md) | [Next »](./index.md)
