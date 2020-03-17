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

    Classes,
    process;

const

    BUFF_SIZE = 2048;

    procedure initProgram(
        const afpcProc : TProcess;
        const fpcBin : string;
        const instantFpcBin : string;
        const cacheDir : string;
        const filename : string;
        const cgienv : TStrings
    );

    function readProgramOutput(const afpcProc : TProcess) : string;

implementation

uses

    SysUtils;

    procedure readOutput(const procOut : TStream; const outputStr : TStream);
    var bytesRead : integer;
        buff : pointer;
    begin
        getMem(buff, BUFF_SIZE);
        try
            repeat
                bytesRead := procOut.read(buff^, BUFF_SIZE);
                //TODO: handle timeout when process taking too
                //much time to complete
                outputStr.writeBuffer(buff^, bytesRead);
            until bytesRead = 0;
        finally
            freeMem(buff);
        end;
    end;

    procedure initProgram(
        const afpcProc : TProcess;
        const fpcBin : string;
        const instantFpcBin : string;
        const cacheDir : string;
        const filename : string;
        const cgienv : TStrings
    );
    begin
        afpcProc.executable := instantFpcBin;
        afpcProc.parameters.add('--compiler=' + fpcBin);
        afpcProc.parameters.add('--set-cache=' + cacheDir);
        afpcProc.parameters.add(filename);
        afpcProc.environment := cgienv;
        afpcProc.Options := afpcProc.Options + [poUsePipes];
    end;

    function readProgramOutput(const afpcProc : TProcess) : string;
    var
        outputStr : TStringStream;
    begin
        outputStr := TStringStream.create('');
        try
            readOutput(afpcProc.output, outputStr);
            result := outputStr.dataString;
        finally
            outputStr.free();
        end;
    end;

end.
