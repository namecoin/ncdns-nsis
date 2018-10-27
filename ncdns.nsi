!ifndef NCDNS_PRODVER
  #!ifdef POSIX_BUILD
  !error "Must define NCDNS_PRODVER"
  #!else
  ## This won't currently work for Go binaries, since they don't have any
  ## version information embedded in them.
  #  !system 'powershell -executionpolicy bypass -noninteractive -file getver.ps1 . < nul'
  #  !include '_ver.nsi'
  #  !delfile '_ver.nsi'
  #!endif
!endif

!include "MUI2.nsh"


# INSTALLER SETTINGS
##############################################################################
OutFile "${OUTFN}"

# Jeremy Rand thinks people shouldn't change this because it might affect build
# determinism, so any PR which changes this should probably highlight him or
# something.
SetCompressor /SOLID lzma

!define MUI_ICON "media\namecoin.ico"
!define MUI_FINISHPAGE_NOAUTOCLOSE
!define MUI_UNFINISHPAGE_NOAUTOCLOSE
!define MUI_PAGE_CUSTOMFUNCTION_SHOW ShowCallback

!include "components-dialog.nsdinc"

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
Page custom ComponentDialogCreate ComponentDialogLeave
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

!insertmacro MUI_LANGUAGE English

!ifdef NCDNS_64BIT
  InstallDir $PROGRAMFILES64\ncdns
!else
  InstallDir $PROGRAMFILES\ncdns
!endif

InstallDirRegKey HKLM "Software\Namecoin\ncdns" "InstallPath"
ShowInstDetails show
ShowUninstDetails show

RequestExecutionLevel admin
XPStyle on
CRCCheck on

# Branding.
Name "ncdns for Windows"
BrandingText "Namecoin"

# Installer .exe version tables.
VIAddVersionKey "ProductName" "ncdns"
VIAddVersionKey "ProductVersion" "${NCDNS_PRODVER}"
VIProductVersion "${NCDNS_PRODVER}"
VIAddVersionKey "InternalName" "ncdns"
VIAddVersionKey "FileDescription" "ncdns Installer"
VIAddVersionKey "FileVersion" "${NCDNS_PRODVER}"
!ifndef POSIX_BUILD
  VIFileVersion "${NCDNS_PRODVER}"
!endif
VIAddVersionKey "OriginalFilename" "ncdns-install.exe"
VIAddVersionKey "CompanyName" "Namecoin"
VIAddVersionKey "LegalCopyright" "2017 Hugo Landau <hlandau@devever.net>"
VIAddVersionKey "LegalTrademarks" "ncdns, Namecoin"
VIAddVersionKey "Comments" "ncdns Installer"


# VARIABLES
##############################################################################
Var /GLOBAL UnboundConfPath
Var /GLOBAL UnboundFragmentLocation
Var /GLOBAL DNSSECTriggerUninstallCommand
Var /GLOBAL NamecoinCoreUninstallCommand
Var /GLOBAL NamecoinCoreDataDir
Var /GLOBAL SkipNamecoinCore
Var /GLOBAL SkipUnbound
Var /GLOBAL UseSPV

Var /GLOBAL NamecoinCoreDetected
Var /GLOBAL UnboundDetected

Var /GLOBAL CurChromium_Path
Var /GLOBAL CurChromium_TransportSecurity
Var /GLOBAL CurChromium_lockfile
Var /GLOBAL FindHandle
Var /GLOBAL ProfileName
Var /GLOBAL ChromiumFound
Var /GLOBAL ChromiumRejected
Var /GLOBAL JREPath
Var /GLOBAL JREDetected
Var /GLOBAL JRE32Detected
Var /GLOBAL JRE64Detected
Var /GLOBAL VC2010_x86_32Detected
Var /GLOBAL VC2010_x86_64Detected
Var /GLOBAL VC2012_x86_32Detected
Var /GLOBAL VC2012_x86_64Detected
Var /GLOBAL VC2015_x86_32Detected
Var /GLOBAL VC2015_x86_64Detected
Var /GLOBAL BindRequirementsMet
Var /GLOBAL BindRequirementsURL
Var /GLOBAL BindRequirementsError
Var /GLOBAL BitcoinJRequirementsMet
Var /GLOBAL BitcoinJRequirementsError
Var /GLOBAL FirefoxDetected
Var /GLOBAL Firefox32Detected
Var /GLOBAL Firefox64Detected
Var /GLOBAL FirefoxCurrentVersion
Var /GLOBAL FirefoxInstallDirectoryRegistryKey
Var /GLOBAL FirefoxInstallDirectoryBackSlashes
Var /GLOBAL FirefoxInstallDirectoryForwardSlashes
Var /GLOBAL FirefoxProfileINI
Var /GLOBAL FirefoxProfileNumber
Var /GLOBAL FirefoxIsDefaultProfile
Var /GLOBAL FirefoxIsRelativeProfile
Var /GLOBAL FirefoxRawProfileDirectoryBackSlashes
Var /GLOBAL FirefoxRawProfileDirectoryForwardSlashes
Var /GLOBAL FirefoxProfileDirectoryBackSlashes
Var /GLOBAL FirefoxProfileDirectoryForwardSlashes
Var /GLOBAL FirefoxTempDBDirectoryBackSlashes
Var /GLOBAL FirefoxTempDBDirectoryForwardSlashes
Var /GLOBAL FirefoxError
Var /GLOBAL Firefox32Error
Var /GLOBAL Firefox64Error
Var /GLOBAL FirefoxRejected

# PRELAUNCH CHECKS
##############################################################################
!Include WinVer.nsh
!include x64.nsh

!include "StrFunc.nsh"
${StrRep}

Function .onInit
  ${IfNot} ${AtLeastWinVista}
    MessageBox "MB_OK|MB_ICONSTOP" "ncdns requires Windows Vista or later."
    Abort
  ${EndIf}

  SetShellVarContext all

  # Make sections mandatory.
  Call ConfigSections

  # Detect if already installed.
  Call CheckReinstall

  # Detect already installed dependencies.
  Call DetectNamecoinCore
  Call DetectUnbound
  Call DetectJRE
  Call DetectVC2010_x86_32
  Call DetectVC2010_x86_64
  Call DetectVC2012_x86_32
  Call DetectVC2012_x86_64
  Call DetectVC2015_x86_32
  Call DetectVC2015_x86_64
  Call DetectBindRequirements
  Call DetectBitcoinJRequirements
  Call DetectFirefoxAnyArch

  Call FailIfBindRequirementsNotMet
FunctionEnd

Function un.onInit
  SetShellVarContext all
FunctionEnd

Function CheckReinstall
  ClearErrors
  ReadRegStr $0 HKLM "System\CurrentControlSet\Services\ncdns" "ImagePath"
  IfErrors not_installed

  MessageBox "MB_OK|MB_ICONSTOP" "ncdns for Windows is already installed.$\n$\nTo reinstall ncdns for Windows, first uninstall it."
  Abort

not_installed:
FunctionEnd

Function DetectVC2010_x86_32
  # https://blogs.msdn.microsoft.com/astebner/2010/05/05/mailbag-how-to-detect-the-presence-of-the-visual-c-2010-redistributable-package/
  # https://stackoverflow.com/a/34199260
  ReadRegDWORD $0 HKLM "SOFTWARE\Microsoft\VisualStudio\10.0\VC\VCRedist\x86" "Installed"
  ${If} $0 != "1"
    Push 0
    Pop $VC2010_x86_32Detected
  ${Else}
    Push 1
    Pop $VC2010_x86_32Detected
  ${EndIf}
FunctionEnd

Function DetectVC2010_x86_64
  # https://blogs.msdn.microsoft.com/astebner/2010/05/05/mailbag-how-to-detect-the-presence-of-the-visual-c-2010-redistributable-package/
  # https://stackoverflow.com/a/34199260
  ReadRegDWORD $0 HKLM "SOFTWARE\Microsoft\VisualStudio\10.0\VC\VCRedist\x64" "Installed"
  ${If} $0 != "1"
    Push 0
    Pop $VC2010_x86_64Detected
  ${Else}
    Push 1
    Pop $VC2010_x86_64Detected
  ${EndIf}
FunctionEnd

Function DetectVC2012_x86_32
  # https://blogs.msdn.microsoft.com/astebner/2010/05/05/mailbag-how-to-detect-the-presence-of-the-visual-c-2010-redistributable-package/
  # https://stackoverflow.com/a/34199260
  ReadRegDWORD $0 HKLM "SOFTWARE\Microsoft\VisualStudio\11.0\VC\Runtimes\x86" "Installed"
  ${If} $0 != "1"
    Push 0
    Pop $VC2012_x86_32Detected
  ${Else}
    Push 1
    Pop $VC2012_x86_32Detected
  ${EndIf}
FunctionEnd

Function DetectVC2012_x86_64
  # https://blogs.msdn.microsoft.com/astebner/2010/05/05/mailbag-how-to-detect-the-presence-of-the-visual-c-2010-redistributable-package/
  # https://stackoverflow.com/a/34199260
  ReadRegDWORD $0 HKLM "SOFTWARE\Microsoft\VisualStudio\11.0\VC\Runtimes\x64" "Installed"
  ${If} $0 != "1"
    Push 0
    Pop $VC2012_x86_64Detected
  ${Else}
    Push 1
    Pop $VC2012_x86_64Detected
  ${EndIf}
FunctionEnd

Function DetectVC2015_x86_32
  # https://blogs.msdn.microsoft.com/astebner/2010/05/05/mailbag-how-to-detect-the-presence-of-the-visual-c-2010-redistributable-package/
  # https://stackoverflow.com/a/34199260
  ReadRegDWORD $0 HKLM "SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x86" "Installed"
  ${If} $0 != "1"
    Push 0
    Pop $VC2015_x86_32Detected
  ${Else}
    Push 1
    Pop $VC2015_x86_32Detected
  ${EndIf}
FunctionEnd

Function DetectVC2015_x86_64
  # https://blogs.msdn.microsoft.com/astebner/2010/05/05/mailbag-how-to-detect-the-presence-of-the-visual-c-2010-redistributable-package/
  # https://stackoverflow.com/a/34199260
  ReadRegDWORD $0 HKLM "SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64" "Installed"
  ${If} $0 != "1"
    Push 0
    Pop $VC2015_x86_64Detected
  ${Else}
    Push 1
    Pop $VC2015_x86_64Detected
  ${EndIf}
FunctionEnd

Function DetectNamecoinCore
  ClearErrors
  ReadRegStr $0 HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Namecoin Core (32-bit)" "UninstallString"
  IfErrors 0 found
  ClearErrors
  ReadRegStr $0 HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Namecoin Core (64-bit)" "UninstallString"
  IfErrors 0 found
  Goto absent
found:
  Push 1
  Pop $NamecoinCoreDetected
  Return
absent:
  Push 0
  Pop $NamecoinCoreDetected
FunctionEnd

Function DetectUnbound
  ClearErrors
  ReadRegDWORD $0 HKLM "System\CurrentControlSet\Services\unbound" "Type"
  IfErrors absent 0
  Push 1
  Pop $UnboundDetected
  Return
absent:
  Push 0
  Pop $UnboundDetected
FunctionEnd

Var /GLOBAL DetectJRE_W
Function DetectJRE
  StrCpy $JREDetected 0

  # Check for 64-bit JRE
  ${If} ${RunningX64}
    SetRegView 64
    StrCpy $DetectJRE_W "SOFTWARE\JavaSoft\Java Runtime Environment"
    Call DetectJREUnder
    SetRegView lastused

    ${If} $JREDetected == 1
      StrCpy $JRE32Detected 0
      StrCpy $JRE64Detected 1
      Return
    ${EndIf}
  ${EndIf}

  # Check for 32-bit JRE
  SetRegView 32
  StrCpy $DetectJRE_W "SOFTWARE\JavaSoft\Java Runtime Environment"
  Call DetectJREUnder
  SetRegView lastused

  ${If} $JREDetected == 1
    StrCpy $JRE32Detected 1
    StrCpy $JRE64Detected 0
    Return
  ${EndIf}

  # No JRE detected
  StrCpy $JRE32Detected 0
  StrCpy $JRE64Detected 0
FunctionEnd

Function DetectJREUnder
  ClearErrors
  ReadRegStr $0 HKLM "$DetectJRE_W" "CurrentVersion"
  IfErrors not_found
  StrCmp $0 "" not_found

  ClearErrors
  ReadRegStr $JREPath HKLM "$DetectJRE_W\$0" "JavaHome"
  IfErrors not_found
  StrCmp $JREPath "" not_found
  StrCpy $JREDetected 1

not_found:
  Return
FunctionEnd

Function DetectBindRequirements
  # BIND's binaries link against *both* the Visual C++ 2012 and 2015
  # Redistributables.  Don't ask me why, I don't know.

  ${If} ${RunningX64}
    ${If} $VC2012_x86_64Detected == 0
      Push 0
      Pop $BindRequirementsMet
      StrCpy $BindRequirementsURL "https://www.microsoft.com/en-us/download/details.aspx?id=30679"
      StrCpy $BindRequirementsError "ncdns for Windows requires the Microsoft Visual C++ 2012 (64-bit) Redistributable.$\n$\nYou can download it from:$\n$BindRequirementsURL"
      Return
    ${EndIf}
    ${If} $VC2015_x86_64Detected == 0
      Push 0
      Pop $BindRequirementsMet
      StrCpy $BindRequirementsURL "https://www.microsoft.com/en-us/download/details.aspx?id=53587"
      StrCpy $BindRequirementsError "ncdns for Windows requires the Microsoft Visual C++ 2015 (64-bit) Redistributable.$\n$\nYou can download it from:$\n$BindRequirementsURL"
      Return
    ${EndIf}
  ${Else}
    ${If} $VC2012_x86_32Detected == 0
      Push 0
      Pop $BindRequirementsMet
      StrCpy $BindRequirementsURL "https://www.microsoft.com/en-us/download/details.aspx?id=30679"
      StrCpy $BindRequirementsError "ncdns for Windows requires the Microsoft Visual C++ 2012 (32-bit) Redistributable.$\n$\nYou can download it from:$\n$BindRequirementsURL"
      Return
    ${EndIf}
    ${If} $VC2015_x86_32Detected == 0
      Push 0
      Pop $BindRequirementsMet
      StrCpy $BindRequirementsURL "https://www.microsoft.com/en-us/download/details.aspx?id=53587"
      StrCpy $BindRequirementsError "ncdns for Windows requires the Microsoft Visual C++ 2015 (32-bit) Redistributable.$\n$\nYou can download it from:$\n$BindRequirementsURL"
      Return
    ${EndIf}
  ${EndIf}

  Push 1
  Pop $BindRequirementsMet
  StrCpy $BindRequirementsError ""
FunctionEnd

Function FailIfBindRequirementsNotMet
  ${If} $BindRequirementsMet == 0
    MessageBox "MB_OK|MB_ICONSTOP" "$BindRequirementsError"
    ExecShell "open" "$BindRequirementsURL"
    Abort
  ${EndIf}
FunctionEnd

Function DetectBitcoinJRequirements
  ${If} $JRE64Detected == 1
    ${If} $VC2010_x86_64Detected == 1
      Push 1
      Pop $BitcoinJRequirementsMet
      StrCpy $BitcoinJRequirementsError ""
      Return
    ${EndIf}
  ${EndIf}

  ${If} $JRE32Detected == 1
    ${If} $VC2010_x86_32Detected == 1
      Push 1
      Pop $BitcoinJRequirementsMet
      StrCpy $BitcoinJRequirementsError ""
      Return
    ${EndIf}
  ${EndIf}

  ${If} $JREDetected == 0
    StrCpy $BitcoinJRequirementsError "Java must be installed"
  ${Else}
    StrCpy $BitcoinJRequirementsError "Microsoft Visual C++ 2010 Redistributable Package must be installed"
  ${EndIf}

  Push 0
  Pop $BitcoinJRequirementsMet
FunctionEnd

Function DetectFirefoxAnyArch
  # Check for 64-bit Firefox requirements
  # Visual C++ 2010 Redistributable is needed by Tor's certutil binaries
  ${If} $VC2010_x86_64Detected == 0
    StrCpy $Firefox64Error "Microsoft Visual C++ 2010 Redistributable Package must be installed"
    Goto not_64
  ${EndIf}
  # Visual C++ 2015 Redistributable is needed by Mozilla's CKBI binaries
  ${If} $VC2015_x86_64Detected == 0
    StrCpy $Firefox64Error "Microsoft Visual C++ 2015 Redistributable Package must be installed"
    Goto not_64
  ${EndIf}

  # Check for 64-bit Firefox
  ${If} ${RunningX64}
    SetRegView 64
    Call DetectFirefoxSingleArch
    SetRegView lastused

    ${If} $FirefoxDetected == 1
      StrCpy $Firefox32Detected 0
      StrCpy $Firefox64Detected 1

      StrCpy $Firefox32Error "64-bit Firefox was detected and took priority"

      Return
    ${Else}
      StrCpy $Firefox64Error "$FirefoxError"
    ${EndIf}
  ${Else}
    StrCpy $Firefox64Error "Not running a 64-bit OS"
  ${EndIf}

not_64:

  # Check for 32-bit Firefox requirements
  # Visual C++ 2010 Redistributable is needed by Tor's certutil binaries
  ${If} $VC2010_x86_32Detected == 0
    StrCpy $Firefox32Error "Microsoft Visual C++ 2010 Redistributable Package must be installed"
    Goto not_32
  ${EndIf}
  # Visual C++ 2015 Redistributable is needed by Mozilla's CKBI binaries
  ${If} $VC2015_x86_32Detected == 0
    StrCpy $Firefox32Error "Microsoft Visual C++ 2015 Redistributable Package must be installed"
    Goto not_32
  ${EndIf}

  # Check for 32-bit Firefox
  SetRegView 32
  Call DetectFirefoxSingleArch
  SetRegView lastused

  ${If} $FirefoxDetected == 1
    StrCpy $Firefox32Detected 1
    StrCpy $Firefox64Detected 0
    Return
  ${Else}
    StrCpy $Firefox32Error "$FirefoxError"
  ${EndIf}

not_32:

  # At this point, Firefox wasn't detected at all
  StrCpy $Firefox32Detected 0
  StrCpy $Firefox64Detected 0
FunctionEnd

Function DetectFirefoxSingleArch
  # Check Firefox version
  ClearErrors
  ReadRegStr $FirefoxCurrentVersion HKLM "SOFTWARE\Mozilla\Mozilla Firefox" "CurrentVersion"
  IfErrors versionerror 0

  # Check Firefox install directory
  StrCpy $FirefoxInstallDirectoryRegistryKey "SOFTWARE\Mozilla\Mozilla Firefox\$FirefoxCurrentVersion\Main"
  ReadRegStr $FirefoxInstallDirectoryBackSlashes HKLM "$FirefoxInstallDirectoryRegistryKey" "Install Directory"
  ${StrRep} $FirefoxInstallDirectoryForwardSlashes "$FirefoxInstallDirectoryBackSlashes" "\" "/"
  IfErrors installdirectoryerror 0

  # We need the current user's $APPDATA for accessing the Firefox profile.
  SetShellVarContext current

  # Try Profile 0
  Push 0
  Pop $FirefoxProfileNumber

  # Get the info for Profile
  StrCpy $FirefoxProfileINI "$APPDATA\Mozilla\Firefox\profiles.ini"
  ReadINIStr $FirefoxIsDefaultProfile "$FirefoxProfileINI" "Profile$FirefoxProfileNumber" "Default"
  ReadINIStr $FirefoxIsRelativeProfile "$FirefoxProfileINI" "Profile$FirefoxProfileNumber" "IsRelative"
  ReadINIStr $FirefoxRawProfileDirectoryForwardSlashes "$FirefoxProfileINI" "Profile$FirefoxProfileNumber" "Path"
  IfErrors profileinierror 0

  # Fail if Profile 0 isn't the default or isn't relative.
  # In the future maybe we'll support those edge cases.
  ${If} "$FirefoxIsDefaultProfile" != "1"
    Goto profiledefaulterror
  ${EndIf}
  ${If} "$FirefoxIsRelativeProfile" != "1"
    Goto profilerelativeerror
  ${EndIf}

  # Get the profile directory
  ${StrRep} $FirefoxRawProfileDirectoryBackSlashes "$FirefoxRawProfileDirectoryForwardSlashes" "/" "\"
  StrCpy $FirefoxProfileDirectoryBackSlashes "$APPDATA\Mozilla\Firefox\$FirefoxRawProfileDirectoryBackSlashes"
  ${StrRep} $FirefoxProfileDirectoryForwardSlashes "$FirefoxProfileDirectoryBackSlashes" "\" "/"

  # Make sure the profile directory has an NSS sqlite database in it
  IfFileExists "$FirefoxProfileDirectoryBackSlashes\cert9.db" 0 cert9error
  IfFileExists "$FirefoxProfileDirectoryBackSlashes\key4.db" 0 key4error
  IfFileExists "$FirefoxProfileDirectoryBackSlashes\pkcs11.txt" 0 pkcs11error

  Push 1
  Pop $FirefoxDetected

  Goto restoreappdata

versionerror:
  StrCpy $FirefoxError "Couldn't detect Firefox version"
  Goto absent

installdirectoryerror:
  StrCpy $FirefoxError "Couldn't detect Firefox install directory from registry key $FirefoxInstallDirectoryRegistryKey"
  Goto absent

profileinierror:
  StrCpy $FirefoxError "Couldn't read Firefox profile INI from $FirefoxProfileINI"
  Goto absent

profiledefaulterror:
  StrCpy $FirefoxError "Firefox profile 0 is not default: Default=$FirefoxIsDefaultProfile"
  Goto absent

profilerelativeerror:
  StrCpy $FirefoxError "Firefox profile 0 is not relative: IsRelative=$FirefoxIsRelativeProfile"
  Goto absent

cert9error:
  StrCpy $FirefoxError "cert9.db is missing from Firefox profile in $FirefoxProfileDirectoryBackSlashes"
  Goto absent

key4error:
  StrCpy $FirefoxError "key4.db is missing from Firefox profile in $FirefoxProfileDirectoryBackSlashes"
  Goto absent

pkcs11error:
  StrCpy $FirefoxError "pkcs11.txt is missing from Firefox profile in $FirefoxProfileDirectoryBackSlashes"
  Goto absent

absent:
  Push 0
  Pop $FirefoxDetected

restoreappdata:
  # Restore SetShellVarContext
  SetShellVarContext all

FunctionEnd

# DIALOG HELPERS
##############################################################################
Function ShowCallback
  SendMessage $mui.WelcomePage.Text ${WM_SETTEXT} 0 "STR:$(MUI_TEXT_WELCOME_INFO_TEXT)$\n$\nThis software is open source and licenced under the GPLv3 License. It is distributed WITHOUT ANY WARRANTY."
FunctionEnd


Function ComponentDialogCreate
  Call fnc_components_dialog_Create

  ${If} $NamecoinCoreDetected == 1
    ${NSD_SetText} $hCtl_components_dialog_NamecoinCore_Status "An existing Namecoin Core installation was detected."
    ${NSD_SetText} $hCtl_components_dialog_NamecoinCore_Yes "Automatically configure Namecoin Core (recommended)"
    ${If} $BitcoinJRequirementsMet == 1
      ${NSD_SetText} $hCtl_components_dialog_NamecoinCore_SPV "Install and use the BitcoinJ SPV client instead (lighter, less secure)"
    ${Else}
      ${NSD_SetText} $hCtl_components_dialog_NamecoinCore_SPV "Cannot use BitcoinJ SPV client ($BitcoinJRequirementsError)"
      EnableWindow $hCtl_components_dialog_NamecoinCore_SPV 0
    ${EndIf}
    ${NSD_SetText} $hCtl_components_dialog_NamecoinCore_No "I will configure Namecoin Core myself (manual configuration required)"
  ${Else}
    ${NSD_SetText} $hCtl_components_dialog_NamecoinCore_Status "An existing Namecoin Core installation was not detected."
    ${If} $BitcoinJRequirementsMet == 1
      ${NSD_SetText} $hCtl_components_dialog_NamecoinCore_Yes "Install and configure Namecoin Core (heavier, more secure)"
      ${NSD_SetText} $hCtl_components_dialog_NamecoinCore_SPV "Install and use the BitcoinJ SPV client (lighter, less secure)"
    ${Else}
      ${NSD_SetText} $hCtl_components_dialog_NamecoinCore_Yes "Install and configure Namecoin Core (recommended)"
      ${NSD_SetText} $hCtl_components_dialog_NamecoinCore_SPV "Cannot use BitcoinJ SPV client ($BitcoinJRequirementsError)"
      EnableWindow $hCtl_components_dialog_NamecoinCore_SPV 0
    ${EndIf}
    ${NSD_SetText} $hCtl_components_dialog_NamecoinCore_No "I will provide my own Namecoin node (manual configuration required)"
  ${EndIf}

  ${If} $UnboundDetected == 1
    ${NSD_SetText} $hCtl_components_dialog_Unbound_Status "An existing Unbound installation was detected."
    ${NSD_SetText} $hCtl_components_dialog_Unbound_Yes "Automatically configure Unbound (recommended)"
    ${NSD_SetText} $hCtl_components_dialog_Unbound_No "I will configure Unbound myself (manual configuration required)"
  ${Else}
    ${NSD_SetText} $hCtl_components_dialog_Unbound_Status "An existing Unbound installation was not detected."
    ${NSD_SetText} $hCtl_components_dialog_Unbound_Yes "Install and configure Unbound/DNSSEC Trigger (recommended)"
    ${NSD_SetText} $hCtl_components_dialog_Unbound_No "I will provide my own DNS resolver (manual configuration required)"
  ${EndIf}

  nsDialogs::Show
FunctionEnd

Function ComponentDialogLeave
  ${NSD_GetState} $hCtl_components_dialog_NamecoinCore_No $SkipNamecoinCore
  ${NSD_GetState} $hCtl_components_dialog_NamecoinCore_SPV $UseSPV
  ${NSD_GetState} $hCtl_components_dialog_Unbound_No $SkipUnbound

  ${If} $UseSPV == ${BST_CHECKED}
    StrCpy $SkipNamecoinCore 1
  ${EndIf}
FunctionEnd


# INSTALL SECTIONS
##############################################################################
Section "ncdns" Sec_ncdns
  SetOutPath $INSTDIR
  Call LogRequirementsChecks
  Call Reg
  Call DNSSECTrigger
  Call NamecoinCoreConfig
  Call NamecoinCore
  Call Service
  Call Files
  Call FilesConfig
  Call BitcoinJ
  Call TrustConfig
  Call FilesSecurePre
  Call TLSFirefoxConfig
  Call KeyConfig
  Call FilesSecure
  Call ServiceStart
  Call UnboundConfig

  AddSize 12288  # Disk space estimation.
SectionEnd


# UNINSTALL SECTIONS
##############################################################################
Section "Uninstall"
  Call un.UnboundConfig
  Call un.TrustConfig
  Call un.Service
  Call un.Files
  Call un.NamecoinCore
  Call un.BitcoinJ
  Call un.DNSSECTrigger
  Call un.Reg
  RMDir "$INSTDIR"
SectionEnd


Function LogRequirementsChecks
  ${If} $JREDetected == 1
    ${If} $JRE32Detected == 1
      DetailPrint "JRE is 32-bit."
    ${EndIf}

    ${If} $JRE64Detected == 1
      DetailPrint "JRE is 64-bit."
    ${EndIf}
  ${Else}
    DetailPrint "JRE was NOT detected."
  ${EndIf}

  ${If} $VC2010_x86_32Detected == 1
    DetailPrint "Microsoft Visual C++ 2010 Redistributable Package 32-bit was detected."
  ${Else}
    DetailPrint "Microsoft Visual C++ 2010 Redistributable Package 32-bit was NOT detected."
  ${EndIf}

  ${If} $VC2010_x86_64Detected == 1
    DetailPrint "Microsoft Visual C++ 2010 Redistributable Package 64-bit was detected."
  ${Else}
    DetailPrint "Microsoft Visual C++ 2010 Redistributable Package 64-bit was NOT detected."
  ${EndIf}

  ${If} $VC2012_x86_32Detected == 1
    DetailPrint "Microsoft Visual C++ 2012 Redistributable Package 32-bit was detected."
  ${Else}
    DetailPrint "Microsoft Visual C++ 2012 Redistributable Package 32-bit was NOT detected."
  ${EndIf}

  ${If} $VC2012_x86_64Detected == 1
    DetailPrint "Microsoft Visual C++ 2012 Redistributable Package 64-bit was detected."
  ${Else}
    DetailPrint "Microsoft Visual C++ 2012 Redistributable Package 64-bit was NOT detected."
  ${EndIf}

  ${If} $VC2015_x86_32Detected == 1
    DetailPrint "Microsoft Visual C++ 2015 Redistributable Package 32-bit was detected."
  ${Else}
    DetailPrint "Microsoft Visual C++ 2015 Redistributable Package 32-bit was NOT detected."
  ${EndIf}

  ${If} $VC2015_x86_64Detected == 1
    DetailPrint "Microsoft Visual C++ 2015 Redistributable Package 64-bit was detected."
  ${Else}
    DetailPrint "Microsoft Visual C++ 2015 Redistributable Package 64-bit was NOT detected."
  ${EndIf}

  ${If} $BitcoinJRequirementsMet == 1
    DetailPrint "BitcoinJ can be installed."
  ${Else}
    DetailPrint "$BitcoinJRequirementsError before BitcoinJ can be installed."
  ${EndIf}

  ${If} $Firefox32Detected == 1
    DetailPrint "Firefox 32-bit was detected."
  ${Else}
    DetailPrint "Firefox 32-bit was not detected: $Firefox32Error"
  ${EndIf}

  ${If} $Firefox64Detected == 1
    DetailPrint "Firefox 64-bit was detected."
  ${Else}
    DetailPrint "Firefox 64-bit was not detected: $Firefox64Error"
  ${EndIf}
FunctionEnd

# REGISTRY AND UNINSTALL INFORMATION INSTALLATION/UNINSTALLATION
##############################################################################
Function Reg
  WriteRegStr HKLM "Software\Namecoin\ncdns" "InstallPath" "$INSTDIR"

  # Uninstall information.
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ncdns" "DisplayName" "Namecoin ncdns"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ncdns" "UninstallString" '"$INSTDIR\uninst.exe"'
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ncdns" "QuietUninstallString" '"$INSTDIR\uninst.exe" /S'
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ncdns" "InstallLocation" "$INSTDIR"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ncdns" "DisplayIcon" "$INSTDIR\namecoin.ico"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ncdns" "Publisher" "Namecoin"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ncdns" "HelpLink" "https://www.namecoin.org/"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ncdns" "URLInfoAbout" "https://www.namecoin.org/"
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ncdns" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ncdns" "NoRepair" 1
FunctionEnd

Function un.Reg
  DeleteRegKey HKLM "Software\Namecoin\ncdns"
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ncdns"
FunctionEnd


# DNSSEC TRIGGER CHAIN INSTALLATION
##############################################################################
Function DNSSECTrigger
!ifndef NO_DNSSEC_TRIGGER
  ${If} $UnboundDetected == 1
    # Already have DNSSEC Trigger
    Return
  ${EndIf}
  ${If} $SkipUnbound == ${BST_CHECKED}
    Return
  ${EndIf}

  # Install DNSSEC Trigger
  DetailPrint "Installing DNSSEC Trigger..."
  File /oname=$TEMP\dnssec_trigger_setup.exe ${ARTIFACTS}\${DNSSEC_TRIGGER_FN}
again:
  ExecWait $TEMP\dnssec_trigger_setup.exe

  Call DetectUnbound
  ${If} $UnboundDetected == 0
    MessageBox "MB_OKCANCEL|MB_ICONSTOP" "DNSSEC Trigger was not installed correctly. Press OK to retry or Cancel to abort the installer." /SD IDCANCEL IDOK again
    Abort
  ${EndIf}

  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ncdns" "ncdns_InstalledDNSSECTrigger" 1
  Delete /REBOOTOK $TEMP\dnssec_trigger_setup.exe
!endif
FunctionEnd

Function un.DNSSECTrigger
!ifndef NO_DNSSEC_TRIGGER
  # Determine if we were responsible for installing DNSSEC Trigger; if so, we
  # should offer to uninstall it.
  ClearErrors
  ReadRegDWORD $0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ncdns" "ncdns_InstalledDNSSECTrigger"
  IfErrors done
  IntCmp $0 0 done

  # Detect DNSSEC Trigger uninstall command. If we cannot find it, don't offer
  # to uninstall it, as we don't know how.
  ClearErrors
  ReadRegStr $DNSSECTriggerUninstallCommand HKLM "Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\DnssecTrigger" "QuietUninstallString"
  IfErrors 0 found
  ReadRegStr $DNSSECTriggerUninstallCommand HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\DnssecTrigger" "QuietUninstallString"
  IfErrors 0 found
  Goto done
 
found:
  # Ask the user if they want to uninstall DNSSEC Trigger.
  MessageBox MB_YESNO|MB_ICONQUESTION "When you installed ncdns for Windows, DNSSEC Trigger was installed automatically as a necessary dependency of ncdns for Windows. Would you like to remove it? If you leave it in place, you will not be able to connect to .bit domains, but will still enjoy DNSSEC-secured domain name lookups.$\n$\nSelect Yes to remove DNSSEC Trigger." IDYES 0 IDNO done

  # Uninstall DNSSEC Trigger.
  DetailPrint "Uninstalling DNSSEC Trigger... $DNSSECTriggerUninstallCommand"
  ExecWait $DNSSECTriggerUninstallCommand
  DeleteRegValue HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ncdns" "ncdns_InstalledDNSSECTrigger"

done:
  # Didn't install/not uninstalling DNSSEC Trigger.
!endif
FunctionEnd


# NAMECOIN CORE CONFIG
##############################################################################
Function NamecoinCoreConfig
  ${If} $SkipNamecoinCore == 1
    DetailPrint "Not configuring Namecoin Core."
    Return
  ${EndIf}

  DetailPrint "Configuring Namecoin Core..."

  # We need the current user's $APPDATA for configuring Namecoin Core.
  SetShellVarContext current

  # We have to set 'server=1' in namecoin.conf. We can use cookies to get the
  # rest, so that's all we need.
  #
  # The Namecoin Core installer provides the user an option to launch Namecoin
  # Core at the end. Therefore, we must do this before we launch the Namecoin Core
  # installer.
  #
  ClearErrors
  ReadRegStr $NamecoinCoreDataDir HKCU "Software\Namecoin\Namecoin-Qt" "strDataDir"
  IfErrors 0 haveDataDir

  # We need to set the data directory pre-emptively so we can put a new namecoin.conf
  # there.
  StrCpy $NamecoinCoreDataDir "$APPDATA\Namecoin"
  WriteRegStr HKCU "Software\Namecoin\Namecoin-Qt" "strDataDir" $NamecoinCoreDataDir

haveDataDir:
  DetailPrint 'Creating directory "$NamecoinCoreDataDir"...'
  CreateDirectory $NamecoinCoreDataDir

  # Configure cookie directory.
  CreateDirectory C:\ProgramData\NamecoinCookie
  nsExec::ExecToLog 'icacls "C:\ProgramData\NamecoinCookie" /inheritance:r /T /grant "SYSTEM:(OI)(CI)F" "Administrators:(OI)(CI)F" "Users:(OI)(CI)F"'
  nsExec::ExecToLog 'icacls "C:\ProgramData\NamecoinCookie\.cookie" /reset'

  # Now we need to make sure namecoin.conf exists and has 'server=1'.
  # We'll do this with a powershell script, much as we do for configuring Unbound.

  # Execute confignamecoinconf.ps1.
  File /oname=$PLUGINSDIR\confignamecoinconf.ps1 confignamecoinconf.ps1
  FileOpen $4 "$PLUGINSDIR\confignamecoinconf.cmd" w
  FileWrite $4 'powershell -executionpolicy bypass -noninteractive -file "$PLUGINSDIR\confignamecoinconf.ps1" '
  FileWrite $4 '"$NamecoinCoreDataDir" < nul'
  FileClose $4
  nsExec::ExecToLog '$PLUGINSDIR\confignamecoinconf.cmd'
  Delete $PLUGINSDIR\confignamecoinconf.ps1
  Delete $PLUGINSDIR\confignamecoinconf.cmd

  # Restore SetShellVarContext
  SetShellVarContext all
FunctionEnd


# NAMECOIN CORE CHAIN INSTALLATION
##############################################################################
Function NamecoinCore
!ifndef NO_NAMECOIN_CORE
  ${If} $NamecoinCoreDetected == 1
    # Already have Namecoin Core
    DetailPrint "An existing Namecoin Core installation was detected. Not installing."
    Return
  ${EndIf}
  DetailPrint "An existing Namecoin Core installation was NOT detected."

  ${If} $SkipNamecoinCore == ${BST_CHECKED}
    DetailPrint "Not installing Namecoin Core."
    Return
  ${EndIf}

  # Install Namecoin Core
  DetailPrint "Installing Namecoin Core..."
  File /oname=$TEMP\namecoin-setup-unsigned.exe ${ARTIFACTS}\${NAMECOIN_FN}
again:
  ExecWait $TEMP\namecoin-setup-unsigned.exe

  Call DetectNamecoinCore
  ${If} $NamecoinCoreDetected == 0
    MessageBox "MB_OKCANCEL|MB_ICONSTOP" "Namecoin Core was not installed correctly. Press OK to retry or Cancel to abort the installer." /SD IDCANCEL IDOK again
    Abort
  ${EndIf}

  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ncdns" "ncdns_InstalledNamecoinCore" 1
  Delete /REBOOTOK $TEMP\namecoin-setup-unsigned.exe
!endif
FunctionEnd

Function un.NamecoinCore
!ifndef NO_NAMECOIN_CORE
  # Determine if we were responsible for installing Namecoin Core; if so, we
  # should uninstall it.
  ClearErrors
  ReadRegDWORD $0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ncdns" "ncdns_InstalledNamecoinCore"
  IfErrors done
  IntCmp $0 0 done

  # Detect Namecoin Core uninstall command. If we cannot find it, don't offer
  # to uninstall it, as we don't know how.
  ClearErrors
!ifdef NCDNS_64BIT
  ReadRegStr $NamecoinCoreUninstallCommand HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Namecoin Core (64-bit)" "UninstallString"
!else
  ReadRegStr $NamecoinCoreUninstallCommand HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Namecoin Core (32-bit)" "UninstallString"
!endif
  IfErrors 0 found
  Goto done

found:
  # Ask the user if they want to uninstall Namecoin Core
  MessageBox MB_YESNO|MB_ICONQUESTION "When you installed ncdns for Windows, Namecoin Core was installed automatically as a necessary dependency of ncdns for Windows. Would you like to remove it? If you leave it in place, you will not be able to connect to .bit domains, but will still be able to use Namecoin Core as a Namecoin node and wallet.$\n$\nSelect Yes to remove Namecoin Core." IDYES 0 IDNO done

  # Uninstall Namecoin Core.
  DetailPrint "Uninstalling Namecoin Core... $NamecoinCoreUninstallCommand"
  ExecWait $NamecoinCoreUninstallCommand
  DeleteRegValue HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ncdns" "ncdns_InstalledNamecoinCore"

done:
  # Didn't install/not uninstalling Namecoin Core.
!endif
FunctionEnd


# BITCOINJ INSTALLATION
##############################################################################
Function BitcoinJ
!ifndef NO_BITCOINJ
  ${If} $UseSPV == ${BST_UNCHECKED}
    # User did not elect to use SPV.
    DetailPrint "Not installing BitcoinJ."
    Return
  ${EndIf}

  # Install BitcoinJ
  DetailPrint "Installing BitcoinJ..."
  CreateDirectory $INSTDIR\BitcoinJ
  File /oname=$INSTDIR\BitcoinJ\bitcoinj-daemon.jar ${ARTIFACTS}\bitcoinj-daemon.jar
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ncdns" "ncdns_InstalledBitcoinJ" 1

  # Create data directory.
  CreateDirectory C:\ProgramData\NamecoinBitcoinJ

  # Configure ncdns to use BitcoinJ port.
  FileOpen $4 "$INSTDIR\etc\ncdns.conf" a
  FileSeek $4 0 END
  FileWrite $4 '$\r$\n$\r$\n## ++SPV++$\r$\n## Added automatically by installer to point ncdns to SPV client.$\r$\nnamecoinrpcaddress="127.0.0.1:6563"$\r$\n## ++/SPV++$\r$\n$\r$\n'
  FileClose $4

  # Write a batch script to enable BitcoinJ to be easily launched.
  FileOpen $4 "$INSTDIR\BitcoinJ\Launch BitcoinJ.cmd" w
  FileWrite $4 'C:$\r$\ncd "C:\ProgramData\NamecoinBitcoinJ"$\r$\njava -jar "$INSTDIR\BitcoinJ\bitcoinj-daemon.jar" --connection.proxyenabled=false --connection.streamisolation=false --namelookup.latest.algo=leveldbtxcache --server.port=6563$\r$\n'
  FileClose $4

  # Create shortcuts to the batch script.
  CreateShortcut "$SMPROGRAMS\Namecoin BitcoinJ.lnk" "$INSTDIR\BitcoinJ\Launch BitcoinJ.cmd"
  CreateShortcut "$DESKTOP\Namecoin BitcoinJ.lnk" "$INSTDIR\BitcoinJ\Launch BitcoinJ.cmd"
!endif
FunctionEnd

Function un.BitcoinJ
!ifndef NO_BITCOINJ
  # Determine if we installed BitcoinJ.
  ClearErrors
  ReadRegDWORD $0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ncdns" "ncdns_InstalledBitcoinJ"
  IfErrors done
  IntCmp $0 0 done

  # Remove BitcoinJ.
  DetailPrint "Removing BitcoinJ..."
  Delete "$SMPROGRAMS\Namecoin BitcoinJ.lnk"
  Delete "$DESKTOP\Namecoin BitcoinJ.lnk"
  Delete "$INSTDIR\BitcoinJ\Launch BitcoinJ.cmd"
  Delete /REBOOTOK $INSTDIR\BitcoinJ\bitcoinj-daemon.jar
  RMDir $INSTDIR\BitcoinJ
  DeleteRegValue HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ncdns" "ncdns_InstalledBitcoinJ"

done:
  # Didn't install BitcoinJ, so not uninstalling it.
!endif
FunctionEnd


# FILE INSTALLATION/UNINSTALLATION
##############################################################################
Function Files
  WriteUninstaller "uninst.exe"
  CreateDirectory $INSTDIR\bin
  CreateDirectory $INSTDIR\etc
  File /oname=$INSTDIR\namecoin.ico media\namecoin.ico
  File /oname=$INSTDIR\bin\ncdns.exe ${ARTIFACTS}\ncdns.exe
  File /oname=$INSTDIR\etc\ncdns.conf ${NEUTRAL_ARTIFACTS}\ncdns.conf
  CreateDirectory $INSTDIR\etc\ncdns.conf.d

  File /oname=$INSTDIR\bin\dnssec-keygen.exe ${ARTIFACTS}\dnssec-keygen.exe
  File /oname=$INSTDIR\bin\libisc.dll ${ARTIFACTS}\libisc.dll
  File /oname=$INSTDIR\bin\libdns.dll ${ARTIFACTS}\libdns.dll
  File /oname=$INSTDIR\bin\libeay32.dll ${ARTIFACTS}\libeay32.dll
  File /oname=$INSTDIR\bin\libxml2.dll ${ARTIFACTS}\libxml2.dll

#!if /FileExists "${ARTIFACTS}\ncdt.exe"
# This is listed in NSIS.chm but doesn't appear to be supported on the POSIX
# makensis version I'm using. Bleh.
#!endif

  File /nonfatal /oname=$INSTDIR\bin\ncdt.exe ${ARTIFACTS}\ncdt.exe
  File /nonfatal /oname=$INSTDIR\bin\ncdumpzone.exe ${ARTIFACTS}\ncdumpzone.exe
  File /nonfatal /oname=$INSTDIR\bin\generate_nmc_cert.exe ${ARTIFACTS}\generate_nmc_cert.exe
  File /nonfatal /oname=$INSTDIR\bin\q.exe ${ARTIFACTS}\q.exe
FunctionEnd

Function FilesConfig
  ${If} $SkipNamecoinCore == 1
    DetailPrint "Not configuring use of cookie auth."
    Return
  ${EndIf}

  # Configure ncdns to use cookie auth.
  DetailPrint "Configuring use of cookie auth."
  FileOpen $4 "$INSTDIR\etc\ncdns.conf" a
  FileSeek $4 0 END
  FileWrite $4 '$\r$\n$\r$\n## ++COOKIE++$\r$\n## Added automatically by installer because Namecoin Core is being used, so using cookie auth.$\r$\nnamecoinrpccookiepath="C:/ProgramData/NamecoinCookie/.cookie"$\r$\n## ++/COOKIE++$\r$\n$\r$\n'
  FileClose $4
FunctionEnd

Function FilesSecurePre
  nsExec::ExecToLog 'icacls "$INSTDIR\etc" /inheritance:r /T /grant "NT SERVICE\ncdns:(OI)(CI)R" "SYSTEM:(OI)(CI)F" "Administrators:(OI)(CI)F"'
FunctionEnd

Function FilesSecure
  # Ensure only ncdns service and administrators can read ncdns.conf.
  Call FilesSecurePre
  nsExec::ExecToLog 'icacls "$INSTDIR\etc\ncdns.conf" /reset'
  nsExec::ExecToLog 'icacls "$INSTDIR\etc\ncdns.conf.d" /reset /T'
  nsExec::ExecToLog 'icacls "$INSTDIR\etc\zsk" /reset'
  nsExec::ExecToLog 'icacls "$INSTDIR\etc\zsk\bit.private" /reset'
  nsExec::ExecToLog 'icacls "$INSTDIR\etc\zsk\bit.key" /reset'
  nsExec::ExecToLog 'icacls "$INSTDIR\etc\ksk" /reset'
  nsExec::ExecToLog 'icacls "$INSTDIR\etc\ksk\bit.private" /reset'
  nsExec::ExecToLog 'icacls "$INSTDIR\bit.key" /reset'
FunctionEnd

Function un.Files
  Delete $INSTDIR\bin\ncdns.exe
  Delete $INSTDIR\bin\dnssec-keygen.exe
  Delete $INSTDIR\bin\libisc.dll
  Delete $INSTDIR\bin\libdns.dll
  Delete $INSTDIR\bin\libeay32.dll
  Delete $INSTDIR\bin\libxml2.dll
  Delete $INSTDIR\bin\ncdt.exe
  Delete $INSTDIR\bin\ncdumpzone.exe
  Delete $INSTDIR\bin\generate_nmc_cert.exe
  Delete $INSTDIR\bin\q.exe

  Delete $INSTDIR\bin\mar-tools-32\nss-certutil.exe
  Delete $INSTDIR\bin\mar-tools-32\freebl3.dll
  Delete $INSTDIR\bin\mar-tools-32\mozglue.dll
  Delete $INSTDIR\bin\mar-tools-32\nss3.dll
  Delete $INSTDIR\bin\mar-tools-32\nssdbm3.dll
  Delete $INSTDIR\bin\mar-tools-32\softokn3.dll
  RMDir $INSTDIR\bin\mar-tools-32

  !ifdef NCDNS_64BIT
    Delete $INSTDIR\bin\mar-tools-64\nss-certutil.exe
    Delete $INSTDIR\bin\mar-tools-64\freebl3.dll
    Delete $INSTDIR\bin\mar-tools-64\mozglue.dll
    Delete $INSTDIR\bin\mar-tools-64\nss3.dll
    Delete $INSTDIR\bin\mar-tools-64\nssdbm3.dll
    Delete $INSTDIR\bin\mar-tools-64\softokn3.dll
    RMDir $INSTDIR\bin\mar-tools-64
  !endif

  Delete $INSTDIR\etc\ncdns.conf
  Delete $INSTDIR\etc\ncdns.conf.d\tls-negative-firefox.conf
  Delete $INSTDIR\etc\ncdns.conf.d\tls-positive-firefox.conf
  Delete $INSTDIR\etc\ksk\bit.private
  Delete $INSTDIR\bit.key
  Delete $INSTDIR\etc\zsk\bit.private
  Delete $INSTDIR\etc\zsk\bit.key
  RMDir $INSTDIR\bin
  RMDir $INSTDIR\etc\ksk
  RMDir $INSTDIR\etc\zsk
  RMDir $INSTDIR\etc\ncdns.conf.d
  RMDir $INSTDIR\etc\nss-temp-db
  RMDir $INSTDIR\etc
  Delete $INSTDIR\namecoin.ico
  Delete $INSTDIR\uninst.exe
FunctionEnd


# FILE INSTALLATION/UNINSTALLATION
##############################################################################
Function KeyConfig
  DetailPrint "Generating DNSSEC key..."
  File /oname=$PLUGINSDIR\keyconfig.ps1 keyconfig.ps1
  FileOpen $4 "$PLUGINSDIR\keyconfig.cmd" w
  FileWrite $4 'powershell -executionpolicy bypass -noninteractive -file "$PLUGINSDIR\keyconfig.ps1" '
  FileWrite $4 '"$INSTDIR" < nul'
  FileClose $4
  nsExec::ExecToLog '$PLUGINSDIR\keyconfig.cmd'
  Delete $PLUGINSDIR\keyconfig.ps1
  Delete $PLUGINSDIR\keyconfig.cmd
FunctionEnd


# SERVICE INSTALLATION/UNINSTALLATION
##############################################################################
Function Service
  nsExec::ExecToLog 'sc create ncdns binPath= "ncdns.tmp" start= auto error= normal obj= "NT AUTHORITY\LocalService" DisplayName= "ncdns"'
  # Use service SID.
  nsExec::ExecToLog 'sc sidtype ncdns restricted'
  nsExec::ExecToLog 'sc description ncdns "Namecoin ncdns daemon"'
  # Restrict privileges. 'sc privs' interprets an empty list as meaning no
  # privilege restriction... this one seems low-risk.
  nsExec::ExecToLog 'sc privs ncdns "SeChangeNotifyPrivilege"'
  # Set the proper image path manually rather than try to escape it properly
  # above.
  WriteRegStr HKLM "System\CurrentControlSet\Services\ncdns" "ImagePath" '"$INSTDIR\bin\ncdns.exe" "-conf=$INSTDIR\etc\ncdns.conf"'
FunctionEnd

Function ServiceStart
  nsExec::Exec 'net start ncdns'
FunctionEnd

Function un.Service
  nsExec::Exec 'net stop ncdns'
  nsExec::ExecToLog 'sc delete ncdns'
FunctionEnd


# UNBOUND CONFIGURATION
##############################################################################
Function UnboundConfig
  ${If} $SkipUnbound == 1
    Return
  ${EndIf}

  # Detect dnssec-trigger/Unbound installation.
  ClearErrors
  ReadRegStr $UnboundConfPath HKLM "Software\Wow6432Node\DnssecTrigger" "InstallLocation"
  IfErrors 0 found
  ReadRegStr $UnboundConfPath HKLM "Software\DnssecTrigger" "InstallLocation"
  IfErrors 0 found
  ReadRegStr $UnboundConfPath HKLM "Software\Wow6432Node\Unbound" "InstallLocation"
  IfErrors 0 found
  ReadRegStr $UnboundConfPath HKLM "Software\Unbound" "InstallLocation"
  IfErrors 0 found
not_found:
  DetailPrint "*** dnssec-trigger installation was NOT found, not configuring Unbound."
  StrCpy $UnboundConfPath ""
  Return

  # dnssec-trigger/Unbound is installed. Adapt the Unbound config to include from a
  # directory.
found:
  DetailPrint "*** dnssec-trigger installation WAS found, configuring Unbound."
  IfFileExists "$UnboundConfPath\unbound.conf" found2
  IfFileExists "$UnboundConfPath\service.conf" found2
  Goto not_found
found2:
  CreateDirectory "$UnboundConfPath\unbound.conf.d"

  # Unbound on Windows doesn't appear to support globbing include directives,
  # contrary to the documentation. So use this kludge instead.
  File /oname=$UnboundConfPath\rebuild-confd-list.cmd rebuild-confd-list.cmd
  nsExec::ExecToLog '"$UnboundConfPath\rebuild-confd-list.cmd"'

  # The configunbound.ps1 performs two functions:
  #   1. It ensures an appropriate include: line is added to unbound.conf.
  #   2. It fills in the path in this file and renames it.
  File /oname=$UnboundConfPath\unbound.conf.d\ncdns-inst.conf.in ncdns-inst.conf.in

  # Execute configunbound.ps1.
  File /oname=$PLUGINSDIR\configunbound.ps1 configunbound.ps1
  # We execute the script via a dynamically written batch file because Windows
  # command line escaping is very strange and has been behaving strangely if
  # done directly from NSIS. This behaves consistently.
  FileOpen $4 "$PLUGINSDIR\configunbound.cmd" w
  FileWrite $4 'powershell -executionpolicy bypass -noninteractive -file "$PLUGINSDIR\configunbound.ps1" '
  FileWrite $4 '"$UnboundConfPath" "$INSTDIR" < nul'
  FileClose $4
  nsExec::ExecToLog '$PLUGINSDIR\configunbound.cmd'
  Delete $PLUGINSDIR\configunbound.ps1
  Delete $PLUGINSDIR\configunbound.cmd

  # Add a config fragment in the newly configured directory.
  WriteRegStr HKLM "Software\Namecoin\ncdns" "UnboundFragmentLocation" "$UnboundConfPath\unbound.conf.d"
  nsExec::ExecToLog '"$UnboundConfPath\rebuild-confd-list.cmd"'

  # Windows, unbelievably, doesn't appear to have any way to restart a service
  # from the command line. stop followed by start isn't the same as a restart
  # because it doesn't restart dependencies automatically.
  nsExec::ExecToLog 'net stop /yes unbound'
  nsExec::ExecToLog 'net start unbound'
  nsExec::ExecToLog 'net start dnssectrigger'
FunctionEnd

Function un.UnboundConfig
  ClearErrors
  ReadRegStr $UnboundFragmentLocation HKLM "Software\Namecoin\ncdns" "UnboundFragmentLocation"
  IfErrors not_found 0

  # Delete the fragment which was installed, but do not deconfigure the
  # configuration directory.
  Delete $UnboundFragmentLocation\ncdns-inst.conf
  nsExec::ExecToLog '"$UnboundFragmentLocation\..\rebuild-confd-list.cmd"'

  nsExec::ExecToLog 'net stop /yes unbound'
  nsExec::ExecToLog 'net start unbound'
  nsExec::ExecToLog 'net start dnssectrigger'

not_found:
FunctionEnd


# REGISTRY PERMISSION CONFIGURATION FOR NCDNS TRUST INJECTION
##############################################################################
Function TrustConfig
  StrCpy $ChromiumFound 0
  StrCpy $ChromiumRejected 0

  File /oname=$PLUGINSDIR\tlsrestrict_chromium_tool.exe ${ARTIFACTS}\tlsrestrict_chromium_tool.exe

  # Configure Chromium installations.
  StrCpy $CurChromium_Path "$LOCALAPPDATA\Google\Chrome\User Data"
  StrCpy $CurChromium_lockfile "$LOCALAPPDATA\Google\Chrome\User Data\lockfile"
  Call ChromiumConfigAtLocSet
  StrCpy $CurChromium_Path "$LOCALAPPDATA\Google\Chrome SxS\User Data"
  StrCpy $CurChromium_lockfile "$LOCALAPPDATA\Google\Chrome SxS\User Data\lockfile"
  Call ChromiumConfigAtLocSet
  StrCpy $CurChromium_Path "$LOCALAPPDATA\Chromium\User Data"
  StrCpy $CurChromium_lockfile "$LOCALAPPDATA\Chromium\User Data\lockfile"
  Call ChromiumConfigAtLocSet

  StrCpy $CurChromium_TransportSecurity "$APPDATA\Opera Software\Opera Stable\TransportSecurity"
  StrCpy $CurChromium_lockfile "$APPDATA\Opera Software\Opera Stable\lockfile"
  Call ChromiumConfigAtLoc

  Delete $PLUGINSDIR\tlsrestrict_chromium_tool.exe

  ${If} $ChromiumFound = 0
    DetailPrint "*** Chromium support was not configured."
    Return
  ${EndIf}

  Call TrustInjectionConfig

  DetailPrint "*** Chromium support was configured."
FunctionEnd

Function un.TrustConfig
  Call un.TrustInjectionConfig
FunctionEnd

Function ChromiumConfigAtLocSet
  ClearErrors
  FindFirst $FindHandle $ProfileName $CurChromium_Path\*
again:
  IfErrors done
  DetailPrint "PFN '$ProfileName' under $CurChromium_Path"

  StrCpy $CurChromium_TransportSecurity "$CurChromium_Path\$ProfileName\TransportSecurity"
  Call ChromiumConfigAtLoc

  ClearErrors
  FindNext $FindHandle $ProfileName
  Goto again

done:
  FindClose $FindHandle
FunctionEnd

Function ChromiumConfigAtLoc
  # No-op if profile doesn't exist.
  IfFileExists "$CurChromium_TransportSecurity" 0 not_found

  # Don't re-prompt the user if they've already assented/declined once.
  ${If} $ChromiumFound = 1
    Goto chose_yes
  ${EndIf}
  ${If} $ChromiumRejected = 1
    Goto chose_no
  ${EndIf}

  # Prompt user.
reprompt:
  MessageBox MB_ICONQUESTION|MB_YESNO "You currently have Chromium or Google Chrome installed.  ncdns can enable HTTPS for Namecoin websites in Chromium/Chrome.  This will protect your communications with Namecoin-enabled websites from being easily wiretapped or tampered with in transit.  Doing this requires giving ncdns permission to modify Windows's root certificate authority list.  ncdns will not intentionally add any certificate authorities to Windows, but if an attacker were able to exploit ncdns, they might be able to wiretap or tamper with your Internet traffic (both Namecoin and non-Namecoin websites).  If you plan to access Namecoin-enabled websites on this computer from any web browser other than Chromium, Chrome, Firefox, or Tor Browser, you should not enable HTTPS for Namecoin websites in Chromium/Chrome.$\n$\nWould you like to enable HTTPS for Namecoin websites in Chromium/Chrome?" /SD IDNO IDYES chose_yes IDNO chose_no

chose_no:
  DetailPrint "*** Skipping profile because user elected not to configure Chromium/Chrome: $CurChromium_TransportSecurity"
  StrCpy $ChromiumFound 0
  StrCpy $ChromiumRejected 1
  Return

chose_yes:
  StrCpy $ChromiumFound 1
  StrCpy $ChromiumRejected 0

check_again:
  IfFileExists "$CurChromium_lockfile" 0 not_locked
  MessageBox MB_OKCANCEL "One or more copies of Google Chrome or Chromium or a Chromium-based web browser appear to be open. Please close them before proceeding, then press OK." IDOK check_again IDCANCEL 0
  Goto reprompt

not_locked:
  DetailPrint "*** Configuring Chromium/Chrome profile: $CurChromium_TransportSecurity"
  FileOpen $4 "$PLUGINSDIR\tlsrestrict_chromium.cmd" w
  FileWrite $4 '"$PLUGINSDIR\tlsrestrict_chromium_tool.exe" -tlsrestrict.chromium-ts-path="$CurChromium_TransportSecurity"'
  FileClose $4
  nsExec::ExecToLog '"$PLUGINSDIR\tlsrestrict_chromium.cmd"'
  Delete $PLUGINSDIR\tlsrestrict_chromium.cmd

not_found:
  Return
FunctionEnd

Function TrustInjectionConfig
  # Configure permissions
  File /oname=$PLUGINSDIR\regpermrun.ps1 regpermrun.ps1
  File /oname=$PLUGINSDIR\regperm.ps1 regperm.ps1
  FileOpen $4 "$PLUGINSDIR\regpermrun.cmd" w
  FileWrite $4 'powershell -executionpolicy bypass -noninteractive -file "$PLUGINSDIR\regpermrun.ps1" install < nul'
  FileClose $4
  nsExec::ExecToLog '"$PLUGINSDIR\regpermrun.cmd"'
  Delete $PLUGINSDIR\regpermrun.cmd
  Delete $PLUGINSDIR\regpermrun.ps1
  Delete $PLUGINSDIR\regperm.ps1

  FileOpen $4 "$INSTDIR\etc\ncdns.conf" a
  FileSeek $4 0 END
  FileWrite $4 '$\r$\n$\r$\n## ++TRUST++$\r$\n## Added automatically by installer because truststore mode was enabled.$\r$\n[certstore]$\r$\ncryptoapi=true$\r$\n## ++/TRUST++$\r$\n$\r$\n'
  FileClose $4
FunctionEnd

Function un.TrustInjectionConfig
  # Keep this the same as the above (NSIS forces function duplication for the uninstaller, alas.)
  File /oname=$PLUGINSDIR\regpermrun.ps1 regpermrun.ps1
  File /oname=$PLUGINSDIR\regperm.ps1 regperm.ps1
  FileOpen $4 "$PLUGINSDIR\regpermrun.cmd" w
  FileWrite $4 'powershell -executionpolicy bypass -noninteractive -file "$PLUGINSDIR\regpermrun.ps1" uninstall < nul'
  FileClose $4
  nsExec::ExecToLog '"$PLUGINSDIR\regpermrun.cmd"'
  Delete $PLUGINSDIR\regpermrun.cmd
  Delete $PLUGINSDIR\regpermrun.ps1
  Delete $PLUGINSDIR\regperm.ps1
FunctionEnd

# CONFIGURATION FOR FIREFOX TLS
##############################################################################
Function TLSFirefoxConfig
  # No-op if Firefox not detected.
  ${If} ${RunningX64}
    ${If} $Firefox64Detected == 0
      DetailPrint "*** Skipping Firefox config on 64-bit OS because Firefox 64-bit was not detected"
      Return
    ${EndIf}
  ${Else}
    ${If} $Firefox32Detected == 0
      DetailPrint "*** Skipping Firefox config on 32-bit OS because Firefox 32-bit was not detected"
      Return
    ${EndIf}
  ${EndIf}

  ${If} $UseSPV == ${BST_CHECKED}
    DetailPrint "*** Skipping Firefox config because Firefox is not compatible with ConsensusJ-Namecoin yet"
    Return
  ${EndIf}

  # Prompt user.
  MessageBox MB_ICONQUESTION|MB_YESNO "You currently have Mozilla Firefox installed.  ncdns can enable HTTPS for Namecoin websites in Firefox.  This will protect your communications with Namecoin-enabled websites from being easily wiretapped or tampered with in transit.  Doing this requires giving ncdns permission to modify Firefox's profile folder.  ncdns will use this permission to add certificate overrides for legitimate self-signed Namecoin TLS certificates, and to apply name constraints that prevent public certificate authorities from issuing Namecoin TLS certificates.  ncdns will not intentionally do anything else with this permission, but if an attacker were able to exploit ncdns, they might be able to compromise your Firefox installation.$\n$\nWould you like to enable HTTPS for Namecoin websites in Firefox?" /SD IDNO IDYES chose_yes IDNO chose_no

chose_no:
  DetailPrint "*** Skipping Firefox config because user elected not to configure Firefox"
  StrCpy $FirefoxRejected 1
  Return

chose_yes:
  DetailPrint "*** User elected to configure Firefox"
  StrCpy $FirefoxRejected 0

  DetailPrint "*** Firefox: Installing 32-bit mar-tools"
  CreateDirectory $INSTDIR\bin\mar-tools-32
  File /oname=$INSTDIR\bin\mar-tools-32\nss-certutil.exe ${ARTIFACTS}\mar-tools-32\nss-certutil.exe
  File /oname=$INSTDIR\bin\mar-tools-32\freebl3.dll ${ARTIFACTS}\mar-tools-32\freebl3.dll
  File /oname=$INSTDIR\bin\mar-tools-32\mozglue.dll ${ARTIFACTS}\mar-tools-32\mozglue.dll
  File /oname=$INSTDIR\bin\mar-tools-32\nss3.dll ${ARTIFACTS}\mar-tools-32\nss3.dll
  File /oname=$INSTDIR\bin\mar-tools-32\nssdbm3.dll ${ARTIFACTS}\mar-tools-32\nssdbm3.dll
  File /oname=$INSTDIR\bin\mar-tools-32\softokn3.dll ${ARTIFACTS}\mar-tools-32\softokn3.dll

  !ifdef NCDNS_64BIT
    DetailPrint "*** Firefox: Installing 64-bit mar-tools"
    CreateDirectory $INSTDIR\bin\mar-tools-64
    File /oname=$INSTDIR\bin\mar-tools-64\nss-certutil.exe ${ARTIFACTS}\mar-tools-64\nss-certutil.exe
    File /oname=$INSTDIR\bin\mar-tools-64\freebl3.dll ${ARTIFACTS}\mar-tools-64\freebl3.dll
    File /oname=$INSTDIR\bin\mar-tools-64\mozglue.dll ${ARTIFACTS}\mar-tools-64\mozglue.dll
    File /oname=$INSTDIR\bin\mar-tools-64\nss3.dll ${ARTIFACTS}\mar-tools-64\nss3.dll
    File /oname=$INSTDIR\bin\mar-tools-64\nssdbm3.dll ${ARTIFACTS}\mar-tools-64\nssdbm3.dll
    File /oname=$INSTDIR\bin\mar-tools-64\softokn3.dll ${ARTIFACTS}\mar-tools-64\softokn3.dll
  !endif

  DetailPrint "*** Firefox: Calculating temporary DB directory..."
  StrCpy $FirefoxTempDBDirectoryBackSlashes "$INSTDIR\etc\nss-temp-db"
  DetailPrint "*** Firefox: Temporary DB directory (backslash format) is $FirefoxTempDBDirectoryBackSlashes"
  ${StrRep} $FirefoxTempDBDirectoryForwardSlashes "$FirefoxTempDBDirectoryBackSlashes" "\" "/"
  DetailPrint "*** Firefox: Temporary DB directory (forward-slash format) is $FirefoxTempDBDirectoryForwardSlashes"

  DetailPrint "*** Firefox: Creating temporary DB directory $FirefoxTempDBDirectoryBackSlashes"
  CreateDirectory "$FirefoxTempDBDirectoryBackSlashes"
  DetailPrint "*** Firefox: Granting ncdns modify permission for temporary DB directory $FirefoxTempDBDirectoryBackSlashes"
  nsExec::ExecToLog 'icacls "$FirefoxTempDBDirectoryBackSlashes" /inheritance:r /T /grant "NT SERVICE\ncdns:(OI)(CI)M" "SYSTEM:(OI)(CI)F" "Administrators:(OI)(CI)F"'

  DetailPrint "*** Firefox: Granting ncdns modify permission for Firefox profile directory $FirefoxProfileDirectoryBackSlashes"
  # TODO: can we restrict this to only cert_override.txt and the NSS DB files?
  # Note: we don't use /inheritance:r here because it would prevent normal users from using Firefox.
  nsExec::ExecToLog 'icacls "$FirefoxProfileDirectoryBackSlashes" /T /grant "NT SERVICE\ncdns:(OI)(CI)M"'

  DetailPrint "*** Firefox: Granting ncdns read permission for CKBI in Firefox install directory $FirefoxInstallDirectoryBackSlashes"
  # Note: we don't use /inheritance:r here because it would prevent normal users from using Firefox.
  nsExec::ExecToLog 'icacls "$FirefoxInstallDirectoryBackSlashes" /T /grant "NT SERVICE\ncdns:(OI)(CI)R"'

  DetailPrint "*** Firefox: Granting ncdns read permission for Firefox version in Windows registry"
  File /oname=$PLUGINSDIR\regpermfirefoxversion.ps1 regpermfirefoxversion.ps1
  FileOpen $4 "$PLUGINSDIR\regpermfirefoxversion.cmd" w
  FileWrite $4 'powershell -executionpolicy bypass -noninteractive -file "$PLUGINSDIR\regpermfirefoxversion.ps1" install < nul'
  FileClose $4
  nsExec::ExecToLog '"$PLUGINSDIR\regpermfirefoxversion.cmd"'
  Delete $PLUGINSDIR\regpermfirefoxversion.cmd
  Delete $PLUGINSDIR\regpermfirefoxversion.ps1

  # Write the ncdns config for TLS/Negative/Firefox
  DetailPrint "*** Firefox: Creating tls-negative-firefox.conf"
  File /oname=$INSTDIR\etc\ncdns.conf.d\tls-negative-firefox.conf ${NEUTRAL_ARTIFACTS}\tls-negative-firefox.conf
  FileOpen $4 "$INSTDIR\etc\ncdns.conf.d\tls-negative-firefox.conf" a
  FileSeek $4 0 END
  FileWrite $4 'nss-ckbi-dir="$FirefoxInstallDirectoryForwardSlashes"$\r$\n'
  FileWrite $4 'nss-temp-db-dir="$FirefoxTempDBDirectoryForwardSlashes"$\r$\n'
  FileWrite $4 'nss-dest-db-dir="$FirefoxProfileDirectoryForwardSlashes"$\r$\n'
  FileClose $4

  # Write the ncdns config for TLS/Positive/Firefox
  DetailPrint "*** Firefox: Creating tls-positive-firefox.conf"
  File /oname=$INSTDIR\etc\ncdns.conf.d\tls-positive-firefox.conf ${NEUTRAL_ARTIFACTS}\tls-positive-firefox.conf
  FileOpen $4 "$INSTDIR\etc\ncdns.conf.d\tls-positive-firefox.conf" a
  FileSeek $4 0 END
  FileWrite $4 'profiledir="$FirefoxProfileDirectoryForwardSlashes"$\r$\n'
  FileClose $4

  DetailPrint "*** Firefox: Finished configuration"
FunctionEnd

#
##############################################################################
Function ConfigSections
  SectionSetFlags ${Sec_ncdns} 25
FunctionEnd
