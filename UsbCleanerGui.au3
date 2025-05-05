#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
;~ #AutoIt3Wrapper_Compression=4
;~ #AutoIt3Wrapper_UseUpx=y
#AutoIt3Wrapper_Run_Au3Stripper=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#pragma compile(Icon, res\UsbCleaner.ico)
#pragma compile(Out, Install\Files\UsbCleanerGui.exe)
#pragma compile(FileDescription, UsbCleaner)
#pragma compile(ProductName, UsbCleaner)
#pragma compile(ProductVersion, 0.1.14.505)
#pragma compile(FileVersion, 0.1.14.505, 0.1.14.505) ; The last parameter is optional.
#pragma compile(LegalCopyright, 2019-2022 © Tunisian Community of Computer Science Teachers)
#pragma compile(Comments,'UsbCleaner Gui')
#pragma compile(ProductContact,moez.romdhane@tarbia.tn)
#pragma compile(ProductPublisherURL, https://github.com/romoez/UsbCleaner)
#pragma compile(CompanyName, Tunisian Community of Computer Science Teachers)
#pragma compile(AutoItExecuteAllowed, False)

#include <GUIConstantsEx.au3>
#include <MsgBoxConstants.au3>
#include <ButtonConstants.au3>
#include <StaticConstants.au3>

; Constants
Global $sUsbCleanerExe = @ScriptDir & '\UsbCleaner.exe'
Global $hGUI, $cButton, $cStatus, $bExeExists = FileExists($sUsbCleanerExe)

; Color Constants
Global Const $COLOR_RED = 0xFF0000
Global Const $COLOR_GREEN = 0x009900
Global Const $COLOR_WHITE = 0xFFFFFF

CreateGUI()
UpdateInterface()
AdlibRegister("UpdateInterface", 1000) ; Auto-refresh every second

While 1
	Switch GUIGetMsg()
		Case $GUI_EVENT_CLOSE
			ExitLoop
		Case $cButton
			If Not $bExeExists Then ContinueLoop
			ToggleProtection()
	EndSwitch
WEnd

AdlibUnRegister("UpdateInterface")
GUIDelete($hGUI)
Exit

Func CreateGUI()
	$hGUI = GUICreate("UsbCleaner", 250, 130)

	; Main button
	$cButton = GUICtrlCreateCheckbox("Enable Protection", 25, 25, 200, 50, $BS_PUSHLIKE)
	GUICtrlSetState($cButton, $GUI_DISABLE)

	; Status label
	$cStatus = GUICtrlCreateLabel("", 25, 85, 200, 30, $SS_CENTER)
	GUICtrlSetFont($cStatus, 9, 600)

	GUISetState()
EndFunc   ;==>CreateGUI

Func UpdateInterface()
	Local $sButtonText, $sStatus, $iColor

	If Not $bExeExists Then
		$sStatus = "EXE INTROUVABLE!"
		$iColor = $COLOR_RED
		$sButtonText = "Cannot find UsbCleaner.exe"
		GUICtrlSetTip($cButton, "Veuillez réinstaller UsbCleaner", "Erreur", 1, 1)
	Else
		If ProcessExists("UsbCleaner.exe") Then
			$sStatus = "PROTECTION ACTIVE"
			$iColor = $COLOR_GREEN
			$sButtonText = "Disable Protection"
			GUICtrlSetTip($cButton, "")
		Else
			$sStatus = "PROTECTION INACTIVE"
			$iColor = $COLOR_RED
			$sButtonText = "Enable Protection"
			GUICtrlSetTip($cButton, "Cliquez pour activer la protection", "Protection désactivée", 1, 1)
		EndIf
	EndIf

	GUICtrlSetData($cStatus, $sStatus)
	GUICtrlSetColor($cStatus, $COLOR_WHITE)
	GUICtrlSetBkColor($cStatus, $iColor)
	GUICtrlSetData($cButton, $sButtonText)
	GUICtrlSetState($cButton, $bExeExists ? $GUI_ENABLE : $GUI_DISABLE)
EndFunc   ;==>UpdateInterface

Func ToggleProtection()
	Local $iPID

	If ProcessExists("UsbCleaner.exe") Then
		ProcessClose("UsbCleaner.exe")
		While ProcessExists("UsbCleaner.exe")
			Sleep(100) ; Sleep longer to reduce CPU usage
		WEnd
	Else
		$iPID = Run($sUsbCleanerExe)
		If $iPID = 0 Then
			MsgBox($MB_ICONERROR, "Erreur", "Impossible de démarrer USBCleaner!")
			Return
		EndIf
		Local $hTimer = TimerInit()
		While TimerDiff($hTimer) < 2000 ; Attente max 2s
			If ProcessExists("UsbCleaner.exe") Then ExitLoop
			Sleep(100)
		WEnd
	EndIf
	UpdateInterface()
EndFunc   ;==>ToggleProtection