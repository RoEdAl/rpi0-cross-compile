#
# extract-crt-spcecs.cmake
#

CMAKE_MINIMUM_REQUIRED(VERSION 3.21)

FUNCTION(JsonArrayAppend OutVar JsonArray Line)
    STRING(JSON ArrayLength LENGTH "${JsonArray}")
    STRING(JSON JsonArray SET "${JsonArray}" ${ArrayLength} "\"${Line}\"")
    SET(${OutVar} "${JsonArray}" PARENT_SCOPE)
ENDFUNCTION()

FUNCTION(RenameStartupFiles OutVar ObjFilesVar ObjPrefix JsonArray)
    STRING(JSON ArrayLength LENGTH "${JsonArray}")
    MATH(EXPR ArrayLength1 "${ArrayLength}-1")
    SET(OBJ_FILES)
    FOREACH(i RANGE ${ArrayLength1})
        STRING(JSON Line GET "${JsonArray}" ${i})

        STRING(REGEX MATCHALL "([a-zA-Z]?crt[a-zA-Z0-9_]*)(\\.o|\\%O)\\%s" LOBJ_FILES "${Line}")
        LIST(TRANSFORM LOBJ_FILES REPLACE "\\%s$" "")
        LIST(TRANSFORM LOBJ_FILES REPLACE "\\%O$" "")
        LIST(TRANSFORM LOBJ_FILES REPLACE "\\.o$" "")
        LIST(TRANSFORM LOBJ_FILES APPEND ".o")
        LIST(APPEND OBJ_FILES ${LOBJ_FILES})

        STRING(REGEX REPLACE "([a-zA-Z]?crt[a-zA-Z0-9_]*)(\\.o|\\%O)\\%s" "${ObjPrefix}\\1%O%s" Line "${Line}")
        STRING(JSON JsonArray SET "${JsonArray}" ${i} "\"${Line}\"")
    ENDFOREACH()
    SET(${OutVar} "${JsonArray}" PARENT_SCOPE)
    SET(${ObjFilesVar} ${OBJ_FILES} PARENT_SCOPE)
ENDFUNCTION()

FUNCTION(WriteLines FilePath SpecStringName JsonArray)
    FILE(WRITE ${FilePath} "*${SpecStringName}:\n")
    STRING(JSON ArrayLength LENGTH "${JsonArray}")
    MATH(EXPR ArrayLength1 "${ArrayLength}-1")
    FOREACH(i RANGE ${ArrayLength1})
        STRING(JSON Line GET "${JsonArray}" ${i})
        FILE(APPEND ${FilePath} "${Line}\n")
    ENDFOREACH()
ENDFUNCTION()

FUNCTION(WriteObjFiles FilePath ObjPrefix)
    SET(JSON_OBJ "{\"files\":[]}")
    STRING(JSON JSON_OBJ SET "${JSON_OBJ}" prefix "\"${ObjPrefix}\"")
    MATH(EXPR ArgC1 "${ARGC}-1")
    FOREACH(i RANGE 2 ${ArgC1})
        LIST(GET ARGV ${i} OBJ_FILE)
        STRING(JSON JSON_OBJ SET "${JSON_OBJ}" files ${i} "\"${OBJ_FILE}\"")
    ENDFOREACH()
    FILE(WRITE ${FilePath} "${JSON_OBJ}\n")
ENDFUNCTION()

IF(CMAKE_ARGV3)
    IF(${CMAKE_ARGV3} STREQUAL arm-linux-gnueabihf)
        SET(SPECS_PREFIX ${CMAKE_ARGV3})
        SET(GCC_DRIVER arm-linux-gnueabihf-gcc)
    ELSEIF(${CMAKE_ARGV3} STREQUAL arm-none-linux-gnueabihf)
        SET(SPECS_PREFIX ${CMAKE_ARGV3})
        FILE(REAL_PATH "~/arm-none-linux-gnueabihf/bin/arm-none-linux-gnueabihf-gcc" GCC_DRIVER EXPAND_TILDE)
    ELSE()
        MESSAGE(FATAL_ERROR "Invalid GCC driver: ${CMAKE_ARGV3}")
    ENDIF()
ELSE()
    MESSAGE(FATAL_ERROR "GCC driver not specified")
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

EXECUTE_PROCESS(
    COMMAND ${GCC_DRIVER} -dumpspecs
    COMMAND jq -nR "[inputs]"
    OUTPUT_VARIABLE SPECS_LINES
    COMMAND_ERROR_IS_FATAL ANY
    TIMEOUT 15
)

SET(SPECS_TO_PROCESS startfile endfile)

STRING(JSON LinesCnt LENGTH "${SPECS_LINES}")
MATH(EXPR LinesCnt1 "${LinesCnt}-1")

UNSET(SPEC_NAMES)
SET(SPEC_IDX -1)
FOREACH(i RANGE ${LinesCnt1})
    STRING(JSON line GET "${SPECS_LINES}" ${i})
    IF("${line}" MATCHES "^\\*(.+):$")
        SET(SPEC_NAME "${CMAKE_MATCH_1}")
        LIST(APPEND SPEC_NAMES "${SPEC_NAME}")
        SET(SPEC_${SPEC_NAME} "[]")
        LIST(FIND SPECS_TO_PROCESS ${SPEC_NAME} SPEC_IDX)
    ELSEIF(${SPEC_IDX} GREATER_EQUAL 0)
        JsonArrayAppend(SPEC_${SPEC_NAME} "${SPEC_${SPEC_NAME}}" "${line}")
    ENDIF()
ENDFOREACH()

IF(DEFINED SPEC_endfile)
    RenameStartupFiles(SPEC_endfile OBJ_FILES rpi- "${SPEC_endfile}")
    IF(NO_SYSROOT)
        MESSAGE(NOTICE "${SPEC_endfile}")
    ELSE()
        RenameStartupFiles(SPEC_endfile OBJ_FILES rpi- "${SPEC_endfile}")
        CMAKE_PATH(APPEND CMAKE_SYSROOT usr lib ${SPECS_PREFIX}-endfile-specs.txt OUTPUT_VARIABLE SPECS_FILE_PATH)
        CMAKE_PATH(APPEND CMAKE_SYSROOT usr lib ${SPECS_PREFIX}-endfile-objs.json OUTPUT_VARIABLE JSON_FILE_PATH)
        MESSAGE(STATUS "[SPECS] ${SPECS_FILE_PATH} [${OBJ_FILES}]")
        WriteLines(${SPECS_FILE_PATH} endfile "${SPEC_endfile}")
        WriteObjFiles(${JSON_FILE_PATH} rpi- ${OBJ_FILES})
    ENDIF()
ENDIF()

IF(DEFINED SPEC_startfile)
    RenameStartupFiles(SPEC_startfile OBJ_FILES rpi- "${SPEC_startfile}")
    IF(NO_SYSROOT)
        MESSAGE(NOTICE "${SPEC_startfile}")
    ELSE()
        CMAKE_PATH(APPEND CMAKE_SYSROOT usr lib ${SPECS_PREFIX}-startfile-specs.txt OUTPUT_VARIABLE SPECS_FILE_PATH)
        CMAKE_PATH(APPEND CMAKE_SYSROOT usr lib ${SPECS_PREFIX}-startfile-objs.json OUTPUT_VARIABLE JSON_FILE_PATH)
        MESSAGE(STATUS "[SPECS] ${SPECS_FILE_PATH} [${OBJ_FILES}]")
        WriteLines(${SPECS_FILE_PATH} startfile "${SPEC_startfile}")
        WriteObjFiles(${JSON_FILE_PATH} rpi- ${OBJ_FILES})
    ENDIF()
ENDIF()
