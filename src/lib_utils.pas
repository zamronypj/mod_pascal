{*-----------------------------------------
 * mod_pascal
 * Apache 2.4 module which can execute
 * Pascal program
 *
 * @link      https://github.com/zamronypj/mod_pascal
 * @copyright Copyright (c) 2020 Zamrony P. Juhara
 * @license   https://github.com/zamronypj/mod_pascal/blob/master/LICENSE (LGPL-2.1)
 *------------------------------------------}
unit lib_utils;

interface

{$MODE OBJFPC}
{$H+}

uses

    sysutils;

    function asString(avalue : pchar) : string;

implementation

    function asString(avalue : pchar) : string;
    begin
        if avalue <> nil then
        begin
            result := strpas(avalue);
        end else
        begin
            result := '';
        end;
    end;
end.
