#
# gcc-lib-search-dirs.cmake
#

CMAKE_MINIMUM_REQUIRED(VERSION 3.21)

#
# first argument - name of or path to gcc driver
#
# Default value: gcc
#
IF(CMAKE_ARGV3)
    IF(${CMAKE_ARGV3} STREQUAL arm-linux-gnueabihf)
        SET(GCC_DRIVER arm-linux-gnueabihf-gcc)
    ELSEIF(${CMAKE_ARGV3} STREQUAL arm-none-linux-gnueabihf)
        FILE(REAL_PATH "~/arm-none-linux-gnueabihf/bin/arm-none-linux-gnueabihf-gcc" GCC_DRIVER EXPAND_TILDE)
    ELSEIF(${CMAKE_ARGV3} STREQUAL armv6-unknown-linux-gnueabihf)
        SET(GCC_DRIVER clang)
    ELSE()
        SET(GCC_DRIVER ${CMAKE_ARGV3})
    ENDIF()
ELSE()
    SET(GCC_DRIVER gcc)
    SET(CMAKE_SYSROOT /)
ENDIF()

#
# second argument - SYSROOT path
#
# Default value: ~/sysroot or /
#
IF(CMAKE_ARGV4)
    SET(CMAKE_SYSROOT "${CMAKE_ARGV4}")
ELSEIF(NOT CMAKE_SYSROOT)
    FILE(REAL_PATH "~/sysroot" CMAKE_SYSROOT EXPAND_TILDE)
    IF(NOT IS_DIRECTORY ${CMAKE_SYSROOT})
        SET(CMAKE_SYSROOT "/")
    ENDIF()
ENDIF()

MESSAGE(VERBOSE "GCC: ${GCC_DRIVER}")
MESSAGE(VERBOSE "SYSROOT: ${CMAKE_SYSROOT}")

# -------------------------------------------------------------------

FUNCTION(GetPathObj SearchPath)
    CMAKE_PATH(NORMAL_PATH SearchPath OUTPUT_VARIABLE NormalizedPath)
    FILE(REAL_PATH ${SearchPath} RealPath)
    CMAKE_PATH(COMPARE "${NormalizedPath}" EQUAL "${RealPath}" PATH_CMP)
    IF(PATH_CMP)
        SET(PATH_OBJ "\"${NormalizedPath}\"" PARENT_SCOPE)
    ELSE()
        SET(PATH_OBJ "{}")
        STRING(JSON PATH_OBJ SET "${PATH_OBJ}" "path" "\"${NormalizedPath}\"")
        STRING(JSON PATH_OBJ SET "${PATH_OBJ}" "real_path" "\"${RealPath}\"")
        SET(PATH_OBJ "${PATH_OBJ}" PARENT_SCOPE)
    ENDIF()
ENDFUNCTION()

FUNCTION(ToPathsArray)
    IF(${ARGC} GREATER 1)
        SET(JA "[]")
        SET(IDX 0)
        FOREACH(i IN LISTS ARGV)
            GetPathObj(${i})
            STRING(JSON JA SET "${JA}" ${IDX} "${PATH_OBJ}")
            MATH(EXPR IDX "${IDX}+1")
        ENDFOREACH()
        SET(JSON_ARRAY "${JA}" PARENT_SCOPE)
    ELSEIF(${ARGC} GREATER 0)
        GetPathObj(${ARGV0})
        SET(JSON_ARRAY "${PATH_OBJ}" PARENT_SCOPE)
    ELSE()
        SET(JSON_ARRAY PARENT_SCOPE)
    ENDIF()
ENDFUNCTION()

FUNCTION(ProcessDirList Category DirList)
    STRING(REGEX MATCHALL "[^:]+" DIRS_RAW "${DirList}")
    SET(DIRS)
    FOREACH(l IN LISTS DIRS_RAW)
        IF("${l}" MATCHES "^=/(.+)$")
            IF(IS_DIRECTORY "/${CMAKE_MATCH_1}")
                MESSAGE(VERBOSE "[${Category}][append] ${l}")
                SET(sl "/${CMAKE_MATCH_1}")
                CMAKE_PATH(NORMAL_PATH sl OUTPUT_VARIABLE rl)
                LIST(APPEND DIRS "${rl}")
            ELSE()
                MESSAGE(VERBOSE "[${Category}][skip]: ${l}")
            ENDIF()
        ELSEIF(IS_DIRECTORY "${l}")
            MESSAGE(VERBOSE "[${Category}][append] ${l}")
            CMAKE_PATH(NORMAL_PATH l OUTPUT_VARIABLE rl)
            LIST(APPEND DIRS "${rl}")
        ELSE()
            MESSAGE(VERBOSE "[${Category}][skip] ${l}")
        ENDIF()    
    ENDFOREACH()

    LIST(REMOVE_DUPLICATES DIRS)
    LIST(TRANSFORM DIRS REPLACE "/+$" "")
    SET(DIRS ${DIRS} PARENT_SCOPE)
ENDFUNCTION()

FUNCTION(ToJsonArray)
    IF(${ARGC} GREATER 1)
        SET(JA "[]")
        SET(IDX 0)
        FOREACH(i IN LISTS ARGV)
            STRING(JSON JA SET "${JA}" ${IDX} "\"${i}\"")
            MATH(EXPR IDX "${IDX}+1")
        ENDFOREACH()
        SET(JSON_ARRAY "${JA}" PARENT_SCOPE)
    ELSEIF(${ARGC} GREATER 0)
        SET(JSON_ARRAY "\"${ARGV0}\"" PARENT_SCOPE)
    ELSE()
        SET(JSON_ARRAY PARENT_SCOPE)
    ENDIF()
ENDFUNCTION()

FUNCTION(GccVersion GccDriver)
    EXECUTE_PROCESS(
        COMMAND ${GccDriver} --version
        OUTPUT_VARIABLE VERSION_ML
        OUTPUT_STRIP_TRAILING_WHITESPACE
        COMMAND_ERROR_IS_FATAL ANY
        TIMEOUT 15
    )
    STRING(REGEX MATCHALL "[^\n\r]+" VERSION_LINES "${VERSION_ML}")
    LIST(GET VERSION_LINES 0 GCC_VERSION)
    SET(GCC_VERSION "${GCC_VERSION}" PARENT_SCOPE)
ENDFUNCTION()

FUNCTION(GccMultiarch GccDriver)
    EXECUTE_PROCESS(
        COMMAND ${GccDriver} -print-multiarch
        RESULT_VARIABLE GCC_MULTIARCH_RES
        OUTPUT_VARIABLE GCC_MULTIARCH
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
        TIMEOUT 15
    )
    IF(${GCC_MULTIARCH_RES} EQUAL 0)
        SET(GCC_MULTIARCH "${GCC_MULTIARCH}" PARENT_SCOPE)
    ELSE()
        SET(GCC_MULTIARCH PARENT_SCOPE)
    ENDIF()
ENDFUNCTION()

FUNCTION(ScanDirForStartFiles SearchPath)
    SET(StartFilesTypes)
    FILE(GLOB CrtBegin LIST_DIRECTORIES false RELATIVE ${SearchPath} "${SearchPath}/crtbegin*.o")
    FILE(GLOB CrtEnd LIST_DIRECTORIES false RELATIVE ${SearchPath} "${SearchPath}/crtend*.o")
    LIST(LENGTH CrtBegin CrtBeginLen)
    LIST(LENGTH CrtEnd CrtEndLen)
    IF(${CrtBeginLen} GREATER 0 OR ${CrtEndLen} GREATER 0)
        LIST(APPEND StartFilesTypes libgcc)
    ENDIF()

    FILE(GLOB CrtBegin LIST_DIRECTORIES false RELATIVE ${SearchPath} "${SearchPath}/crtbegin*.o.distrib")
    FILE(GLOB CrtEnd LIST_DIRECTORIES false RELATIVE ${SearchPath} "${SearchPath}/crtend*.o.distrib")
    LIST(LENGTH CrtBegin CrtBeginLen)
    LIST(LENGTH CrtEnd CrtEndLen)
    IF(${CrtBeginLen} GREATER 0 OR ${CrtEndLen} GREATER 0)
        LIST(APPEND StartFilesTypes libgcc.distrib)
    ENDIF()

    FILE(GLOB Crtx LIST_DIRECTORIES false RELATIVE ${SearchPath} "${SearchPath}/?crt?.o")
    LIST(LENGTH Crtx CrtxLen)
    IF(${CrtxLen} GREATER 0)
        LIST(APPEND StartFilesTypes libc)
    ENDIF()

    FILE(GLOB Crtx LIST_DIRECTORIES false RELATIVE ${SearchPath} "${SearchPath}/?crt?.o.distrib")
    LIST(LENGTH Crtx CrtxLen)
    IF(${CrtxLen} GREATER 0)
        LIST(APPEND StartFilesTypes libc.distrib)
    ENDIF()

    SET(START_FILES_TYPES ${StartFilesTypes} PARENT_SCOPE)
ENDFUNCTION()

FUNCTION(GetStartFileObj SearchPath)
    ScanDirForStartFiles(${SearchPath})
    LIST(LENGTH START_FILES_TYPES START_FILES_TYPES_LEN)

    FILE(REAL_PATH ${SearchPath} RealPath)
    CMAKE_PATH(COMPARE "${SearchPath}" NOT_EQUAL "${RealPath}" PATH_CMP)

    IF(${START_FILES_TYPES_LEN} GREATER 0 OR PATH_CMP)
        SET(START_FILE_OBJ "{}")
        STRING(JSON START_FILE_OBJ SET "${START_FILE_OBJ}" path "\"${SearchPath}\"")
        IF(PATH_CMP)
            STRING(JSON START_FILE_OBJ SET "${START_FILE_OBJ}" real_path "\"${RealPath}\"")
        ENDIF()

        IF(${START_FILES_TYPES_LEN} GREATER 0)
            ToJsonArray(${START_FILES_TYPES})
            STRING(JSON START_FILE_OBJ SET "${START_FILE_OBJ}" startup "${JSON_ARRAY}")
        ENDIF()
        SET(START_FILE_OBJ "${START_FILE_OBJ}" PARENT_SCOPE)
    ELSE()
        SET(START_FILE_OBJ "\"${SearchPath}\"" PARENT_SCOPE)
    ENDIF()
ENDFUNCTION()

FUNCTION(GetStartfilesPaths)
    SET(DIRS ${ARGV})
    LIST(REMOVE_DUPLICATES DIRS)
    
    SET(STARTUP_FILES_PATHS "[]")
    SET(IDX 0)
    FOREACH(l IN LISTS DIRS)
        GetStartFileObj(${l})
        STRING(JSON STARTUP_FILES_PATHS SET "${STARTUP_FILES_PATHS}" ${IDX} "${START_FILE_OBJ}")
        MATH(EXPR IDX "${IDX}+1")
    ENDFOREACH()
    SET(STARTUP_FILES_PATHS "${STARTUP_FILES_PATHS}" PARENT_SCOPE)
ENDFUNCTION()

# -------------------------------------------------------------------

SET(DIR_OBJ "{\"search_dirs\": {}}")

GccVersion(${GCC_DRIVER})
STRING(JSON DIR_OBJ SET "${DIR_OBJ}" version "\"${GCC_VERSION}\"")

GccMultiarch(${GCC_DRIVER})
IF(GCC_MULTIARCH)
    STRING(JSON DIR_OBJ SET "${DIR_OBJ}" multiarch "\"${GCC_MULTIARCH}\"")
ENDIF()

CMAKE_PATH(SET CMAKE_SYSROOT NORMALIZE "${CMAKE_SYSROOT}")
CMAKE_PATH(COMPARE ${CMAKE_SYSROOT} EQUAL / NO_SYSROOT)

IF(NO_SYSROOT)
    EXECUTE_PROCESS(
        COMMAND ${GCC_DRIVER} -print-search-dirs
        OUTPUT_VARIABLE SEARCH_DIRS_ML
        COMMAND_ERROR_IS_FATAL ANY
        TIMEOUT 15
    )
ELSE()
    STRING(JSON DIR_OBJ SET "${DIR_OBJ}" sysroot "\"${CMAKE_SYSROOT}\"")

    EXECUTE_PROCESS(
        COMMAND ${GCC_DRIVER} --sysroot=${CMAKE_SYSROOT} -print-search-dirs
        OUTPUT_VARIABLE SEARCH_DIRS_ML
        COMMAND_ERROR_IS_FATAL ANY
        TIMEOUT 15
    )
ENDIF()

IF(SEARCH_DIRS_ML)
    SET(CATEGORIES)
    STRING(REGEX MATCHALL "[^\n\r]+" SEARCH_DIRS_RAW "${SEARCH_DIRS_ML}")
    FOREACH(l IN LISTS SEARCH_DIRS_RAW)
        IF(NOT "${l}" MATCHES "^(.+): (.+)$")
            CONTINUE()
        ENDIF()

        SET(CATEGORY "${CMAKE_MATCH_1}")
        LIST(APPEND CATEGORIES ${CATEGORY})
        ProcessDirList("${CATEGORY}" "${CMAKE_MATCH_2}")
        SET("DIRS_${CATEGORY}" ${DIRS})
    ENDFOREACH()

    FOREACH(c IN LISTS CATEGORIES)
        ToPathsArray(${DIRS_${c}})
        IF(JSON_ARRAY)
            STRING(JSON DIR_OBJ SET "${DIR_OBJ}" search_dirs ${c} "${JSON_ARRAY}")
        ENDIF()
    ENDFOREACH()

    GetStartfilesPaths(${DIRS_install} ${DIRS_libraries})
    IF(STARTUP_FILES_PATHS)
        STRING(JSON DIR_OBJ SET "${DIR_OBJ}" search_dirs startup_files "${STARTUP_FILES_PATHS}")
    ENDIF()
ENDIF()

# MESSAGE(NOTICE "${DIR_OBJ}") --> stderr
# Output JSON to stdout.
EXECUTE_PROCESS(
    COMMAND ${CMAKE_COMMAND} -E echo "${DIR_OBJ}"
    TIMEOUT 15
    ENCODING UTF8
)
