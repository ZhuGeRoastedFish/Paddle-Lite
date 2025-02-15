# Copyright (c) 2018 PaddlePaddle Authors. All Rights Reserved.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set(ANDROID TRUE)
set(ANDROID_ARCH_ABI_LIST "arm64-v8a" "armeabi-v7a" "armeabi-v6" "armeabi" "mips" "mips64" "x86" "x86_64")
set(ANDROID_STL_TYPE_LIST "c++_static" "gnustl_static" "c++_shared")

# Android ndk
if(NOT DEFINED ANDROID_NDK)
    set(ANDROID_NDK $ENV{NDK_ROOT})
    if(NOT ANDROID_NDK)
        message(FATAL_ERROR "Must set ANDROID_NDK or env NDK_ROOT")
    endif()
endif()

# ANDROID_NATIVE_API_LEVEL
if(NOT DEFINED ANDROID_NATIVE_API_LEVEL)
    set(ANDROID_NATIVE_API_LEVEL "21")
    if(ARM_TARGET_ARCH_ABI STREQUAL "armv7")
        if(LITE_WITH_NPU AND NOT LITE_ON_TINY_PUBLISH)
            set(ANDROID_NATIVE_API_LEVEL "24") # HIAI DDK depends on android-24
        elseif(NOT LITE_ON_TINY_PUBLISH)
            set(ANDROID_NATIVE_API_LEVEL "21") # OpenCV-4.1.0 requires Android API Level >= 21
        else()
            set(ANDROID_NATIVE_API_LEVEL "16")
        endif()
    endif()
endif()

# ANDROID_ARCH_ABI
if(ARM_TARGET_ARCH_ABI STREQUAL "armv7hf")
    message(FATAL_ERROR "ANDROID does not support hardfp on v7 use armv7 instead.")
endif()
set(ANDROID_ARCH_ABI ${ARM_TARGET_ARCH_ABI} CACHE STRING "Choose Android Arch ABI")
if(ARM_TARGET_ARCH_ABI STREQUAL "armv8")
    set(ANDROID_ARCH_ABI "arm64-v8a")
endif()
if(ARM_TARGET_ARCH_ABI STREQUAL "armv7")
    set(ANDROID_ARCH_ABI "armeabi-v7a")
endif()
if(NOT ANDROID_ARCH_ABI IN_LIST ANDROID_ARCH_ABI_LIST)
    message(FATAL_ERROR "ANDROID_ARCH_ABI must be one of ${ANDROID_ARCH_ABI_LIST}")
endif()
if(ANDROID_ARCH_ABI STREQUAL "armeabi-v7a")
    message(STATUS "armeabi-v7a use softfp by default.")
    set(CMAKE_ANDROID_ARM_NEON ON)
    message(STATUS "NEON is enabled on arm-v7a with softfp.")
endif()

# ANDROID_STL_TYPE
if(NOT DEFINED ANDROID_STL_TYPE)
    set(ANDROID_STL_TYPE "c++_static")
else()
    if(NOT ANDROID_STL_TYPE IN_LIST ANDROID_STL_TYPE_LIST)
        message(FATAL_ERROR "ANDROID_STL_TYPE must be one of ${ANDROID_STL_TYPE_LIST}")
    endif()
endif()

set(CMAKE_SYSTEM_NAME Android)
set(CMAKE_SYSTEM_VERSION ${ANDROID_NATIVE_API_LEVEL})
set(CMAKE_ANDROID_ARCH_ABI ${ANDROID_ARCH_ABI})
set(CMAKE_ANDROID_NDK ${ANDROID_NDK})
set(CMAKE_ANDROID_STL_TYPE ${ANDROID_STL_TYPE})

# Toolchain
if(ARM_TARGET_LANG STREQUAL "gcc")
    if(ARM_TARGET_ARCH_ABI STREQUAL "armv8")
        set(CMAKE_SYSTEM_PROCESSOR aarch64)
        set(CMAKE_C_COMPILER "aarch64-linux-gnu-gcc")
        set(CMAKE_CXX_COMPILER "aarch64-linux-gnu-g++")
    elseif(ARM_TARGET_ARCH_ABI STREQUAL "armv7")
        set(CMAKE_SYSTEM_PROCESSOR armv7-a)
        set(CMAKE_C_COMPILER "arm-linux-gnueabi-gcc")
        set(CMAKE_CXX_COMPILER "arm-linux-gnueabi-g++")
    else()
        message(FATAL_ERROR "INVALID ARM TARGET ARCH ABI: ${ARM_TARGET_ARCH_ABI}")
    endif()
endif()
if(ARM_TARGET_LANG STREQUAL "clang")
    set(CMAKE_ANDROID_NDK_TOOLCHAIN_VERSION ${ARM_TARGET_LANG})
    set(ANDROID_TOOLCHAIN clang)
    set(CMAKE_TOOLCHAIN_FILE ${ANDROID_NDK}/build/cmake/android.toolchain.cmake)
    set(ANDROID_ABI ${ANDROID_ARCH_ABI})
    set(ANDROID_STL ${ANDROID_STL_TYPE})
    if(ARM_TARGET_ARCH_ABI STREQUAL "armv8")
        set(triple aarch64-v8a-linux-android)
        if(ANDROID_STL_TYPE MATCHES "^c\\+\\+_")
            # Use CMAKE_CXX_STANDARD_LIBRARIES_INIT to ensure libunwind and libc++ is linked in the right order
            set(CMAKE_CXX_STANDARD_LIBRARIES_INIT "${CMAKE_CXX_STANDARD_LIBRARIES_INIT} ${ANDROID_NDK}/sources/cxx-stl/llvm-libc++/libs/${ANDROID_ARCH_ABI}/libunwind.a")
            if (ANDROID_NATIVE_API_LEVEL LESS 21)
                set(CMAKE_CXX_STANDARD_LIBRARIES_INIT "${CMAKE_CXX_STANDARD_LIBRARIES_INIT} ${ANDROID_NDK}/sources/cxx-stl/llvm-libc++/libs/${ANDROID_ARCH_ABI}/libandroid_support.a")
            endif()
            if(ANDROID_STL_TYPE STREQUAL "c++_shared")
                set(CMAKE_CXX_STANDARD_LIBRARIES_INIT "${CMAKE_CXX_STANDARD_LIBRARIES_INIT} ${ANDROID_NDK}/sources/cxx-stl/llvm-libc++/libs/${ANDROID_ARCH_ABI}/libc++_shared.so")
            elseif(ANDROID_STL_TYPE STREQUAL "c++_static")
                set(CMAKE_CXX_STANDARD_LIBRARIES_INIT "${CMAKE_CXX_STANDARD_LIBRARIES_INIT} ${ANDROID_NDK}/sources/cxx-stl/llvm-libc++/libs/${ANDROID_ARCH_ABI}/libc++_static.a")
                set(CMAKE_CXX_STANDARD_LIBRARIES_INIT "${CMAKE_CXX_STANDARD_LIBRARIES_INIT} ${ANDROID_NDK}/sources/cxx-stl/llvm-libc++/libs/${ANDROID_ARCH_ABI}/libc++abi.a")
            else()
                message(FATAL_ERROR "Invalid Android STL TYPE: ${ANDROID_STL_TYPE}.")
            endif()
        endif()
    elseif(ARM_TARGET_ARCH_ABI STREQUAL "armv7")
        set(triple arm-v7a-linux-android)
        set(ANDROID_ARM_NEON TRUE)
        if(ANDROID_STL_TYPE MATCHES "^c\\+\\+_")
            # Use CMAKE_CXX_STANDARD_LIBRARIES_INIT to ensure libunwind and libc++ is linked in the right order
            set(CMAKE_CXX_STANDARD_LIBRARIES_INIT "${CMAKE_CXX_STANDARD_LIBRARIES_INIT} ${ANDROID_NDK}/sources/cxx-stl/llvm-libc++/libs/${ANDROID_ARCH_ABI}/libunwind.a")
            if (ANDROID_NATIVE_API_LEVEL LESS 21)
                set(CMAKE_CXX_STANDARD_LIBRARIES_INIT "${CMAKE_CXX_STANDARD_LIBRARIES_INIT} ${ANDROID_NDK}/sources/cxx-stl/llvm-libc++/libs/${ANDROID_ARCH_ABI}/libandroid_support.a")
            endif()
            if(ANDROID_STL_TYPE STREQUAL "c++_shared")
                set(CMAKE_CXX_STANDARD_LIBRARIES_INIT "${CMAKE_CXX_STANDARD_LIBRARIES_INIT} ${ANDROID_NDK}/sources/cxx-stl/llvm-libc++/libs/${ANDROID_ARCH_ABI}/libc++_shared.so")
            elseif(ANDROID_STL_TYPE STREQUAL "c++_static")
                set(CMAKE_CXX_STANDARD_LIBRARIES_INIT "${CMAKE_CXX_STANDARD_LIBRARIES_INIT} ${ANDROID_NDK}/sources/cxx-stl/llvm-libc++/libs/${ANDROID_ARCH_ABI}/libc++_static.a")
                set(CMAKE_CXX_STANDARD_LIBRARIES_INIT "${CMAKE_CXX_STANDARD_LIBRARIES_INIT} ${ANDROID_NDK}/sources/cxx-stl/llvm-libc++/libs/${ANDROID_ARCH_ABI}/libc++abi.a")
            else()
                message(FATAL_ERROR "Invalid Android STL TYPE: ${ANDROID_STL_TYPE}.")
            endif()
        endif()
    else()
        message(FATAL_ERROR "Clang do not support this ${ARM_TARGET_ARCH_ABI}, use armv8 or armv7")
    endif()

    set(CMAKE_C_COMPILER clang)
    set(CMAKE_C_COMPILER_TARGET ${triple})
    set(CMAKE_CXX_COMPILER clang++)
    set(CMAKE_CXX_COMPILER_TARGET ${triple})
    message(STATUS "CMAKE_CXX_COMPILER_TARGET: ${CMAKE_CXX_COMPILER_TARGET}")
endif()

# Definitions
add_definitions(-DLITE_WITH_LINUX)
add_definitions(-DLITE_WITH_ANDROID)
