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
#pragma compile(ProductVersion, 0.1.9.519)
#pragma compile(FileVersion, 0.1.9.519, 0.1.9.519) ; The last parameter is optional.
#pragma compile(LegalCopyright, 2019-2022 © La Communauté Tunisienne des Enseignants d'Informatique)
#pragma compile(Comments,'UsbCleaner Gui')
#pragma compile(ProductContact,moez.romdhane@tarbia.tn)
#pragma compile(ProductPublisherURL, https://github.com/romoez/UsbCleaner)
#pragma compile(CompanyName, La Communauté Tunisienne des Enseignants d'Informatique)
#pragma compile(AutoItExecuteAllowed, False)

#include <GUIConstantsEx.au3>
#include <MsgBoxConstants.au3>
#include <ButtonConstants.au3>

$hGUI = GUICreate("UsbCleaner", 250, 100)

$cButton = GUICtrlCreateCheckbox("Enable Protection", 25, 25, 200, 50, $BS_PUSHLIKE)
GUICtrlSetTip($cButton, " ", "Click to enable protection", 1,1)

$sUsbCleanerExe = @ScriptDir & '\UsbCleaner.exe'
if not FileExists($sUsbCleanerExe) Then
	GUICtrlSetData($cButton, "Cannot find UsbCleaner.exe")
	GUICtrlSetTip($cButton, "Please reinstall UsbCleaner to solve the problem.", "Cannot find UsbCleaner.exe", 1,1)
	GUICtrlSetState($cButton, $GUI_DISABLE)
EndIf
If ProcessExists("UsbCleaner.exe") Then
	GUICtrlSetData($cButton, "Disable Protection")
	GUICtrlSetTip($cButton, "This will temporarily disable protection until computer restarted", "Click to disable protection", 1,1)
EndIf


GUISetState()

While 1
    Switch GUIGetMsg()
        Case $GUI_EVENT_CLOSE
            Exit
        Case $cButton
            Switch GUICtrlRead($cButton)
                Case $GUI_CHECKED
                    $iResponse = MsgBox($MB_TASKMODAL + $MB_YESNO, "UsbCleaner", "Are you sure you want to disable protection?")
					if $iResponse = 6 Then
						ProcessClose("UsbCleaner.exe")
						GUICtrlSetData($cButton, "Enable Protection")
						GUICtrlSetTip($cButton, " ", "Click to enable protection", 1,1)
					EndIf
                Case Else
                    $iResponse = MsgBox($MB_TASKMODAL + $MB_YESNO, "UsbCleaner", "Are you sure you want to enable protection?")
;~ 					ConsoleWrite($iResponse & @CRLF)
					if $iResponse = 6 Then
						run($sUsbCleanerExe)
						GUICtrlSetData($cButton, "Disable Protection")
						GUICtrlSetTip($cButton, "This will temporarily disable protection until computer restarted", "Click to disable protection", 1,1)
					EndIf
            EndSwitch
    EndSwitch
WEnd