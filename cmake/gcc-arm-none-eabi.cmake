set(CMAKE_SYSTEM_NAME               Generic)
set(CMAKE_SYSTEM_PROCESSOR          arm)

set(CMAKE_C_COMPILER_ID GNU)
set(CMAKE_CXX_COMPILER_ID GNU)

# Some default GCC settings.
# If ARM_GNU_TOOLCHAIN_BIN is set, use that toolchain explicitly.
# Otherwise, arm-none-eabi-* must be available from PATH.
set(ARM_GNU_TOOLCHAIN_BIN "" CACHE PATH "Path to the Arm GNU Toolchain bin directory")
if((NOT ARM_GNU_TOOLCHAIN_BIN) AND DEFINED ENV{ARM_GNU_TOOLCHAIN_BIN})
    set(ARM_GNU_TOOLCHAIN_BIN "$ENV{ARM_GNU_TOOLCHAIN_BIN}")
endif()

if(ARM_GNU_TOOLCHAIN_BIN)
    file(TO_CMAKE_PATH "${ARM_GNU_TOOLCHAIN_BIN}" ARM_GNU_TOOLCHAIN_BIN)
    set(TOOLCHAIN_PREFIX "${ARM_GNU_TOOLCHAIN_BIN}/arm-none-eabi-")
else()
    set(TOOLCHAIN_PREFIX arm-none-eabi-)
endif()

set(TOOLCHAIN_EXECUTABLE_SUFFIX "")
if(CMAKE_HOST_WIN32 AND ARM_GNU_TOOLCHAIN_BIN)
    set(TOOLCHAIN_EXECUTABLE_SUFFIX ".exe")
endif()

set(CMAKE_C_COMPILER                ${TOOLCHAIN_PREFIX}gcc${TOOLCHAIN_EXECUTABLE_SUFFIX})
set(CMAKE_ASM_COMPILER              ${CMAKE_C_COMPILER})
set(CMAKE_CXX_COMPILER              ${TOOLCHAIN_PREFIX}g++${TOOLCHAIN_EXECUTABLE_SUFFIX})
set(CMAKE_LINKER                    ${TOOLCHAIN_PREFIX}g++${TOOLCHAIN_EXECUTABLE_SUFFIX})
set(CMAKE_OBJCOPY                   ${TOOLCHAIN_PREFIX}objcopy${TOOLCHAIN_EXECUTABLE_SUFFIX})
set(CMAKE_SIZE                      ${TOOLCHAIN_PREFIX}size${TOOLCHAIN_EXECUTABLE_SUFFIX})

set(CMAKE_EXECUTABLE_SUFFIX_ASM     ".elf")
set(CMAKE_EXECUTABLE_SUFFIX_C       ".elf")
set(CMAKE_EXECUTABLE_SUFFIX_CXX     ".elf")

set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

# MCU specific flags
set(TARGET_FLAGS "-mcpu=cortex-m4 -mfpu=fpv4-sp-d16 -mfloat-abi=hard ")

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${TARGET_FLAGS}")
set(CMAKE_ASM_FLAGS "${CMAKE_C_FLAGS} -x assembler-with-cpp -MMD -MP")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -Wextra -Wpedantic -fdata-sections -ffunction-sections")

set(CMAKE_C_FLAGS_DEBUG "-O0 -g3")
set(CMAKE_C_FLAGS_RELEASE "-Os -g0")
set(CMAKE_CXX_FLAGS_DEBUG "-O0 -g3")
set(CMAKE_CXX_FLAGS_RELEASE "-Os -g0")

set(CMAKE_CXX_FLAGS "${CMAKE_C_FLAGS} -fno-rtti -fno-exceptions -fno-threadsafe-statics")

set(CMAKE_C_LINK_FLAGS "${TARGET_FLAGS}")
set(CMAKE_C_LINK_FLAGS "${CMAKE_C_LINK_FLAGS} -T \"${CMAKE_SOURCE_DIR}/STM32F407XX_FLASH.ld\"")
set(CMAKE_C_LINK_FLAGS "${CMAKE_C_LINK_FLAGS} --specs=nano.specs")
set(CMAKE_C_LINK_FLAGS "${CMAKE_C_LINK_FLAGS} -Wl,-Map=${CMAKE_PROJECT_NAME}.map -Wl,--gc-sections")
set(CMAKE_C_LINK_FLAGS "${CMAKE_C_LINK_FLAGS} -Wl,--start-group -lc -lm -Wl,--end-group")
set(CMAKE_C_LINK_FLAGS "${CMAKE_C_LINK_FLAGS} -Wl,--print-memory-usage")

set(CMAKE_CXX_LINK_FLAGS "${CMAKE_C_LINK_FLAGS} -Wl,--start-group -lstdc++ -lsupc++ -Wl,--end-group")
