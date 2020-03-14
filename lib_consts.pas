unit lib_consts;

interface

{$MODE OBJFPC}
{$H+}

const

    MODULE_NAME = 'pascal_module';
    HANDLER_NAME = 'pascal-handler';


    {$IFDEF UNIX}
        DEFAULT_INSTANT_FPC_BIN = '/usr/local/bin/instantfpc';
        DEFAULT_CACHE_DIR = '/tmp';
    {$ENDIF}

    {$IFDEF WINDOWS}
        DEFAULT_INSTANT_FPC_BIN = 'C:\fpc\bin\instantfpc';
        DEFAULT_CACHE_DIR = 'C:\Windows\Temp';
    {$ENDIF}

implementation
end.
