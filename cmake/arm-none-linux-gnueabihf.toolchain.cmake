#
# arm-none-linux-gnueabihf.toolchain.cmake
#
# Download arm-none-linux-gnueabihf toolchain from
# https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads
#
set(CMAKE_SYSTEM_NAME               Linux)
set(CMAKE_SYSTEM_PROCESSOR          arm)
set(CPACK_PACKAGE_ARCHITECTURE      armhf)
set(triple                          arm-none-linux-gnueabihf)
set(btriple                         arm-linux-gnueabihf)
set(gccbase                          /home/vscode/${triple})
set(sysroot                         /home/vscode/sysroot)

set(CMAKE_AR                        ${gccbase}/bin/${triple}-ar${CMAKE_EXECUTABLE_SUFFIX})
set(CMAKE_ASM_COMPILER              ${gccbase}/bin/${triple}-gcc${CMAKE_EXECUTABLE_SUFFIX})
set(CMAKE_C_COMPILER                ${gccbase}/bin/${triple}-gcc${CMAKE_EXECUTABLE_SUFFIX})
set(CMAKE_C_COMPILER_TARGET         ${triple})
set(CMAKE_C_LIBRARY_ARCHITECTURE    ${btriple})
set(CMAKE_CXX_COMPILER              ${gccbase}/bin/${triple}-g++${CMAKE_EXECUTABLE_SUFFIX})
set(CMAKE_CXX_COMPILER_TARGET       ${triple})
set(CMAKE_CXX_LIBRARY_ARCHITECTURE  ${btriple})

function(set_cxx_init_flags)
    list(JOIN ARGV " " C_FLAGS_INIT)
    set(CMAKE_C_FLAGS_INIT "${C_FLAGS_INIT}" CACHE INTERNAL "")
    set(CMAKE_CXX_FLAGS_INIT "${C_FLAGS_INIT}" CACHE INTERNAL "")
endfunction()

function(set_rpi_cxx_init_flags)
    set_cxx_init_flags(${ARGV} -mtls-dialect=gnu)
endfunction()

function(set_cxx_standard_include_directories)
    foreach(lang C CXX)
        SET("CMAKE_${lang}_STANDARD_INCLUDE_DIRECTORIES" ${ARGV} CACHE INTERNAL "")
    endforeach()

    set(cflags)
    foreach(inc ${ARGV})
        list(APPEND cflags "-isystem")
        list(APPEND cflags ${inc})
    endforeach()
    string(JOIN " " C_FLAGS_INIT "${CMAKE_C_FLAGS_INIT}" ${cflags})
    string(JOIN " " CXX_FLAGS_INIT "${CMAKE_CXX_FLAGS_INIT}" ${cflags})
    set(CMAKE_C_FLAGS_INIT "${C_FLAGS_INIT}" CACHE INTERNAL "")
    set(CMAKE_CXX_FLAGS_INIT "${CXX_FLAGS_INIT}" CACHE INTERNAL "")
endfunction()

function(set_sysroot_cxx_standard_include_directories)
    list(TRANSFORM ARGV PREPEND "=" OUTPUT_VARIABLE incs)
    set_cxx_standard_include_directories(${incs})
endfunction()

function(set_linker_init_flags)
    list(JOIN ARGV " " LINKER_FLAGS_INIT)
    foreach(target SHARED STATIC MODULE EXE)
        set("CMAKE_${target}_LINKER_FLAGS_INIT" "${LINKER_FLAGS_INIT}" CACHE INTERNAL "")
    endforeach()
endfunction()

function(init_sysroot_linker_search_paths)
    list(TRANSFORM ARGV PREPEND "-L=" OUTPUT_VARIABLE lopts)
    set_linker_init_flags(${lopts})
endfunction()

# ---------------------------------------------------------------

set_rpi_cxx_init_flags(-marm -march=armv6+fp -mfpu=vfp -mfloat-abi=hard -mtune=arm1176jzf-s)
set(CMAKE_SYSROOT ${sysroot})
set(CMAKE_STAGING_PREFIX ${sysroot})

# paths relative to SYSROOT
set_sysroot_cxx_standard_include_directories(
    /usr/local/include/${btriple}
    /usr/local/include
    /usr/include/${btriple}
    /usr/include
    /include/${btriple}
    /include
)
init_sysroot_linker_search_paths(
    /usr/local/lib
    /usr/lib
    /usr/lib/gcc
    /lib
)

set(CMAKE_CROSSCOMPILING_EMULATOR /usr/bin/qemu-arm-static -cpu arm1176 -L ${sysroot} CACHE INTERNAL "")

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
