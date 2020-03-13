unit instant_fpc;

interface

{$MODE OBJFPC}
{$H+}

    {------------------------
     Compile program source using
     InstantFPC
    -------------------------}
    function compileProgram(const filename : string; out compileOutput : string) : integer;

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

    function compileProgram(
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
                afpcProc.executable := '/usr/local/bin/instantfpc';
                afpcProc.environment.add('INSTANTFPCCACHE=/home/zamroni/.cache/instantfpc');
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
