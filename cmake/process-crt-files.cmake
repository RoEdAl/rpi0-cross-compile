#
# process-crt-files.cmake
#

CMAKE_MINIMUM_REQUIRED(VERSION 3.21)

FUNCTION(ProcessObjFile Action WorkDir ObjPrefix ObjFile)
    CMAKE_PATH(APPEND WorkDir ${ObjFile} OUTPUT_VARIABLE ObjPath)
    IF(NOT EXISTS ${ObjPath})
        MESSAGE(STATUS "${ObjFile} ❗")
        RETURN()
    ENDIF()

    IF(${Action} STREQUAL link)
        SET(LinkedObjFile ${ObjPrefix}${ObjFile})
        CMAKE_PATH(APPEND WorkDir ${LinkedObjFile} OUTPUT_VARIABLE LinkedObjPath)
        IF(IS_SYMLINK ${LinkedObjPath})
            FILE(REMOVE ${LinkedObjPath})
        ELSEIF(EXISTS ${LinkedObjPath})
            MESSAGE(WARNING "Not a symlink: ${LinkedObjFile}")
            RETURN()
        ENDIF()
        FILE(CREATE_LINK ${ObjFile} ${LinkedObjPath} SYMBOLIC)
        MESSAGE(STATUS "${ObjFile} → ${LinkedObjFile}")
    ELSEIF(${Action} STREQUAL unlink)
        SET(LinkedObjFile ${ObjPrefix}${ObjFile})
        CMAKE_PATH(APPEND WorkDir ${LinkedObjFile} OUTPUT_VARIABLE LinkedObjPath)
        IF(IS_SYMLINK ${LinkedObjPath})
            FILE(REMOVE "${LinkedObjPath}")
            MESSAGE(STATUS "${ObjFile} ↛ ${LinkedObjFile}")
        ELSEIF(EXISTS ${LinkedObjPath})
            MESSAGE(WARNING "Not a symlink: ${LinkedObjFile}")
            RETURN()
        ENDIF()
    ELSE()
        MESSAGE(WARNING "Unknown action: ${Action}")
    ENDIF()
ENDFUNCTION()

FUNCTION(ProcessObjFiles Action WorkDir JsonObj)
    STRING(JSON OBJ_PREFIX GET "${JsonObj}" prefix)
    STRING(JSON OBJ_CNT LENGTH "${JsonObj}" files)
    IF(${OBJ_CNT} LESS_EQUAL 0)
        RETURN()
    ENDIF()
    MATH(EXPR OBJ_CNT "${OBJ_CNT}-1")
    FOREACH(i RANGE ${OBJ_CNT})
        STRING(JSON OBJ_FILE GET "${JsonObj}" files ${i})
        ProcessObjFile(${Action} ${WorkDir} ${OBJ_PREFIX} ${OBJ_FILE})
    ENDFOREACH()
ENDFUNCTION()

IF(CMAKE_ARGV3)
    IF(${CMAKE_ARGV3} STREQUAL arm-linux-gnueabihf)
        SET(SPECS_PREFIX ${CMAKE_ARGV3})
    ELSEIF(${CMAKE_ARGV3} STREQUAL arm-none-linux-gnueabihf)
        SET(SPECS_PREFIX ${CMAKE_ARGV3})
    ELSE()
        MESSAGE(FATAL_ERROR "Invalid GCC driver: ${CMAKE_ARGV3}")
    ENDIF()
ELSE()
    MESSAGE(FATAL_ERROR "GCC driver not specified")
ENDIF()

IF(CMAKE_ARGV4)
    SET(SPEC_ACTION ${CMAKE_ARGV4})
ELSE()
    SET(SPEC_ACTION link)
ENDIF()

IF(DEFINED ENV{SYSROOT})
    SET(CMAKE_SYSROOT $ENV{SYSROOT})
    CMAKE_PATH(SET CMAKE_SYSROOT NORMALIZE "${CMAKE_SYSROOT}")
ELSE()
    FILE(REAL_PATH "~/sysroot" CMAKE_SYSROOT EXPAND_TILDE)
ENDIF()

IF(NOT IS_DIRECTORY ${CMAKE_SYSROOT})
    SET(CMAKE_SYSROOT /)
ENDIF()

CMAKE_PATH(COMPARE ${CMAKE_SYSROOT} EQUAL / NO_SYSROOT)
IF(NO_SYSROOT)
    MESSAGE(FATAL_ERROR "Sysroot directory doesn't exitst")
ENDIF()

CMAKE_PATH(APPEND CMAKE_SYSROOT usr lib OUTPUT_VARIABLE SPECS_DIR)

FILE(GLOB SPECS_FILES
    LIST_DIRECTORIES false
    RELATIVE "${SPECS_DIR}"
    "${SPECS_DIR}/${SPECS_PREFIX}-*-objs.json"
)
FOREACH(f IN LISTS SPECS_FILES)
    CMAKE_PATH(APPEND SPECS_DIR ${f} OUTPUT_VARIABLE sp)
    FILE(READ ${sp} OBJ_FILES)
    IF(NOT OBJ_FILES)
        CONTINUE()
    ENDIF()
    MESSAGE(STATUS "[SPECS]: ${f}")
    ProcessObjFiles("${SPEC_ACTION}" ${SPECS_DIR} "${OBJ_FILES}")
ENDFOREACH()
