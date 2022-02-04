

Func _AutoRun($ftoautorun,$fState=1)
$RegRunKey = "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
if $fState=1 Then
	$fTemp=RegRead($RegRunKey,@ScriptName)
	if $fTemp<>$ftoautorun or @error Then
		RegWrite($RegRunKey, @ScriptName, "REG_SZ", $ftoautorun)
		if @error Then
			MsgBox(16,"Error","Can not write registry")
			Exit 0
		EndIf
	EndIf
	Return True
ElseIf $fState=0 Then
	RegDelete($RegRunKey,@ScriptName)
	Return True
EndIf
EndFunc
