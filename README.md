# Alliance-HPM-Dev 使用说明

## 1. 工作区定位

本仓库是一个基于 **HPM SDK** 的嵌入式开发工作区，核心目标是：

- 以 `user_template` 作为用户工程模板，快速复制出新项目
- 复用 `alliance_hpm_base_platform` 中的通用业务驱动封装
- 依赖 `hpm_sdk` 完成底层 BSP、驱动、中间件与工具链集成

## 2. 目录组成

```text
/workspace
├── user_template/                 # 用户工程模板（主入口）
├── alliance_hpm_base_platform/    # 通用平台层（GPIO/UART/SPI/CAN等）
├── hpm_sdk/                       # HPM 官方 SDK（子模块）
├── tools/
│   ├── scripts/                   # 辅助脚本（build_ui/openocd安装）
│   └── openocd-hpm/               # HPM OpenOCD 安装目录
├── .envrc                         # 进入目录后自动加载开发环境
├── .devcontainer/                 # Dev Container 配置
└── Dockerfile                     # 开发镜像定义
```

## 3. 关键模块说明

### 3.1 `user_template/`

用于创建新工程，包含：

- `Makefile`：统一构建入口（`configure/build/artifacts/clean`）
- `user_app/`：应用代码（`main.c` 等）
- `user_board/`：板级文件（`board.*`、`pinmux.*`、`user_board.yaml/cfg`）
- `linkers/`：GCC / IAR / Segger 链接脚本

构建状态展示由 `Makefile` 调用：

- `tools/scripts/build_ui.sh`

### 3.2 `alliance_hpm_base_platform/`

放置可在多个项目复用的通用封装代码，如：

- `gpio/`
- `uart/`
- `spi/`（含 BMI088 相关头文件）
- `can/`

`user_template/user_app/CMakeLists.txt` 支持按需开启公共平台头文件引入。

### 3.3 `hpm_sdk/`

官方 SDK（当前工作区通过 `HPM_SDK_BASE=/workspace/hpm_sdk` 使用）。

### 3.4 `tools/`

- `tools/scripts/build_ui.sh`：构建结果汇总与错误提取
- `tools/scripts/install-hpm-openocd.sh`：OpenOCD 安装脚本
- `tools/openocd-hpm/install/bin/openocd`：OpenOCD 可执行程序

## 4. 快速开始

### 4.1 初始化环境

推荐使用 `direnv` 自动加载 `.envrc`：

```bash
cd /workspace
direnv allow
```

检查关键变量：

```bash
echo "$HPM_SDK_BASE"
echo "$GNURISCV_TOOLCHAIN_PATH"
which riscv32-unknown-elf-gcc
```

### 4.2 编译模板工程

```bash
cd /workspace/user_template
make build
```

导出产物（到 `user_template/output/`）：

```bash
make artifacts
```

## 5. 基于模板创建新工程

```bash
cd /workspace
cp -a user_template my_project
cd my_project
make clean
make build
```

说明：

- `make clean` 很重要，可避免复制来的旧 `build/CMakeCache.txt` 导致路径冲突。
- 产物默认在 `my_project/output/`。

## 6. 常用构建命令

```bash
make configure
make build
make artifacts
make clean
```

可覆盖参数示例：

```bash
make build BOARD=user_board CMAKE_BUILD_TYPE=Release HPM_BUILD_TYPE=flash_xip
```

## 7. 使用技巧（建议）

- 复制模板后第一步执行 `make clean`，避免缓存污染。
- 板级命名保持一致：目录名、`board.name`、配置文件语义一致。
- 日常排障先看 `build/last_build.log`，再结合 `build_ui.sh` 汇总信息定位。
- 如果要长期复用公共模块，优先放在 `alliance_hpm_base_platform/`，项目仅保留应用与板级差异。
- 需要重新生成 IDE 工程（IAR/Segger）时，先 `make clean` 再 `make build`。

## 8. 常见问题

### Q1: 复制模板后第一次构建失败，提示 CMakeCache 路径不一致

原因：复制时带上了旧 `build/`。

处理：

```bash
make clean
make build
```

### Q2: 找不到 SDK 或工具链

先确认已执行 `direnv allow`，并检查：

```bash
echo "$HPM_SDK_BASE"
echo "$GNURISCV_TOOLCHAIN_PATH"
```

## 9. Dev Container 环境搭建

本项目提供 `.devcontainer/devcontainer.json`，在 VS Code 中一键启动容器化开发环境。

### 9.1 平台差异说明

| 平台 | 挂载方式 | opencode/codex/claude 配置共享 |
|------|---------|-------------------------------|
| **Windows + Docker Desktop（默认）** | WSL UNC + `USERPROFILE` 双挂载 | ✅ 自动符号链接（含 XDG 路径） |
| **Arch Linux（原生 Docker）** | `${localEnv:HOME}` 单挂载 | ✅ 自动符号链接（需手动切换配置） |

### 9.2 Windows + Docker Desktop（👈 默认配置）

默认挂载两个目录：

| 挂载 | 来源 | 容器路径 | 用途 |
|------|------|---------|------|
| WSL home | `\\wsl.localhost\archlinux\home\kaiser` | `/mnt/wsl-home` | opencode 二进制 (`~/.opencode`) |
| Windows 用户目录 | `%USERPROFILE%` | `/mnt/win-home` | opencode XDG 配置 (`~/.config/opencode`) + 认证 (`~/.local/share/opencode`) |

容器启动后自动完成：

```
/mnt/wsl-home/.opencode                   → ~/.opencode          (二进制)
/mnt/win-home/.config/opencode            → ~/.config/opencode   (配置)
/mnt/win-home/.local/share/opencode       → ~/.local/share/opencode (auth)
/mnt/*/.codex / .claude                   → ~/.codex / ~/.claude
export PATH="$HOME/.opencode/bin:$PATH"   → ~/.zshrc
```

> **自定义路径**：如果 WSL 发行版名或用户名不同，修改第一个 mount 的 source：
> ```jsonc
> "source": "\\\\wsl.localhost\\<你的发行版>\\home\\<你的用户名>"
> ```

### 9.3 Arch Linux（原生 Docker）

1. 注释掉两个 Windows 挂载块
2. 取消注释 `${localEnv:HOME}` 挂载块（文件中有注释指引）

```jsonc
"mounts": [
    { "source": "/dev", "target": "/dev", "type": "bind" },
    // 注释掉 WSL 和 USERPROFILE 两个挂载块 ↑
    // 取消注释下面 ↓
    {
        "source": "${localEnv:HOME}",
        "target": "/mnt/home",
        "type": "bind"
    }
]
```

容器启动后自动符号链接宿主机 `~/.codex`、`~/.claude`、`~/.opencode` 及 XDG 路径。

### 9.4 镜像内容

首次启动自动构建 Docker 镜像（基于 `Dockerfile`），包含：

- Ubuntu 24.04 / GCC-14 / RISC-V GNU Toolchain（交叉编译）
- LLVM clangd（代码智能提示）/ CMake / Ninja / Make
- OpenOCD 依赖库 / Oh-My-Zsh / direnv
- 后续启动复用镜像缓存，无需重新构建

---

## 10. 推荐阅读

- 模板详细说明：`/workspace/user_template/README_zh.md`
- SDK 总览：`/workspace/hpm_sdk/README_zh.md`
