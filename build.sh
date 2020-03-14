#-----------------------------------------
# mod_pascal
# Apache 2.4 module which can execute
# Pascal program
#
# @link      https://github.com/zamronypj/mod_pascal
# @copyright Copyright (c) 2020 Zamrony P. Juhara
# @license   https://github.com/zamronypj/mod_pascal/blob/master/LICENSE (LGPL-2.1)
#------------------------------------------
#!/bin/bash

#------------------------------------------------------
# Build script for Linux
#------------------------------------------------------


if [ -z "${BUILD_TYPE}" ]; then
export BUILD_TYPE="prod"
fi

if [ -z "${SRC_DIR}" ]; then
export SRC_DIR="src"
fi

if [ -z "${UNIT_OUTPUT_DIR}" ]; then
    export UNIT_OUTPUT_DIR="bin/unit"
fi

if [ -z "${LIB_OUTPUT_DIR}" ]; then
export LIB_OUTPUT_DIR="bin"
fi

if [ -z "${LIB_OUTPUT_NAME}" ]; then
export LIB_OUTPUT_NAME="mod_pascal.so"
fi

if [ -z "${SOURCE_LIB_NAME}" ]; then
export SOURCE_LIB_NAME="mod_pascal.pas"
fi

if [ -z "${FPC_BIN}" ]; then
export FPC_BIN="fpc"
fi

${FPC_BIN} @build.cfg ${SRC_DIR}/${SOURCE_LIB_NAME}
