library aimp_lancast;

{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) FIELDS([]) PROPERTIES([])}

uses
  Windows,
  SysUtils,
  aimp_lancast_core in 'aimp_lancast_core.pas' {frmLanCast};

{$R *.res}

type

  { TWinampDSPModule }

  PWinampDSPModule = ^TWinampDSPModule;
  TWinampDSPModule = record
     Description: PAnsiChar;
     ParentWindow: HWND;
     LibInstance: HINST; // filled in by calling app
     Config: procedure (Module: PWinampDSPModule); cdecl;
     Init: function (Module: PWinampDSPModule): Integer; cdecl;  // 0 on success
     // modify waveform samples: returns number of samples to actually write
     // (typically numsamples, but no more than twice numsamples, and no less than half numsamples)
     // numsamples should always be at least 128. should, but I'm not sure
     ModifySamples: function (Module: PWinampDSPModule; Samples: Pointer; NumSamples, BPS, Channels, Freq: Integer): Integer; cdecl;
     Quit: procedure(Module: PWinampDSPModule); cdecl;
     UserData: Pointer;
  end;

  { TWinampDSPHeader }

  PWinampDSPHeader = ^TWinampDSPHeader;
  TWinampDSPHeader = record
    Version: Integer;    // DSP_HDRVER  v32 - Default support
    Description: PAnsiChar;
    GetModule: function (Index: Cardinal): PWinampDSPModule; cdecl;
    //Sf: function (Key: Integer): Integer; cdecl; in v33
  end;

const
  PluginName = 'LanCast';
var
  FHeader: TWinampDSPHeader;
  FModule: TWinampDSPModule;

  procedure winampDSPFree(Module: PWinampDSPModule); cdecl;
  begin
    FreeAndNil(Module^.UserData);
  end;

  procedure winampDSPConfig(Module: PWinampDSPModule); cdecl;
  begin
    TfrmLanCast(Module^.UserData).Show;
  end;

  function winampDSPInit(Module: PWinampDSPModule): Integer; cdecl;
  begin
    Module^.UserData := TfrmLanCast.Create(Module.ParentWindow);
    winampDSPConfig(Module);
    Result := 0;
  end;

  function winampDSPProcess(Module: PWinampDSPModule; Samples: Pointer; NumSamples, BPS, Channels, Freq: Integer): Integer; cdecl;
  begin
    TfrmLanCast(Module^.UserData).OnData(Samples, NumSamples, BPS, Channels, Freq);
    Result := NumSamples;
  end;

  function winampDSPGetModule(Index: Cardinal): PWinampDSPModule; cdecl;
  begin
    if Index = 0 then
    begin
      ZeroMemory(@FModule, SizeOf(FModule));
      FModule.Description := PluginName;
      FModule.Init := @winampDSPInit;
      FModule.Config := @winampDSPConfig;
      FModule.Quit := @winampDSPFree;
      FModule.ModifySamples := @winampDSPProcess;
      Result := @FModule;
    end
    else
      Result := nil;
  end;

  function winampDSPGetHeader2: PWinampDSPHeader; cdecl;
  begin
    FHeader.Version := 32;
    FHeader.Description := PluginName;
    FHeader.GetModule := winampDSPGetModule;
    Result := @FHeader;
  end;

exports
  winampDSPGetHeader2;
begin
end.
