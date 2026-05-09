🌐 Language: [English](README.md) | [中文](README-ZH.md)
# FK407 STM32CubeMX CMake Template

This is a generic firmware template for **STM32F407VETx**, based on STM32CubeMX + CMake + Ninja. Out of the box, it supports:

- Building bare-metal firmware (`arm-none-eabi-*`)
- Flashing/reset via DAPLink/CMSIS-DAP + pyOCD
- A minimal UART connectivity check on USART1 (PA9/PA10, 115200 8N1)

The goal is simple: **start from a known-good baseline that can build, flash, and print over UART, then extend it for your own project**.

The template development and validation are based on the [FanKe Technology STM32F407VET6 Core Board](https://item.taobao.com/item.htm?abbucket=19&id=581847252103).

Of course, the template is not limited to this development board—or even to the F407 family. You can reuse its workflow and toolchain for other microcontrollers as well.

## When to use this template

- You want to start a new STM32F4 firmware project without building the CMake/toolchain setup from scratch.
- Your team needs one reusable template across different PCs via per-machine settings in `template.config.json`.
- You want to ask an agent to initialize and customize a project on top of this template.

## What is included

- MCU: `STM32F407VETx`
- Build: CMake Presets + Ninja
- Toolchain: Arm GNU Toolchain
- Flash/Debug: pyOCD (default target: `stm32f407vetx`)
- Example output: `build/Debug/FK407-template.elf`
- Main local config: `template.config.json`

## Quick start

You can complete most tasks in this template with Codex or similar tools. In most cases, you only need to connect the hardware correctly. If you are not sure how to wire the board, the tools can guide you step by step.

That said, if you have zero MCU experience, you may still run into practical issues during bring-up. This template is intended to be a good first hands-on embedded project with a clean baseline.

### 1) Connect the board

By default, this template uses:

- SWD for flashing and debugging
- USART for serial logging

You typically need:

- One SWD debugger (DAPLink recommended; ST-Link also works)
- One USB-to-UART adapter (some debuggers already include a USB CDC serial bridge)

#### SWD wiring

Connect your board pins to the SWD debugger:

| Board pin      | Debugger pin |
| -------------- | ------------ |
| SWDIO          | SWDIO        |
| SWCLK / SWC    | SWCLK        |
| 3.3V           | Vref / 3V3   |
| GND            | GND          |

> DAPLink is the preferred option for this template.
>
> Check that your debugger Vref is actually 3.3V.
>
> If your board supports it, powering the MCU from a dedicated 5V supply is usually better than powering the whole board from the debugger.

#### USART wiring

Connect board UART pins to your USB-to-UART adapter:

| Board pin | UART adapter pin |
| --------- | ---------------- |
| TX        | RX               |
| RX        | TX               |
| GND       | GND              |

> TX/RX must be crossed.
> Some debuggers (such as DAPLink variants) may already expose a serial interface, so an extra UART adapter may not be required.

---

### 2) Install dependencies

Required tools:

- CMake 3.22+
- Ninja
- Arm GNU Toolchain
- Python 3
- pyOCD

### 3) Update local config

Edit `template.config.json` after cloning. Usually you only need to set:

- `armToolchainBin` (can stay empty if PATH already points to the correct toolchain)
- `pyocdTarget` (default is `stm32f407vetx`)
- `serial.port` (for example `COM8`)

### 4) Configure and build

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/template-task.ps1 check-tools
powershell -NoProfile -ExecutionPolicy Bypass -File tools/template-task.ps1 configure
powershell -NoProfile -ExecutionPolicy Bypass -File tools/template-task.ps1 build
```

### 5) Flash the board

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/template-task.ps1 probe
powershell -NoProfile -ExecutionPolicy Bypass -File tools/template-task.ps1 flash
powershell -NoProfile -ExecutionPolicy Bypass -File tools/template-task.ps1 reset
```

### 6) UART check (optional)

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/template-task.ps1 serial-test
```

If wiring and port settings are correct, you should see repeated `Hello World` output.

## How to ask an agent to initialize your project

You can give an agent one clear prompt describing your target setup. Include:

- New project name (`projectName`)
- Target MCU (if not STM32F407VETx)
- Required peripherals (UART/SPI/I2C/CAN/USB, etc.)
- Flash/debug method and pyOCD target
- Serial test port and baud rate

Example prompt:

```text
Please initialize a new project from this template:
1) Rename projectName to MotorCtrl-F407
2) Keep DAPLink + pyOCD, target stm32f407vetx
3) Enable USART1 (115200) and SPI1
4) Run configure + build and confirm ELF output exists
5) Update README with build and flash instructions
```

An agent can also help with:

- Adding new source files and modular folders
- Restructuring CMake targets
- Updating VS Code tasks/launch settings
- Adding minimal validation code (for example UART echo, SPI loopback)

## Repository map

- `FK407-template.ioc`: CubeMX project source
- `template.config.json`: user-editable local config
- `tools/template-task.ps1`: helper entrypoint for common actions
- `Core/`, `Drivers/`: firmware source and HAL/CMSIS
- `cmake/`: toolchain and CMake helper scripts

---

If you only want to get started quickly, follow **Quick start**. If you want to customize quickly, give your requirements to an agent and let it initialize from this template.
