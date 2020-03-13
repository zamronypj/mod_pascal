{-----------------------------------------
   Apache 2.4 module which can execute pascal
   program

   @author Zamrony P. Juhara <zamronypj@yahoo.com>
------------------------------------------}
library mod_pascal;

{$MODE OBJFPC}
{$H+}

uses

    sysUtils,
    httpd24,
    apr24,
    instant_fpc;

const

    MODULE_NAME = 'pascal_module';

    DEFAULT_INSTANT_FPC_BIN = '/usr/local/bin/instantfpc';
    DEFAULT_CACHE_DIR = '/tmp';

var
    pascal_module: module;{$IFDEF UNIX} public name MODULE_NAME;{$ENDIF}

exports

    pascal_module name MODULE_NAME;

{----------------------------------------------
  Handles apache requests
-----------------------------------------------}
function defaultHandler(r: prequest_rec): Integer; cdecl;
var
    requestedHandler: string;
    compileOutput : string;
    instantFpcBin : string;
    cacheDir : string;
begin
    //TODO: add ability to set from configuration
    instantFpcBin := DEFAULT_INSTANT_FPC_BIN;
    cacheDir := DEFAULT_CACHE_DIR;

    requestedHandler := r^.handler;

    { We decline to handle a request if r->handler is not the value of MODULE_NAME}
    if not sameText(requestedHandler, MODULE_NAME) then
    begin
        result := DECLINED;
        exit;
    end;

    ap_set_content_type(r, 'text/html');

    if not fileExists(r^.filename) then
    begin
        result := HTTP_NOT_FOUND;
        exit;
    end;

    if (r^.header_only <> 0) then
    begin
        { handle HEAD request }
        result := OK;
        exit;
    end;

    compileProgram(
        instantFpcBin,
        cacheDir,
        r^.filename,
        compileOutput
    );
    ap_rwrite(pchar(compileOutput), length(compileOutput), r);

    result := OK;
end;

{*******************************************************************
*  Registers the hooks
*******************************************************************}
procedure registerHooks(p: papr_pool_t); cdecl;
begin
    ap_hook_handler(@defaultHandler, nil, nil, APR_HOOK_MIDDLE);
end;

{*******************************************************************
*  Library initialization code
*******************************************************************}

begin
    fillChar(pascal_module, sizeOf(pascal_module), 0);

    STANDARD20_MODULE_STUFF(pascal_module);

    with pascal_module do
    begin
        name := MODULE_NAME;
        register_hooks := @registerHooks;
    end;
end.
