#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
;~ #AutoIt3Wrapper_Compression=4
;~ #AutoIt3Wrapper_UseUpx=y
#AutoIt3Wrapper_Run_Au3Stripper=y
#AutoIt3Wrapper_Res_Field=URL|https://github.com/romoez/UsbCleaner
#AutoIt3Wrapper_Res_Field=Email|moez.romdhane@tarbia.tn
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#pragma compile(Icon, res\UsbCleaner.ico)
#pragma compile(Out, Install\Files\UsbWatcher.exe)
#pragma compile(FileDescription, UsbWatcher)
#pragma compile(ProductName, UsbCleaner)
#pragma compile(ProductVersion, 0.1.12.415)
#pragma compile(FileVersion, 0.1.12.415, 0.1.12.415) ; The last parameter is optional.
#pragma compile(LegalCopyright, 2019-2025 © La Communauté Tunisienne des Enseignants d'Informatique)
#pragma compile(Comments,'UsbWatcher')
#pragma compile(CompanyName, La Communauté Tunisienne des Enseignants d'Informatique)
#pragma compile(AutoItExecuteAllowed, False)


;~ #include <FileConstants.au3>
#include <String.au3>
#include <WinAPIFiles.au3>
#include <Array.au3>
#include <File.au3>
#include <ScreenCapture.au3>

If $CMDLINE[0] < 2 Then
	Exit
EndIf

Global Const $FREE_SPACE_DRIVE_BACKUP = 5000 ; en Mo
Global $DossierSauvegardes = "Sauvegardes"
Global $Lecteur = LecteurSauvegarde()
Global Const $UID_SESSION_FILE = $CMDLINE[2]  & ".txt"

If Not FileExists($Lecteur & $DossierSauvegardes) Then
	DirCreate($Lecteur & $DossierSauvegardes)
EndIf
;~ Dossier Captures d'écran
If Not FileExists($Lecteur & $DossierSauvegardes & "\BacBackup") Then
	_UnLockFolder($Lecteur & $DossierSauvegardes)
	DirCreate($Lecteur & $DossierSauvegardes & "\BacBackup")
EndIf

FileSetAttrib($Lecteur & $DossierSauvegardes, "+SH")
_LockFolder($Lecteur & $DossierSauvegardes)


;~ Sous Dossier Captures d'écran
Global $DossierSession = IniRead($Lecteur & $DossierSauvegardes & "\BacBackup\BacBackup.ini", "Params", "DossierSession", "/^_^\")
If Not FileExists($Lecteur & $DossierSauvegardes & "\BacBackup\" & $DossierSession) _
	Or _AncienneSession($Lecteur & $DossierSauvegardes & "\BacBackup\" & $DossierSession, $UID_SESSION_FILE) Then
	$Tmp = StringLeft($DossierSession, 3)
;~    MsgBox ( 0, "", $Tmp  )
	If StringRegExp($Tmp, "([0-9]{3})", 0) = 0 Then
		$Tmp = "001"
	Else
		$Tmp = $Tmp + 1
		If $Tmp > 999 Then
			$Tmp = "001"
		EndIf
	EndIf
	$Tmp = "00" & $Tmp
	$Tmp = StringRight($Tmp, 3)

	$DossierSession = $Tmp & '___' & @MDAY & "_" & @MON & "_" & @YEAR & "___" & @HOUR & "h" & @MIN
	IniWrite($Lecteur & $DossierSauvegardes & "\BacBackup\BacBackup.ini", "Params", "DossierSession", $DossierSession)
EndIf

Global $FullPathDossierSession = StringUpper($Lecteur) & $DossierSauvegardes & "\BacBackup\" & $DossierSession
If Not FileExists($FullPathDossierSession) Then
	DirCreate($FullPathDossierSession)
EndIf

If FileExists($FullPathDossierSession) And Not FileExists($FullPathDossierSession & "\" & $UID_SESSION_FILE) Then
	Local $hInfoFile = FileOpen($FullPathDossierSession & "\" & $UID_SESSION_FILE, 1)
	FileWriteLine($hInfoFile, 'UsbWatcher Unique ID Session')
	FileClose($hInfoFile)
EndIf


If Not FileExists($FullPathDossierSession & "\1-UsbWatcher") Then
	DirCreate($FullPathDossierSession & "\1-UsbWatcher")
EndIf

$FullPathDossierSession = $FullPathDossierSession & "\1-UsbWatcher"
If Not FileExists($FullPathDossierSession)	 Then
	Exit
EndIf
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@     Début Programme Principal    @@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

_KillOtherScript()
Init()

Func Init()
	If $CMDLINE[0] And FileExists($CMDLINE[1]) Then
		Local $drive_letter = $CMDLINE[1]
		Local $aArray = _FileListToArrayRec($drive_letter, "*", $FLTAR_FILES, $FLTAR_RECUR)
		If Not IsArray($aArray) Then Return
		Local $aUsbInfo = _GetUsbDriveInfo($drive_letter)  ; $UsbInfo[0] = Caption, $UsbInfo[1] = $SerialNumber, $UsbInfo[2] = Size (Go)
		Local $Fldr = @HOUR & "_" & @MIN & "_" & @SEC
		Local $sInfoUSB = ""
		If IsArray($aUsbInfo) Then
			$return = StringRegExp($aUsbInfo[1], "^[A-Za-z0-9_ -\.]+$", 0)
			If @error == 0 And $return Then
				$Fldr = $Fldr & "___SN__" & $aUsbInfo[1]
			EndIf
			$sInfoUSB += 'Modèle  : ' & $aUsbInfo[0] & @CRLF
			$sInfoUSB += 'Capacité: ' & $aUsbInfo[2] & " Go" & @CRLF
			$sInfoUSB += 'N°Série : ' & $aUsbInfo[1] & @CRLF
		EndIf
		$FullPathDossierSession = $FullPathDossierSession & "\" & $Fldr
		If FileExists($FullPathDossierSession) Then
			$i = 0
			While FileExists($FullPathDossierSession & "_" & $i)
				$i = $i + 1
			WEnd
			$FullPathDossierSession = $FullPathDossierSession & "_" & $i
		EndIf
		DirCreate($FullPathDossierSession)
		If FileExists($FullPathDossierSession) Then
				Local $hInfoFile = FileOpen($FullPathDossierSession & "\" & "00_info.txt", 1)
				FileWriteLine($hInfoFile, 'Lecteur : ' & $drive_letter)
				FileWriteLine($hInfoFile, 'Heure   : ' & @HOUR & ":" & @MIN & ":" & @SEC)
				FileWriteLine($hInfoFile, $sInfoUSB)
				FileWriteLine($hInfoFile, "------------------------------------------")
				FileWriteLine($hInfoFile, "Nombre de fichiers dans la Clé USB: " & $aArray[0])
				FileWriteLine($hInfoFile, "------------------------------------------")
				_FileWriteFromArray ($hInfoFile, $aArray, 1)
				FileClose($hInfoFile)
				$aArray = 0
				_Capturer($drive_letter, $FullPathDossierSession, 100)
		EndIf
	EndIf
EndFunc   ;==>Init

;#########################################################################################

Func _Capturer($drive_letter, $FullPathDossierSession, $iNb)
	Local $NomImage
	For $i = 1 To $iNb
		$NomImage = @HOUR & "h_" & @MIN & "_" & @SEC & ".png"
		_ScreenCapture_Capture($FullPathDossierSession & "\" & $NomImage)
		If @error <> 0 Or Not FileExists($drive_letter) Then
			Return
		EndIf
		Sleep(1500)
	Next
EndFunc   ;==>Capturer

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

;#########################################################################################

Func LecteurSauvegarde()
	Local $aDrive = DriveGetDrive('FIXED')
    Local $HomeDrive = StringLeft(@WindowsDir,2)
	; $Lecteur = @HomeDrive ; "C:" ; $aDrive[1] ; $aDrive[1] peut être A: !!
	$Lecteur = $HomeDrive ; "C:" ; $aDrive[1] ; $aDrive[1] peut être A: !!
	For $i = 1 To $aDrive[0]
		If $aDrive[$i] = $HomeDrive Then ContinueLoop
		If (DriveGetType($aDrive[$i], $DT_BUSTYPE) <> "USB") _ ; pour Exclure les hdd externes
				And _WinAPI_IsWritable($aDrive[$i]) _
				And DriveSpaceFree($aDrive[$i] & "\") > $FREE_SPACE_DRIVE_BACKUP _ ;1Go
				Then
			$Lecteur = $aDrive[$i]
			ExitLoop
		EndIf
	Next
	$Lecteur = $Lecteur & "\"
	Return $Lecteur
EndFunc   ;==>LecteurSauvegarde

;#########################################################################################

Func _LockFolder($Dossier)
	If FileExists($Dossier) = 0 Then Return SetError(1, 0, -1)
	RunWait('"' & @ComSpec & '" /c cacls.exe "' & $Dossier & '" /E /P "' & @UserName & '":N', '', @SW_HIDE)
EndFunc   ;==>_LockFolder

;#########################################################################################

Func _UnlockFolder($Dossier)
	If FileExists($Dossier) = 0 Then Return SetError(1, 0, -1)
	RunWait('"' & @ComSpec & '" /c cacls.exe "' & $Dossier & '" /E /P "' & @UserName & '":F', '', @SW_HIDE)
EndFunc   ;==>_UnlockFolder

Func _GetUsbDriveInfo($drive_letter)
    Local $drive_letter_found, $UsbInfo[3]
    $wbemFlagReturnImmediately = 0x10
    $wbemFlagForwardOnly = 0x20
    $colItems = ""
    $strComputer = "localhost"

    $objWMIService = ObjGet("winmgmts:\\" & $strComputer & "\root\CIMV2")
	if IsObj($objWMIService) Then
		$colItems = $objWMIService.ExecQuery("SELECT * FROM Win32_LogicalDiskToPartition", "WQL", $wbemFlagReturnImmediately + $wbemFlagForwardOnly)
		If IsObj($colItems) Then
			For $objItem In $colItems
						If IsObj($objItem) Then
								$LogicalDiskToPartitionAntecedent = _StringBetween($objItem.Antecedent, '"', '"')
								$LogicalDiskToPartitionDependent = _StringBetween($objItem.Dependent, '"', '"')
								;ConsoleWrite(@CR & $LogicalDiskToPartitionAntecedent[0] & " - " & $LogicalDiskToPartitionDependent[0])
								$drive_statistics = $LogicalDiskToPartitionAntecedent[0]
								$drive_letter_found = $LogicalDiskToPartitionDependent[0]
								If $drive_letter = $drive_letter_found Then
										ExitLoop
								EndIf
						EndIf
			Next
		Else
	;~         MsgBox(0, "WMI Output", "No WMI Objects Found for class: " & "Win32_LogicalDiskToPartition")
			Return $UsbInfo
		EndIf
	Else
		Return $UsbInfo
	EndIf
    If $drive_letter <> $drive_letter_found Then Return 0 ; If drive letter isn't function returns 0

    $colItems = $objWMIService.ExecQuery("SELECT * FROM Win32_DiskDriveToDiskPartition", "WQL", $wbemFlagReturnImmediately + $wbemFlagForwardOnly)
    If IsObj($colItems) Then
        For $objItem In $colItems
            $DiskDriveToDiskPartitionAntecedent = _StringBetween($objItem.Antecedent, '"', '"')
            $DiskDriveToDiskPartitionDependent = _StringBetween($objItem.Dependent, '"', '"')
            ;ConsoleWrite(@CR & $DiskDriveToDiskPartitionAntecedent[0] & " - " & $DiskDriveToDiskPartitionDependent[0])
            $drive_statistics_found = $DiskDriveToDiskPartitionDependent[0]
            $drive_physical = StringTrimLeft($DiskDriveToDiskPartitionAntecedent[0], StringInStr($DiskDriveToDiskPartitionAntecedent[0], "\", 1, -1))
            ;MsgBox(0,"TEST", $drive_physical)
            If $drive_statistics = $drive_statistics_found Then
                ExitLoop
            EndIf
        Next
    Else
;~         MsgBox(0, "WMI Output", "No WMI Objects Found for class: " & "Win32_DiskDriveToDiskPartition")
		Return 1
    EndIf

    $colItems = $objWMIService.ExecQuery("SELECT * FROM Win32_DiskDrive", "WQL", $wbemFlagReturnImmediately + $wbemFlagForwardOnly)
    If IsObj($colItems) Then
        For $objItem In $colItems
            ;MsgBox(0,324234, $objItem.DeviceID)
            $DeviceID = StringTrimLeft($objItem.DeviceID, StringInStr($objItem.DeviceID, "\", 1, -1))
            ;MsgBox(0,122, $DeviceID)
            If $drive_physical = $DeviceID Then
				$UsbInfo[0] = $objItem.Caption
				$UsbInfo[1] = $objItem.SerialNumber
				$UsbInfo[2] = OctetsVersGo($objItem.Size)
                Return $UsbInfo
            EndIf
        Next
    Else
;~         MsgBox(0, "WMI Output", "No WMI Objects Found for class: " & "Win32_DiskDrive")
		Return 2
    EndIf
EndFunc   ;==>_GetPNPDeviceID


Func OctetsVersGo($octets)
    ; Calculer la taille en Go
    Local $go = $octets / 1073741824 ; 1 Go = 1024 * 1024 * 1024 octets

    ; Trouver la puissance de 2 la plus proche
    Local $puissance = 0
    While (2 ^ $puissance < $go)
        $puissance += 1
    WEnd

    ; Retourner la valeur arrondie
    Return 2 ^ $puissance
EndFunc


Func _AncienneSession($cheminSessionCourante, $fichierSessionCourante)
    If StringRight($cheminSessionCourante, 1) <> "\" Then
        $cheminSessionCourante = $cheminSessionCourante & "\"
    EndIf

    If FileExists($cheminSessionCourante & $fichierSessionCourante) Then
        Return False
    EndIf

    Local $pattern = $cheminSessionCourante & "????.??.??__??.??.??__????????.txt"
    Local $files = FileFindFirstFile($pattern)

    ; Si aucun fichier n'est trouvé
    If $files = -1 Then
        Return False
    EndIf

    Local $file
    Local $found = False

    While 1
        $file = FileFindNextFile($files)
        If @error Then ExitLoop

        If StringRegExp($file, "^\d{4}\.\d{2}\.\d{2}__\d{2}\.\d{2}\.\d{2}__[0-9A-Fa-f]{8}\.txt$") Then
            $found = True
            ExitLoop
        EndIf
    WEnd

    FileClose($files)

    Return $found
EndFunc