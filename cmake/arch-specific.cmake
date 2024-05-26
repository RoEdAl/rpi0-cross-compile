#
# arch-specific
#
CMAKE_MINIMUM_REQUIRED(VERSION 3.21)

FUNCTION(CheckArchSpecificTag TagName TagValue)
    SET(TAG_CHECKED ON)
    # Attribute Section: aeabi
    IF(${TagName} STREQUAL "Attribute Section")
        IF(NOT "${TagValue}" STREQUAL aeabi)
            SET(TAG_CHECK_FAILED ON PARENT_SCOPE)
            SET(TAG_EXPECTED_VALUE aeabi PARENT_SCOPE)
        ENDIF()    
    ELSEIF(${TagName} STREQUAL Tag_CPU_name)
        IF(NOT ("${TagValue}" STREQUAL 6 OR "${TagValue}" STREQUAL 6KZ  OR "${TagValue}" STREQUAL arm1136jf-s))
            SET(TAG_CHECK_FAILED ON PARENT_SCOPE)
            SET(TAG_EXPECTED_VALUE "6, 6KZ or arm1136jf-s" PARENT_SCOPE)
        ENDIF()
    ELSEIF(${TagName} STREQUAL Tag_CPU_arch)
        IF(NOT ("${TagValue}" STREQUAL v6 OR "${TagValue}" STREQUAL v6KZ))
            SET(TAG_CHECK_FAILED ON PARENT_SCOPE)
            SET(TAG_EXPECTED_VALUE "v6, v6KZ or arm1136jf-s" PARENT_SCOPE)
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
    ELSEIF(${TagName} STREQUAL Tag_ABI_VFP_args)
        IF(NOT "${TagValue}" STREQUAL "VFP registers")
            SET(TAG_CHECK_FAILED ON PARENT_SCOPE)
            SET(TAG_EXPECTED_VALUE "VFP registers" PARENT_SCOPE)
        ENDIF()    
    ELSE()
        SET(TAG_CHECKED OFF)
    ENDIF()
    SET(TAG_CHECKED ${TAG_CHECKED} PARENT_SCOPE)
ENDFUNCTION()

FUNCTION(CheckArchSpecificTags MODULE_PATH)
    CMAKE_PATH(GET MODULE_PATH FILENAME MODULE_NAME)

    EXECUTE_PROCESS(
        COMMAND ${CMAKE_READELF} -AW ${MODULE_PATH}
        OUTPUT_VARIABLE ARCH_SPECIFIC_NL
        OUTPUT_STRIP_TRAILING_WHITESPACE    
        COMMAND_ERROR_IS_FATAL ANY
        TIMEOUT 15
    )

    IF(NOT ARCH_SPECIFIC_NL)
        SET(CHECK_FAILED PARENT_SCOPE)
        RETURN()
    ENDIF()

    UNSET(CHECK_FAILED)
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
            MESSAGE(STATUS "[${MODULE_NAME}][arch ·] ${CMAKE_MATCH_1}: ${CMAKE_MATCH_2}")
        ELSEIF(TAG_CHECK_FAILED)
            MESSAGE(STATUS "[${MODULE_NAME}][arch ⍻] ${CMAKE_MATCH_1}: ${CMAKE_MATCH_2} [expected: ${TAG_EXPECTED_VALUE}]")
            SET(CHECK_FAILED ON)
        ELSE()
            MESSAGE(STATUS "[${MODULE_NAME}][arch ✓] ${CMAKE_MATCH_1}: ${CMAKE_MATCH_2}")
        ENDIF()
    ENDFOREACH()

    SET(CHECK_FAILED ${CHECK_FAILED} PARENT_SCOPE)
ENDFUNCTION()

IF(NOT DEFINED CMAKE_READELF)
    MESSAGE(FATAL_ERROR "readelf utility not specified")
ENDIF()

SET(MODULES_FAILED)
MATH(EXPR ARGC1 "${CMAKE_ARGC}-1")
FOREACH(i RANGE 4 ${ARGC1})
    UNSET(CHECK_FAILED)
    CheckArchSpecificTags(${CMAKE_ARGV${i}})
    IF(CHECK_FAILED)
        LIST(APPEND MODULES_FAILED ${CMAKE_ARGV${i}})
    ENDIF()
ENDFOREACH()

IF(MODULES_FAILED)
    LIST(LENGTH MODULES_FAILED CNT)
    MESSAGE(FATAL_ERROR "[arch] ${CNT} module(s) failed")
ENDIF()
