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

var
    pascal_module: module;{$ifdef unix} public name MODULE_NAME;{$endif}

exports

    pascal_module name MODULE_NAME;

{*******************************************************************
*  Handles apache requests
*******************************************************************}
function defaultHandler(r: prequest_rec): Integer; cdecl;

var
    requestedHandler: string;
    compileOutput : string;

begin
    requestedHandler := r^.handler;

    { We decline to handle a request if r->handler is not the value of MODULE_NAME}
    if not SameText(requestedHandler, MODULE_NAME) then
    begin
        result := DECLINED;
        Exit;
    end;

    ap_set_content_type(r, 'text/html');

    { If the request is for a header only, and not a request for
    the whole content, then return OK now. We don't have to do
    anything else.
    }
    if (r^.header_only <> 0) then
    begin
        result := OK;
        exit;
    end;

    if (fileExists(r^.filename)) then
    begin
        compileOutput := '';
        compileProgram(r^.filename, compileOutput);
        ap_rwrite(PChar(compileOutput), length(compileOutput), r);
        result := OK;
    end else
    begin
        result := HTTP_NOT_FOUND;
    end;
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
