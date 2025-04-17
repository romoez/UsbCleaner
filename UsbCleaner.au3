#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
;~ #AutoIt3Wrapper_Compression=4
;~ #AutoIt3Wrapper_UseUpx=y
#AutoIt3Wrapper_Run_Au3Stripper=y
#AutoIt3Wrapper_Res_Field=URL|https://github.com/romoez/UsbCleaner
#AutoIt3Wrapper_Res_Field=Email|moez.romdhane@tarbia.tn
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#pragma compile(Icon, res\UsbCleaner.ico)
#pragma compile(Out, Install\Files\UsbCleaner.exe)
#pragma compile(FileDescription, UsbCleaner)
#pragma compile(ProductName, UsbCleaner)
#pragma compile(ProductVersion, 0.1.13.417)
#pragma compile(FileVersion, 0.1.13.417, 0.1.13.417) ; The last parameter is optional.
#pragma compile(LegalCopyright, 2019-2025 © La Communauté Tunisienne des Enseignants d'Informatique)
#pragma compile(Comments,'UsbCleaner')
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

Global Const $UID_SESSION = _GetUidSession()

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
				$iBacCollectorUSB = _CleanUp($aFiles)
				If FileExists(@ScriptDir & "\UsbWatcher.exe") And Not $iBacCollectorUSB Then
					ShellExecute(@ScriptDir & "\UsbWatcher.exe", $New & " " & $UID_SESSION)
				EndIf

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
    ; Définir des constantes pour les extensions suspectes et les actions répétitives
    Const $EXTENSIONS_SUSPECTES = [".lnk", ".pif", ".vbs", ".vbe", ".wsf"]
    Const $TAILLE_MAX_EXE = 512000
	Const $BC_FILE_NAME = "BACCOLLECTOR"
	Const $BC_FILE_NAME_LEN = StringLen($BC_FILE_NAME)

    Local $iBacCollectorUSB = 0
    If Not IsArray($aFiles) Then Return $iBacCollectorUSB ; Quitter si $aFiles n'est pas un tableau valide

    ; Initialiser les variables locales
    Local $sDrive, $sDir, $sFileName, $sExtension, $iFileSize, $bIsDirectory
    Local $sDriveRoot = StringLeft($aFiles[1], 3) ; Récupérer la racine du lecteur

    ; Afficher la barre de progression
    ProgressOn("UsbCleaner", "Scan du lecteur """ & $sDriveRoot & """", "[0%] Initialisation...", Default, Default)

    For $i = 1 To $aFiles[0]
        ; Mettre à jour la barre de progression toutes les 10 itérations pour réduire la charge CPU
        If Mod($i, 10) = 0 Then
            ProgressSet(Round(($i - 1) / $aFiles[0] * 100), "[" & Round(($i - 1) / $aFiles[0] * 100) & "%] " & $aFiles[$i])
        EndIf
		$bIsDirectory = StringInStr(FileGetAttrib($aFiles[$i]), 'D')
		If $bIsDirectory And $aFiles[$i] = "System Volume Information" Then ContinueLoop

        ; Supprimer les attributs de fichier pour permettre la manipulation
        FileSetAttrib($aFiles[$i], "-RASH")

        ; Ignorer les dossiers
        If  $bIsDirectory Then ContinueLoop

        ; Extraire les informations du chemin du fichier
        _PathSplit($aFiles[$i], $sDrive, $sDir, $sFileName, $sExtension)

        ; Vérifier si le fichier contient "BacCollector"
        If StringLen($sFileName) = $BC_FILE_NAME_LEN And StringUpper($sFileName) = $BC_FILE_NAME Then
            $iBacCollectorUSB = 1
        EndIf

        ; Traiter les fichiers suspects
        If $sFileName & $sExtension = "autorun.inf" Or _ArraySearch($EXTENSIONS_SUSPECTES, $sExtension) <> -1 Then
            FileMove($aFiles[$i], $sDrive & $SUSPICIOUS_FILES_FOLDER & $sFileName & $sExtension, 9)
        ElseIf $sExtension = ".exe" Then
            $iFileSize = FileGetSize($aFiles[$i])
            If $iFileSize < $TAILLE_MAX_EXE Then
                FileMove($aFiles[$i], $sDrive & $SUSPICIOUS_FILES_FOLDER & $sFileName & $sExtension, 9)
            EndIf
        EndIf
    Next

    ; Nettoyer les ressources
    $aFiles = 0
    _SetIconToSuspiciousFilesFolder($sDrive)
    ProgressOff()

    Return $iBacCollectorUSB
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

Func _GetUidSession()
    $Uuid = StringFormat("%04i.%02i.%02i__%02i.%02i.%02i__%04X%04X", @YEAR, @MON, @MDAY, @HOUR, @MIN, @SEC, _
            Random(0, 0xffff), _
            BitOR(Random(0, 0x0fff), 0x4000) _
        )
	Return $Uuid
EndFunc

While 1
	$GuiMsg = GUIGetMsg()
WEnd


