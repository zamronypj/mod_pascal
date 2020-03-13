{-----------------------------------------
   mod_pascal,
   Apache 2.4 module which can execute
   Pascal program

   @author Zamrony P. Juhara <zamronypj@yahoo.com>
------------------------------------------}
library mod_pascal;

{$MODE OBJFPC}
{$H+}

uses

    sysutils,
    httpd24,
    apr24,
    instant_fpc;

const

    MODULE_NAME = 'pascal_module';
    HANDLER_NAME = 'pascal-handler';

    DEFAULT_INSTANT_FPC_BIN = '/usr/local/bin/instantfpc';
    DEFAULT_CACHE_DIR = '/tmp';

var
    pascalModule: module;{$IFDEF UNIX} public name MODULE_NAME;{$ENDIF}

exports

    pascalModule name MODULE_NAME;

{----------------------------------------------
  Handles apache requests
-----------------------------------------------}
function defaultHandler(req: prequest_rec): Integer; cdecl;
var
    requestedHandler: string;
    compileOutput : string;
    instantFpcBin : string;
    cacheDir : string;
begin
    //TODO: add ability to set from configuration
    instantFpcBin := DEFAULT_INSTANT_FPC_BIN;
    cacheDir := DEFAULT_CACHE_DIR;

    requestedHandler := req^.handler;

    { We decline request if req->handler is not HANDLER_NAME}
    if not sameText(requestedHandler, HANDLER_NAME) then
    begin
        result := DECLINED;
        exit;
    end;

    ap_set_content_type(req, 'text/html');

    if not fileExists(req^.filename) then
    begin
        result := HTTP_NOT_FOUND;
        exit;
    end;

    if (req^.header_only <> 0) then
    begin
        { handle HEAD request }
        result := OK;
        exit;
    end;

    //TODO: setup CGI Environment variable

    compileProgram(
        instantFpcBin,
        cacheDir,
        req^.filename,
        compileOutput
    );

    //TODO: setup HTTP response header

    ap_rwrite(pchar(compileOutput), length(compileOutput), req);

    result := OK;
end;

{----------------------------------------------
  Registers the hooks
-----------------------------------------------}
procedure registerHooks(p: papr_pool_t); cdecl;
begin
    ap_hook_handler(@defaultHandler, nil, nil, APR_HOOK_MIDDLE);
end;

{---------------------------------------------------
  Library initialization code
----------------------------------------------------}

begin
    fillChar(pascalModule, sizeOf(pascalModule), 0);

    STANDARD20_MODULE_STUFF(pascalModule);

    with pascalModule do
    begin
        name := MODULE_NAME;
        register_hooks := @registerHooks;
    end;
end.
