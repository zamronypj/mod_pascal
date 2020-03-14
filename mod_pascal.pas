{*-----------------------------------------
 *  mod_pascal,
 *  Apache 2.4 module which can execute
 *  Pascal program
 *
 *  @author Zamrony P. Juhara <zamronypj@yahoo.com>
 *------------------------------------------}
library mod_pascal;

{$MODE OBJFPC}
{$H+}

uses

    httpd24,
    apr,
    apr24,
    lib_consts,
    main_handler;

var

    pascalModule: module;{$IFDEF UNIX} public name MODULE_NAME;{$ENDIF}

exports

    pascalModule name MODULE_NAME;

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
