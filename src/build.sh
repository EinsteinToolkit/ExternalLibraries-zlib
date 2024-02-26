#! /bin/bash

################################################################################
# Build
################################################################################

# Set up shell
if [ "$(echo ${VERBOSE} | tr '[:upper:]' '[:lower:]')" = 'yes' ]; then
    set -x                      # Output commands
fi
set -e                          # Abort on errors

# Set locations
THORN=ZLIB
NAME=zlib-1.2.8
SRCDIR="$(dirname $0)"
BUILD_DIR=${SCRATCH_BUILD}/build/${THORN}
if [ -z "${ZLIB_INSTALL_DIR}" ]; then
    INSTALL_DIR=${SCRATCH_BUILD}/external/${THORN}
else
    echo "Installing zlib into ${ZLIB_INSTALL_DIR} "
    INSTALL_DIR=${ZLIB_INSTALL_DIR}
fi
DONE_FILE=${SCRATCH_BUILD}/done/${THORN}
ZLIB_DIR=${INSTALL_DIR}

# Set up environment
unset LIBS
if echo '' ${ARFLAGS} | grep 64 > /dev/null 2>&1; then
    export OBJECT_MODE=64
fi

# Disable parallel make. With parallel make, I sometimes
# encounter a build error "ld: in libz.a, malformed archive
# TOC entry for _zlibVersion, offset 824872 is beyond end of
# file 237568 for architecture x86_64"
unset MAKEFLAGS

echo "zlib: Preparing directory structure..."
cd ${SCRATCH_BUILD}
mkdir build external done 2> /dev/null || true
rm -rf ${BUILD_DIR} ${INSTALL_DIR}
mkdir ${BUILD_DIR} ${INSTALL_DIR}

echo "zlib: Unpacking archive..."
pushd ${BUILD_DIR}
${TAR?} xzf ${SRCDIR}/dist/${NAME}.tar.gz

echo "zlib: Configuring..."
cd ${NAME}
./configure --prefix=${ZLIB_DIR} --static

echo "zlib: Building..."
${MAKE}

echo "zlib: Installing..."
${MAKE} install prefix=${ZLIB_DIR}
popd

 echo "zlib: Cleaning up..."
 rm -rf ${BUILD_DIR}

date > ${DONE_FILE}
echo "zlib: Done."
