#
# armv6-unknown-linux-gnueabihf.toolchain.cmake
# CLang cross-compiler for Raspberry Pi 0/1B/1B+
#
# ⚠ WARNING ⚠
# arm-unknown-linux-gnueabihf is a wrong target for Raspberry Pi
# See: 
#    clang now makes binaries an original Pi B+ can't run
#    https://rachelbythebay.com/w/2023/11/30/armv6/
#
set(CMAKE_SYSTEM_NAME               Linux)
set(CMAKE_SYSTEM_PROCESSOR          arm)

set(triple                          armv6-unknown-linux-gnueabihf)
set(btriple                         arm-linux-gnueabihf)

file(REAL_PATH "~/sysroot" sysroot EXPAND_TILDE)

set(CPACK_PACKAGE_ARCHITECTURE armhf)
# set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS_PRIVATE_DIRS
#     ${sysroot}/usr/local/lib/${btriple}
#     ${sysroot}/usr/local/lib
#     ${sysroot}/usr/lib/${btriple}
#     ${sysroot}/usr/lib
# )

set(CMAKE_C_COMPILER                clang${CMAKE_EXECUTABLE_SUFFIX})
set(CMAKE_C_COMPILER_AR             ${btriple}-ar${CMAKE_EXECUTABLE_SUFFIX})
set(CMAKE_C_COMPILER_RANLIB         ${btriple}-ranlib${CMAKE_EXECUTABLE_SUFFIX})
set(CMAKE_C_COMPILER_TARGET         ${triple})
set(CMAKE_C_LIBRARY_ARCHITECTURE    ${btriple})
set(CMAKE_CXX_COMPILER              clang++${CMAKE_EXECUTABLE_SUFFIX})
set(CMAKE_CXX_COMPILER_AR           ${btriple}-ar${CMAKE_EXECUTABLE_SUFFIX})
set(CMAKE_CXX_COMPILER_RANLIB       ${btriple}-ranlib${CMAKE_EXECUTABLE_SUFFIX})
set(CMAKE_CXX_COMPILER_TARGET       ${triple})
set(CMAKE_CXX_LIBRARY_ARCHITECTURE  ${btriple})

#
# Use utilities from binutils-arm-linux-gnueabihf
#
set(CMAKE_ADDR2LINE                 ${btriple}-addr2line${CMAKE_EXECUTABLE_SUFFIX})
set(CMAKE_AR                        ${btriple}-ar${CMAKE_EXECUTABLE_SUFFIX})
set(CMAKE_NM                        ${btriple}-nm${CMAKE_EXECUTABLE_SUFFIX})
set(CMAKE_OBJCOPY                   ${btriple}-objcopy${CMAKE_EXECUTABLE_SUFFIX})
set(CMAKE_OBJDUMP                   ${btriple}-objdump${CMAKE_EXECUTABLE_SUFFIX})
set(CMAKE_RANLIB                    ${btriple}-ranlib${CMAKE_EXECUTABLE_SUFFIX})
set(CMAKE_READELF                   ${btriple}-readelf${CMAKE_EXECUTABLE_SUFFIX})
set(CMAKE_STRIP                     ${btriple}-strip${CMAKE_EXECUTABLE_SUFFIX})
set(COVERAGE_COMMAND                ${btriple}-gcov${CMAKE_EXECUTABLE_SUFFIX})

# CMAKE_LINKER_TYPE was introduced in version 3.29 of CMake
set(CMAKE_LINKER_TYPE               LLD)

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
    if(${CMAKE_VERSION} VERSION_LESS 3.29)
        # CMAKE_LINKER_TYPE variable isn't supported
        list(APPEND lopts -fuse-ld=lld)
    endif()
    foreach(dir IN LISTS ARGV)
        cmake_path(APPEND sysroot ${dir} OUTPUT_VARIABLE libdir)
        if(NOT IS_DIRECTORY ${libdir})
            continue()
        endif()
        list(APPEND lopts "-L=/${dir}")
    endforeach()
    set_linker_init_flags(${lopts}) 
endfunction()

# ---------------------------------------------------------------

set(CMAKE_SYSROOT ${sysroot})
set(CMAKE_STAGING_PREFIX ${sysroot})

# paths relative to SYSROOT
set_sysroot_cxx_standard_include_directories(
    usr/local/include/${btriple}
    usr/local/include
    usr/include/${btriple}
    usr/include
    include/${btriple}
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
