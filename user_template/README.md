# HPM User Template

HPM (HPMicro) 嵌入式开发工程模板，基于 **Board/Interface/Driver/App** 四层架构。

## 架构概览

```
┌─────────────────────────────────────────────────────────┐
│                    App (纯业务逻辑)                       │
│              禁止包含任何 hpm_* 头文件                     │
├─────────────────────────────────────────────────────────┤
│                Interface (C11 抽象接口)                   │
│          intf_pwm.h / intf_uart.h / intf_spi.h          │
├─────────────────────────────────────────────────────────┤
│              Driver/hpm_impl (SDK 适配层)                 │
│            drv_pwm.c / drv_uart.c (唯一可调用             │
│                   hpm_sdk API 的地方)                    │
├─────────────────────────────────────────────────────────┤
│                Board (硬件配置层)                         │
│      board_pins.h (IOCFG) / board_init.c (时钟引脚)       │
│      user_board/ hpm5301evklite_board/ (板级 BSP)        │
└─────────────────────────────────────────────────────────┘
```

## 目录结构

```
user_template/
├── CMakeLists.txt              # 顶层构建配置
├── Makefile                    # 构建入口
├── Board/                      # 硬件配置层
│   ├── hpm_board_config/       # 板级初始化 (board_pins.h, board_init.c)
│   ├── user_board/             # 自定义板级 BSP
│   └── hpm5301evklite_board/   # HPM5301 EVK Lite BSP
├── Interface/                  # C11 抽象接口
│   ├── intf_pwm.h              # PWM 接口
│   ├── intf_adc.h              # ADC 接口
│   ├── intf_uart.h             # UART 接口
│   ├── intf_spi.h              # SPI 接口
│   ├── intf_i2c.h              # I2C 接口
│   └── intf_default.c          # 默认桩实现
├── Driver/
│   └── hpm_impl/               # HPM SDK 适配
│       ├── drv_pwm.c           # PWM 驱动实现
│       └── drv_uart.c          # UART 驱动实现
├── App/                        # 应用层
│   ├── main.c                  # 入口 (桥接初始化)
│   └── Logic/
│       └── app_logic.c         # 业务逻辑 (纯 C11)
├── linkers/                    # 链接脚本
│   ├── gcc/
│   ├── iar/
│   └── segger/
└── README.md
```

## 分层规则

| 层级 | 可包含头文件 | 职责 |
|------|-------------|------|
| **App** | `intf_*.h`, 标准 C | 纯业务逻辑，硬件无关 |
| **Interface** | 标准 C | 定义抽象接口，ops 注册机制 |
| **Driver** | `intf_*.h`, `hpm_*.h` | 实现接口，调用 SDK API |
| **Board** | `hpm_*.h` | 时钟、引脚初始化 |

## 快速开始

```bash
# 编译
make build

# 指定板级
make BOARD=hpm5301evklite_board build

# 导出产物
make artifacts

# 烧录
make flash
```

## 创建新工程（推荐）

建议在工作区根目录使用脚本创建新工程：

```bash
cd /workspace
bash tools/scripts/new_project <project_name>
```

脚本会自动：

- 复制本模板工程
- 将 `Board/user_board` 重命名为 `Board/<project_name>_board`
- 生成项目级 `.clangd`（相对路径）
- 生成 `<project_name>.code-workspace`（相对路径），并自动包含：
  - 新工程目录
  - `hpm_sdk`
  - `alliance_hpm_base_platform`

## 添加新外设接口

1. **Interface**: 创建 `intf_xxx.h`，定义 `intf_xxx_ops_t` 和 `intf_xxx_register()`
2. **Interface**: 在 `intf_default.c` 中添加桩实现
3. **Driver**: 创建 `drv_xxx.c`，实现 ops 并调用 `intf_xxx_register()`
4. **Board**: 在 `board_pins.h` 中添加引脚定义
5. **App**: 在 `main.c` 中调用注册函数

## 可用板级

| 板级 | 说明 |
|------|------|
| `user_board` | 自定义板级模板 (默认) |
| `hpm5301evklite_board` | HPM5301 EVK Lite 官方开发板 |

```bash
make list-boards
```

## 许可证

BSD-3-Clause
