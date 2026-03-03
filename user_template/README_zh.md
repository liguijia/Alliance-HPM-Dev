# 用户工程模板（user_template）

## 1. 模板定位

`user_template` 用于快速创建一个可编译的 HPMicro 用户工程，包含：

- 应用入口与业务代码骨架（`user_app`）
- 板级支持包骨架（`user_board`）
- 三套工具链链接脚本（`linkers`）
- 统一构建入口（`Makefile`）

该模板只承载“单工程所需最小内容”，通用平台代码放在仓库根目录独立维护：

- `/workspace/alliance_hpm_base_platform`（可选引用）

## 2. 目录说明

```text
user_template/
├── Makefile
├── user_app/
│   ├── CMakeLists.txt
│   ├── inc/
│   └── src/main.c
├── user_board/
│   ├── CMakeLists.txt
│   ├── board.c / board.h
│   ├── pinmux.c / pinmux.h
│   ├── user_board.yaml
│   └── user_board.cfg
├── linkers/
│   ├── gcc/user_linker.ld
│   ├── iar/user_linker.icf
│   └── segger/user_linker.icf
└── README_zh.md
```

## 3. 构建工作流

`Makefile` 已封装 CMake + Ninja 工作流，默认流程如下：

1. 自动识别板目录：在工程根目录查找 `*_board` 目录，提取 `BOARD` 名称。  
   当前模板默认识别为 `user_board`。
2. 配置阶段：执行 `cmake -S user_app -B build` 并传入板型、架构、ABI 等参数。
3. 编译阶段：执行 `cmake --build build -j`。
4. 产物阶段（`make artifacts`）：将 `build/output/demo.*` 复制为 `output/<项目名>.*`。

常用命令：

```bash
make configure     # 仅配置
make build         # 配置 + 编译
make artifacts     # 配置 + 编译 + 导出产物到 output/
make clean         # 清理 .cache/build/output
```

可覆盖变量（示例）：

```bash
make build BOARD=user_board CMAKE_BUILD_TYPE=Release HPM_BUILD_TYPE=flash_xip
```

## 4. 新建工程推荐方式

推荐从“干净模板”创建新工程：

1. 复制模板目录并重命名，例如 `my_project`
2. 删除缓存目录（若存在）：`build/`、`output/`、`.cache/`
3. 在新目录执行 `make build`

示例：

```bash
cp -a user_template my_project
cd my_project
make clean
make build
```

## 5. 重要注意事项（复制后首编失败的常见原因）

如果复制时把旧的 `build/CMakeCache.txt` 一起带过去，首次构建可能报错：

- 新目录路径与缓存中的旧 source/build 路径不一致

处理方式：

- 执行 `make clean` 后重新 `make build`
- 或手动删除 `build/ output/ .cache` 后重建

## 6. 与通用平台组件的关系

`user_app/CMakeLists.txt` 提供以下可选能力：

- `ALLIANCE_HPM_BASE_PLATFORM_DIR`：通用平台目录（默认指向仓库根目录下 `alliance_hpm_base_platform`）
- `ENABLE_COMMON_PLATFORM_HEADERS`：是否将通用平台头文件加入当前应用

示例：

```bash
cmake -S user_app -B build \
  -DBOARD=user_board \
  -DENABLE_COMMON_PLATFORM_HEADERS=ON
```

当开启 `ENABLE_COMMON_PLATFORM_HEADERS=ON` 时，若目录不存在会在配置阶段直接报错，请先确认路径有效。

## 7. 板级命名约定

请保持以下名称一致：

- 板目录名：`<name>_board`（例如 `user_board`）
- YAML 文件中的 `board.name`
- 板级配置文件名（`<name>.yaml` / `<name>.cfg` 的命名语义）

名称不一致会影响板级识别、IDE 工程生成或调试配置关联。
