#! /bin/bash

################################################################################
# Prepare
################################################################################

# Set up shell
if [ "$(echo ${VERBOSE} | tr '[:upper:]' '[:lower:]')" = 'yes' ]; then
    set -x                      # Output commands
fi
set -e                          # Abort on errors

. $CCTK_HOME/lib/make/bash_utils.sh

# Take care of requests to build the library in any case
ZLIB_DIR_INPUT=$ZLIB_DIR
if [ "$(echo "${ZLIB_DIR}" | tr '[a-z]' '[A-Z]')" = 'BUILD' ]; then
    ZLIB_BUILD=yes
    ZLIB_DIR=
else
    ZLIB_BUILD=
fi

# Try to find the library if build isn't explicitly requested
if [ -z "${ZLIB_BUILD}" ]; then
    find_lib ZLIB zlib 1 1.0 "z" "zlib.h" "$ZLIB_DIR"
fi

THORN=zlib

################################################################################
# Build
################################################################################

if [ -n "${ZLIB_BUILD}" -o -z "${ZLIB_DIR}" ]; then
    echo "BEGIN MESSAGE"
    echo "Using bundled zlib..."
    echo "END MESSAGE"

    check_tools "tar"

    # Set locations
    BUILD_DIR=${SCRATCH_BUILD}/build/${THORN}
    if [ -z "${ZLIB_INSTALL_DIR}" ]; then
        INSTALL_DIR=${SCRATCH_BUILD}/external/${THORN}
    else
        echo "BEGIN MESSAGE"
        echo "Installing zlib into ${ZLIB_INSTALL_DIR}"
        echo "END MESSAGE"
        INSTALL_DIR=${ZLIB_INSTALL_DIR}
    fi
    ZLIB_BUILD=1
    ZLIB_DIR=${INSTALL_DIR}
    ZLIB_INC_DIRS=${ZLIB_DIR}/include
    ZLIB_LIB_DIRS=${ZLIB_DIR}/lib
    ZLIB_LIBS=z
else
    ZLIB_BUILD=
    DONE_FILE=${SCRATCH_BUILD}/done/${THORN}
    if [ ! -e ${DONE_FILE} ]; then
        mkdir ${SCRATCH_BUILD}/done 2> /dev/null || true
        date > ${DONE_FILE}
    fi
fi

################################################################################
# Configure Cactus
################################################################################

# Pass configuration options to build script
echo "BEGIN MAKE_DEFINITION"
echo "ZLIB_BUILD       = ${ZLIB_BUILD}"
echo "ZLIB_INSTALL_DIR = ${ZLIB_INSTALL_DIR}"
echo "END MAKE_DEFINITION"

set_make_vars "ZLIB" "$ZLIB_LIBS" "$ZLIB_LIB_DIRS" "$ZLIB_INC_DIRS"

# Pass options to Cactus
echo "BEGIN MAKE_DEFINITION"
echo "ZLIB_DIR      = ${ZLIB_DIR}"
echo "ZLIB_INC_DIRS = ${ZLIB_INC_DIRS}"
echo "ZLIB_LIB_DIRS = ${ZLIB_LIB_DIRS}"
echo "ZLIB_LIBS     = ${ZLIB_LIBS}"
echo "END MAKE_DEFINITION"

echo 'INCLUDE_DIRECTORY $(ZLIB_INC_DIRS)'
echo 'LIBRARY_DIRECTORY $(ZLIB_LIB_DIRS)'
echo 'LIBRARY           $(ZLIB_LIBS)'
