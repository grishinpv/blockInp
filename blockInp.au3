#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Version=Beta
#AutoIt3Wrapper_Icon=lock.ico
#AutoIt3Wrapper_Res_Comment=Block Input
#AutoIt3Wrapper_Res_Description=��������� ��� ��������� �����
#AutoIt3Wrapper_Res_Fileversion=1.0.6
#AutoIt3Wrapper_Res_LegalCopyright=Pavel Grishin
#AutoIt3Wrapper_Res_Language=1049
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <BlockInputEx.au3>
#Include <GDIPlus.au3>
#Include <Pop-ups.au3>
#include <Autorun.au3>



; ������ ������ ���� �������������
if Not @Compiled then
	MsgBox(16,"Error","Script in not compiled")
	exit 0
EndIf



; ������ ����������
 _ShowTrayHelp()



; ���������� ������� ��� ������ �� ���������
OnAutoItExitRegister("_Exit")



; ���������� ��������� ���� ���������
Opt("TrayMenuMode",1)
Opt("TrayOnEventMode",1)




; ������ ���� ����
$fTray_fBlockKind=TrayCreateItem("���������� ������ ����������")
TrayItemSetOnEvent(-1,"_set_fBlockKind")
TrayCreateItem("")
$fTray_AutoRunState=TrayCreateItem("���./����. ����������")
TrayItemSetOnEvent(-1,"_set_AutoRun")
TrayCreateItem("")
TrayCreateItem("�����")
TrayitemSetOnEvent(-1, "_Exit")




; ������ ���������� ���������
$path=@TempDir & "\blockInp"
$InitPath = @ScriptDir & "\lock.png"
$configPath = $path & "\blockInp_config.ini"



; �������������� ����������� ���������
_GDIPlus_Startup()



; ������������� ������� ������� Shift+ALT+F2, ��������� ������� �� ���������� (�������������)
Global $fHotKey = "+!{F2}"
HotKeySet($fHotKey,"Block")



; ���������� ������� ����������� ��������, �������������, ���� �����������
if not FileExists($path & "\lock.png") then
	DirCreate($path)
	$res=FileInstall("lock.png", $path & "\lock.png")
EndIf

Global $fBlockKind = True ; Default value show icon or not
Global $fSkipFirstRun = True	; Default value block first run or not

; ���������� ������� ����� �������� ����������, ���� ����������� - ������� � ���������� �����������
if Not FileExists($configPath) Then
	FileOpen($configPath,1)
	IniWrite($configPath,"BlockKind","fBlockKind", $fBlockKind)
	IniWrite($configPath,"HotKey","fHotKey", $fHotKey)
	IniWrite($configPath,"BlockKind","fSkipFirstRun", $fSkipFirstRun)
EndIf



; //// ���������� ���������� ���������� ////
; ���������� ������ �������� ��� ������������ ����������
Global $hImage1 = _GDIPlus_ImageLoadFromFile(@TempDir & '\blockinp\lock.png')


; ������������ ���� ����������� ��������
Global $hPopup1 = _Popup_Register()


;~ Global $Flag_IsBlocked = True
 Global $Flag_IsBlocked = False ; !!!!!!!!!!!!!!!!�� ���������, ����������� ��� ������ ���



;//////////////////////////////////////////////



; ������ ��������� ��������� �� ����� ������
_ReadSettings("BlockKind") ; True = show, False = Hide
_ReadSettings("HotKey")
ConsoleWrite (@CRLF & "BlockKind sett = " & $fBlockKind & @CRLF)



; ������������� ��������� ���� � ������������ � ��������� �����������
if $fBlockKind = "True" Then
	TrayItemSetState($fTray_fBlockKind, $TRAY_CHECKED)
ElseIf $fBlockKind="False" Then
	TrayItemSetState($fTray_fBlockKind,$TRAY_UNCHECKED)
EndIf



; ������������� ��������� ���� � ������������ � ����������� �����������
if RegRead("HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",@ScriptName)="" Then
	TrayItemSetState($fTray_AutoRunState,$TRAY_UNCHECKED)
Else
	TrayItemSetState($fTray_AutoRunState, $TRAY_CHECKED)
EndIf



; ��������� ������� ����������
Block()



; ������ ������� ������������ � ����������� �����
While 1
    Sleep(100)
WEnd




;//////////////////////////////////////////////////////////////////////
; �������
; ////////////////////////////////////////////////////////////////////



; ������� ���������� (��������)
Func Block()

	ConsoleWrite("Block -->" & @CRLF)
	ConsoleWrite(@TAB & "$Flag_IsBlocked = " & $Flag_IsBlocked & @CRLF)

	_ReadSettings("HotKey")

	; �������� ������� ����������, �������� ������� ������ ������ {LSHIFT} {RALT} {F2} �� �������
	if $Flag_IsBlocked = False Then
		if $fSkipFirstRun = True Then
			$fSkipFirstRun = False
			ConsoleWrite(@TAB & "Skip lock" & @CRLF)
			ConsoleWrite("Block <--" & @CRLF)
			Return
		Else
			ConsoleWrite(@TAB & "Do lock" & @CRLF)
		EndIf

		; ������ ���� ����������� �������� �� ����� �� �������
		if $fBlockKind = True then
			_Popup1()
		EndIf

		; ��������� ������� ������ ���������� ��� ����� ����������
		_ShowTrayHelp()

		; ���������� ������ ��� ������
		$time=TimerInit()

		; ������������� ����������
		_BlockInputEx(1,"{LSHIFT}|{RALT}|{F2}|")

		; ��������� ���������� ���� = ���������� �����������
		$Flag_IsBlocked = True

		; ���� ����������� ������ ���������� � ������� 3 ���
		while 1
			if TimerDiff($time)>3000 then
				TrayTip("","",0)
				ExitLoop
			EndIf

		; ��� ������ �������� ���������� ������ �������� � ����
		Sleep(100)
		WEnd

	ElseIf $Flag_IsBlocked = True Then

		ConsoleWrite(@TAB & "Do unlock" & @CRLF)

		; �������� ������� ���������� � ���������� 0 ��� ������ ����������
		_BlockInputEx(0)

		; �������� ��� ������ ����������
		sleep (100)

		; ������ ��������
		_Popup_Hide($hPopup1,1)

		; �������� ��� ������ ��������
		sleep(100)

		; ��������� ���������� ���� = ���������� �����
		$Flag_IsBlocked = False
	EndIf

	ConsoleWrite("Block <--" & @CRLF)
	ConsoleWrite(@TAB & "$Flag_IsBlocked = " & $Flag_IsBlocked & @CRLF)
EndFunc



; ������� ��������� ��������
Func _Popup1()

	Local $hGraphic, $hArea, $hBitmap, $hFamily, $hFont, $hFormat, $hBrush, $tLayout, $aData, $ix, $iy
	Local $Text = StringFormat('%01d:%02d', @HOUR, @MIN)

	; Draw current time (xx:xx) on "Image1.png" and create bitmap
	$ix = _GDIPlus_ImageGetWidth ($hImage1)
	$iy=_GDIPlus_ImageGetHeight ($hImage1)

	$hArea = _GDIPlus_BitmapCloneArea($hImage1, 0, 0, $ix, $iy, $GDIP_PXF32ARGB)
;~ 	$hGraphic = _GDIPlus_ImageGetGraphicsContext($hArea)
;~ 	$hFamily = _GDIPlus_FontFamilyCreate('Tahoma')
;~ 	$hFont = _GDIPlus_FontCreate($hFamily, 38, 0, 2)
;~ 	$tLayout = _GDIPlus_RectFCreate(0, 0, 0, 0)
;~ 	$hFormat = _GDIPlus_StringFormatCreate()
;~ 	$hBrush = _GDIPlus_BrushCreateSolid(0xC0FFFFFF)
;	_GDIPlus_GraphicsSetTextRenderingHint($hGraphic, 3)
;~ 	$aData = _GDIPlus_GraphicsMeasureString($hGraphic, $Text, $hFont, $tLayout, $hFormat)
;~ 	$tLayout = $aData[0]
;~ 	DllStructSetData($tLayout, 1, (133 - DllStructGetData($tLayout, 3)) / 2)
;~ 	DllStructSetData($tLayout, 2, (133 - DllStructGetData($tLayout, 4)) / 2)
;~ 	_GDIPlus_GraphicsDrawStringEx($hGraphic, $Text, $hFont, $aData[0], $hFormat, $hBrush)
	$hBitmap = _GDIPlus_BitmapCreateHBITMAPFromBitmap($hArea)
;~ 	_GDIPlus_GraphicsDispose($hGraphic)
;~ 	_GDIPlus_StringFormatDispose($hFormat)
;~ 	_GDIPlus_FontFamilyDispose($hFamily)
;~ 	_GDIPlus_FontDispose($hFont)
;~ 	_GDIPlus_BrushDispose($hBrush)
	_GDIPlus_ImageDispose($hArea)

	;MsgBox(0,"",$hBitmap)
	; Show pop-up image
	_Popup_Show($hPopup1, $hBitmap, 1, -1, -1, -1, 0)

EndFunc   ;==>_Popup1


; ������� ������ �� ���������
Func _Exit()

	; ��������� ����������� ���������
	_GDIPlus_Shutdown()

	; �������� ��� ���������� ������������ ����������
	sleep(100)

	; ����� True
	Exit 0
EndFunc



; ������� ������ ���������� ��� ����� ����������
Func _ShowTrayHelp()

	; ���������� ���������� ��� ����� ����������
	TrayTip("BlockInput", "����� ���������/����� ���������� ������������ ������� ��������� ������:" & @CRLF & "{LEFT SHIFT} + (RIGHT ALT} + {F2}",3)

EndFunc



; ������� ������ �������� �� �������� ������ ini �����
Func _ReadSettings($fIniSectionName)
	Select
		Case $fIniSectionName = "BlockKind"
			$fBlockKind=IniRead($configPath,$fIniSectionName,"fBlockKind","")
			if $fBlockKind="" Then MsgBox(16, "Error", "��������� ������ �� �����")
			$fSkipFirstRunTmp = IniRead($configPath,$fIniSectionName,"fSkipFirstRun","")
			if $fSkipFirstRunTmp = "" Then
				ConsoleWrite("Use default SkipFirstRun = True" & @CRLF)
			Else
				ConsoleWrite("Set SkipFirstRun = " & $fSkipFirstRunTmp & @CRLF)
				$fSkipFirstRun = $fSkipFirstRunTmp
			EndIf
		Case $fIniSectionName = "HotKey"
			$fHotKeyTmp = IniRead($configPath,$fIniSectionName,"$fHotKey","")
			if $fHotKeyTmp="" Then
				ConsoleWrite("Use default hotkey" & @CRLF)
			Else
				$fHotKey = $fHotKeyTmp
			EndIf
			ConsoleWrite("Set hotkey = " & $fHotKey & @CRLF)
			HotKeySet($fHotKey,"Block")
	EndSelect
EndFunc



; ������� ������������ ���� ���������� (� ������������ �������� ��� ���)
Func _set_fBlockKind()
	ConsoleWrite(@CRLF & "Tray fBlocKind Func")
	$fTrayVal = TrayItemGetState(@TRAY_ID)
	ConsoleWrite(@CRLF & "TrayItemGetState(@TRAY_ID) = " & $fTrayVal)
	if $fTrayVal =  $TRAY_CHECKED+$TRAY_ENABLE Then
		IniWrite($configPath,"BlockKind", "fBlockKind", "True")
		$fBlockKind = True
		ConsoleWrite (@crlf & "$fBlockKind = True")
	ElseIf $fTrayVal = $TRAY_UNCHECKED+$TRAY_ENABLE Then
		ConsoleWrite (@crlf & "$fBlockKind = False")
		IniWrite($configPath,"BlockKind", "fBlockKind", "False")
		$fBlockKind = False
	EndIf
EndFunc



; ������� ������������ �����������
Func _set_AutoRun()
	$fTrayVal = TrayItemGetState(@TRAY_ID)
	if $fTrayVal =  $TRAY_CHECKED+$TRAY_ENABLE Then
		_AutoRun(@ScriptFullPath,1)
		ConsoleWrite (@crlf & "AutoRun= True")
	ElseIf $fTrayVal = $TRAY_UNCHECKED+$TRAY_ENABLE Then
		_AutoRun(@ScriptFullPath,0)
		ConsoleWrite (@crlf & "AutoRun = False")
	EndIf
EndFunc