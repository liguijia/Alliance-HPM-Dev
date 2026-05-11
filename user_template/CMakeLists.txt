# CMakeLists.txt
# Copyright (c) 2024 HPMicro
# SPDX-License-Identifier: BSD-3-Clause

cmake_minimum_required(VERSION 3.13)

# Linker scripts
set(CUSTOM_GCC_LINKER_FILE ${CMAKE_CURRENT_SOURCE_DIR}/linkers/gcc/user_linker.ld)
set(CUSTOM_SES_LINKER_FILE ${CMAKE_CURRENT_SOURCE_DIR}/linkers/segger/user_linker.icf)
set(CUSTOM_IAR_LINKER_FILE ${CMAKE_CURRENT_SOURCE_DIR}/linkers/iar/user_linker.icf)

find_package(hpm-sdk REQUIRED HINTS $ENV{HPM_SDK_BASE})

project(user_app)

# ============================================================================
# Include Paths
# ============================================================================

# Interface headers (hardware-independent)
sdk_app_inc(${CMAKE_CURRENT_SOURCE_DIR}/Interface)

# App headers
sdk_app_inc(${CMAKE_CURRENT_SOURCE_DIR}/App/Logic)

# ============================================================================
# Source Files
# ============================================================================

# Driver implementations
sdk_app_src(Driver/hpm_impl/drv_pwm.c)
sdk_app_src(Driver/hpm_impl/drv_uart.c)

# App logic (no hpm_* dependencies)
sdk_app_src(App/Logic/app_logic.c)

# Interface layer stubs
sdk_app_src(Interface/intf_default.c)

# Main entry
sdk_app_src(App/main.c)

# ============================================================================
# Generate IDE Projects
# ============================================================================

generate_ide_projects()
