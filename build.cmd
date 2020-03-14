REM-----------------------------------------
REM mod_pascal
REM Apache 2.4 module which can execute
REM Pascal program
REM
REM @link      https://github.com/zamronypj/mod_pascal
REM @copyright Copyright (c) 2020 Zamrony P. Juhara
REM @license   https://github.com/zamronypj/mod_pascal/blob/master/LICENSE (LGPL-2.1)
REM------------------------------------------

REM ------------------------------------
REM -- build script for Windows
REM ------------------------------------

IF NOT DEFINED BUILD_TYPE (SET BUILD_TYPE="prod")
IF NOT DEFINED SRC_DIR (SET SRC_DIR="src")
IF NOT DEFINED UNIT_OUTPUT_DIR (SET UNIT_OUTPUT_DIR="bin\unit")
IF NOT DEFINED LIB_OUTPUT_DIR (SET LIB_OUTPUT_DIR="bin")
IF NOT DEFINED LIB_OUTPUT_NAME (SET LIB_OUTPUT_NAME="mod_pascal.so")
IF NOT DEFINED SOURCE_LIB_NAME (SET SOURCE_LIB_NAME="mod_pascal.pas")
IF NOT DEFINED FPC_BIN (SET FPC_BIN="fpc")

%FPC_BIN% @build.cfg %SRC_DIR%\%SOURCE_LIB_NAME%
