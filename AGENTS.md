# Agent Guide For This STM32 Template

This file is for Codex or other coding agents working in this repository. It summarizes the STM32CubeMX CMake workflow so agents do not need a local custom skill installed.

## Project Identity

- This is a generic STM32CubeMX CMake template, not an application-specific product.
- MCU source of truth: `FK407-template.ioc`.
- Current MCU: `STM32F407VETx`.
- Current pyOCD target: `stm32f407vetx`.
- Current UART bring-up: USART1 on PA9 TX and PA10 RX, 115200 8N1.
- Current build output: `build/Debug/FK407-template.elf`.
- User-editable host configuration: `template.config.json`.

## Windows And PowerShell

- Assume commands run in PowerShell.
- Prefer native PowerShell syntax; do not use Bash heredocs or process substitution.
- Prefer `rg` for searches when available.
- If a command fails because of quoting, execution policy, or shell syntax, switch strategy immediately.
- For VS Code tasks, this template uses `powershell -NoProfile -ExecutionPolicy Bypass -File tools/template-task.ps1 ...`.

## Toolchain Baseline

Expected tools:

- CMake 3.22 or newer
- Ninja
- Arm GNU Toolchain for `arm-none-eabi-gcc`, `arm-none-eabi-g++`, `arm-none-eabi-gdb`, `arm-none-eabi-objcopy`, `arm-none-eabi-size`
- Python 3.x
- pyOCD for CMSIS-DAP/DAPLink flash and debug
- VS Code extensions: C/C++, CMake Tools, Cortex-Debug, optionally Serial Monitor

Validate before firmware changes:

```powershell
cmake --version
ninja --version
arm-none-eabi-gcc --version
arm-none-eabi-gdb --version
python --version
pyocd --version
```

If `arm-none-eabi-gcc` resolves to an old vendor SDK copy, do not continue blindly. Set `armToolchainBin` in `template.config.json` or set `ARM_GNU_TOOLCHAIN_BIN` so CMake uses a modern Arm GNU Toolchain.

## Files To Read First

When entering the project, inspect:

```powershell
Get-Content .\template.config.json
Get-Content .\CMakePresets.json
Get-Content .\CMakeLists.txt
Get-Content .\cmake\gcc-arm-none-eabi.cmake
Get-Content .\cmake\stm32cubemx\CMakeLists.txt
Select-String -Path .\*.ioc -Pattern 'Mcu\.|ProjectManager.TargetToolchain|USART|SPI|I2C|RCC'
```

Also inspect peripheral code before using handles:

```powershell
Get-Content .\Core\Src\main.c
Get-Content .\Core\Src\usart.c
Get-Content .\Core\Inc\usart.h
```

Derive MCU, pins, clocks, linker script, startup file, and UART handle from the current project files. Do not copy target names from another STM32 project.

## CubeMX CMake Shape

Expected structure:

- `.ioc`: source of truth for MCU part, pinout, peripherals, clock tree, firmware package, and `TargetToolchain=CMake`.
- `CMakeLists.txt`: top-level CMake entry and user-owned extension point.
- `CMakePresets.json`: Debug/Release configure and build presets using Ninja.
- `cmake/gcc-arm-none-eabi.cmake`: cross toolchain file, CPU flags, linker script, nano specs, map output, memory usage output.
- `cmake/stm32cubemx/CMakeLists.txt`: generated source aggregation and HAL/CMSIS include paths.
- `Core/Inc` and `Core/Src`: generated application headers and sources.
- `Drivers`: HAL/LL and CMSIS drivers.
- `startup_stm32*.s`: vector table/reset startup.
- `STM32*_FLASH.ld`: flash/RAM memory map.

## Firmware Editing Rules

- Treat CubeMX-generated code as regenerable.
- Put application logic inside `/* USER CODE BEGIN ... */` and `/* USER CODE END ... */` blocks.
- Good locations:
  - `Core/Src/main.c` for simple bring-up and main loop logic.
  - `Core/Src/<peripheral>.c` user blocks for peripheral hooks.
  - `Core/Inc/<peripheral>.h` user blocks for declarations.
  - top-level `CMakeLists.txt` for new user-owned modules.
- Avoid editing `cmake/stm32cubemx/CMakeLists.txt` for user modules unless there is a clear reason.
- Keep template changes small and generic. Do not add application-specific protocols or host software.

Minimal UART pattern:

```c
/* USER CODE BEGIN 2 */
uint8_t msg[] = "Hello World\r\n";
/* USER CODE END 2 */

/* USER CODE BEGIN 3 */
HAL_UART_Transmit(&huart1, msg, sizeof(msg) - 1U, HAL_MAX_DELAY);
HAL_Delay(1000);
/* USER CODE END 3 */
```

Always replace `huart1` with the handle declared by the generated `Core/Inc/usart.h` if the UART changes.

## Build Workflow

Preferred helper commands:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/template-task.ps1 check-tools
powershell -NoProfile -ExecutionPolicy Bypass -File tools/template-task.ps1 configure
powershell -NoProfile -ExecutionPolicy Bypass -File tools/template-task.ps1 build
```

Raw CMake equivalent:

```powershell
cmake --preset Debug
cmake --build --preset Debug
```

After build, verify:

- The compiler is a modern Arm GNU Toolchain, not an unrelated vendor SDK.
- The linker prints flash/RAM usage.
- `build/Debug/FK407-template.elf` exists.
- Warnings are understood before calling the build clean.

## DAPLink And pyOCD

Use pyOCD for CMSIS-DAP/DAPLink:

```powershell
pyocd pack find STM32F407VETx
pyocd pack install STM32F407VETx
pyocd list --targets --name stm32f407vetx
pyocd list --probes -O cmsis_dap.prefer_v1=true
```

If Windows probe enumeration fails through libusb or CMSIS-DAP v2, prefer CMSIS-DAP v1/HID with:

```powershell
-O cmsis_dap.prefer_v1=true
```

Flash/reset through the template helper:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/template-task.ps1 flash
powershell -NoProfile -ExecutionPolicy Bypass -File tools/template-task.ps1 reset
```

Raw command:

```powershell
pyocd flash -O cmsis_dap.prefer_v1=true --target stm32f407vetx build\Debug\FK407-template.elf
```

Use the part name from `.ioc` or `pyocd list --targets`, normalized to pyOCD's target name. Do not trust the probe's self-reported board target if it conflicts with the CubeMX MCU.

## Serial Bring-up

For UART verification, derive the active UART instance, pins, and baud rate from:

- `.ioc`
- `Core/Src/usart.c`
- `Core/Inc/usart.h`

This template currently uses USART1, PA9/PA10, 115200 8N1. The helper reads the COM port from `template.config.json`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/template-task.ps1 serial-test
```

If serial output is missing, check COM port, baud rate, TX/RX crossover, shared ground, alternate function/remap, and whether the firmware uses the same `huartX` as the wired UART.

## Troubleshooting

- `cmake` missing: install CMake or set `cmakePath` in `template.config.json`.
- `ninja` missing: install Ninja and make it available from PATH.
- Wrong GCC selected: set `armToolchainBin` in `template.config.json`, then delete `build/Debug` and reconfigure.
- Configure fails: inspect `cmake/gcc-arm-none-eabi.cmake`, linker script path, and `CMakePresets.json`.
- Missing HAL symbols: check `cmake/stm32cubemx/CMakeLists.txt` and `stm32f4xx_hal_conf.h`.
- pyOCD target not found: install the correct CMSIS-Pack and verify with `pyocd list --targets --name <target>`.
- pyOCD probe enumeration fails: try `cmsis_dap.prefer_v1=true` and confirm the probe appears as CMSIS-DAP/HID.
- Flash succeeds but firmware does not run: reset target, check boot pins, power, SWD wiring, flash origin, and clock configuration.
- UART output missing: check wiring and UART instance before changing firmware.
- COM port access denied: another serial monitor or bridge likely owns the port. Do not kill user processes automatically; report the owner candidates and ask the user to close the serial tool.

## Completion Criteria

Treat a bring-up task as complete only when these pass:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/template-task.ps1 check-tools
powershell -NoProfile -ExecutionPolicy Bypass -File tools/template-task.ps1 configure
powershell -NoProfile -ExecutionPolicy Bypass -File tools/template-task.ps1 build
powershell -NoProfile -ExecutionPolicy Bypass -File tools/template-task.ps1 probe
powershell -NoProfile -ExecutionPolicy Bypass -File tools/template-task.ps1 flash
```

For UART work, also confirm expected bytes from the configured serial port.
