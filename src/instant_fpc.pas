{*-----------------------------------------
 * mod_pascal
 * Apache 2.4 module which can execute
 * Pascal program
 *
 * @link      https://github.com/zamronypj/mod_pascal
 * @copyright Copyright (c) 2020 Zamrony P. Juhara
 * @license   https://github.com/zamronypj/mod_pascal/blob/master/LICENSE (LGPL-2.1)
 *------------------------------------------}
unit instant_fpc;

interface

{$MODE OBJFPC}
{$H+}

uses

    Classes;

    {------------------------
     run program source using
     InstantFPC
    -------------------------}
    function execProgram(
        const fpcBin : string;
        const cacheDir : string;
        const filename : string;
        const cgienv : TStrings;
        out compileOutput : string
    ) : integer;

implementation

uses

    SysUtils,
    process;

const

    BUFF_SIZE = 2048;

    procedure readOutput(const proc : TProcess; const outputStr : TStream);
    var bytesRead : integer;
        buff : pointer;
    begin
        getMem(buff, BUFF_SIZE);
        try
            repeat
                bytesRead := proc.Output.read(buff^, BUFF_SIZE);
                //TODO: handle timeout when process taking too
                //much time to complete
                outputStr.writeBuffer(buff^, bytesRead);
            until bytesRead = 0;
        finally
            freeMem(buff);
        end;
    end;

    function execProgram(
        const fpcBin : string;
        const cacheDir : string;
        const filename : string;
        const cgienv : TStrings;
        out compileOutput : string
    ) : integer;
    var afpcProc : TProcess;
        outputStr : TStringStream;
    begin
        outputStr := TStringStream.create('');
        try
            afpcProc := TProcess.create(nil);
            try
                afpcProc.executable := fpcBin;
                afpcProc.parameters.add('--set-cache=' + cacheDir);
                afpcProc.parameters.add(filename);
                afpcProc.environment := cgienv;
                afpcProc.Options := afpcProc.Options + [poUsePipes];
                afpcProc.execute();
                readOutput(afpcProc, outputStr);
                compileOutput := outputStr.dataString;
                result := afpcProc.exitCode;
            finally
                afpcProc.free();
            end;
        finally
            outputStr.free();
        end;
    end;

end.
