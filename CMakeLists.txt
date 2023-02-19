cmake_minimum_required(VERSION 3.21)

include(cmake/pico_sdk_import.cmake)
include(cmake/zig.cmake)

project(pico)

set(PICO_BOARD pico_w)
pico_sdk_init()

add_executable(pico)
target_zig_source(pico
    src/main.zig
    )
target_zig_crosstarget(pico
    arm-freestanding-eabi
    cortex_m0plus
    )
target_zig_add_module(pico
    picosdk
    lib/picosdk.zig
    lib/rp2040.zig
    )

pico_enable_stdio_usb(pico 1)
pico_enable_stdio_uart(pico 0)

target_link_libraries(pico
    pico_stdlib
    pico_cyw43_arch_none
    )

pico_add_extra_outputs(pico)

add_custom_target(flash
    COMMAND picotool load -f pico.uf2
    DEPENDS pico
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    )
