# FK407 STM32CubeMX CMake 模板

本仓库是一个可复用的 STM32F407VETx 固件模板，由 STM32CubeMX 生成并使用 CMake 工具链构建。它包含一个最小化的 USART1 `Hello World` 启动测试、DAPLink/pyOCD 烧录支持，以及工作区本地的 VS Code 任务配置。

该模板有意不绑定到某一台电脑。用户相关的配置值，例如工具路径、pyOCD 目标名称和串口号，都集中在 `template.config.json` 中。

## 项目信息

- MCU：STM32F407VETx
- 构建系统：基于 Ninja 的 CMake Presets
- 工具链：用于裸机开发的 Arm GNU Toolchain，即 `arm-none-eabi-*`
- 调试/烧录探针：通过 pyOCD 使用 DAPLink / CMSIS-DAP
- 固件入口：`Core/Src/main.c`
- UART 测试：USART1，PA9 TX，PA10 RX，115200 8N1
- 调试输出：`build/Debug/FK407-template.elf`

## 安装前置工具

构建前请先安装以下工具：

- CMake 3.22 或更新版本
- Ninja
- Arm GNU Toolchain，包含 `arm-none-eabi-gcc`、`arm-none-eabi-gdb`、`arm-none-eabi-objcopy` 和 `arm-none-eabi-size`
- Python 3.x
- pyOCD：`python -m pip install -U pyocd`
- VS Code，推荐扩展：
  - `ms-vscode.cpptools`
  - `ms-vscode.cmake-tools`
  - `marus25.cortex-debug`
  - 可选：`ms-vscode.vscode-serial-monitor`

验证基础工具：

```powershell
cmake --version
ninja --version
arm-none-eabi-gcc --version
arm-none-eabi-gdb --version
python --version
pyocd --version
```

如果 `arm-none-eabi-gcc` 解析到了旧的厂商 SDK 副本，请在 `template.config.json` 中设置 `armToolchainBin`，不要依赖 PATH。

## 配置此模板

克隆后编辑 `template.config.json`：

```json
{
  "projectName": "FK407-template",
  "buildPreset": "Debug",
  "cmakePath": "cmake",
  "armToolchainBin": "",
  "pyocdPath": "pyocd",
  "pyocdTarget": "stm32f407vetx",
  "pyocdOptions": ["-O", "cmsis_dap.prefer_v1=true"],
  "serial": {
    "port": "COM8",
    "baudRate": 115200,
    "dataBits": 8,
    "parity": "None",
    "stopBits": "One"
  }
}
```

重要字段说明：

- `armToolchainBin`：如果正确的 Arm GNU Toolchain 已经位于 PATH 的最前面，则保持为空。当安装了多个工具链时，将其设置为绝对路径，例如 `C:\\Program Files\\Arm GNU Toolchain arm-none-eabi\\bin`。
- `pyocdPath`：使用 PATH 中的 `pyocd`，或者设置为 pyOCD 的绝对路径。
- `pyocdTarget`：pyOCD 目标名称。本模板使用 `stm32f407vetx`。
- `pyocdOptions`：对于在 Windows 上通过 CMSIS-DAP v1/HID 工作更稳定的 DAPLink 探针，保留 `cmsis_dap.prefer_v1=true`。
- `serial.port`：设置为本机 USB-UART 端口，例如 `COM8`。

如果在 CMake 已经配置过项目之后修改了 `armToolchainBin`，请删除 `build/Debug` 并重新配置，避免 CMake 缓存旧的编译器路径。

## 安装 MCU Pack

查找并安装该 MCU 对应的 pyOCD CMSIS-Pack：

```powershell
pyocd pack find STM32F407VETx
pyocd pack install STM32F407VETx
pyocd list --targets --name stm32f407vetx
```

本地的 `pyocd.yaml` 保存了适用于该系列开发板的 DAPLink/SWD 选项。目标型号本身通过 `template.config.json` 传入。

## 构建

推荐使用辅助命令：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/template-task.ps1 check-tools
powershell -NoProfile -ExecutionPolicy Bypass -File tools/template-task.ps1 configure
powershell -NoProfile -ExecutionPolicy Bypass -File tools/template-task.ps1 build
```

当 PATH 已经正确配置时，也可以直接使用原始 CMake 命令：

```powershell
cmake --preset Debug
cmake --build --preset Debug
```

预期输出：

```text
build/Debug/FK407-template.elf
```

## 使用 DAPLink 烧录

通过 DAPLink 连接开发板，并验证探针：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/template-task.ps1 probe
```

烧录当前 Debug ELF：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/template-task.ps1 flash
powershell -NoProfile -ExecutionPolicy Bypass -File tools/template-task.ps1 reset
```

等效的原始命令：

```powershell
pyocd flash -O cmsis_dap.prefer_v1=true --target stm32f407vetx build\Debug\FK407-template.elf
```

## 串口 Hello World 测试

固件会通过 USART1 每秒发送一次 `Hello World\r\n`。更新 `template.config.json` 中的 `serial.port` 后运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/template-task.ps1 serial-test
```

预期输出：

```text
Hello World
Hello World
Hello World
```

如果没有输出，请检查 UART TX/RX 是否交叉连接、是否共地、COM 端口是否选择正确、波特率是否正确，以及 USB-UART 适配器是否连接到 PA9/PA10。

如果辅助脚本提示 COM 端口无法打开，请先关闭其他串口终端。常见占用者包括 VS Code Serial Monitor、厂商串口桥接工具、PuTTY、Tera Term 或另一个 PowerShell 会话。

## VS Code

在 VS Code 中打开此文件夹，并使用以下任务：

- `Check Tools`
- `Probe DAPLink`
- `Configure Debug`
- `Build Debug`
- `Flash Debug`
- `Serial Test`

这些任务会调用 `tools/template-task.ps1`，因此会使用 `template.config.json`。

自动的 CMake 打开即配置功能被有意禁用。请使用 `Configure Debug`，这样辅助脚本可以在 CMake 选择编译器之前应用 `template.config.json`。

Cortex-Debug 启动配置为 `Debug STM32 via DAPLink`。它读取：

- 目标来自 `.vscode/settings.json` 中的 `fk407.pyocdTarget`
- GDB 路径来自 `.vscode/settings.json` 中的 `fk407.gdbPath`

如果 Cortex-Debug 无法从 PATH 中找到 GDB，请将 `fk407.gdbPath` 设置为 `arm-none-eabi-gdb` 的绝对路径。

## 固件自定义规则

大多数 CubeMX 生成的文件都可以重新生成。尽可能将应用代码放在 `/* USER CODE BEGIN ... */` 和 `/* USER CODE END ... */` 块中。

适合放置用户代码的位置：

- `Core/Src/main.c`：用于启动逻辑和主循环
- `Core/Src/<peripheral>.c` 的用户代码块：用于外设相关钩子
- `Core/Inc/<peripheral>.h` 的用户代码块：用于声明
- 顶层 `CMakeLists.txt`：用于额外的用户自有源文件

除非你明确接受 CubeMX 可能覆盖该文件，否则请避免手动编辑 `cmake/stm32cubemx/CMakeLists.txt`。

## 当前验证快照

在最初的 bring-up 电脑上，该模板使用以下环境验证通过：

- Arm GNU Toolchain 14.2.1
- pyOCD 0.44.0
- DAPLink CMSIS-DAP 探针
- COM8，115200 8N1

成功的串口输出为重复的 `Hello World` 行。其他用户不需要使用完全相同的工具版本，但应使用较新的 Arm GNU Toolchain，并为 `STM32F407VETx` 安装正确的 pyOCD pack。
