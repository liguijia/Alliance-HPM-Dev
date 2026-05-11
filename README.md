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

### 9.1 双配置开箱即用方案

当前仓库提供两套 Dev Container 配置：

| 配置目录 | 适用场景 | Home 来源 |
|---------|---------|----------|
| `.devcontainer/` | 默认推荐，Windows / Docker Desktop | `${localEnv:USERPROFILE}` |
| `.devcontainer-linux/` | Linux / Arch Linux 主机 | `${localEnv:HOME}` |
| `.devcontainer-windows/` | Windows fallback（与默认等价保留） | `${localEnv:USERPROFILE}` |

推荐选择策略：

- **Windows / Docker Desktop**：直接使用默认 `.devcontainer/`
- **Arch Linux / Linux**：使用 `.devcontainer-linux/`
- **Windows fallback**：如需保留旧选择方式，也可继续使用 `.devcontainer-windows/`

### 9.2 Root 用户模式

**当前容器统一以 `root` 用户直接运行，不再创建普通用户（如 `alliance`）。**

容器内 `HOME=/root`，所有持久化数据均存放于 `/root` 下：

| 目录 | 用途 |
|------|------|
| `/root/.config/opencode` | opencode 配置（插件、命令、主题等） |
| `/root/.local/share/opencode` | opencode 运行时数据（auth.json 等） |
| `/root/.cache/opencode` | opencode 缓存 |
| `/root/.codex` / `.claude` / `.agents` | 从宿主机 symlink 的 AI 工具配置 |

脚本会自动探测宿主机目录布局并完成 symlink / 文件复制：

```text
/host-home/.codex or .config/codex               → /root/.codex
/host-home/.claude or .config/claude             → /root/.claude
/host-home/.agents or .config/agents             → /root/.agents
/host-home/.config/opencode                      → /root/.config/opencode
/host-home/AppData/Roaming/opencode              → /root/.config/opencode
/host-home-ro/.local/share/opencode/auth.json          → /root/.local/share/opencode/auth.json
/host-home-ro/AppData/Local/opencode/auth.json         → /root/.local/share/opencode/auth.json
```

> 说明：`opencode` CLI 本体已在镜像内安装，因此不再依赖宿主机 `~/.opencode/bin/opencode`。

### 9.3 Windows 默认方案（`.devcontainer/`）

当前默认 Dev Container 面向 **Windows + Docker Desktop**，使用 `USERPROFILE` 作为宿主机 Home 来源：

| 挂载 | 来源 | 容器路径 | 用途 |
|------|------|---------|------|
| Host Home | `${localEnv:USERPROFILE}` | `/host-home` | 共享 `~/.codex`、`~/.claude`、`~/.agents`、opencode 配置 |
| Host Home(只读) | `${localEnv:USERPROFILE}` | `/host-home-ro` | 只读读取 opencode 认证数据 |
| Docker Volume | `alliance-hpm-dev-opencode-data` | `/root/.local/share/opencode` | 容器内持久化 opencode 数据 |
| Docker Volume | `alliance-hpm-dev-opencode-cache` | `/root/.cache/opencode` | 容器内持久化 opencode 缓存 |

### 9.4 Linux / Arch Linux 方案（`.devcontainer-linux/`）

如果你的宿主机本身就是 Linux / Arch Linux，请选择：

- 配置目录：`.devcontainer-linux/`
- Home 挂载来源：`${localEnv:HOME}`

该配置会自动兼容：

- `$HOME/.config/opencode`
- `$HOME/.local/share/opencode`
- `$HOME/.codex`
- `$HOME/.claude`
- `$HOME/.agents`

### 9.5 Windows fallback 方案（`.devcontainer-windows/`）

如果你的 Windows 宿主机里 `HOME` 不存在，或者 VS Code / Docker Desktop 无法正确解析 `${localEnv:HOME}`，请改用：

- 配置目录：`.devcontainer-windows/`
- Home 挂载来源：`${localEnv:USERPROFILE}`

其余行为与默认方案保持一致：

- `opencode` CLI 仍然在镜像内安装
- 配置/认证仍然自动探测
- 仍然使用同一套 `post-create.sh`

### 9.6 开箱即用前提

为了保证 Windows 和 Arch Linux 都能开箱即用，请确保宿主机至少满足以下之一：

#### Windows（默认配置 `.devcontainer/`）

- opencode 配置位于以下任一位置：
  - `%USERPROFILE%\AppData\Roaming\opencode`
  - `%USERPROFILE%\.config\opencode`

#### Windows（fallback 配置 `.devcontainer-windows/`）

- `USERPROFILE` 环境变量正常存在
- 推荐 opencode 配置位于以下任一位置：
  - `%USERPROFILE%\AppData\Roaming\opencode`
  - `%USERPROFILE%\.config\opencode`

#### Arch Linux / Linux（配置 `.devcontainer-linux/`）

- `HOME` 环境变量正常存在
- 推荐使用标准 XDG 路径：
  - `$HOME/.config/opencode`
  - `$HOME/.local/share/opencode`

### 9.7 在 VS Code 中如何选择配置

如果 VS Code 检测到多个 Dev Container 配置目录，通常会提示你选择。

建议这样选：

- Windows / Docker Desktop：选 `.devcontainer/`
- Linux / Arch Linux：选 `.devcontainer-linux/`
- 如果要保留 Windows 备用配置，也可以选 `.devcontainer-windows/`

如果当前已经打开了错误配置，可以：

1. `Dev Containers: Reopen Folder Locally`
2. 再执行 `Dev Containers: Reopen in Container`
3. 选择正确的配置目录

### 9.8 如果容器里已有 `codex` / `claude` 但没有 `opencode`

这通常说明当前容器是基于旧镜像创建的，还没包含最新的 `opencode-ai` 安装步骤。

处理方式二选一：

1. **推荐：重建容器**

   - `Dev Containers: Rebuild and Reopen in Container`

2. **快速修复：在容器内手动重跑初始化脚本**

   ```bash
   bash .devcontainer/post-create.sh
   ```

该脚本现在会在发现 `opencode` 缺失时自动执行：

```bash
npm install -g opencode-ai
```

修复后可验证：

```bash
which opencode
opencode --version
```

> 说明：当前配置**不会**在镜像构建阶段执行 `npm install -g npm@latest`，也不再依赖 `NodeSource setup_22.x` 脚本。这是为了避免某些网络 / 源组合下出现类似 `Cannot find module 'promise-retry'` 或 NodeSource 初始化失败的构建问题。

### 9.9 镜像内容

首次启动自动构建 Docker 镜像（基于 `Dockerfile`），包含：

- Ubuntu 24.04 / GCC-14 / RISC-V GNU Toolchain（交叉编译）
- LLVM clangd（代码智能提示）/ CMake / Ninja / Make
- OpenOCD 依赖库 / Oh-My-Zsh / direnv
- 后续启动复用镜像缓存，无需重新构建

### 9.10 Root 使用验证步骤

容器启动后，在终端中执行以下命令验证 root 模式已生效：

```bash
# 1. 确认当前用户为 root
whoami
# 期望输出: root

# 2. 确认 HOME 指向 /root
echo "$HOME"
# 期望输出: /root

# 3. 确认工作目录为 /workspace
pwd
# 期望输出: /workspace

# 4. 确认 opencode / codex / claude CLI 可用
which opencode && opencode --version
which codex && codex --version
which claude && claude --version

# 5. 确认 AI 工具配置已从宿主机同步
ls -la /root/.codex
ls -la /root/.claude
ls -la /root/.config/opencode

# 6. 确认环境变量已设置
echo "$HPM_SDK_BASE"
echo "$GNURISCV_TOOLCHAIN_PATH"
which riscv32-unknown-elf-gcc
```

---

## 10. 推荐阅读

- 模板详细说明：`/workspace/user_template/README_zh.md`
- SDK 总览：`/workspace/hpm_sdk/README_zh.md`
