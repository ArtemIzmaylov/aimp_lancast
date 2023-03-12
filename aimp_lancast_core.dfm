object frmLanCast: TfrmLanCast
  Left = 0
  Top = 0
  BorderStyle = bsToolWindow
  Caption = 'AIMP LanCast'
  ClientHeight = 56
  ClientWidth = 598
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  FormStyle = fsStayOnTop
  OnClose = FormClose
  TextHeight = 15
  object btnStart: TACLButton
    AlignWithMargins = True
    Left = 499
    Top = 16
    Width = 96
    Height = 24
    Margins.Bottom = 16
    Margins.Top = 16
    Align = alRight
    TabOrder = 0
    OnClick = btnStartClick
    Caption = 'Start'
    ExplicitTop = 3
    ExplicitHeight = 50
  end
  object btnStop: TACLButton
    AlignWithMargins = True
    Left = 397
    Top = 16
    Width = 96
    Height = 24
    Margins.Bottom = 16
    Margins.Top = 16
    Align = alRight
    TabOrder = 1
    OnClick = btnStopClick
    Caption = 'Stop'
    ExplicitLeft = 354
    ExplicitTop = 15
    ExplicitHeight = 32
  end
  object pnlState: TACLPanel
    AlignWithMargins = True
    Left = 3
    Top = 3
    Width = 388
    Height = 50
    Align = alClient
    TabOrder = 2
    Borders = []
    ExplicitTop = -2
    ExplicitWidth = 368
    ExplicitHeight = 58
    object lbState: TACLValidationLabel
      AlignWithMargins = True
      Left = 3
      Top = 3
      Width = 382
      Height = 16
      Align = alTop
      Style.WordWrap = True
      Icon = vliInformation
      ExplicitTop = 0
      ExplicitWidth = 368
    end
    object lbHost: TACLLabel
      AlignWithMargins = True
      Left = 24
      Top = 22
      Width = 361
      Height = 12
      Margins.Bottom = 0
      Margins.Left = 24
      Margins.Top = 0
      Align = alTop
      Enabled = False
      AutoSize = True
      Caption = '1'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -10
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      ExplicitTop = 34
      ExplicitWidth = 341
    end
    object lbListeners: TACLLabel
      AlignWithMargins = True
      Left = 24
      Top = 34
      Width = 361
      Height = 12
      Margins.Bottom = 0
      Margins.Left = 24
      Margins.Top = 0
      Align = alTop
      Enabled = False
      AutoSize = True
      Caption = '1'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -10
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      ExplicitWidth = 341
    end
  end
  object tmUpdateState: TACLTimer
    OnTimer = tmUpdateStateTimer
    Left = 552
    Top = 64
  end
end
