{*-----------------------------------------
 * mod_pascal
 * Apache 2.4 module which can execute
 * Pascal program
 *
 * @link      https://github.com/zamronypj/mod_pascal
 * @copyright Copyright (c) 2020 Zamrony P. Juhara
 * @license   https://github.com/zamronypj/mod_pascal/blob/master/LICENSE (LGPL-2.1)
 *------------------------------------------}
library mod_pascal;

{$MODE OBJFPC}
{$H+}

uses

    SysUtils,
    Classes,
    httpd24,
    apr,
    apr24,
    lib_consts,
    instant_fpc,
    lib_utils;

var

    pascalModule: module;{$IFDEF UNIX} public name MODULE_NAME;{$ENDIF}

exports

    pascalModule name MODULE_NAME;


    function buildCgiEnv(req: prequest_rec; const cgienv : TStrings) : TStrings;
    var headerValue : string;
        isStrIp : integer;
    begin
        //ap_add_common_vars(req);
        //ap_add_cgi_vars(req);
        cgiEnv.add('PATH=' + GetEnvironmentVariable('PATH'));

        cgienv.add('GATEWAY_INTERFACE=CGI/1.1');

        headerValue := asString(apr_table_get(req^.headers_in, 'Content-Type'));
        if (headerValue = '') then
        begin
            headerValue := asString(req^.content_type);
        end;
        cgienv.add('CONTENT_TYPE=' + headerValue);

        cgienv.add('CONTENT_LENGTH=' + asString(apr_table_get(req^.headers_in, 'Content-Length')));

        cgienv.add('GATEWAY_INTERFACE=CGI/1.1');
        cgienv.add('SERVER_PROTOCOL=' + asString(req^.protocol));
        cgienv.add('SERVER_PORT=' + IntToStr(ap_get_server_port(req)));
        cgienv.add('SERVER_NAME=' + asString(ap_get_server_name_for_url(req)));

        //ap_get_server_banner() returns gibberish data. not sure why. Encoding?
        //cgienv.add('SERVER_SOFTWARE=' + asString(ap_get_server_banner()));
        cgienv.add('SERVER_SOFTWARE=Apache');

        cgienv.add('PATH_INFO=' + asString(req^.path_info));
        cgienv.add('REQUEST_METHOD=' + asString(req^.method));
        cgienv.add('QUERY_STRING=' + asString(req^.args));
        cgienv.add('SCRIPT_NAME=' + asString(req^.filename));
        cgienv.add('PATH_TRANSLATED=' + asString(req^.filename));
        cgienv.add('REMOTE_ADDR=' + asString(req^.useragent_ip));

        cgienv.add('REMOTE_HOST=' + asString(
            ap_get_remote_host(
                req^.connection,
                req^.per_dir_config,
                REMOTE_HOST,
                @isStrIp
            )
        ));

        //HTTP protocol specific
        headerValue := asString(apr_table_get(req^.headers_in, 'Content-Encoding'));
        if (headerValue = '') then
        begin
            headerValue := asString(req^.content_encoding);
        end;
        cgienv.add('HTTP_CONTENT_ENCODING=' + headerValue);
        cgienv.add('HTTP_ACCEPT=' + asString(apr_table_get(req^.headers_in, 'Accept')));
        cgienv.add('HTTP_USER_AGENT=' + asString(apr_table_get(req^.headers_in, 'User-Agent')));
        cgienv.add('HTTP_X_REQUESTED_WITH=' + asString(apr_table_get(req^.headers_in, 'X-Requested-With')));
        cgienv.add('HTTP_HOST=' + asString(apr_table_get(req^.headers_in, 'Host')));
        result := cgienv;
    end;

    function executeProgram(
        req: prequest_rec;
        out compileOutput : string
    ) : integer;
    var
        instantFpcBin : string;
        fpcBin : string;
        cacheDir : string;
        cgienv : TStrings;
    begin
        //TODO: add ability to set from configuration
        fpcBin := DEFAULT_FPC_BIN;
        instantFpcBin := DEFAULT_INSTANT_FPC_BIN;
        cacheDir := DEFAULT_CACHE_DIR;

        //TODO: setup CGI Environment variable
        cgienv := TStringList.create();
        try
            result := execProgram(
                fpcBin,
                instantFpcBin,
                cacheDir,
                req^.filename,
                buildCgiEnv(req, cgienv),
                compileOutput
            );
        finally
            cgienv.free();
        end;

    end;

    {----------------------------------------------
      Handles apache requests
      @param req Apache request
      @return status
    -----------------------------------------------}
    function pascalHandler(req: prequest_rec): integer; cdecl;
    var
        requestedHandler: string;
        compileOutput : string;
    begin

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

        executeProgram(req, compileOutput);

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

begin
    {---------------------------------------------------
        Library initialization code
    ----------------------------------------------------}
    fillChar(pascalModule, sizeOf(pascalModule), 0);

    STANDARD20_MODULE_STUFF(pascalModule);

    with pascalModule do
    begin
        name := MODULE_NAME;
        register_hooks := @registerPascalHooks;
    end;
end.
