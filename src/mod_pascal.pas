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
    process,
    httpd24,
    apr24,
    lib_consts,
    instant_fpc,
    lib_utils;

const

    FPC_BIN_PARAM = 0;
    INSTANTFPC_BIN_PARAM = 1;
    CACHEDIR_PARAM = 2;

type

    TPascalParams = array[FPC_BIN_PARAM..CACHEDIR_PARAM] of command_rec;

    TPascalModuleCfg = record
        fpcBin : string;
        instantfpcBin : string;
        cacheDir : string;
    end;

var

    pascalModule: module;{$IFDEF UNIX} public name MODULE_NAME;{$ENDIF}
    pascalParams : TPascalParams;
    moduleCfg : TPascalModuleCfg;

exports

    pascalModule name MODULE_NAME;


    function buildHttpEnv(req: prequest_rec; const cgienv : TStrings) : TStrings;
    var
        headers : papr_array_header_t;
        headersEntry : papr_table_entry_t;
        headerEnv, key : string;
        i : integer;
    begin
        headers := apr_table_elts(req^.headers_in);
        headersEntry := papr_table_entry_t(headers^.elts);
        for i := 0 to headers^.nelts - 1 do
        begin
            key := asString(headersEntry^.key);
            //skip Content-Type and Content-Length as this will be set in CGI Environment
            if not (SameText(key, 'Content-Type') or SameText(key, 'Content-Length')) then
            begin
                //transform for example Content-Encoding into HTTP_CONTENT_ENCODING
                headerEnv := 'HTTP_' + upperCase(stringReplace(key, '-', '_', [rfReplaceAll]));
                cgienv.add(headerEnv + '=' + asString(headersEntry^.val));
            end;
            inc(headersEntry);
        end;

        result := cgienv;
    end;

    function buildCgiEnv(req: prequest_rec; const cgienv : TStrings) : TStrings;
    var headerValue : string;
       isStrIp : integer;
    begin
        cgiEnv.add('PATH=' + GetEnvironmentVariable('PATH'));
        cgienv.add('GATEWAY_INTERFACE=CGI/1.1');
        headerValue := asString(apr_table_get(req^.headers_in, 'Content-Type'));
        if (headerValue = '') then
        begin
            headerValue := asString(req^.content_type);
        end;
        cgienv.add('CONTENT_TYPE=' + headerValue);

        cgienv.add('CONTENT_LENGTH=' + asString(apr_table_get(req^.headers_in, 'Content-Length')));

        cgienv.add('SERVER_PROTOCOL=' + asString(req^.protocol));
        cgienv.add('SERVER_PORT=' + IntToStr(ap_get_server_port(req)));
        cgienv.add('SERVER_NAME=' + asString(ap_get_server_name_for_url(req)));

        //ap_get_server_banner() returns gibberish data. not sure why. Encoding?
        //cgienv.add('SERVER_SOFTWARE=' + asString(ap_get_server_banner()));
        cgienv.add('SERVER_SOFTWARE=Apache');

        cgienv.add('PATH_INFO=' + asString(req^.path_info));
        cgienv.add('REQUEST_URI=' + asString(req^.uri));
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

        //HTTP protocol specific environment
        result := buildHttpEnv(req, cgienv);
    end;

    procedure readRequestBody(req : prequest_rec; const bodyStr : TStream);
    var bytesRead : integer;
        buff : pointer;
    begin
        getMem(buff, BUFF_SIZE);
        try
            if ap_setup_client_block(req, REQUEST_CHUNKED_DECHUNK) <> OK then
            begin
                exit;
            end;

            if (ap_should_client_block(req) = 1) then
            begin
                repeat
                    bytesRead := ap_get_client_block(req, buff, BUFF_SIZE);
                    bodyStr.writeBuffer(buff^, bytesRead);
                until bytesRead = 0;
            end;
        finally
            freeMem(buff);
        end;
    end;

    function executeProgram(
        req: prequest_rec;
        out compileOutput : string
    ) : integer;
    var
        cgienv : TStrings;
        proc : TProcess;
    begin
        cgienv := TStringList.create();
        try
            proc := TProcess.create(nil);
            try
                initProgram(
                    proc,
                    moduleCfg.fpcBin,
                    moduleCfg.instantFpcBin,
                    moduleCfg.cacheDir,
                    req^.filename,
                    buildCgiEnv(req, cgienv)
                );
                proc.execute();
                //read request body and pipe it into instantfpc STDIN
                readRequestBody(req, proc.Input);
                compileOutput := readProgramOutput(proc);
                result := proc.exitCode;
            finally
                proc.free();
            end;
        finally
            cgienv.free();
        end;
    end;

    function buildResponseHeader(req : prequest_rec; var compileOutput : string) : integer;
    var headerParts : string;
        i, headerMarkerPos : integer;
        headers : TStringArray;
        keyval : TStringArray;
        key, val : string;
    begin
        result := OK;
        //TODO: not very performant string operation. lot of string copies.
        //need to improve by avoiding it
        headerMarkerPos := pos(LineEnding+LineEnding, compileOutput);
        headerParts := copy(compileOutput, 1, headerMarkerPos - 1);
        headers := headerParts.split(LineEnding);
        for i:= 0 to Length(headers) - 1 do
        begin
            keyval := headers[i].split(':');
            key := trim(keyval[0]);
            val := trim(keyval[1]);
            if sameText(key, 'Status') then
            begin
                result := strtoInt(val);
            end else
            if sameText(key, 'Content-Type') then
            begin
                ap_set_content_type(req, pchar(val));
            end else
            begin
                apr_table_setn(req^.headers_out, pchar(key), pchar(val));
            end;
        end;
        //remove header part
        compileOutput := copy(compileOutput, headerMarkerPos + 1, length(compileOutput) - length(headerParts));
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

        if (executeProgram(req, compileOutput) <> 0) then
        begin
            result := HTTP_INTERNAL_SERVER_ERROR;
            exit;
        end;

        result := buildResponseHeader(req, compileOutput);

        ap_rwrite(pchar(compileOutput), length(compileOutput), req);
    end;

    {----------------------------------------------
       Registers the hooks
       @param pool Apache memory pool object
    -----------------------------------------------}
    procedure registerPascalHooks(pool: papr_pool_t); cdecl;
    begin
        ap_hook_handler(@pascalHandler, nil, nil, APR_HOOK_MIDDLE);
    end;

    {----------------------------------------------
       set fpc executable binary path from config
    -----------------------------------------------}
    function setFpcBin(parms: Pcmd_parms; mconfig: pointer; arg: Pchar): Pchar; cdecl;
    begin
        moduleCfg.fpcBin := asString(arg);
        result := nil;
    end;

    {----------------------------------------------
       set instantfpc executable binary path from config
    -----------------------------------------------}
    function setInstantFpcBin(parms: Pcmd_parms; mconfig: pointer; arg: Pchar): Pchar; cdecl;
    begin
        moduleCfg.instantfpcBin := asString(arg);
        result := nil;
    end;

    {----------------------------------------------
       set instantfpc cache directory from config
    -----------------------------------------------}
    function setInstantFpcCacheDir(parms: Pcmd_parms; mconfig: pointer; arg: Pchar): Pchar; cdecl;
    begin
        moduleCfg.cacheDir := asString(arg);
        result := nil;
    end;

begin
    {---------------------------------------------------
        Module configuration initialization code
    ----------------------------------------------------}
    //set default value
    moduleCfg.fpcBin := DEFAULT_FPC_BIN;
    moduleCfg.instantFpcBin := DEFAULT_INSTANT_FPC_BIN;
    moduleCfg.cacheDir := DEFAULT_CACHE_DIR;

    fillChar(pascalParams, sizeOf(pascalParams), 0);
    pascalParams[FPC_BIN_PARAM] := AP_INIT_TAKE1(
        'FpcBin',
        @setFpcBin,
        nil,
        RSRC_CONF,
        'fpc binary executable path'
    );
    pascalParams[INSTANTFPC_BIN_PARAM] := AP_INIT_TAKE1(
        'InstantFpcBin',
        @setInstantFpcBin,
        nil,
        RSRC_CONF,
        'instantfpc binary executable path'
    );
    pascalParams[CACHEDIR_PARAM] := AP_INIT_TAKE1(
        'InstantFpcCacheDir',
        @setInstantFpcCacheDir,
        nil, RSRC_CONF,
        'instantfpc cache directory'
    );

    {---------------------------------------------------
        Library initialization code
    ----------------------------------------------------}
    fillChar(pascalModule, sizeOf(pascalModule), 0);
    STANDARD20_MODULE_STUFF(pascalModule);
    pascalModule.name := MODULE_NAME;
    pascalModule.register_hooks := @registerPascalHooks;
    pascalModule.cmds := @pascalParams;
end.
