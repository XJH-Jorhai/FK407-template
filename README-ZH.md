🌐 Language: [English](README.md) | [中文](README-ZH.md)
# FK407 STM32CubeMX CMake Template

这是一个面向 **STM32F407VETx** 的通用固件模板，基于 STM32CubeMX + CMake + Ninja，开箱可用于：

- 生成并构建裸机工程（`arm-none-eabi-*`）
- 使用 DAPLink/CMSIS-DAP + pyOCD 下载和复位
- 通过 USART1（PA9/PA10, 115200 8N1）做最小串口连通性验证

模板的目标是：**让你快速从一个可编译、可下载、可串口验证的基线开始，再按你的项目需求扩展**。

## 这个模板适合什么场景

- 你要新建 STM32F4 固件项目，但不想从零配工具链和 CMake。
- 你希望团队成员在不同电脑上，通过 `template.config.json` 填写本机路径后即可复用同一模板。
- 你希望后续让 Agent 在这个基线上自动化完成初始化、外设改造或代码生成。

## 模板包含什么

- MCU: `STM32F407VETx`
- Build: CMake Presets + Ninja
- Toolchain: Arm GNU Toolchain
- Flash/Debug: pyOCD（默认 target: `stm32f407vetx`）
- 示例输出: `build/Debug/FK407-template.elf`
- 主配置文件: `template.config.json`

## 快速开始（使用者视角）

### 1) 安装依赖

至少需要：

- CMake 3.22+
- Ninja
- Arm GNU Toolchain
- Python 3
- pyOCD

### 2) 修改本机配置

克隆后先编辑 `template.config.json`，重点填写：

- `armToolchainBin`（如 PATH 中已有正确工具链可留空）
- `pyocdTarget`（本模板默认 `stm32f407vetx`）
- `serial.port`（如 `COM8`）

### 3) 配置并编译

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/template-task.ps1 check-tools
powershell -NoProfile -ExecutionPolicy Bypass -File tools/template-task.ps1 configure
powershell -NoProfile -ExecutionPolicy Bypass -File tools/template-task.ps1 build
```

### 4) 下载到板子

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/template-task.ps1 probe
powershell -NoProfile -ExecutionPolicy Bypass -File tools/template-task.ps1 flash
powershell -NoProfile -ExecutionPolicy Bypass -File tools/template-task.ps1 reset
```

### 5) 串口验证（可选）

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/template-task.ps1 serial-test
```

若连接正确，应看到周期性 `Hello World` 输出。

## 如何让 Agent 基于模板初始化你的工程

你可以直接给 Agent 一段需求，让它在这个模板上完成初始化。建议一次说清以下信息：

- 新工程名（projectName）
- 目标 MCU（若不是 STM32F407VETx）
- 你要启用的外设（UART/SPI/I2C/CAN/USB 等）
- 调试下载方式（DAPLink/ST-Link、pyOCD target）
- 串口测试端口与波特率

示例指令：

```text
请基于这个模板初始化一个新工程：
1) projectName 改为 MotorCtrl-F407
2) 保留 DAPLink + pyOCD，target 使用 stm32f407vetx
3) 开启 USART1(115200) 和 SPI1
4) 生成后完成 configure + build，确认 elf 产物存在
5) 更新 README，写清楚如何编译和下载
```

如果你需要，Agent 也可以继续帮你做：

- 增加新的源文件与模块化目录
- 调整 CMake 结构
- 添加 VS Code task / launch 配置
- 增加最小功能自测代码（比如串口回显、SPI 回环）

## 目录速览

- `FK407-template.ioc`：CubeMX 工程源
- `template.config.json`：本机可编辑配置
- `tools/template-task.ps1`：常用任务入口
- `Core/`、`Drivers/`：固件源码与 HAL/CMSIS
- `cmake/`：工具链与 CMake 辅助脚本

---

如果你只想“尽快开始”，按“快速开始”执行即可；如果你要“快速定制”，把需求直接交给 Agent，让它在此模板上自动完成初始化和首轮验证。
