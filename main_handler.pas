unit main_handler;

interface

{$MODE OBJFPC}
{$H+}

uses

    httpd24,
    apr24;

    {----------------------------------------------
       Registers the hooks
       @param pool Apache memory pool object
    -----------------------------------------------}
    procedure registerPascalHooks(pool: papr_pool_t); cdecl;

implementation

uses

    sysutils,
    instant_fpc,
    lib_consts;

    {----------------------------------------------
      Handles apache requests
      @param req Apache request
      @return status
    -----------------------------------------------}
    function pascalHandler(req: prequest_rec): Integer; cdecl;
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

        execProgram(
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
       @param pool Apache memory pool object
    -----------------------------------------------}
    procedure registerPascalHooks(pool: papr_pool_t); cdecl;
    begin
        ap_hook_handler(@pascalHandler, nil, nil, APR_HOOK_MIDDLE);
    end;

end.
