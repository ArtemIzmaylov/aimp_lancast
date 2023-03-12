unit aimp_lancast_core;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  // System
  System.Classes,
  System.SysUtils,
  System.Variants,
  // ACL
  ACL.Classes.StringList,
  ACL.Classes.Timer,
  ACL.UI.Controls.BaseControls,
  ACL.UI.Controls.Buttons,
  ACL.UI.Controls.Labels,
  ACL.UI.Controls.Panel,
  ACL.UI.Forms,
  ACL.Utils.Common,
  // Vcl
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs;

{$REGION 'BASS API'}
const
  BASS_WMA_ENCODE_SCRIPT = $20000; // set script (mid-stream tags) in the WMA encoding
  BASS_WMA_TAG_UNICODE   = 1;

type
  HWMENCODE = DWORD;		// WMA encoding handle
  CLIENTCONNECTPROC = procedure(handle: HWMENCODE; connect: BOOL; ip: PAnsiChar; user: Pointer); stdcall;
  TBASS_WMA_EncodeClose = function(handle:HWMENCODE): BOOL; stdcall;
  TBASS_WMA_EncodeGetPort = function(handle:HWMENCODE): DWORD; stdcall;
  TBASS_WMA_EncodeOpenNetwork = function (freq, chans, flags, bitrate, port, clients: DWORD): HWMENCODE; stdcall;
  TBASS_WMA_EncodeSetNotify = function(handle: HWMENCODE; proc: CLIENTCONNECTPROC; user: Pointer): BOOL; stdcall;
  TBASS_WMA_EncodeSetTag = function(handle:HWMENCODE; tag,text:PChar; form:DWORD): BOOL; stdcall;
  TBASS_WMA_EncodeWrite = function(handle:HWMENCODE; buffer:Pointer; length:DWORD): BOOL; stdcall;
{$ENDREGION}

type

  { TfrmLanCast }

  TfrmLanCast = class(TACLForm)
    btnStart: TACLButton;
    btnStop: TACLButton;
    lbHost: TACLLabel;
    lbListeners: TACLLabel;
    lbState: TACLValidationLabel;
    pnlState: TACLPanel;
    tmUpdateState: TACLTimer;

    procedure btnStartClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure tmUpdateStateTimer(Sender: TObject);
  strict private
  {$REGION 'BASSWMA'}
    FBASSEncodeClose: TBASS_WMA_EncodeClose;
    FBASSEncodeGetPort: TBASS_WMA_EncodeGetPort;
    FBASSEncodeOpenNetwork: TBASS_WMA_EncodeOpenNetwork;
    FBASSEncodeSetNotify: TBASS_WMA_EncodeSetNotify;
    FBASSEncodeSetTag: TBASS_WMA_EncodeSetTag;
    FBASSEncodeWrite: TBASS_WMA_EncodeWrite;
    FBASSReady: Boolean;
    FLibHandle: THandle;
    class procedure OnClientProc(handle: HWMENCODE; connect: BOOL; ip: PAnsiChar; user: Pointer); stdcall; static;
  {$ENDREGION}
  strict private type
  {$REGION 'Internal Types'}
    TCastState = (csStopped, csStarted, csEncoding, csError);

    TStreamInfo = record
      Bits: Integer;
      Freq: Integer;
      NumChannels: Integer;
    end;
  {$ENDREGION}
  strict private const
    Bitrate = 160000; // todo: allow to choose it
    MaxClients = 50;
  strict private
    FAppWndHandle: THandle;
    FCastState: TCastState;
    FEncoder: HWMENCODE;
    FEncoderPort: Integer;
    FListeners: Integer;
    FSongTitle: UnicodeString;
    FStreamInfo: TStreamInfo;

    procedure Start(Freq, Channels, Bits: Integer);
    procedure Stop;
  protected
    procedure UpdateState;
    procedure UpdateStreamTitle;
  public
    constructor Create(AAppWndHandle: THandle); reintroduce;
    procedure OnData(Samples: Pointer; NumSamples, Bits, Channels, Freq: Integer);
  end;

implementation

{$R *.dfm}

{ TfrmLanCast }

constructor TfrmLanCast.Create(AAppWndHandle: THandle);
begin
  inherited Create(nil);
  FBASSReady := True;
  FAppWndHandle := AAppWndHandle;
  FLibHandle := GetModuleHandle('bass_wma.dll');
  if FLibHandle = 0 then
    FLibHandle := acLoadLibrary('bass_wma.dll');
  @FBASSEncodeClose := acGetProcAddress(FLibHandle, 'BASS_WMA_EncodeClose', FBASSReady);
  @FBASSEncodeOpenNetwork := acGetProcAddress(FLibHandle, 'BASS_WMA_EncodeOpenNetwork', FBASSReady);
  @FBASSEncodeGetPort := acGetProcAddress(FLibHandle, 'BASS_WMA_EncodeGetPort', FBASSReady);
  @FBASSEncodeSetNotify := acGetProcAddress(FLibHandle, 'BASS_WMA_EncodeSetNotify', FBASSReady);
  @FBASSEncodeSetTag := acGetProcAddress(FLibHandle, 'BASS_WMA_EncodeSetTag', FBASSReady);
  @FBASSEncodeWrite := acGetProcAddress(FLibHandle, 'BASS_WMA_EncodeWrite', FBASSReady);
  UpdateState;
end;

class procedure TfrmLanCast.OnClientProc(handle: HWMENCODE; connect: BOOL; ip: PAnsiChar; user: Pointer);
begin
  InterlockedIncrement(TfrmLanCast(user).FListeners);
end;

procedure TfrmLanCast.OnData(Samples: Pointer; NumSamples, Bits, Channels, Freq: Integer);
begin
  if FCastState = TCastState.csStopped then
    Exit;
  if FCastState = TCastState.csStarted then
    Start(Freq, Channels, Bits);
  if FCastState = TCastState.csEncoding then
  begin
    if (FStreamInfo.Bits <> Bits) or (FStreamInfo.Freq <> Freq) or (FStreamInfo.NumChannels <> Channels) then
    begin
      Stop;
      Start(Freq, Channels, Bits);
    end;
  end;
  if FCastState = TCastState.csEncoding then
    FBASSEncodeWrite(FEncoder, Samples, NumSamples * Channels * Bits div 8);
end;

procedure TfrmLanCast.Start(Freq, Channels, Bits: Integer);
begin
  if FBASSReady then
  begin
    FStreamInfo.Bits := Bits;
    FStreamInfo.Freq := Freq;
    FStreamInfo.NumChannels := Channels;
    if Bits = 16 then
      FEncoder := FBASSEncodeOpenNetwork(Freq, Channels, BASS_WMA_ENCODE_SCRIPT, Bitrate, 0, MaxClients);
    if FEncoder <> 0 then
    begin
      FBASSEncodeSetNotify(FEncoder, OnClientProc, Self);
      FBASSEncodeSetTag(FEncoder, 'Title', 'AIMP LanCast', BASS_WMA_TAG_UNICODE);
      FEncoderPort := FBASSEncodeGetPort(FEncoder);
      FCastState := TCastState.csEncoding;
    end
    else
      FCastState := TCastState.csError;
  end;
end;

procedure TfrmLanCast.Stop;
begin
  if FBassReady then
  try
    FBASSEncodeClose(FEncoder);
  finally
    FCastState := TCastState.csStopped;
    FListeners := 0;
    FEncoder := 0;
  end;
end;

procedure TfrmLanCast.UpdateState;
begin
  btnStart.Visible := FCastState = TCastState.csStopped;
  btnStop.Visible := FCastState <> TCastState.csStopped;

  if not FBASSReady then
    lbState.SetCaption('Error: BASS_WMA was not loaded', vliError)
  else if (FCastState = csError) and (FStreamInfo.Bits <> 16) then
    lbState.SetCaption('Error: only 16 bits depth is supported', vliError)
  else if (FCastState = csError) then
    lbState.SetCaption('Error: failed to initialize the Encoder', vliError)
  else if (FCastState = csStarted) then
    lbState.SetCaption('Waiting for data...', vliWarning)
  else if (FCastState = csEncoding) then
    lbState.SetCaption('On Air', vliSuccess)
  else
    lbState.SetCaption('Ready to start', vliInformation);

  lbListeners.Caption := Format('Listeners: %d / %d', [FListeners, MaxClients]);
  lbListeners.Visible := FCastState = csEncoding;
  lbHost.Caption := 'mms://<host-ip>:' + IntToStr(FEncoderPort);
  lbHost.Visible := FCastState = csEncoding;

  UpdateStreamTitle;
end;

procedure TfrmLanCast.UpdateStreamTitle;
begin
  if FCastState = csEncoding then
  begin
    FSongTitle := acGetWindowText(FAppWndHandle);
    FBASSEncodeSetTag(FEncoder, 'Caption', PWideChar(FSongTitle), BASS_WMA_TAG_UNICODE);
  end;
end;

procedure TfrmLanCast.btnStartClick(Sender: TObject);
begin
  FCastState := TCastState.csStarted;
  UpdateState;
end;

procedure TfrmLanCast.btnStopClick(Sender: TObject);
begin
  Stop;
  UpdateState;
end;

procedure TfrmLanCast.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caNone;
end;

procedure TfrmLanCast.tmUpdateStateTimer(Sender: TObject);
begin
  UpdateState;
end;

end.
