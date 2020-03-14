REM-----------------------------------------
REM mod_pascal
REM Apache 2.4 module which can execute
REM Pascal program
REM
REM @link      https://github.com/zamronypj/mod_pascal
REM @copyright Copyright (c) 2020 Zamrony P. Juhara
REM @license   https://github.com/zamronypj/mod_pascal/blob/master/LICENSE (LGPL-2.1)
REM------------------------------------------

REM------------------------------------------------------
REM Script to setup compiler configuration for Windows
REM------------------------------------------------------

copy build.prod.cfg.sample build.prod.cfg
copy build.dev.cfg.sample build.dev.cfg
copy build.cfg.sample build.cfg
