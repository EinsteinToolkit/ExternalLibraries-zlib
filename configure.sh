#! /bin/bash

################################################################################
# Prepare
################################################################################

# Set up shell
if [ "$(echo ${VERBOSE} | tr '[:upper:]' '[:lower:]')" = 'yes' ]; then
    set -x                      # Output commands
fi
set -e                          # Abort on errors



################################################################################
# Search
################################################################################

if [ -z "${ZLIB_DIR}" ]; then
    echo "BEGIN MESSAGE"
    echo "zlib selected, but ZLIB_DIR not set. Checking some places..."
    echo "END MESSAGE"
    
    DIRS="/usr /usr/local /usr/local/packages /usr/local/apps /opt/local ${HOME} c:/packages"
    # look into each directory
    for dir in $DIRS; do
        # libraries might have different file extensions
        for libext in a so dylib; do
            # libraries can be in /lib or /lib64
            for libdir in lib64 lib; do
                FILES="include/zlib.h $libdir/libz.$libext"
                # assume this is the one and check all needed files
                ZLIB_DIR="$dir"
                for file in $FILES; do
                    # discard this directory if one file was not found
                    if [ ! -r "$dir/$file" ]; then
                        unset ZLIB_DIR
                        break
                    fi
                done
                # don't look further if all files have been found
                if [ -n "$ZLIB_DIR" ]; then
                    break
                fi
            done
            # don't look further if all files have been found
            if [ -n "$ZLIB_DIR" ]; then
                break
            fi
        done
        # don't look further if all files have been found
        if [ -n "$ZLIB_DIR" ]; then
            break
        fi
    done
    
    if [ -z "$ZLIB_DIR" ]; then
        echo "BEGIN MESSAGE"
        echo "zlib not found"
        echo "END MESSAGE"
    else
        echo "BEGIN MESSAGE"
        echo "Found zlib in ${ZLIB_DIR}"
        echo "END MESSAGE"
    fi
fi



################################################################################
# Build
################################################################################

if [ -z "${ZLIB_DIR}"                                                   \
     -o "$(echo "${ZLIB_DIR}" | tr '[a-z]' '[A-Z]')" = 'BUILD' ]
then
    echo "BEGIN MESSAGE"
    echo "Building zlib..."
    echo "END MESSAGE"
    
    # Set locations
    THORN=zlib
    NAME=zlib-1.2.5
    SRCDIR=$(dirname $0)
    BUILD_DIR=${SCRATCH_BUILD}/build/${THORN}
    if [ -z "${ZLIB_INSTALL_DIR}" ]; then
        INSTALL_DIR=${SCRATCH_BUILD}/external/${THORN}
    else
        echo "BEGIN MESSAGE"
        echo "Installing zlib into ${ZLIB_INSTALL_DIR}"
        echo "END MESSAGE"
        INSTALL_DIR=${ZLIB_INSTALL_DIR}
    fi
    DONE_FILE=${SCRATCH_BUILD}/done/${THORN}
    ZLIB_DIR=${INSTALL_DIR}
    
    if [ -e ${DONE_FILE} -a ${DONE_FILE} -nt ${SRCDIR}/dist/${NAME}.tar.gz \
                         -a ${DONE_FILE} -nt ${SRCDIR}/configure.sh ]
    then
        echo "BEGIN MESSAGE"
        echo "zlib has already been built; doing nothing"
        echo "END MESSAGE"
    else
        echo "BEGIN MESSAGE"
        echo "Building zlib"
        echo "END MESSAGE"

        # Build in a subshell
        (
        exec >&2                # Redirect stdout to stderr
        if [ "$(echo ${VERBOSE} | tr '[:upper:]' '[:lower:]')" = 'yes' ]; then
            set -x              # Output commands
        fi
        set -e                  # Abort on errors
        cd ${SCRATCH_BUILD}
        
        # Set up environment
        export LDFLAGS
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
        mkdir build external done 2> /dev/null || true
        rm -rf ${BUILD_DIR} ${INSTALL_DIR}
        mkdir ${BUILD_DIR} ${INSTALL_DIR}
        
        echo "zlib: Unpacking archive..."
        pushd ${BUILD_DIR}
        ${TAR} xzf ${SRCDIR}/dist/${NAME}.tar.gz
        ${PATCH} -p0 < ${SRCDIR}/dist/install.diff
        
        echo "zlib: Configuring..."
        cd ${NAME}
        # Guess whether Cactus uses static linking, and if so, build
        # only static libraries
        ./configure --prefix=${ZLIB_DIR} $(if echo '' ${LDFLAGS} | grep -q static; then echo '' '--static'; fi)
        
        echo "zlib: Building..."
        ${MAKE}
        
        echo "zlib: Installing..."
        ${MAKE} install prefix=${ZLIB_DIR}
        popd
        
        echo "zlib: Cleaning up..."
        rm -rf ${BUILD_DIR}
        
        date > ${DONE_FILE}
        echo "zlib: Done."
        
        )
        
        if (( $? )); then
            echo 'BEGIN ERROR'
            echo 'Error while building zlib. Aborting.'
            echo 'END ERROR'
            exit 1
        fi
    fi
    
fi



################################################################################
# Check for additional libraries
################################################################################

# Set options
if [ "${ZLIB_DIR}" = '/usr' -o "${ZLIB_DIR}" = '/usr/local' ]; then
    ZLIB_INC_DIRS=''
    ZLIB_LIB_DIRS=''
else
    ZLIB_INC_DIRS="${ZLIB_DIR}/include"
    ZLIB_LIB_DIRS="${ZLIB_DIR}/lib"
fi
ZLIB_LIBS='z'



################################################################################
# Configure Cactus
################################################################################

# Pass options to Cactus
echo "BEGIN MAKE_DEFINITION"
echo "HAVE_ZLIB     = 1"
echo "ZLIB_DIR      = ${ZLIB_DIR}"
echo "ZLIB_INC_DIRS = ${ZLIB_INC_DIRS}"
echo "ZLIB_LIB_DIRS = ${ZLIB_LIB_DIRS}"
echo "ZLIB_LIBS     = ${ZLIB_LIBS}"
echo "END MAKE_DEFINITION"

echo 'INCLUDE_DIRECTORY $(ZLIB_INC_DIRS)'
echo 'LIBRARY_DIRECTORY $(ZLIB_LIB_DIRS)'
echo 'LIBRARY           $(ZLIB_LIBS)'