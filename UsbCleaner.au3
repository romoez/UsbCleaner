#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
;~ #AutoIt3Wrapper_Compression=4
;~ #AutoIt3Wrapper_UseUpx=y
#AutoIt3Wrapper_Run_Au3Stripper=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#pragma compile(Icon, res\UsbCleaner.ico)
#pragma compile(Out, Install\Files\UsbCleaner.exe)
#pragma compile(FileDescription, UsbCleaner)
#pragma compile(ProductName, UsbCleaner)
#pragma compile(ProductVersion, 0.1.9.519)
#pragma compile(FileVersion, 0.1.9.519, 0.1.9.519) ; The last parameter is optional.
#pragma compile(LegalCopyright, 2019-2022 © La Communauté Tunisienne des Enseignants d'Informatique)
#pragma compile(Comments,'UsbCleaner')
#pragma compile(ProductContact,moez.romdhane@tarbia.tn)
#pragma compile(ProductPublisherURL, https://github.com/romoez/UsbCleaner)
#pragma compile(CompanyName, La Communauté Tunisienne des Enseignants d'Informatique)
#pragma compile(AutoItExecuteAllowed, False)

;~ https://www.autoitscript.com/forum/topic/42402-detecting-usb-drive-insertion/
;~ https://www.autoitscript.com/forum/topic/105016-usb-device-detection-media-device/
;~ #include <Crypt.au3>
#include <WinAPIFiles.au3>
#include <File.au3>

Dim $DBT_DEVICEARRIVAL = "0x00008000"
Dim $DBT_DEVICECOMPLETEREMOVAL = "0x00008004"
Dim $USB_ATTENTION = "0x00000007"
Dim $WM_DEVICECHANGE = 0x0219
Dim $Drives
Dim $Drive_Type = "ALL"
Dim $MyDrive = "STUFF"
Global Const $SUSPICIOUS_FILES_FOLDER = "\SuspiciousFiles\"

_KillOtherScript()

UpdateDrives()
GUICreate("")
GUIRegisterMsg($WM_DEVICECHANGE, "DeviceChange")

Func DeviceChange($hWndGUI, $MsgID, $WParam, $LParam)
	Switch $WParam
		Case $DBT_DEVICECOMPLETEREMOVAL
			UpdateDrives()
		Case $DBT_DEVICEARRIVAL
			$New = FindNewDrive()
			If _WinAPI_IsWritable($New) Then
				$aFiles = _FileListToArray($New, "*", Default, True)
				_CleanUp($aFiles)

				Run("explorer.exe /e, " & $New)
			EndIf
			UpdateDrives()
	EndSwitch
EndFunc   ;==>DeviceChange

Func FindNewDrive()
	$Temp = DriveGetDrive("REMOVABLE")
	If IsArray($Temp) Then
		For $i = 1 To $Temp[0]
			$Old = False
			For $j = 1 To $Drives[0]
				If $Drives[$j] == $Temp[$i] Then $Old = True
			Next
			If $Old == False Then Return $Temp[$i]
		Next
	EndIf
EndFunc   ;==>FindNewDrive

Func UpdateDrives()
	$Drives = DriveGetDrive($Drive_Type)
EndFunc   ;==>UpdateDrives

Func _CleanUp(ByRef $aFiles)
	Local $sHashFile = ""
	If IsArray($aFiles) Then
		Local $sDrive = "", $sDir = "", $sFileName = "", $sExtension = ""
		ProgressOn("UsbCleaner", "Scan du lecteur """ & StringLeft($aFiles[1], 3) & """", "[0%] Initialisation...", Default, Default)
		For $i = 1 To $aFiles[0]
			ProgressSet(Round(($i - 1) / $aFiles[0] * 100), "[" & Round(($i - 1) / $aFiles[0] * 100) & "%] " & $aFiles[$i])
			FileSetAttrib($aFiles[$i], "-RASH")
			$sExtension = ""
			$sFileName = ""
			_PathSplit($aFiles[$i], $sDrive, $sDir, $sFileName, $sExtension)
			If FileGetAttrib($aFiles[$i]) = 'D' Then ContinueLoop
			If $sFileName & $sExtension = "autorun.inf" Or $sExtension = ".lnk" Or $sExtension = ".pif" Or $sExtension = ".vbs" Or $sExtension = ".vbe" Or $sExtension = ".wsf" Then
				FileMove($aFiles[$i], $sDrive & $SUSPICIOUS_FILES_FOLDER & $sFileName & $sExtension, 9)
			ElseIf $sExtension = ".exe" Then
				$iFileSize = FileGetSize($aFiles[$i])
				If ($iFileSize >= 512000) Then ContinueLoop
				FileMove($aFiles[$i], $sDrive & $SUSPICIOUS_FILES_FOLDER & $sFileName & $sExtension, 9)
			EndIf
		Next
		$aFiles = 0
		_SetIconToSuspiciousFilesFolder($sDrive)
		ProgressOff()
	EndIf

EndFunc   ;==>_CleanUp

Func _SetIconToSuspiciousFilesFolder($sDrive)
	If Not FileExists($sDrive & $SUSPICIOUS_FILES_FOLDER) Then Return
	FileInstall(".\res\SuspiciousFilesFolder.ico", $sDrive & $SUSPICIOUS_FILES_FOLDER)

	If FileExists($sDrive & $SUSPICIOUS_FILES_FOLDER & 'desktop.ini') Then
		FileSetAttrib($sDrive & $SUSPICIOUS_FILES_FOLDER & 'desktop.ini', "-RASH")
	EndIf
	$hFile = FileOpen($sDrive & $SUSPICIOUS_FILES_FOLDER & 'desktop.ini', 2 + 256)
	If $hFile = -1 Then
		Return
	EndIf
	FileWrite($hFile, "[.ShellClassInfo]" & @CRLF & "IconFile=SuspiciousFilesFolder.ico")
	FileWrite($hFile, @CRLF & "IconResource=SuspiciousFilesFolder.ico")
	FileClose($hFile)

	FileSetAttrib($sDrive & $SUSPICIOUS_FILES_FOLDER, "+S")
	FileSetAttrib($sDrive & $SUSPICIOUS_FILES_FOLDER & 'desktop.ini', '+SH')
	FileSetAttrib($sDrive & $SUSPICIOUS_FILES_FOLDER & 'SuspiciousFilesFolder.ico', "+SH")

	$hFile = FileOpen($sDrive & $SUSPICIOUS_FILES_FOLDER & '___created_by_UsbCleaner.txt', 2 + 256)
	If $hFile = -1 Then
		Return
	EndIf
	FileWrite($hFile, "UsbCleaner URL:" & @CRLF)
	FileWrite($hFile, "https://github.com/romoez/UsbCleaner")
	FileClose($hFile)
EndFunc   ;==>_SetIconToSuspiciousFilesFolder

Func _KillOtherScript()
	Local $list = ProcessList()
	For $i = 1 To $list[0][0]
		If $list[$i][0] = @ScriptName Then
			If $list[$i][1] <> @AutoItPID Then
				; Kill process
				$r = ProcessClose($list[$i][1])
			EndIf
		EndIf
	Next
EndFunc   ;==>_KillOtherScript

While 1
	$GuiMsg = GUIGetMsg()
WEnd


