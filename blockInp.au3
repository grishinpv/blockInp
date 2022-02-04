#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Version=Beta
#AutoIt3Wrapper_Icon=lock.ico
#AutoIt3Wrapper_Res_Comment=Block Input
#AutoIt3Wrapper_Res_Description=Программа бля бокировки ввода
#AutoIt3Wrapper_Res_Fileversion=1.0.6
#AutoIt3Wrapper_Res_LegalCopyright=Pavel Grishin
#AutoIt3Wrapper_Res_Language=1049
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <BlockInputEx.au3>
#Include <GDIPlus.au3>
#Include <Pop-ups.au3>
#include <Autorun.au3>



; Скрипт должен быть скомпилирован
if Not @Compiled then
	MsgBox(16,"Error","Script in not compiled")
	exit 0
EndIf



; Первое знакомство
 _ShowTrayHelp()



; Определяем функцию при выходе из программы
OnAutoItExitRegister("_Exit")



; Определяем поведение трея программы
Opt("TrayMenuMode",1)
Opt("TrayOnEventMode",1)




; Задаем меню трей
$fTray_fBlockKind=TrayCreateItem("Отображать значок блокировки")
TrayItemSetOnEvent(-1,"_set_fBlockKind")
TrayCreateItem("")
$fTray_AutoRunState=TrayCreateItem("Вкл./Выкл. Автозапуск")
TrayItemSetOnEvent(-1,"_set_AutoRun")
TrayCreateItem("")
TrayCreateItem("Выход")
TrayitemSetOnEvent(-1, "_Exit")




; Задаем переменные окружения
$path=@TempDir & "\blockInp"
$InitPath = @ScriptDir & "\lock.png"
$configPath = $path & "\blockInp_config.ini"



; Инициализируем графический интерфейс
_GDIPlus_Startup()



; Устанавливаем горячую клавишу Shift+ALT+F2, выполняем функцию по комбинации (разблокировка)
Global $fHotKey = "+!{F2}"
HotKeySet($fHotKey,"Block")



; Определяем наличие всплывающей картинки, устанавливаем, если отсутсвтует
if not FileExists($path & "\lock.png") then
	DirCreate($path)
	$res=FileInstall("lock.png", $path & "\lock.png")
EndIf

Global $fBlockKind = True ; Default value show icon or not
Global $fSkipFirstRun = True	; Default value block first run or not

; Определяем наличие файла настроек блокировки, если отсутствует - создаем с дефолтными настройками
if Not FileExists($configPath) Then
	FileOpen($configPath,1)
	IniWrite($configPath,"BlockKind","fBlockKind", $fBlockKind)
	IniWrite($configPath,"HotKey","fHotKey", $fHotKey)
	IniWrite($configPath,"BlockKind","fSkipFirstRun", $fSkipFirstRun)
EndIf



; //// Определяем глобальные переменные ////
; Инициируем объект картинки для графического интерфейса
Global $hImage1 = _GDIPlus_ImageLoadFromFile(@TempDir & '\blockinp\lock.png')


; Регистрируем окно всплывающей картинки
Global $hPopup1 = _Popup_Register()


;~ Global $Flag_IsBlocked = True
 Global $Flag_IsBlocked = False ; !!!!!!!!!!!!!!!!По умолчанию, блокируется при старте Апп



;//////////////////////////////////////////////



; Читаем настройки программы по имени секции
_ReadSettings("BlockKind") ; True = show, False = Hide
_ReadSettings("HotKey")
ConsoleWrite (@CRLF & "BlockKind sett = " & $fBlockKind & @CRLF)



; Устанавливаем параметры трея в соответсвтии с прчтеными настройками
if $fBlockKind = "True" Then
	TrayItemSetState($fTray_fBlockKind, $TRAY_CHECKED)
ElseIf $fBlockKind="False" Then
	TrayItemSetState($fTray_fBlockKind,$TRAY_UNCHECKED)
EndIf



; Устанавливаем параметры трея в соответсвтии с настройками автозапуска
if RegRead("HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",@ScriptName)="" Then
	TrayItemSetState($fTray_AutoRunState,$TRAY_UNCHECKED)
Else
	TrayItemSetState($fTray_AutoRunState, $TRAY_CHECKED)
EndIf



; Выполняем функцию блокировки
Block()



; Ождаем реакции пользователя в бесконечном цикле
While 1
    Sleep(100)
WEnd




;//////////////////////////////////////////////////////////////////////
; Функции
; ////////////////////////////////////////////////////////////////////



; Функция блокировки (основная)
Func Block()

	ConsoleWrite("Block -->" & @CRLF)
	ConsoleWrite(@TAB & "$Flag_IsBlocked = " & $Flag_IsBlocked & @CRLF)

	_ReadSettings("HotKey")

	; Вызываем функцию блокировки, разрешая нажатие только клавиш {LSHIFT} {RALT} {F2} по условию
	if $Flag_IsBlocked = False Then
		if $fSkipFirstRun = True Then
			$fSkipFirstRun = False
			ConsoleWrite(@TAB & "Skip lock" & @CRLF)
			ConsoleWrite("Block <--" & @CRLF)
			Return
		Else
			ConsoleWrite(@TAB & "Do lock" & @CRLF)
		EndIf

		; Выводи окно всплывающей картинки на экран по условию
		if $fBlockKind = True then
			_Popup1()
		EndIf

		; Выполняем функцию показа информации как снять блокировку
		_ShowTrayHelp()

		; Инициируем таймер для балуна
		$time=TimerInit()

		; Устанавливаем блокировку
		_BlockInputEx(1,"{LSHIFT}|{RALT}|{F2}|")

		; Объявляем глобальный флаг = Блокировка установлена
		$Flag_IsBlocked = True

		; Цикл отображения балуна информации в течении 3 сек
		while 1
			if TimerDiff($time)>3000 then
				TrayTip("","",0)
				ExitLoop
			EndIf

		; для снятия загрузки процессора вносим задержку в цикл
		Sleep(100)
		WEnd

	ElseIf $Flag_IsBlocked = True Then

		ConsoleWrite(@TAB & "Do unlock" & @CRLF)

		; Вызываем функицю блокировки с параметром 0 для снятия блокировки
		_BlockInputEx(0)

		; Задержка для снятия блокировки
		sleep (100)

		; Прячем картинку
		_Popup_Hide($hPopup1,1)

		; Задержка для снятия картинки
		sleep(100)

		; Объявляем глобальный флаг = блокировка снята
		$Flag_IsBlocked = False
	EndIf

	ConsoleWrite("Block <--" & @CRLF)
	ConsoleWrite(@TAB & "$Flag_IsBlocked = " & $Flag_IsBlocked & @CRLF)
EndFunc



; Функция отрисовки картинки
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


; Функция выхода из программы
Func _Exit()

	; Отключаем графический интерфейс
	_GDIPlus_Shutdown()

	; Задержка для отключения графического интерфейса
	sleep(100)

	; Выход True
	Exit 0
EndFunc



; Функция показа информации как снять блокировку
Func _ShowTrayHelp()

	; Показываем информацию как снять блокировку
	TrayTip("BlockInput", "Чтобы установит/снять блокировку одновременно нажмите сочетание клавиш:" & @CRLF & "{LEFT SHIFT} + (RIGHT ALT} + {F2}",3)

EndFunc



; Функция чтения настроек по заданной секции ini файла
Func _ReadSettings($fIniSectionName)
	Select
		Case $fIniSectionName = "BlockKind"
			$fBlockKind=IniRead($configPath,$fIniSectionName,"fBlockKind","")
			if $fBlockKind="" Then MsgBox(16, "Error", "Настройки заданы не верно")
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



; Функция переключения типа блокировки (с отображением картинки или без)
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



; Функиця переключения автозапуска
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