#
# arch-specific
#
CMAKE_MINIMUM_REQUIRED(VERSION 3.21)

FUNCTION(CheckArchSpecificTag TagName TagValue)
    SET(TAG_CHECKED ON)
    IF(${TagName} STREQUAL Tag_CPU_name)
        IF(NOT ("${TagValue}" STREQUAL 6 OR "${TagValue}" STREQUAL 6KZ))
            SET(TAG_CHECK_FAILED ON PARENT_SCOPE)
            SET(TAG_EXPECTED_VALUE "6 or 6KZ" PARENT_SCOPE)
        ENDIF()
    ELSEIF(${TagName} STREQUAL Tag_CPU_arch)
        IF(NOT ("${TagValue}" STREQUAL v6 OR "${TagValue}" STREQUAL v6KZ))
            SET(TAG_CHECK_FAILED ON PARENT_SCOPE)
            SET(TAG_EXPECTED_VALUE "v6 or v6KZ" PARENT_SCOPE)
        ENDIF()
    ELSEIF(${TagName} STREQUAL Tag_THUMB_ISA_use)
        IF(NOT "${TagValue}" STREQUAL Thumb-1)
            SET(TAG_CHECK_FAILED ON PARENT_SCOPE)
            SET(TAG_EXPECTED_VALUE Thumb-1 PARENT_SCOPE)
        ENDIF()
    ELSEIF(${TagName} STREQUAL Tag_FP_arch)
        IF(NOT "${TagValue}" STREQUAL VFPv2)
            SET(TAG_CHECK_FAILED ON PARENT_SCOPE)
            SET(TAG_EXPECTED_VALUE VFPv2 PARENT_SCOPE)
        ENDIF()
    ELSE()
        SET(TAG_CHECKED OFF)
    ENDIF()
    SET(TAG_CHECKED ${TAG_CHECKED} PARENT_SCOPE)
ENDFUNCTION()

IF(NOT DEFINED CMAKE_READELF)
    MESSAGE(FATAL_ERROR "readelf utility not specified")
ENDIF()

IF(NOT DEFINED MODULE_PATH)
    MESSAGE(FATAL_ERROR "Library not specified")
ENDIF()

EXECUTE_PROCESS(
    COMMAND ${CMAKE_READELF} -AW ${MODULE_PATH}
    OUTPUT_VARIABLE ARCH_SPECIFIC_NL
    OUTPUT_STRIP_TRAILING_WHITESPACE    
    COMMAND_ERROR_IS_FATAL ANY
    TIMEOUT 15
)

UNSET(CHECK_FAILED)
IF(ARCH_SPECIFIC_NL)
    STRING(REGEX MATCHALL "[^\n\r]+" ARCH_SPECIFIC ${ARCH_SPECIFIC_NL})
    FOREACH(l IN LISTS ARCH_SPECIFIC)
        UNSET(TAG_CHECKED)
        UNSET(TAG_CHECK_FAILED)
        UNSET(TAG_EXPECTED_VALUE)

        IF("${l}" MATCHES "^[\t ]*(.+):[\t ]*\"(.+)\"$")
            CheckArchSpecificTag("${CMAKE_MATCH_1}" "${CMAKE_MATCH_2}")
        ELSEIF("${l}" MATCHES "^[\t ]*(.+):[\t ]*(.+)$")
            CheckArchSpecificTag("${CMAKE_MATCH_1}" "${CMAKE_MATCH_2}")
        ELSE()
            CONTINUE()
        ENDIF()

        IF(NOT TAG_CHECKED)
            MESSAGE(STATUS "[arch ·] ${CMAKE_MATCH_1}: ${CMAKE_MATCH_2}")
        ELSEIF(TAG_CHECK_FAILED)
            MESSAGE(STATUS "[arch ⍻] ${CMAKE_MATCH_1}: ${CMAKE_MATCH_2} [expected: ${TAG_EXPECTED_VALUE}]")
            SET(CHECK_FAILED ON)
        ELSE()
            MESSAGE(STATUS "[arch ✓] ${CMAKE_MATCH_1}: ${CMAKE_MATCH_2}")
        ENDIF()
    ENDFOREACH()
ENDIF()

IF(CHECK_FAILED)
    MESSAGE(FATAL_ERROR "Invalid architecture-specific data")
ENDIF()
