{-----------------------------------------
   This file is part of mod_pascal,
   Apache 2.4 module which can execute
   Pascal program

   @author Zamrony P. Juhara <zamronypj@yahoo.com>
------------------------------------------}
unit instant_fpc;

interface

{$MODE OBJFPC}
{$H+}

    {------------------------
     run program source using
     InstantFPC
    -------------------------}
    function execProgram(
        const fpcBin : string;
        const cacheDir : string;
        const filename : string;
        out compileOutput : string
    ) : integer;

implementation

uses

    Classes,
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
