#
# CPack - post build script - lintian
#
# Links:
#   - https://manpages.debian.org/bookworm/lintian/lintian.1.en.html
#   - https://manpages.debian.org/bookworm/lintian/lintian-explain-tags.1.en.html
#   - https://decovar.dev/blog/2021/09/23/cmake-cpack-package-deb-apt/
#

CMAKE_MINIMUM_REQUIRED(VERSION 3.21)

LIST(GET CPACK_BUILD_SOURCE_DIRS 0 PROJECT_DIR)
CMAKE_PATH(APPEND PROJECT_DIR cpack suppressed-tags.txt OUTPUT_VARIABLE TAGS_FILE)
MESSAGE(STATUS "[lintian] Tags: ${TAGS_FILE}")

FOREACH(p IN LISTS CPACK_PACKAGE_FILES)
    CMAKE_PATH(GET p EXTENSION LAST_ONLY pext)
    IF(NOT ${pext} STREQUAL .deb)
        CONTINUE()
    ENDIF()

    MESSAGE(STATUS "[lintian] Package: ${p}")
    EXECUTE_PROCESS(
        COMMAND lintian
            --fail-on error,warning
            -q -i
            --color never
            --no-cfg --no-user-dirs
            --suppress-tags-from-file ${TAGS_FILE} ${p}
        TIMEOUT 300
        COMMAND_ERROR_IS_FATAL ANY
    )
ENDFOREACH()
