#
# arm-linux-gnueabihf.toolchain.cmake
#
# Required packages:
#   gcc-arm-linux-gnueabihf
#   g++-arm-linux-gnueabihf
#   binutils-arm-linux-gnueabihf
#
set(CMAKE_SYSTEM_NAME               Linux)
set(CMAKE_SYSTEM_PROCESSOR          arm)
set(triple                          arm-linux-gnueabihf)

file(REAL_PATH "~/sysroot" sysroot EXPAND_TILDE)

set(CPACK_PACKAGE_ARCHITECTURE armhf)
# set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS_PRIVATE_DIRS
#     ${sysroot}/usr/local/lib/${triple}
#     ${sysroot}/usr/local/lib
#     ${sysroot}/usr/lib/${triple}
#     ${sysroot}/usr/lib
# )

set(CMAKE_AR                        ${triple}-ar${CMAKE_EXECUTABLE_SUFFIX})
set(CMAKE_ASM_COMPILER              ${triple}-gcc${CMAKE_EXECUTABLE_SUFFIX})
set(CMAKE_C_COMPILER                ${triple}-gcc${CMAKE_EXECUTABLE_SUFFIX})
set(CMAKE_C_COMPILER_TARGET         ${triple})
set(CMAKE_CXX_COMPILER              ${triple}-g++${CMAKE_EXECUTABLE_SUFFIX})
set(CMAKE_CXX_COMPILER_TARGET       ${triple})
set(CMAKE_STRIP                     ${triple}-strip${CMAKE_EXECUTABLE_SUFFIX})

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
    set(incs)
    foreach(inc IN LISTS ARGV)
        cmake_path(APPEND sysroot ${inc} OUTPUT_VARIABLE incdir)
        if(NOT IS_DIRECTORY ${incdir})
            continue()
        endif()
        list(APPEND incs "=/${inc}")
    endforeach()
    set_cxx_standard_include_directories(${incs})
endfunction()

function(set_linker_init_flags)
    list(JOIN ARGV " " LINKER_FLAGS_INIT)
    foreach(target SHARED STATIC MODULE EXE)
        set("CMAKE_${target}_LINKER_FLAGS_INIT" "${LINKER_FLAGS_INIT}" CACHE INTERNAL "")
    endforeach()
endfunction()

function(init_sysroot_linker_search_paths)
    set(lopts)

    file(GLOB SPECS_FILES LIST_DIRECTORIES false RELATIVE ${sysroot}/usr/lib "${sysroot}/usr/lib/${triple}-*-specs.txt")
    foreach(s IN LISTS SPECS_FILES)
        message(STATUS "[SPECS] ${s}")
    endforeach()
    list(TRANSFORM SPECS_FILES PREPEND "-specs=")

    foreach(dir IN LISTS ARGV)
        cmake_path(APPEND sysroot ${dir} OUTPUT_VARIABLE libdir)
        if(NOT IS_DIRECTORY ${libdir})
            continue()
        endif()
        list(APPEND lopts "-L=/${dir}")
    endforeach()
    set_linker_init_flags(${SPECS_FILES} ${lopts})
endfunction()

# ---------------------------------------------------------------

set_rpi_cxx_init_flags(-marm -march=armv6+fp -mfpu=vfp -mfloat-abi=hard -mtune=arm1176jzf-s)
set(CMAKE_SYSROOT ${sysroot})
set(CMAKE_STAGING_PREFIX ${sysroot})

# paths relative to SYSROOT
set_sysroot_cxx_standard_include_directories(
    usr/local/include/${triple}
    usr/local/include
    usr/include/${triple}
    usr/include
    include/${triple}
    include
)
init_sysroot_linker_search_paths(
    usr/local/lib
    usr/lib
    usr/lib/gcc
    lib
)
set(CMAKE_CROSSCOMPILING_EMULATOR /usr/bin/qemu-arm-static -cpu arm1176 -L ${sysroot} CACHE INTERNAL "")

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
