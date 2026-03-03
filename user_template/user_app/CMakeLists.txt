# Copyright (c) 2021 HPMicro
# SPDX-License-Identifier: BSD-3-Clause

cmake_minimum_required(VERSION 3.13)

set(CUSTOM_GCC_LINKER_FILE ${CMAKE_CURRENT_SOURCE_DIR}/../linkers/gcc/user_linker.ld)
set(CUSTOM_SES_LINKER_FILE ${CMAKE_CURRENT_SOURCE_DIR}/../linkers/segger/user_linker.icf)
set(CUSTOM_IAR_LINKER_FILE ${CMAKE_CURRENT_SOURCE_DIR}/../linkers/iar/user_linker.icf)

find_package(hpm-sdk REQUIRED HINTS $ENV{HPM_SDK_BASE})

project(user_app)

# Common platform path shared by all projects in this workspace.
set(ALLIANCE_HPM_BASE_PLATFORM_DIR
    "${CMAKE_CURRENT_LIST_DIR}/../../alliance_hpm_base_platform"
    CACHE PATH "Path to common alliance_hpm_base_platform")

option(ENABLE_COMMON_PLATFORM_HEADERS
       "Expose alliance_hpm_base_platform headers to user_app"
       OFF)

if(ENABLE_COMMON_PLATFORM_HEADERS)
    if(EXISTS "${ALLIANCE_HPM_BASE_PLATFORM_DIR}")
        sdk_app_inc(${ALLIANCE_HPM_BASE_PLATFORM_DIR})
        sdk_compile_definitions(ENABLE_COMMON_PLATFORM_HEADERS=1)
    else()
        message(FATAL_ERROR
            "Common platform path not found: ${ALLIANCE_HPM_BASE_PLATFORM_DIR}")
    endif()
endif()

sdk_app_inc(inc)
sdk_app_src(src/main.c)

generate_ide_projects()
