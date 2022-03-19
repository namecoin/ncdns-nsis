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
!include "FileFunc.nsh"


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

# From https://docs.microsoft.com/en-US/windows/security/identity-protection/access-control/security-identifiers
!define SID_SYSTEM "*S-1-5-18"
!define SID_ADMINISTRATORS "*S-1-5-32-544"
!define SID_USERS "*S-1-5-32-545"

!include "namecoin-dialog.nsdinc"
!include "dns-dialog.nsdinc"
!include "darknet-dialog.nsdinc"
!include "tls-positive-dialog.nsdinc"
!include "tls-negative-dialog.nsdinc"

!include "exectolog.nsh"

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
Page custom NamecoinDialogCreate NamecoinDialogLeave
Page custom DNSDialogCreate DNSDialogLeave
Page custom DarknetDialogCreate DarknetDialogLeave
Page custom TLSPositiveDialogCreate TLSPositiveDialogLeave
Page custom TLSNegativeDialogCreate TLSNegativeDialogLeave
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
VIAddVersionKey "CompanyName" "Namecoin Project"
VIAddVersionKey "LegalCopyright" "2017-2021 Namecoin Developers"
VIAddVersionKey "LegalTrademarks" "ncdns, Namecoin"
VIAddVersionKey "Comments" "ncdns Installer"


# VARIABLES
##############################################################################
Var /GLOBAL UnboundConfPath
Var /GLOBAL UnboundFragmentLocation
Var /GLOBAL DNSSECTriggerUninstallCommand
Var /GLOBAL NamecoinCoreUninstallCommand
Var /GLOBAL ElectrumNMCUninstallCommand
Var /GLOBAL NamecoinCoreDataDir
Var /GLOBAL UseUnbound
Var /GLOBAL UseNamecoinCore
Var /GLOBAL UseConsensusJ
Var /GLOBAL UseElectrumNMC
Var /GLOBAL UseTorBrowser
Var /GLOBAL UseTorSwitch

Var /GLOBAL NamecoinCoreDetected
Var /GLOBAL ElectrumNMCDetected
Var /GLOBAL UnboundDetected
Var /GLOBAL TorBrowserDetected
Var /GLOBAL TorBrowserDetectReturnCode

Var /GLOBAL CryptoAPIInjectionEnabled
Var /GLOBAL CryptoAPIEncayaEnabled
Var /GLOBAL CryptoAPINameConstraintsEnabled
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
Var /GLOBAL ETLD

Var /GLOBAL ElectrumNMCConfigReturnCode
Var /GLOBAL ElectrumNMCConfigOutput
Var /GLOBAL ServiceNcdnsCreateReturnCode
Var /GLOBAL ServiceNcdnsSidtypeReturnCode
Var /GLOBAL ServiceNcdnsDescriptionReturnCode
Var /GLOBAL ServiceNcdnsPrivsReturnCode
Var /GLOBAL ServiceNcdnsStartReturnCode
Var /GLOBAL ServiceEncayaCreateReturnCode
Var /GLOBAL ServiceEncayaSidtypeReturnCode
Var /GLOBAL ServiceEncayaDescriptionReturnCode
Var /GLOBAL ServiceEncayaPrivsReturnCode
Var /GLOBAL ServiceEncayaStartReturnCode
Var /GLOBAL ServiceStemNSCreateReturnCode
Var /GLOBAL ServiceStemNSSidtypeReturnCode
Var /GLOBAL ServiceStemNSDescriptionReturnCode
Var /GLOBAL ServiceStemNSPrivsReturnCode
Var /GLOBAL ServiceStemNSFailureReturnCode
Var /GLOBAL ServiceStemNSStartReturnCode
Var /GLOBAL CoreCookieDirReturnCode
Var /GLOBAL CoreCookieFileReturnCode
Var /GLOBAL EtcReturnCode
Var /GLOBAL EtcConfReturnCode
Var /GLOBAL EtcConfDReturnCode
Var /GLOBAL EtcConfElectrumReturnCode
Var /GLOBAL EtcConfXlogReturnCode
Var /GLOBAL EtcZskReturnCode
Var /GLOBAL EtcZskPrivReturnCode
Var /GLOBAL EtcZskPubReturnCode
Var /GLOBAL EtcKskReturnCode
Var /GLOBAL EtcKskPrivReturnCode
Var /GLOBAL EtcKskPubReturnCode
Var /GLOBAL EtcEncayaReturnCode
Var /GLOBAL EtcEncayaConfDReturnCode
Var /GLOBAL EtcEncayaConfReturnCode
Var /GLOBAL EtcEncayaConfXlogReturnCode
Var /GLOBAL EtcEncayaRootKeyReturnCode
Var /GLOBAL EtcEncayaListenChainReturnCode
Var /GLOBAL EtcEncayaListenKeyReturnCode
Var /GLOBAL EtcEncayaRootCertReturnCode
Var /GLOBAL EtcNCProp279ReturnCode
Var /GLOBAL EtcNCProp279ConfDReturnCode
Var /GLOBAL EtcNCProp279ConfCoreReturnCode
Var /GLOBAL EtcNCProp279ConfConsensusJReturnCode
Var /GLOBAL EtcNCProp279ConfElectrumReturnCode
Var /GLOBAL KeyDNSSECReturnCode
Var /GLOBAL KeyEncayaReturnCode
Var /GLOBAL TorRunningReturnCode
Var /GLOBAL TorBrowserConfigReturnCode

# PRELAUNCH CHECKS
##############################################################################
!Include WinVer.nsh
!include x64.nsh

Function .onInit
  ${IfNot} ${AtLeastWinVista}
    MessageBox "MB_OK|MB_ICONSTOP" "ncdns requires Windows Vista or later." /SD IDOK
    Abort
  ${EndIf}

  # verifyctl.cmd uses "certutil -v -f -verifyCTL AuthRootWU".
  # The verifyCTL command exists on Windows 8.0 Pro Build 9200, but is
  # unavailable on Windows 7 and Windows Server 2008 R2 Standard Full.
  ${IfNot} ${AtLeastWin8}
    MessageBox "MB_OKCANCEL|MB_ICONEXCLAMATION" "ncdns works best with Windows 8 or later.  If you install ncdns, you will have degraded security.  Would you like to continue installing anyway?" /SD IDOK IDOK win7okay IDCANCEL 0
    Abort
win7okay:
  ${EndIf}

  SetShellVarContext all

  # Make sections mandatory.
  Call ConfigSections

  # Detect if already installed.
  Call CheckReinstall

  # Detect already installed dependencies.
  Call DetectNamecoinCore
  Call DetectElectrumNMC
  Call DetectUnbound
  Call DetectTorBrowser
  Call DetectJRE
  Call DetectVC2010_x86_32
  Call DetectVC2010_x86_64
  Call DetectVC2012_x86_32
  Call DetectVC2012_x86_64
  Call DetectVC2015_x86_32
  Call DetectVC2015_x86_64
  Call DetectBindRequirements
  Call DetectBitcoinJRequirements

  Call DetectETLD

  # Default components: Namecoin
  Push ${BST_CHECKED}
  Pop $UseNamecoinCore
  Push ${BST_UNCHECKED}
  Pop $UseConsensusJ
  Push ${BST_UNCHECKED}
  Pop $UseElectrumNMC

  # Default components: DNS
  Push ${BST_CHECKED}
  Pop $UseUnbound

  # Default components: TLS
  Push ${BST_CHECKED}
  Pop $CryptoAPIInjectionEnabled
  Push ${BST_CHECKED}
  Pop $CryptoAPIEncayaEnabled
  Push ${BST_CHECKED}
  Pop $CryptoAPINameConstraintsEnabled

  Call FailIfBindRequirementsNotMet
FunctionEnd

Function un.onInit
  SetShellVarContext all
FunctionEnd

Function CheckReinstall
  ClearErrors
  ReadRegStr $0 HKLM "System\CurrentControlSet\Services\ncdns" "ImagePath"
  IfErrors not_installed

  MessageBox "MB_OK|MB_ICONSTOP" "ncdns for Windows is already installed.$\n$\nTo reinstall ncdns for Windows, first uninstall it." /SD IDOK
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

Function DetectElectrumNMC
  ClearErrors
  ReadRegStr $0 HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Electrum-NMC" "UninstallString"
  IfErrors 0 found
  Goto absent
found:
  Push 1
  Pop $ElectrumNMCDetected
  Return
absent:
  Push 0
  Pop $ElectrumNMCDetected
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

Function DetectTorBrowser
  File /oname=$PLUGINSDIR\detecttorbrowser.ps1 detecttorbrowser.ps1
  File /oname=$PLUGINSDIR\detecttorbrowserchannel.ps1 detecttorbrowserchannel.ps1
  SetOutPath "$PLUGINSDIR"
  nsExec::ExecToStack 'powershell -executionpolicy bypass -noninteractive -file "$PLUGINSDIR\detecttorbrowser.ps1"'
  Pop $TorBrowserDetectReturnCode
  Pop $TorBrowserDetected
  Delete $PLUGINSDIR\detecttorbrowserchannel.ps1
  Delete $PLUGINSDIR\detecttorbrowser.ps1
  SetOutPath "$INSTDIR"
  ${If} $TorBrowserDetectReturnCode != 0
    MessageBox "MB_OK|MB_ICONSTOP" "Failed to detect Tor Browser." /SD IDOK
    Abort
  ${EndIf}
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
  # BIND's binaries link against the Visual C++ 2015 Redistributable.  Older
  # versions linked against the Visual C++ 2012 Redistributable, but current
  # versions don't.

  ${If} ${RunningX64}
    #${If} $VC2012_x86_64Detected == 0
    #  Push 0
    #  Pop $BindRequirementsMet
    #  StrCpy $BindRequirementsURL "https://www.microsoft.com/en-us/download/details.aspx?id=30679"
    #  StrCpy $BindRequirementsError "ncdns for Windows requires the Microsoft Visual C++ 2012 (64-bit) Redistributable.$\n$\nYou can download it from:$\n$BindRequirementsURL"
    #  Return
    #${EndIf}
    ${If} $VC2015_x86_64Detected == 0
      Push 0
      Pop $BindRequirementsMet
      StrCpy $BindRequirementsURL "https://www.microsoft.com/en-us/download/details.aspx?id=53587"
      StrCpy $BindRequirementsError "ncdns for Windows requires the Microsoft Visual C++ 2015 (64-bit) Redistributable.$\n$\nYou can download it from:$\n$BindRequirementsURL"
      Return
    ${EndIf}
  ${Else}
    #${If} $VC2012_x86_32Detected == 0
    #  Push 0
    #  Pop $BindRequirementsMet
    #  StrCpy $BindRequirementsURL "https://www.microsoft.com/en-us/download/details.aspx?id=30679"
    #  StrCpy $BindRequirementsError "ncdns for Windows requires the Microsoft Visual C++ 2012 (32-bit) Redistributable.$\n$\nYou can download it from:$\n$BindRequirementsURL"
    #  Return
    #${EndIf}
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
    MessageBox "MB_OK|MB_ICONSTOP" "$BindRequirementsError" /SD IDOK
    IfSilent abort_silently
    ExecShell "open" "$BindRequirementsURL"
abort_silently:
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

Function DetectETLD
  ClearErrors
  ${GetOptions} $CMDLINE "/ETLD=" $ETLD
  IfErrors 0 found

  # If not found, use this default
  StrCpy $ETLD "bit"

found:
FunctionEnd

# DIALOG HELPERS
##############################################################################
Function ShowCallback
  SendMessage $mui.WelcomePage.Text ${WM_SETTEXT} 0 "STR:$(MUI_TEXT_WELCOME_INFO_TEXT)$\n$\nThis software is open source and licenced under the GPLv3 License. It is distributed WITHOUT ANY WARRANTY."
FunctionEnd


Function NamecoinDialogCreate
  Call NamecoinDialog_CreateSkeleton

  # Restore state
  ${NSD_SetState} $NamecoinDialog_Core $UseNamecoinCore
  ${NSD_SetState} $NamecoinDialog_ConsensusJ $UseConsensusJ
  ${NSD_SetState} $NamecoinDialog_Electrum $UseElectrumNMC
  ${If} $UseNamecoinCore == ${BST_UNCHECKED}
  ${AndIf} $UseConsensusJ == ${BST_UNCHECKED}
  ${AndIf} $UseElectrumNMC == ${BST_UNCHECKED}
    ${NSD_Check} $NamecoinDialog_Manual
  ${Else}
    ${NSD_Uncheck} $NamecoinDialog_Manual
  ${EndIf}

  ${If} $NamecoinCoreDetected == 1
    ${NSD_SetText} $NamecoinDialog_Status "An existing Namecoin Core installation was detected."
    ${NSD_SetText} $NamecoinDialog_Core "Automatically configure Namecoin Core (recommended)"
    ${If} $BitcoinJRequirementsMet == 1
      ${NSD_SetText} $NamecoinDialog_ConsensusJ "Install and use ConsensusJ-Namecoin instead (lighter, less secure)"
    ${Else}
      ${NSD_SetText} $NamecoinDialog_ConsensusJ "Cannot use ConsensusJ-Namecoin ($BitcoinJRequirementsError)"
      EnableWindow $NamecoinDialog_ConsensusJ 0
    ${EndIf}
    ${NSD_SetText} $NamecoinDialog_Manual "I will configure Namecoin Core myself (manual configuration required)"
  ${Else}
    ${NSD_SetText} $NamecoinDialog_Status "An existing Namecoin Core installation was not detected."
    ${If} $BitcoinJRequirementsMet == 1
      ${NSD_SetText} $NamecoinDialog_Core "Install and configure Namecoin Core (heavier, more secure)"
      ${NSD_SetText} $NamecoinDialog_ConsensusJ "Install and use ConsensusJ-Namecoin (lighter, less secure)"
    ${Else}
      ${NSD_SetText} $NamecoinDialog_Core "Install and configure Namecoin Core (recommended)"
      ${NSD_SetText} $NamecoinDialog_ConsensusJ "Cannot use ConsensusJ-Namecoin ($BitcoinJRequirementsError)"
      EnableWindow $NamecoinDialog_ConsensusJ 0
    ${EndIf}
    ${NSD_SetText} $NamecoinDialog_Manual "I will provide my own Namecoin node (manual configuration required)"
  ${EndIf}

  ${If} $ElectrumNMCDetected == 1
    ${NSD_SetText} $NamecoinDialog_Electrum "Automatically configure Electrum-NMC (lighter, less secure)"
  ${Else}
    ${NSD_SetText} $NamecoinDialog_Electrum "Install and configure Electrum-NMC (lighter, less secure)"
  ${EndIf}

  nsDialogs::Show
FunctionEnd

Function NamecoinDialogLeave
  ${NSD_GetState} $NamecoinDialog_Core $UseNamecoinCore
  ${NSD_GetState} $NamecoinDialog_ConsensusJ $UseConsensusJ
  ${NSD_GetState} $NamecoinDialog_Electrum $UseElectrumNMC
FunctionEnd

Function DNSDialogCreate
  Call DNSDialog_CreateSkeleton

  # Restore state
  ${NSD_SetState} $DNSDialog_Unbound $UseUnbound
  ${If} $UseUnbound == ${BST_UNCHECKED}
    ${NSD_Check} $DNSDialog_Manual
  ${Else}
    ${NSD_Uncheck} $DNSDialog_Manual
  ${EndIf}

  ${If} $UnboundDetected == 1
    ${NSD_SetText} $DNSDialog_Status "An existing Unbound installation was detected."
    ${NSD_SetText} $DNSDialog_Unbound "Automatically configure Unbound (recommended)"
    ${NSD_SetText} $DNSDialog_Manual "I will configure Unbound myself (manual configuration required)"
  ${Else}
    ${NSD_SetText} $DNSDialog_Status "An existing Unbound installation was not detected."
    ${NSD_SetText} $DNSDialog_Unbound "Install and configure Unbound/DNSSEC Trigger (recommended)"
    ${NSD_SetText} $DNSDialog_Manual "I will provide my own DNS resolver (manual configuration required)"
  ${EndIf}

  nsDialogs::Show
FunctionEnd

Function DNSDialogLeave
  ${NSD_GetState} $DNSDialog_Unbound $UseUnbound
FunctionEnd

Function DarknetDialogCreate
  Call DarknetDialog_CreateSkeleton

  ${If} $TorBrowserDetected != ""
    ${NSD_SetText} $DarknetDialog_TorStatus "An existing Tor Browser installation was detected."
    # Restore state
    ${NSD_SetState} $DarknetDialog_Tor $UseTorBrowser
  ${Else}
    ${NSD_SetText} $DarknetDialog_TorStatus "An existing Tor Browser installation was not detected."
    ${NSD_SetState} $DarknetDialog_Tor ${BST_UNCHECKED}
    EnableWindow $DarknetDialog_Tor 0
  ${EndIf}

  nsDialogs::Show
FunctionEnd

Function DarknetDialogLeave
  ${NSD_GetState} $DarknetDialog_Tor $UseTorBrowser

  Push ""
  Pop $UseTorSwitch
  ${If} $UseTorBrowser == ${BST_CHECKED}
    Push "-use_tor"
    Pop $UseTorSwitch
  ${EndIf}
FunctionEnd

Function TLSPositiveDialogCreate
  Call TLSPositiveDialog_CreateSkeleton

  # Restore state
  ${NSD_SetState} $TLSPositiveDialog_CryptoAPILayer1 $CryptoAPIInjectionEnabled
  ${NSD_SetState} $TLSPositiveDialog_CryptoAPILayer2 $CryptoAPIEncayaEnabled

  nsDialogs::Show
FunctionEnd

Function TLSPositiveDialogLeave
  ${NSD_GetState} $TLSPositiveDialog_CryptoAPILayer1 $CryptoAPIInjectionEnabled
  ${NSD_GetState} $TLSPositiveDialog_CryptoAPILayer2 $CryptoAPIEncayaEnabled
FunctionEnd

Function TLSNegativeDialogCreate
  Call TLSNegativeDialog_CreateSkeleton

  # Restore state
  ${NSD_SetState} $TLSNegativeDialog_CryptoAPINCProp $CryptoAPINameConstraintsEnabled

  nsDialogs::Show
FunctionEnd

Function TLSNegativeDialogLeave
  ${NSD_GetState} $TLSNegativeDialog_CryptoAPINCProp $CryptoAPINameConstraintsEnabled
FunctionEnd


# INSTALL SECTIONS
##############################################################################
Section "ncdns" Sec_ncdns
  !ifdef ENABLE_LOGGING
    LogSet on
  !endif
  SetOutPath $INSTDIR
  Call LogRequirementsChecks
  Call Reg
  Call DNSSECTrigger
  Call NamecoinCoreConfig
  Call NamecoinCore
  Call ElectrumNMC
  Call ServiceNcdns
  Call Files
  Call FilesConfig
  Call BitcoinJ
  Call TrustConfig
  Call ServiceEncaya
  Call ServiceStemNS
  Call FilesSecurePre
  Call KeyConfigDNSSEC
  Call ElectrumNMCConfig
  Call FilesSecure
  Call FilesSecureEncayaPre
  Call KeyConfigEncaya
  Call FilesSecureEncaya
  Call CertInjectEncaya
  Call ServiceNcdnsEventLog
  Call ServiceNcdnsStart
  Call ServiceEncayaEventLog
  Call ServiceEncayaStart
  Call UnboundConfig
  Call TorBrowserConfig
  Call ServiceStemNSEventLog
  Call ServiceStemNSStart

  AddSize 12288  # Disk space estimation.
SectionEnd


# UNINSTALL SECTIONS
##############################################################################
Section "Uninstall"
  Call un.UnboundConfig
  Call un.TrustConfig
  Call un.ServiceNcdns
  Call un.ServiceEncaya
  Call un.ServiceStemNS
  Call un.TrustEncayaConfig
  Call un.TorBrowserConfig
  Call un.Files
  Call un.NamecoinCore
  Call un.ElectrumNMC
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

  DetailPrint "Using eTLD $ETLD."
FunctionEnd

# REGISTRY AND UNINSTALL INFORMATION INSTALLATION/UNINSTALLATION
##############################################################################
Function Reg
  WriteRegStr HKLM "Software\Namecoin\ncdns" "InstallPath" "$INSTDIR"

  # Uninstall information.
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ncdns" "DisplayName" "Namecoin ncdns"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ncdns" "DisplayVersion" "${NCDNS_PRODVER}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ncdns" "UninstallString" '"$INSTDIR\uninst.exe"'
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ncdns" "QuietUninstallString" '"$INSTDIR\uninst.exe" /S'
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ncdns" "InstallLocation" "$INSTDIR"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ncdns" "DisplayIcon" "$INSTDIR\namecoin.ico"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ncdns" "Publisher" "Namecoin Project"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ncdns" "HelpLink" "https://www.namecoin.org/"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ncdns" "URLInfoAbout" "https://www.namecoin.org/"
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ncdns" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ncdns" "NoRepair" 1
FunctionEnd

Function un.Reg
  DeleteRegKey HKLM "Software\Namecoin\ncdns"
  DeleteRegKey HKLM "System\CurrentControlSet\Services\EventLog\Application\ncdns"
  DeleteRegKey HKLM "System\CurrentControlSet\Services\EventLog\Application\encaya"
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ncdns"
FunctionEnd


# DNSSEC TRIGGER CHAIN INSTALLATION
##############################################################################
Function DNSSECTrigger
!ifndef NO_DNSSEC_TRIGGER
  ${If} $UnboundDetected == 1
    # Already have Unbound
    DetailPrint "An existing Unbound installation was detected. Not installing."
    Return
  ${EndIf}
  ${If} $UseUnbound == ${BST_UNCHECKED}
    DetailPrint "Not installing DNSSEC Trigger."
    Return
  ${EndIf}

  # Install DNSSEC Trigger
  DetailPrint "Installing DNSSEC Trigger..."
  File /oname=$PLUGINSDIR\dnssec_trigger_setup.exe ${ARTIFACTS}\${DNSSEC_TRIGGER_FN}
again:
  IfSilent install_silent
  # Install with NSIS GUI
  ExecWait '"$PLUGINSDIR\dnssec_trigger_setup.exe"'
  Goto detect
install_silent:
  ExecWait '"$PLUGINSDIR\dnssec_trigger_setup.exe" /S'

detect:
  Call DetectUnbound
  ${If} $UnboundDetected == 0
    MessageBox "MB_OKCANCEL|MB_ICONSTOP" "DNSSEC Trigger was not installed correctly. Press OK to retry or Cancel to abort the installer." /SD IDCANCEL IDOK again
    Abort
  ${EndIf}

  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ncdns" "ncdns_InstalledDNSSECTrigger" 1
  Delete /REBOOTOK $PLUGINSDIR\dnssec_trigger_setup.exe
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
  MessageBox MB_YESNO|MB_ICONQUESTION "When you installed ncdns for Windows, DNSSEC Trigger was installed automatically as a necessary dependency of ncdns for Windows. Would you like to remove it? If you leave it in place, you will not be able to connect to .bit domains, but will still enjoy DNSSEC-secured domain name lookups.$\n$\nSelect Yes to remove DNSSEC Trigger." /SD IDYES IDYES 0 IDNO done

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
  ${If} $UseNamecoinCore == ${BST_UNCHECKED}
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
  ${ExecToLog} 'icacls "C:\ProgramData\NamecoinCookie" /inheritance:r /T /grant "${SID_SYSTEM}:(OI)(CI)F" "${SID_ADMINISTRATORS}:(OI)(CI)F" "${SID_USERS}:(OI)(CI)F"'
  Pop $CoreCookieDirReturnCode
  ${If} $CoreCookieDirReturnCode != 0
    DetailPrint "Failed to set ACL on Namecoin Core cookie directory: return code $CoreCookieDirReturnCode"
    MessageBox "MB_OK|MB_ICONSTOP" "Failed to set ACL on Namecoin Core cookie directory." /SD IDOK
    Abort
  ${EndIf}
  ${ExecToLog} 'icacls "C:\ProgramData\NamecoinCookie\.cookie" /reset'
  Pop $CoreCookieFileReturnCode
  # The cookie file might not exist, which will yield return code 2.
  # See https://github.com/MicrosoftDocs/windowsserverdocs/issues/3303
  ${IfNot} $CoreCookieFileReturnCode == 0
  ${AndIfNot} $CoreCookieFileReturnCode == 2
    DetailPrint "Failed to set ACL on Namecoin Core cookie file: return code $CoreCookieFileReturnCode"
    MessageBox "MB_OK|MB_ICONSTOP" "Failed to set ACL on Namecoin Core cookie file." /SD IDOK
    Abort
  ${EndIf}

  # Now we need to make sure namecoin.conf exists and has 'server=1'.
  # We'll do this with a powershell script, much as we do for configuring Unbound.

  # Execute confignamecoinconf.ps1.
  File /oname=$PLUGINSDIR\confignamecoinconf.ps1 confignamecoinconf.ps1
  ${ExecToLog} 'powershell -executionpolicy bypass -noninteractive -file "$PLUGINSDIR\confignamecoinconf.ps1" -data_dir "$NamecoinCoreDataDir" $UseTorSwitch'
  Delete $PLUGINSDIR\confignamecoinconf.ps1

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

  ${If} $UseNamecoinCore == ${BST_UNCHECKED}
    DetailPrint "Not installing Namecoin Core."
    Return
  ${EndIf}

  # Install Namecoin Core
  DetailPrint "Installing Namecoin Core..."
  File /oname=$PLUGINSDIR\namecoin-setup-unsigned.exe ${ARTIFACTS}\${NAMECOIN_FN}
again:
  IfSilent install_silent
  # Install with NSIS GUI
  ExecWait '"$PLUGINSDIR\namecoin-setup-unsigned.exe"'
  Goto detect
install_silent:
  ExecWait '"$PLUGINSDIR\namecoin-setup-unsigned.exe" /S'

detect:
  Call DetectNamecoinCore
  ${If} $NamecoinCoreDetected == 0
    MessageBox "MB_OKCANCEL|MB_ICONSTOP" "Namecoin Core was not installed correctly. Press OK to retry or Cancel to abort the installer." /SD IDCANCEL IDOK again
    Abort
  ${EndIf}

  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ncdns" "ncdns_InstalledNamecoinCore" 1
  Delete /REBOOTOK $PLUGINSDIR\namecoin-setup-unsigned.exe
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
  MessageBox MB_YESNO|MB_ICONQUESTION "When you installed ncdns for Windows, Namecoin Core was installed automatically as a necessary dependency of ncdns for Windows. Would you like to remove it? If you leave it in place, you will not be able to connect to .bit domains, but will still be able to use Namecoin Core as a Namecoin node and wallet.$\n$\nSelect Yes to remove Namecoin Core." /SD IDYES IDYES 0 IDNO done

  # Uninstall Namecoin Core.
  DetailPrint "Uninstalling Namecoin Core... $NamecoinCoreUninstallCommand"
  ExecWait $NamecoinCoreUninstallCommand
  DeleteRegValue HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ncdns" "ncdns_InstalledNamecoinCore"

done:
  # Didn't install/not uninstalling Namecoin Core.
!endif
FunctionEnd


# ELECTRUM-NMC CHAIN INSTALLATION
##############################################################################
Function ElectrumNMC
!ifndef NO_ELECTRUM_NMC
  ${If} $ElectrumNMCDetected == 1
    # Already have Electrum-NMC
    DetailPrint "An existing Electrum-NMC installation was detected. Not installing."
    Return
  ${EndIf}
  DetailPrint "An existing Electrum-NMC installation was NOT detected."

  ${If} $UseElectrumNMC == ${BST_UNCHECKED}
    DetailPrint "Not installing Electrum-NMC."
    Return
  ${EndIf}

  # Install Electrum-NMC
  DetailPrint "Installing Electrum-NMC..."
  File /oname=$PLUGINSDIR\electrum-nmc-setup.exe ${ARTIFACTS}\${ELECTRUM_NMC_FN}
again:
  IfSilent install_silent
  # Install with NSIS GUI
  ExecWait '"$PLUGINSDIR\electrum-nmc-setup.exe"'
  Goto detect
install_silent:
  ExecWait '"$PLUGINSDIR\electrum-nmc-setup.exe" /S'

detect:
  Call DetectElectrumNMC
  ${If} $ElectrumNMCDetected == 0
    MessageBox "MB_OKCANCEL|MB_ICONSTOP" "Electrum-NMC was not installed correctly. Press OK to retry or Cancel to abort the installer." /SD IDCANCEL IDOK again
    Abort
  ${EndIf}

  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ncdns" "ncdns_InstalledElectrumNMC" 1
  Delete /REBOOTOK $PLUGINSDIR\electrum-nmc-setup.exe
!endif
FunctionEnd

Function un.ElectrumNMC
!ifndef NO_ELECTRUM_NMC
  # Determine if we were responsible for installing Electrum-NMC; if so, we
  # should uninstall it.
  ClearErrors
  ReadRegDWORD $0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ncdns" "ncdns_InstalledElectrumNMC"
  IfErrors done
  IntCmp $0 0 done

  # Detect Electrum-NMC uninstall command. If we cannot find it, don't offer
  # to uninstall it, as we don't know how.
  ClearErrors
  ReadRegStr $ElectrumNMCUninstallCommand HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Electrum-NMC" "UninstallString"
  IfErrors 0 found
  Goto done

found:
  # Ask the user if they want to uninstall Electrum-NMC
  MessageBox MB_YESNO|MB_ICONQUESTION "When you installed ncdns for Windows, Electrum-NMC was installed automatically as a necessary dependency of ncdns for Windows. Would you like to remove it? If you leave it in place, you will not be able to connect to .bit domains, but will still be able to use Electrum-NMC as a Namecoin node and wallet.$\n$\nSelect Yes to remove Electrum-NMC." /SD IDYES IDYES 0 IDNO done

  # Uninstall Electrum-NMC.
  DetailPrint "Uninstalling Electrum-NMC... $ElectrumNMCUninstallCommand"
  ExecWait $ElectrumNMCUninstallCommand
  DeleteRegValue HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ncdns" "ncdns_InstalledElectrumNMC"

done:
  # Didn't install/not uninstalling Electrum-NMC.
!endif
FunctionEnd


# BITCOINJ INSTALLATION
##############################################################################
Function BitcoinJ
!ifndef NO_BITCOINJ
  ${If} $UseConsensusJ == ${BST_UNCHECKED}
    # User did not elect to use SPV.
    DetailPrint "Not installing ConsensusJ-Namecoin."
    Return
  ${EndIf}

  # Install BitcoinJ
  DetailPrint "Installing ConsensusJ-Namecoin..."
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


# ELECTRUM-NMC CONFIG
##############################################################################
Function ElectrumNMCConfig
  ${If} $UseElectrumNMC == ${BST_UNCHECKED}
    DetailPrint "Not configuring Electrum-NMC."
    Return
  ${EndIf}

  DetailPrint "Configuring Electrum-NMC..."

  DetailPrint "Making sure Electrum-NMC is shut off..."

  # We need the current user's $APPDATA for configuring Electrum-NMC.
  SetShellVarContext current

  ${While} ${FileExists} "$APPDATA\Electrum-NMC\daemon"
    MessageBox MB_RETRYCANCEL|MB_ICONEXCLAMATION "Please close Electrum-NMC and then click Retry, or click Cancel to abort installation." /SD IDCANCEL IDRETRY retry

    Abort

    retry:
  ${EndWhile}

  # Restore SetShellVarContext
  SetShellVarContext all

  DetailPrint "Electrum-NMC is shut off."

  DetailPrint "Setting Electrum-NMC static port..."
  File /oname=$PLUGINSDIR\configelectrum.ps1 configelectrum.ps1
  nsExec::ExecToStack 'powershell -executionpolicy bypass -noninteractive -file "$PLUGINSDIR\configelectrum.ps1" $UseTorSwitch'
  Pop $ElectrumNMCConfigReturnCode
  Pop $ElectrumNMCConfigOutput
  Delete $PLUGINSDIR\configelectrum.ps1

  DetailPrint "Granting ncdns access to Electrum-NMC..."
  FileOpen $4 "$INSTDIR\etc\ncdns.conf.d\electrum-nmc.conf" w
  FileWrite $4 "[ncdns]$\r$\n$\r$\n"
  FileWrite $4 "$ElectrumNMCConfigOutput$\r$\n"
  # Electrum-NMC can take a few seconds to run name_show; the default 1500 ms
  # timeout isn't long enough.
  FileWrite $4 'namecoinrpctimeout="5000"$\r$\n'
  FileClose $4

  DetailPrint "Configured Electrum-NMC."
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
  File /oname=$INSTDIR\etc\ncdns.conf.d\xlog.conf ${NEUTRAL_ARTIFACTS}\ncdns.conf.d\xlog.conf

  # BIND files
  File /oname=$INSTDIR\bin\dnssec-keygen.exe ${ARTIFACTS}\dnssec-keygen.exe
  File /oname=$INSTDIR\bin\libcrypto-1_1-x64.dll ${ARTIFACTS}\libcrypto-1_1-x64.dll
  File /oname=$INSTDIR\bin\libdns.dll ${ARTIFACTS}\libdns.dll
  File /oname=$INSTDIR\bin\libisc.dll ${ARTIFACTS}\libisc.dll
  File /oname=$INSTDIR\bin\libisccfg.dll ${ARTIFACTS}\libisccfg.dll
  File /oname=$INSTDIR\bin\libssl-1_1-x64.dll ${ARTIFACTS}\libssl-1_1-x64.dll
  File /oname=$INSTDIR\bin\libxml2.dll ${ARTIFACTS}\libxml2.dll
  File /oname=$INSTDIR\bin\uv.dll ${ARTIFACTS}\uv.dll

#!if /FileExists "${ARTIFACTS}\ncdt.exe"
# This is listed in NSIS.chm but doesn't appear to be supported on the POSIX
# makensis version I'm using. Bleh.
#!endif

  File /oname=$INSTDIR\bin\ncdt.exe ${ARTIFACTS}\ncdt.exe
  File /oname=$INSTDIR\bin\ncdumpzone.exe ${ARTIFACTS}\ncdumpzone.exe
  File /oname=$INSTDIR\bin\generate_nmc_cert.exe ${ARTIFACTS}\generate_nmc_cert.exe
  File /oname=$INSTDIR\bin\q.exe ${ARTIFACTS}\q.exe
FunctionEnd

Function FilesConfig
  ${If} $UseNamecoinCore == ${BST_UNCHECKED}
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
  ${ExecToLog} 'icacls "$INSTDIR\etc" /inheritance:r /T /grant "NT SERVICE\ncdns:(OI)(CI)R" "${SID_SYSTEM}:(OI)(CI)F" "${SID_ADMINISTRATORS}:(OI)(CI)F"'
  Pop $EtcReturnCode
  ${If} $EtcReturnCode != 0
    DetailPrint "Failed to set ACL on etc: return code $EtcReturnCode"
    MessageBox "MB_OK|MB_ICONSTOP" "Failed to set ACL on etc." /SD IDOK
    Abort
  ${EndIf}
FunctionEnd

Function FilesSecure
  # Ensure only ncdns service and administrators can read ncdns.conf.
  Call FilesSecurePre
  ${ExecToLog} 'icacls "$INSTDIR\etc\ncdns.conf" /reset'
  Pop $EtcConfReturnCode
  ${If} $EtcConfReturnCode != 0
    DetailPrint "Failed to set ACL on ncdns config: return code $EtcConfReturnCode"
    MessageBox "MB_OK|MB_ICONSTOP" "Failed to set ACL on ncdns config." /SD IDOK
    Abort
  ${EndIf}
  ${ExecToLog} 'icacls "$INSTDIR\etc\ncdns.conf.d" /reset'
  Pop $EtcConfDReturnCode
  ${If} $EtcConfDReturnCode != 0
    DetailPrint "Failed to set ACL on ncdns config dir: return code $EtcConfDReturnCode"
    MessageBox "MB_OK|MB_ICONSTOP" "Failed to set ACL on ncdns config dir." /SD IDOK
    Abort
  ${EndIf}
  ${If} $UseElectrumNMC == ${BST_CHECKED}
    ${ExecToLog} 'icacls "$INSTDIR\etc\ncdns.conf.d\electrum-nmc.conf" /reset'
    Pop $EtcConfElectrumReturnCode
    ${If} $EtcConfElectrumReturnCode != 0
      DetailPrint "Failed to set ACL on ncdns electrum-nmc config: return code $EtcConfElectrumReturnCode"
      MessageBox "MB_OK|MB_ICONSTOP" "Failed to set ACL on ncdns electrum-nmc config." /SD IDOK
      Abort
    ${EndIf}
  ${EndIf}
  ${ExecToLog} 'icacls "$INSTDIR\etc\ncdns.conf.d\xlog.conf" /reset'
  Pop $EtcConfXlogReturnCode
  ${If} $EtcConfXlogReturnCode != 0
    DetailPrint "Failed to set ACL on ncdns xlog config: return code $EtcConfXlogReturnCode"
    MessageBox "MB_OK|MB_ICONSTOP" "Failed to set ACL on ncdns xlog config." /SD IDOK
    Abort
  ${EndIf}
  ${ExecToLog} 'icacls "$INSTDIR\etc\zsk" /reset'
  Pop $EtcZskReturnCode
  ${If} $EtcZskReturnCode != 0
    DetailPrint "Failed to set ACL on ZSK directory: return code $EtcZskReturnCode"
    MessageBox "MB_OK|MB_ICONSTOP" "Failed to set ACL on ZSK directory." /SD IDOK
    Abort
  ${EndIf}
  ${ExecToLog} 'icacls "$INSTDIR\etc\zsk\bit.private" /reset'
  Pop $EtcZskPrivReturnCode
  ${If} $EtcZskPrivReturnCode != 0
    DetailPrint "Failed to set ACL on ZSK private key: return code $EtcZskPrivReturnCode"
    MessageBox "MB_OK|MB_ICONSTOP" "Failed to set ACL on ZSK private key." /SD IDOK
    Abort
  ${EndIf}
  ${ExecToLog} 'icacls "$INSTDIR\etc\zsk\bit.key" /reset'
  Pop $EtcZskPubReturnCode
  ${If} $EtcZskPubReturnCode != 0
    DetailPrint "Failed to set ACL on ZSK public key: return code $EtcZskPubReturnCode"
    MessageBox "MB_OK|MB_ICONSTOP" "Failed to set ACL on ZSK public key." /SD IDOK
    Abort
  ${EndIf}
  ${ExecToLog} 'icacls "$INSTDIR\etc\ksk" /reset'
  Pop $EtcKskReturnCode
  ${If} $EtcKskReturnCode != 0
    DetailPrint "Failed to set ACL on KSK directory: return code $EtcKskReturnCode"
    MessageBox "MB_OK|MB_ICONSTOP" "Failed to set ACL on KSK directory." /SD IDOK
    Abort
  ${EndIf}
  ${ExecToLog} 'icacls "$INSTDIR\etc\ksk\bit.private" /reset'
  Pop $EtcKskPrivReturnCode
  ${If} $EtcKskPrivReturnCode != 0
    DetailPrint "Failed to set ACL on KSK private key: return code $EtcKskPrivReturnCode"
    MessageBox "MB_OK|MB_ICONSTOP" "Failed to set ACL on KSK private key." /SD IDOK
    Abort
  ${EndIf}
  ${ExecToLog} 'icacls "$INSTDIR\bit.key" /reset'
  Pop $EtcKskPubReturnCode
  ${If} $EtcKskPubReturnCode != 0
    DetailPrint "Failed to set ACL on KSK public key: return code $EtcKskPubReturnCode"
    MessageBox "MB_OK|MB_ICONSTOP" "Failed to set ACL on KSK public key." /SD IDOK
    Abort
  ${EndIf}
FunctionEnd

Function FilesSecureEncayaPre
  ${If} $CryptoAPIEncayaEnabled == ${BST_UNCHECKED}
    DetailPrint "*** Skipping Encaya filesystem permissions because CryptoAPI Encaya support was rejected."
    Return
  ${EndIf}

  ${ExecToLog} 'icacls "$INSTDIR\etc_encaya" /inheritance:r /T /grant "NT SERVICE\encaya:(OI)(CI)R" "${SID_SYSTEM}:(OI)(CI)F" "${SID_ADMINISTRATORS}:(OI)(CI)F"'
  Pop $EtcEncayaReturnCode
  ${If} $EtcEncayaReturnCode != 0
    DetailPrint "Failed to set ACL on etc_encaya: return code $EtcEncayaReturnCode"
    MessageBox "MB_OK|MB_ICONSTOP" "Failed to set ACL on etc_encaya." /SD IDOK
    Abort
  ${EndIf}

  ${ExecToLog} 'icacls "$INSTDIR\etc_encaya\encaya.conf.d" /reset'
  Pop $EtcEncayaConfDReturnCode
  ${If} $EtcEncayaConfDReturnCode != 0
    DetailPrint "Failed to set ACL on encaya config dir: return code $EtcEncayaConfDReturnCode"
    MessageBox "MB_OK|MB_ICONSTOP" "Failed to set ACL on encaya config dir." /SD IDOK
    Abort
  ${EndIf}
  ${ExecToLog} 'icacls "$INSTDIR\etc_encaya\encaya.conf.d\encaya.conf" /reset'
  Pop $EtcEncayaConfReturnCode
  ${If} $EtcEncayaConfReturnCode != 0
    DetailPrint "Failed to set ACL on encaya config: return code $EtcEncayaConfReturnCode"
    MessageBox "MB_OK|MB_ICONSTOP" "Failed to set ACL on encaya config." /SD IDOK
    Abort
  ${EndIf}
  ${ExecToLog} 'icacls "$INSTDIR\etc_encaya\encaya.conf.d\xlog.conf" /reset'
  Pop $EtcEncayaConfXlogReturnCode
  ${If} $EtcEncayaConfXlogReturnCode != 0
    DetailPrint "Failed to set ACL on encaya xlog config: return code $EtcEncayaConfXlogReturnCode"
    MessageBox "MB_OK|MB_ICONSTOP" "Failed to set ACL on encaya xlog config." /SD IDOK
    Abort
  ${EndIf}
FunctionEnd

Function FilesSecureEncaya
  ${If} $CryptoAPIEncayaEnabled == ${BST_UNCHECKED}
    DetailPrint "*** Skipping Encaya filesystem permissions because CryptoAPI Encaya support was rejected."
    Return
  ${EndIf}

  # Ensure only encaya service and administrators can read encaya.conf.
  Call FilesSecureEncayaPre
  ${ExecToLog} 'icacls "$INSTDIR\etc_encaya\root_key.pem" /reset'
  Pop $EtcEncayaRootKeyReturnCode
  ${If} $EtcEncayaRootKeyReturnCode != 0
    DetailPrint "Failed to set ACL on encaya root key: return code $EtcEncayaRootKeyReturnCode"
    MessageBox "MB_OK|MB_ICONSTOP" "Failed to set ACL on encaya root key." /SD IDOK
    Abort
  ${EndIf}
  ${ExecToLog} 'icacls "$INSTDIR\etc_encaya\listen_chain.pem" /reset'
  Pop $EtcEncayaListenChainReturnCode
  ${If} $EtcEncayaListenChainReturnCode != 0
    DetailPrint "Failed to set ACL on encaya listen chain: return code $EtcEncayaListenChainReturnCode"
    MessageBox "MB_OK|MB_ICONSTOP" "Failed to set ACL on encaya listen chain." /SD IDOK
    Abort
  ${EndIf}
  ${ExecToLog} 'icacls "$INSTDIR\etc_encaya\listen_key.pem" /reset'
  Pop $EtcEncayaListenKeyReturnCode
  ${If} $EtcEncayaListenKeyReturnCode != 0
    DetailPrint "Failed to set ACL on encaya listen key: return code $EtcEncayaListenKeyReturnCode"
    MessageBox "MB_OK|MB_ICONSTOP" "Failed to set ACL on encaya listen key." /SD IDOK
    Abort
  ${EndIf}
  ${ExecToLog} 'icacls "$INSTDIR\encaya.pem" /reset'
  Pop $EtcEncayaRootCertReturnCode
  ${If} $EtcEncayaRootCertReturnCode != 0
    DetailPrint "Failed to set ACL on KSK public key: return code $EtcEncayaRootCertReturnCode"
    MessageBox "MB_OK|MB_ICONSTOP" "Failed to set ACL on encaya root certificate." /SD IDOK
    Abort
  ${EndIf}
FunctionEnd

Function FilesSecureTorPre
  ${If} $UseTorBrowser == ${BST_UNCHECKED}
    DetailPrint "*** Skipping Tor filesystem permissions because Tor Browser support was rejected."
    Return
  ${EndIf}

  ${ExecToLog} 'icacls "$INSTDIR\etc_ncprop279" /inheritance:r /T /grant "NT SERVICE\stemns:(OI)(CI)R" "${SID_SYSTEM}:(OI)(CI)F" "${SID_ADMINISTRATORS}:(OI)(CI)F"'
  Pop $EtcNCProp279ReturnCode
  ${If} $EtcNCProp279ReturnCode != 0
    DetailPrint "Failed to set ACL on etc_ncprop279: return code $EtcNCProp279ReturnCode"
    MessageBox "MB_OK|MB_ICONSTOP" "Failed to set ACL on etc_ncprop279." /SD IDOK
    Abort
  ${EndIf}
FunctionEnd

Function FilesSecureTor
  ${If} $UseTorBrowser == ${BST_UNCHECKED}
    DetailPrint "*** Skipping Tor filesystem permissions because Tor Browser support was rejected."
    Return
  ${EndIf}

  # Ensure only StemNS service and administrators can read ncprop279.conf.
  Call FilesSecureTorPre
  ${ExecToLog} 'icacls "$INSTDIR\etc_ncprop279\ncprop279.conf.d" /reset'
  Pop $EtcNCProp279ConfDReturnCode
  ${If} $EtcNCProp279ConfDReturnCode != 0
    DetailPrint "Failed to set ACL on ncprop279 config dir: return code $EtcNCProp279ConfDReturnCode"
    MessageBox "MB_OK|MB_ICONSTOP" "Failed to set ACL on ncprop279 config dir." /SD IDOK
    Abort
  ${EndIf}
  ${If} $UseNamecoinCore == ${BST_CHECKED}
    ${ExecToLog} 'icacls "$INSTDIR\etc_ncprop279\ncprop279.conf.d\namecoin-core.conf" /reset'
    Pop $EtcNCProp279ConfCoreReturnCode
    ${If} $EtcNCProp279ConfCoreReturnCode != 0
      DetailPrint "Failed to set ACL on ncprop279 namecoin-core config: return code $EtcNCProp279ConfCoreReturnCode"
      MessageBox "MB_OK|MB_ICONSTOP" "Failed to set ACL on ncprop279 namecoin-core config." /SD IDOK
      Abort
    ${EndIf}
  ${EndIf}
  ${If} $UseConsensusJ == ${BST_CHECKED}
    ${ExecToLog} 'icacls "$INSTDIR\etc_ncprop279\ncprop279.conf.d\consensusj.conf" /reset'
    Pop $EtcNCProp279ConfConsensusJReturnCode
    ${If} $EtcNCProp279ConfConsensusJReturnCode != 0
      DetailPrint "Failed to set ACL on ncprop279 consensusj config: return code $EtcNCProp279ConfConsensusJReturnCode"
      MessageBox "MB_OK|MB_ICONSTOP" "Failed to set ACL on ncprop279 consensusj config." /SD IDOK
      Abort
    ${EndIf}
  ${EndIf}
  ${If} $UseElectrumNMC == ${BST_CHECKED}
    ${ExecToLog} 'icacls "$INSTDIR\etc_ncprop279\ncprop279.conf.d\electrum-nmc.conf" /reset'
    Pop $EtcNCProp279ConfElectrumReturnCode
    ${If} $EtcNCProp279ConfElectrumReturnCode != 0
      DetailPrint "Failed to set ACL on ncprop279 electrum-nmc config: return code $EtcNCProp279ConfElectrumReturnCode"
      MessageBox "MB_OK|MB_ICONSTOP" "Failed to set ACL on ncprop279 electrum-nmc config." /SD IDOK
      Abort
    ${EndIf}
  ${EndIf}
FunctionEnd

Function un.Files
  Delete $INSTDIR\bin\ncdns.exe
  Delete $INSTDIR\bin\ncdt.exe
  Delete $INSTDIR\bin\ncdumpzone.exe
  Delete $INSTDIR\bin\generate_nmc_cert.exe
  Delete $INSTDIR\bin\q.exe

  # BIND files
  Delete $INSTDIR\bin\dnssec-keygen.exe
  Delete $INSTDIR\bin\libcrypto-1_1-x64.dll
  Delete $INSTDIR\bin\libdns.dll
  Delete $INSTDIR\bin\libisc.dll
  Delete $INSTDIR\bin\libisccfg.dll
  Delete $INSTDIR\bin\libssl-1_1-x64.dll
  Delete $INSTDIR\bin\libxml2.dll
  Delete $INSTDIR\bin\uv.dll

  Delete $INSTDIR\etc\ncdns.conf.d\electrum-nmc.conf
  Delete $INSTDIR\etc\ncdns.conf.d\xlog.conf
  Delete $INSTDIR\etc\ncdns.conf
  Delete $INSTDIR\etc\ksk\bit.private
  Delete $INSTDIR\bit.key
  Delete $INSTDIR\etc\zsk\bit.private
  Delete $INSTDIR\etc\zsk\bit.key
  RMDir $INSTDIR\bin
  RMDir $INSTDIR\etc\ncdns.conf.d
  RMDir $INSTDIR\etc\ksk
  RMDir $INSTDIR\etc\zsk
  RMDir $INSTDIR\etc
  Delete $INSTDIR\namecoin.ico
  Delete $INSTDIR\install.log
  Delete $INSTDIR\uninst.exe
FunctionEnd


# FILE INSTALLATION/UNINSTALLATION
##############################################################################
Function KeyConfigDNSSEC
  DetailPrint "Generating DNSSEC key..."
  File /oname=$PLUGINSDIR\keyconfig.ps1 keyconfig.ps1
  FileOpen $4 "$PLUGINSDIR\keyconfig.cmd" w
  FileWrite $4 'powershell -executionpolicy bypass -noninteractive -file "$PLUGINSDIR\keyconfig.ps1" '
  FileWrite $4 '"$INSTDIR" < nul'
  FileClose $4
  ${ExecToLog} '$PLUGINSDIR\keyconfig.cmd'
  Pop $KeyDNSSECReturnCode
  ${If} $KeyDNSSECReturnCode != 0
    DetailPrint "Failed to generate DNSSEC key: return code $KeyDNSSECReturnCode"
    MessageBox "MB_OK|MB_ICONSTOP" "Failed to generate DNSSEC key." /SD IDOK
    Abort
  ${EndIf}
  Delete $PLUGINSDIR\keyconfig.ps1
  Delete $PLUGINSDIR\keyconfig.cmd
FunctionEnd


# FILE INSTALLATION/UNINSTALLATION
##############################################################################
Function KeyConfigEncaya
  ${If} $CryptoAPIEncayaEnabled == ${BST_UNCHECKED}
    DetailPrint "*** Skipping Encaya key generation because CryptoAPI Encaya support was rejected."
    Return
  ${EndIf}

  File /oname=$PLUGINSDIR\encayagen.exe ${ARTIFACTS}\encayagen.exe

  DetailPrint "Generating Encaya key..."
  ${ExecToLog} '"$PLUGINSDIR\encayagen.exe" "-conf=$INSTDIR\etc_encaya\encaya.conf"'
  Pop $KeyEncayaReturnCode
  ${If} $KeyEncayaReturnCode != 0
    DetailPrint "Failed to generate encaya key: return code $KeyEncayaReturnCode"
    MessageBox "MB_OK|MB_ICONSTOP" "Failed to generate encaya key." /SD IDOK
    Abort
  ${EndIf}

  Delete $PLUGINSDIR\encayagen.exe
FunctionEnd


# SERVICE INSTALLATION/UNINSTALLATION
##############################################################################
Function ServiceNcdns
  ${ExecToLog} 'sc create ncdns binPath= "ncdns.tmp" start= auto error= normal obj= "NT AUTHORITY\LocalService" DisplayName= "ncdns"'
  Pop $ServiceNcdnsCreateReturnCode
  ${If} $ServiceNcdnsCreateReturnCode != 0
    DetailPrint "Failed to create ncdns service: return code $ServiceNcdnsCreateReturnCode"
    MessageBox "MB_OK|MB_ICONSTOP" "Failed to create ncdns service." /SD IDOK
    Abort
  ${EndIf}
  # Use service SID.
  ${ExecToLog} 'sc sidtype ncdns restricted'
  Pop $ServiceNcdnsSidtypeReturnCode
  ${If} $ServiceNcdnsSidtypeReturnCode != 0
    DetailPrint "Failed to restrict ncdns service: return code $ServiceNcdnsSidtypeReturnCode"
    MessageBox "MB_OK|MB_ICONSTOP" "Failed to restrict ncdns service." /SD IDOK
    Abort
  ${EndIf}
  ${ExecToLog} 'sc description ncdns "Namecoin ncdns daemon"'
  Pop $ServiceNcdnsDescriptionReturnCode
  ${If} $ServiceNcdnsDescriptionReturnCode != 0
    DetailPrint "Failed to set description on ncdns service: return code $ServiceNcdnsDescriptionReturnCode"
    MessageBox "MB_OK|MB_ICONSTOP" "Failed to set description on ncdns service." /SD IDOK
    Abort
  ${EndIf}
  # Restrict privileges. 'sc privs' interprets an empty list as meaning no
  # privilege restriction... this one seems low-risk.
  ${ExecToLog} 'sc privs ncdns "SeChangeNotifyPrivilege"'
  Pop $ServiceNcdnsPrivsReturnCode
  ${If} $ServiceNcdnsPrivsReturnCode != 0
    DetailPrint "Failed to set privileges on ncdns service: return code $ServiceNcdnsPrivsReturnCode"
    MessageBox "MB_OK|MB_ICONSTOP" "Failed to set privileges on ncdns service." /SD IDOK
    Abort
  ${EndIf}
  # Set the proper image path manually rather than try to escape it properly
  # above.
  WriteRegStr HKLM "System\CurrentControlSet\Services\ncdns" "ImagePath" '"$INSTDIR\bin\ncdns.exe" "-conf=$INSTDIR\etc\ncdns.conf"'
FunctionEnd

Function ServiceNcdnsEventLog
  WriteRegStr HKLM "System\CurrentControlSet\Services\EventLog\Application\ncdns" "EventMessageFile" "%SystemRoot%\System32\EventCreate.exe"
  # 7 == Error | Warning | Info
  WriteRegDWORD HKLM "System\CurrentControlSet\Services\EventLog\Application\ncdns" "TypesSupported" 7
FunctionEnd

Function ServiceNcdnsStart
  ${ExecToLog} 'net start ncdns'
  Pop $ServiceNcdnsStartReturnCode
  ${If} $ServiceNcdnsStartReturnCode != 0
    DetailPrint "Failed to start ncdns service: return code $ServiceNcdnsStartReturnCode"
    MessageBox "MB_OK|MB_ICONSTOP" "Failed to start ncdns service." /SD IDOK
    Abort
  ${EndIf}
FunctionEnd

Function un.ServiceNcdns
  nsExec::Exec 'net stop ncdns'
  ${ExecToLog} 'sc delete ncdns'
FunctionEnd

Function ServiceEncaya
  ${If} $CryptoAPIEncayaEnabled == ${BST_UNCHECKED}
    DetailPrint "*** Skipping Encaya service creation because CryptoAPI Encaya support was rejected."
    Return
  ${EndIf}

  ${ExecToLog} 'sc create encaya binPath= "encaya.tmp" start= auto error= normal obj= "NT AUTHORITY\LocalService" DisplayName= "encaya"'
  Pop $ServiceEncayaCreateReturnCode
  ${If} $ServiceEncayaCreateReturnCode != 0
    DetailPrint "Failed to create encaya service: return code $ServiceEncayaCreateReturnCode"
    MessageBox "MB_OK|MB_ICONSTOP" "Failed to create encaya service." /SD IDOK
    Abort
  ${EndIf}
  # Use service SID.
  ${ExecToLog} 'sc sidtype encaya restricted'
  Pop $ServiceEncayaSidtypeReturnCode
  ${If} $ServiceEncayaSidtypeReturnCode != 0
    DetailPrint "Failed to restrict encaya service: return code $ServiceEncayaSidtypeReturnCode"
    MessageBox "MB_OK|MB_ICONSTOP" "Failed to restrict encaya service." /SD IDOK
    Abort
  ${EndIf}
  ${ExecToLog} 'sc description encaya "Namecoin AIA daemon"'
  Pop $ServiceEncayaDescriptionReturnCode
  ${If} $ServiceEncayaDescriptionReturnCode != 0
    DetailPrint "Failed to set description on encaya service: return code $ServiceEncayaDescriptionReturnCode"
    MessageBox "MB_OK|MB_ICONSTOP" "Failed to set description on encaya service." /SD IDOK
    Abort
  ${EndIf}
  # Restrict privileges. 'sc privs' interprets an empty list as meaning no
  # privilege restriction... this one seems low-risk.
  ${ExecToLog} 'sc privs encaya "SeChangeNotifyPrivilege"'
  Pop $ServiceEncayaPrivsReturnCode
  ${If} $ServiceEncayaPrivsReturnCode != 0
    DetailPrint "Failed to set privileges on encaya service: return code $ServiceEncayaPrivsReturnCode"
    MessageBox "MB_OK|MB_ICONSTOP" "Failed to set privileges on encaya service." /SD IDOK
    Abort
  ${EndIf}
  # Set the proper image path manually rather than try to escape it properly
  # above.
  WriteRegStr HKLM "System\CurrentControlSet\Services\encaya" "ImagePath" '"$INSTDIR\bin\encaya.exe" "-conf=$INSTDIR\etc_encaya\encaya.conf"'
FunctionEnd

Function ServiceEncayaEventLog
  ${If} $CryptoAPIEncayaEnabled == ${BST_UNCHECKED}
    DetailPrint "*** Skipping Encaya event log registration because CryptoAPI Encaya support was rejected."
    Return
  ${EndIf}

  WriteRegStr HKLM "System\CurrentControlSet\Services\EventLog\Application\encaya" "EventMessageFile" "%SystemRoot%\System32\EventCreate.exe"
  # 7 == Error | Warning | Info
  WriteRegDWORD HKLM "System\CurrentControlSet\Services\EventLog\Application\encaya" "TypesSupported" 7
FunctionEnd

Function ServiceEncayaStart
  ${If} $CryptoAPIEncayaEnabled == ${BST_UNCHECKED}
    DetailPrint "*** Skipping Encaya service start because CryptoAPI Encaya support was rejected."
    Return
  ${EndIf}

  ${ExecToLog} 'net start encaya'
  Pop $ServiceEncayaStartReturnCode
  ${If} $ServiceEncayaStartReturnCode != 0
    DetailPrint "Failed to start encaya service: return code $ServiceEncayaStartReturnCode"
    MessageBox "MB_OK|MB_ICONSTOP" "Failed to start encaya service." /SD IDOK
    Abort
  ${EndIf}
FunctionEnd

Function un.ServiceEncaya
  ${ExecToLog} 'net stop encaya'
  ${ExecToLog} 'sc delete encaya'
FunctionEnd

Function ServiceStemNS
  ${If} $UseTorBrowser == ${BST_UNCHECKED}
    DetailPrint "*** Skipping StemNS service creation because Tor Browser support was rejected."
    Return
  ${EndIf}

  ${ExecToLog} 'sc create stemns binPath= "stemns.tmp" start= auto error= normal obj= "NT AUTHORITY\LocalService" DisplayName= "StemNS"'
  Pop $ServiceStemNSCreateReturnCode
  ${If} $ServiceStemNSCreateReturnCode != 0
    DetailPrint "Failed to create StemNS service: return code $ServiceStemNSCreateReturnCode"
    MessageBox "MB_OK|MB_ICONSTOP" "Failed to create StemNS service." /SD IDOK
    Abort
  ${EndIf}
  # Use service SID.
  # Using a restricted sidtype causes StemNS service to crash on launch.  Maybe
  # a Python issue?  Not motivated to track it down since StemNS will be phased
  # out in the Arti transition.
  ${ExecToLog} 'sc sidtype stemns unrestricted'
  Pop $ServiceStemNSSidtypeReturnCode
  ${If} $ServiceStemNSSidtypeReturnCode != 0
    DetailPrint "Failed to restrict StemNS service: return code $ServiceStemNSSidtypeReturnCode"
    MessageBox "MB_OK|MB_ICONSTOP" "Failed to restrict StemNS service." /SD IDOK
    Abort
  ${EndIf}
  ${ExecToLog} 'sc description stemns "Namecoin Tor Prop279 Pluggable Naming"'
  Pop $ServiceStemNSDescriptionReturnCode
  ${If} $ServiceStemNSDescriptionReturnCode != 0
    DetailPrint "Failed to set description on StemNS service: return code $ServiceStemNSDescriptionReturnCode"
    MessageBox "MB_OK|MB_ICONSTOP" "Failed to set description on StemNS service." /SD IDOK
    Abort
  ${EndIf}
  # Restrict privileges. 'sc privs' interprets an empty list as meaning no
  # privilege restriction... this one seems low-risk.
  ${ExecToLog} 'sc privs stemns "SeChangeNotifyPrivilege"'
  Pop $ServiceStemNSPrivsReturnCode
  ${If} $ServiceStemNSPrivsReturnCode != 0
    DetailPrint "Failed to set privileges on StemNS service: return code $ServiceStemNSPrivsReturnCode"
    MessageBox "MB_OK|MB_ICONSTOP" "Failed to set privileges on StemNS service." /SD IDOK
    Abort
  ${EndIf}
  # Auto-restart service when it fails.
  ${ExecToLog} 'sc failure stemns reset= 15 actions= "restart/1000/restart/1000/restart/15000"'
  Pop $ServiceStemNSFailureReturnCode
  ${If} $ServiceStemNSFailureReturnCode != 0
    DetailPrint "Failed to loop StemNS service: return code $ServiceStemNSFailureReturnCode"
    MessageBox "MB_OK|MB_ICONSTOP" "Failed to loop StemNS service." /SD IDOK
    Abort
  ${EndIf}
  # Set the proper image path manually rather than try to escape it properly
  # above.
  WriteRegStr HKLM "System\CurrentControlSet\Services\stemns" "ImagePath" '"$INSTDIR\bin\winsvcwrap.exe" "-conf=$INSTDIR\etc_winsvcwrap_stemns\winsvcwrap.conf"'
FunctionEnd

Function ServiceStemNSEventLog
  ${If} $UseTorBrowser == ${BST_UNCHECKED}
    DetailPrint "*** Skipping StemNS event log registration because Tor Browser support was rejected."
    Return
  ${EndIf}

  WriteRegStr HKLM "System\CurrentControlSet\Services\EventLog\Application\stemns" "EventMessageFile" "%SystemRoot%\System32\EventCreate.exe"
  # 7 == Error | Warning | Info
  WriteRegDWORD HKLM "System\CurrentControlSet\Services\EventLog\Application\stemns" "TypesSupported" 7
FunctionEnd

Function ServiceStemNSStart
  ${If} $UseTorBrowser == ${BST_UNCHECKED}
    DetailPrint "*** Skipping StemNS service start because Tor Browser support was rejected."
    Return
  ${EndIf}

  ${ExecToLog} 'net start stemns'
  Pop $ServiceStemNSStartReturnCode
  ${If} $ServiceStemNSStartReturnCode != 0
    DetailPrint "Failed to start StemNS service: return code $ServiceStemNSStartReturnCode"
    MessageBox "MB_OK|MB_ICONSTOP" "Failed to start StemNS service." /SD IDOK
    Abort
  ${EndIf}
FunctionEnd

Function un.ServiceStemNS
  ${ExecToLog} 'net stop stemns'
  ${ExecToLog} 'sc delete stemns'
FunctionEnd


# UNBOUND CONFIGURATION
##############################################################################
Function UnboundConfig
  ${If} $UseUnbound == ${BST_UNCHECKED}
    DetailPrint "Not configuring Unbound."
    Return
  ${EndIf}

  # Detect dnssec-trigger/Unbound installation.
  ClearErrors
  ReadRegStr $UnboundConfPath HKLM "Software\Wow6432Node\DnssecTrigger" "InstallLocation"
  ${IfNot} ${Errors}
    DetailPrint "32-bit DNSSEC-Trigger InstallLocation found."
  ${Else}
    ReadRegStr $UnboundConfPath HKLM "Software\DnssecTrigger" "InstallLocation"
    ${IfNot} ${Errors}
      DetailPrint "Native-arch DNSSEC-Trigger InstallLocation found."
    ${Else}
      ReadRegStr $UnboundConfPath HKLM "Software\Wow6432Node\Unbound" "InstallLocation"
      ${IfNot} ${Errors}
        DetailPrint "32-bit standalone Unbound InstallLocation found."
      ${Else}
        ReadRegStr $UnboundConfPath HKLM "Software\Unbound" "InstallLocation"
        ${IfNot} ${Errors}
          DetailPrint "Native-arch standalone Unbound InstallLocation found."
        ${Else}
          DetailPrint "*** Unbound InstallLocation was NOT found."
          MessageBox "MB_OK|MB_ICONSTOP" "Unbound InstallLocation was NOT found." /SD IDOK
          Abort
        ${EndIf}
      ${EndIf}
    ${EndIf}
  ${EndIf}

  ${IfNot} ${FileExists} "$UnboundConfPath\unbound.conf"
  ${AndIfNot} ${FileExists} "$UnboundConfPath\service.conf"
    DetailPrint "*** Unbound configuration file was NOT found."
    # On Cirrus, we always fail to find the file.  Not sure why.  For now,
    # ignore the error by returning instead of aborting.
    #MessageBox "MB_OK|MB_ICONSTOP" "Unbound configuration file was NOT found." /SD IDOK
    #Abort
    Return
  ${Else}
    DetailPrint "Unbound configuration file found."
  ${EndIf}

  CreateDirectory "$UnboundConfPath\unbound.conf.d"

  # Unbound on Windows doesn't appear to support globbing include directives,
  # contrary to the documentation. So use this kludge instead.
  File /oname=$UnboundConfPath\rebuild-confd-list.cmd rebuild-confd-list.cmd
  ${ExecToLog} '"$UnboundConfPath\rebuild-confd-list.cmd"'

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
  ${ExecToLog} '$PLUGINSDIR\configunbound.cmd'
  Delete $PLUGINSDIR\configunbound.ps1
  Delete $PLUGINSDIR\configunbound.cmd

  # Add a config fragment in the newly configured directory.
  WriteRegStr HKLM "Software\Namecoin\ncdns" "UnboundFragmentLocation" "$UnboundConfPath\unbound.conf.d"
  ${ExecToLog} '"$UnboundConfPath\rebuild-confd-list.cmd"'

  # Windows, unbelievably, doesn't appear to have any way to restart a service
  # from the command line. stop followed by start isn't the same as a restart
  # because it doesn't restart dependencies automatically.
  ${ExecToLog} 'net stop /yes unbound'
  ${ExecToLog} 'net start unbound'
  ${ExecToLog} 'net start dnssectrigger'
FunctionEnd

Function un.UnboundConfig
  ClearErrors
  ReadRegStr $UnboundFragmentLocation HKLM "Software\Namecoin\ncdns" "UnboundFragmentLocation"
  IfErrors not_found 0

  # Delete the fragment which was installed, but do not deconfigure the
  # configuration directory.
  Delete $UnboundFragmentLocation\ncdns-inst.conf
  ${ExecToLog} '"$UnboundFragmentLocation\..\rebuild-confd-list.cmd"'

  ${ExecToLog} 'net stop /yes unbound'
  ${ExecToLog} 'net start unbound'
  ${ExecToLog} 'net start dnssectrigger'

not_found:
FunctionEnd


# TOR BROWSER CONFIGURATION
##############################################################################
Function TorBrowserConfig
  ${If} $UseTorBrowser == ${BST_UNCHECKED}
    DetailPrint "Not configuring Tor Browser."
    Return
  ${EndIf}

  DetailPrint "Making sure Tor is shut off..."

  File /oname=$PLUGINSDIR\detecttorrunning.ps1 detecttorrunning.ps1

  ${ExecToLog} 'powershell -executionpolicy bypass -noninteractive -file "$PLUGINSDIR\detecttorrunning.ps1"'
  Pop $TorRunningReturnCode

  ${While} $TorRunningReturnCode == 1
    MessageBox MB_RETRYCANCEL|MB_ICONEXCLAMATION "Please close Tor and then click Retry, or click Cancel to abort installation." /SD IDCANCEL IDRETRY retry

    Delete $PLUGINSDIR\detecttorrunning.ps1

    Abort

    retry:

    ${ExecToLog} 'powershell -executionpolicy bypass -noninteractive -file "$PLUGINSDIR\detecttorrunning.ps1"'
    Pop $TorRunningReturnCode
  ${EndWhile}

  Delete $PLUGINSDIR\detecttorrunning.ps1

  DetailPrint "Tor is shut off."

  DetailPrint "*** Installing ncprop279 files..."
  File /oname=$INSTDIR\bin\ncprop279.exe ${ARTIFACTS}\ncprop279.exe
  CreateDirectory $INSTDIR\etc_ncprop279
  CreateDirectory $INSTDIR\etc_ncprop279\ncprop279.conf.d

  Call FilesSecureTorPre

  ${If} $UseNamecoinCore == ${BST_CHECKED}
    File /oname=$INSTDIR\etc_ncprop279\ncprop279.conf.d\namecoin-core.conf ${NEUTRAL_ARTIFACTS}\ncprop279.conf.d\namecoin-core.conf
  ${ElseIf} $UseConsensusJ == ${BST_CHECKED}
    File /oname=$INSTDIR\etc_ncprop279\ncprop279.conf.d\consensusj.conf ${NEUTRAL_ARTIFACTS}\ncprop279.conf.d\consensusj.conf
  ${ElseIf} $UseElectrumNMC == ${BST_CHECKED}
    DetailPrint "Granting ncprop279 access to Electrum-NMC..."
    FileOpen $4 "$INSTDIR\etc_ncprop279\ncprop279.conf.d\electrum-nmc.conf" w
    FileWrite $4 "[ncprop279]$\r$\n$\r$\n"
    FileWrite $4 "$ElectrumNMCConfigOutput$\r$\n"
    # Electrum-NMC can take a few seconds to run name_show, especially over
    # Tor; the default 1500 ms timeout isn't long enough.
    FileWrite $4 'namecoinrpctimeout="10000"$\r$\n'
    FileClose $4
  ${EndIf}

  Call FilesSecureTor

  DetailPrint "*** Installing Python files..."
  CreateDirectory $INSTDIR\bin\python
  SetOutPath $INSTDIR\bin\python
  File /r ${ARTIFACTS}\python\*.*
  SetOutPath $INSTDIR

  DetailPrint "*** Installing Stem files..."
  CreateDirectory $INSTDIR\bin\python\stem
  SetOutPath $INSTDIR\bin\python\stem
  File /r ${NEUTRAL_ARTIFACTS}\stem\*.*
  SetOutPath $INSTDIR

  DetailPrint "*** Installing StemNS files..."
  File /oname=$INSTDIR\bin\stemns.py ${NEUTRAL_ARTIFACTS}\stemns\stemns.py
  File /oname=$INSTDIR\bin\python\settings_services.py ${NEUTRAL_ARTIFACTS}\stemns\settings_services.py
  File /oname=$INSTDIR\bin\python\settings_port.py ${NEUTRAL_ARTIFACTS}\stemns\settings_port.py

  DetailPrint "*** Installing winsvcwrap files..."
  File /oname=$INSTDIR\bin\winsvcwrap.exe ${ARTIFACTS}\winsvcwrap.exe
  CreateDirectory $INSTDIR\etc_winsvcwrap_stemns
  CreateDirectory $INSTDIR\etc_winsvcwrap_stemns\winsvcwrap.conf.d
  File /oname=$INSTDIR\etc_winsvcwrap_stemns\winsvcwrap.conf.d\xlog.conf ${NEUTRAL_ARTIFACTS}\winsvcwrap.conf.d\xlog.conf

  DetailPrint "*** Configuring winsvcwrap..."
  FileOpen $4 "$INSTDIR\etc_winsvcwrap_stemns\winsvcwrap.conf.d\stemns.conf" w
  FileWrite $4 "[winsvcwrap]$\r$\n$\r$\n"
  FileWrite $4 "run='$INSTDIR\bin\python\python.exe'$\r$\n"
  FileWrite $4 "arg='$INSTDIR\bin\stemns.py'$\r$\n"
  FileWrite $4 "cwd='$INSTDIR\bin'$\r$\n"
  FileClose $4

  DetailPrint "*** Configuring Tor..."
  File /oname=$PLUGINSDIR\configtorbrowser.ps1 configtorbrowser.ps1
  File /oname=$PLUGINSDIR\detecttorbrowser.ps1 detecttorbrowser.ps1
  File /oname=$PLUGINSDIR\detecttorbrowserchannel.ps1 detecttorbrowserchannel.ps1
  SetOutPath "$PLUGINSDIR"
  ${ExecToLog} 'powershell -executionpolicy bypass -noninteractive -file "$PLUGINSDIR\configtorbrowser.ps1"'
  Pop $TorBrowserConfigReturnCode
  Delete $PLUGINSDIR\detecttorbrowserchannel.ps1
  Delete $PLUGINSDIR\detecttorbrowser.ps1
  Delete $PLUGINSDIR\configtorbrowser.ps1
  SetOutPath "$INSTDIR"
  ${If} $TorBrowserConfigReturnCode != 0
    DetailPrint "Failed to configure Tor: return code $TorBrowserConfigReturnCode"
    MessageBox "MB_OK|MB_ICONSTOP" "Failed to configure Tor." /SD IDOK
    Abort
  ${EndIf}
FunctionEnd

Function un.TorBrowserConfig
  DetailPrint "Making sure Tor is shut off..."

  File /oname=$PLUGINSDIR\detecttorrunning.ps1 detecttorrunning.ps1

  ${ExecToLog} 'powershell -executionpolicy bypass -noninteractive -file "$PLUGINSDIR\detecttorrunning.ps1"'
  Pop $TorRunningReturnCode

  ${While} $TorRunningReturnCode == 1
    MessageBox MB_RETRYCANCEL|MB_ICONEXCLAMATION "Please close Tor and then click Retry, or click Cancel to uninstall anyway (might break Tor)." /SD IDCANCEL IDRETRY retry

    ${Break}

    retry:

    ${ExecToLog} 'powershell -executionpolicy bypass -noninteractive -file "$PLUGINSDIR\detecttorrunning.ps1"'
    Pop $TorRunningReturnCode
  ${EndWhile}

  Delete $PLUGINSDIR\detecttorrunning.ps1

  DetailPrint "Tor is shut off."

  # Binaries
  Delete $INSTDIR\bin\ncprop279.exe
  Delete $INSTDIR\bin\winsvcwrap.exe

  # ncprop279 config
  Delete $INSTDIR\etc_ncprop279\ncprop279.conf.d\namecoin-core.conf
  Delete $INSTDIR\etc_ncprop279\ncprop279.conf.d\consensusj.conf
  Delete $INSTDIR\etc_ncprop279\ncprop279.conf.d\electrum-nmc.conf
  RMDir $INSTDIR\etc_ncprop279\ncprop279.conf.d
  RMDir $INSTDIR\etc_ncprop279

  # winsvcwrap config
  Delete $INSTDIR\etc_winsvcwrap_stemns\winsvcwrap.conf.d\stemns.conf
  Delete $INSTDIR\etc_winsvcwrap_stemns\winsvcwrap.conf.d\xlog.conf
  RMDir $INSTDIR\etc_winsvcwrap_stemns\winsvcwrap.conf.d
  RMDir $INSTDIR\etc_winsvcwrap_stemns

  # Python and packages
  RMDir /r $INSTDIR\bin\python

  # StemNS
  Delete $INSTDIR\bin\stemns.py

  File /oname=$PLUGINSDIR\unconfigtorbrowser.ps1 unconfigtorbrowser.ps1
  File /oname=$PLUGINSDIR\detecttorbrowser.ps1 detecttorbrowser.ps1
  File /oname=$PLUGINSDIR\detecttorbrowserchannel.ps1 detecttorbrowserchannel.ps1
  SetOutPath "$PLUGINSDIR"
  ${ExecToLog} 'powershell -executionpolicy bypass -noninteractive -file "$PLUGINSDIR\unconfigtorbrowser.ps1"'
  Pop $TorBrowserConfigReturnCode
  Delete $PLUGINSDIR\detecttorbrowserchannel.ps1
  Delete $PLUGINSDIR\detecttorbrowser.ps1
  Delete $PLUGINSDIR\configtorbrowser.ps1
  SetOutPath "$INSTDIR"
  ${If} $TorBrowserConfigReturnCode != 0
    DetailPrint "Failed to unconfigure Tor: return code $TorBrowserConfigReturnCode"
  ${EndIf}
FunctionEnd

# REGISTRY PERMISSION CONFIGURATION FOR NCDNS TRUST INJECTION
##############################################################################
Function TrustConfig
  Call TrustNameConstraintsConfig
  Call TrustEncayaConfig
  Call TrustInjectionConfig

  DetailPrint "*** CryptoAPI TLS support was configured (if requested)."
FunctionEnd

Function un.TrustConfig
  Call un.TrustInjectionConfig
FunctionEnd

Function TrustEncayaConfig
  ${If} $CryptoAPIEncayaEnabled == ${BST_UNCHECKED}
    DetailPrint "*** Skipping Encaya config because CryptoAPI Encaya support was rejected."
    Return
  ${EndIf}

  DetailPrint "*** Installing Encaya files..."
  File /oname=$INSTDIR\bin\encaya.exe ${ARTIFACTS}\encaya.exe
  CreateDirectory $INSTDIR\etc_encaya
  CreateDirectory $INSTDIR\etc_encaya\encaya.conf.d
  File /oname=$INSTDIR\etc_encaya\encaya.conf.d\encaya.conf ${NEUTRAL_ARTIFACTS}\encaya.conf.d\encaya.conf
  File /oname=$INSTDIR\etc_encaya\encaya.conf.d\xlog.conf ${NEUTRAL_ARTIFACTS}\encaya.conf.d\xlog.conf
FunctionEnd

Function un.TrustEncayaConfig
  # Encaya main files
  Delete $INSTDIR\bin\encaya.exe
  Delete $INSTDIR\etc_encaya\encaya.conf.d\encaya.conf
  Delete $INSTDIR\etc_encaya\encaya.conf.d\xlog.conf
  RMDir $INSTDIR\etc_encaya\encaya.conf.d

  # Encaya keys
  Delete $INSTDIR\etc_encaya\root_key.pem
  Delete $INSTDIR\etc_encaya\listen_chain.pem
  Delete $INSTDIR\etc_encaya\listen_key.pem
  RMDir $INSTDIR\etc_encaya
  Delete $INSTDIR\encaya.pem

  # Encaya root CA
  ${ExecToLog} 'certutil -enterprise -delstore Root "Namecoin Root CA"'
FunctionEnd

Function CertInjectEncaya
  ${If} $CryptoAPIEncayaEnabled == ${BST_UNCHECKED}
    DetailPrint "*** Skipping Encaya certinject because CryptoAPI Encaya support was rejected."
    Return
  ${EndIf}

  # TODO: Delete Encaya cert from trust store when uninstalling
  File /oname=$PLUGINSDIR\certinject.exe ${ARTIFACTS}\certinject.exe

  DetailPrint "*** Configuring Encaya trust"
  FileOpen $4 "$PLUGINSDIR\certinject-encaya.cmd" w
  FileWrite $4 '"$PLUGINSDIR\certinject.exe" -capi.physical-store=enterprise -capi.logical-store=Root "-certinject.cert=$INSTDIR\encaya.pem" -certstore.cryptoapi -eku.server -nc.permitted-dns=$ETLD'
  FileClose $4
  ${ExecToLog} '"$PLUGINSDIR\certinject-encaya.cmd"'
  Delete $PLUGINSDIR\certinject-encaya.cmd

  Delete $PLUGINSDIR\certinject.exe
FunctionEnd

Function TrustNameConstraintsConfig
  ${If} $CryptoAPINameConstraintsEnabled == ${BST_UNCHECKED}
    DetailPrint "*** CryptoAPI Negative TLS support was not configured."
    Return
  ${EndIf}

  DetailPrint "*** Extracting AuthRootWU"
  File /oname=$PLUGINSDIR\verifyctl.cmd verifyctl.cmd
  ${ExecToLog} '"$PLUGINSDIR\verifyctl.cmd"'
  Delete $PLUGINSDIR\verifyctl.cmd

  File /oname=$PLUGINSDIR\certinject.exe ${ARTIFACTS}\certinject.exe

  DetailPrint "*** Configuring name constraints: Root"
  FileOpen $4 "$PLUGINSDIR\certinject-root.cmd" w
  FileWrite $4 '"$PLUGINSDIR\certinject.exe" -capi.physical-store=system -capi.logical-store=Root -capi.all-certs -certstore.cryptoapi -nc.excluded-dns=$ETLD'
  FileClose $4
  ${ExecToLog} '"$PLUGINSDIR\certinject-root.cmd"'
  Delete $PLUGINSDIR\certinject-root.cmd

  DetailPrint "*** Configuring name constraints: AuthRoot"
  FileOpen $4 "$PLUGINSDIR\certinject-authroot.cmd" w
  FileWrite $4 '"$PLUGINSDIR\certinject.exe" -capi.physical-store=system -capi.logical-store=AuthRoot -capi.all-certs -certstore.cryptoapi -nc.excluded-dns=$ETLD'
  FileClose $4
  ${ExecToLog} '"$PLUGINSDIR\certinject-authroot.cmd"'
  Delete $PLUGINSDIR\certinject-authroot.cmd

  # TODO: Configure name constraints for enterprise and group policy too.
  # TODO: Configure name constraints for bit.onion too.

  Delete $PLUGINSDIR\certinject.exe
FunctionEnd

Function TrustInjectionConfig
  ${If} $CryptoAPIInjectionEnabled == ${BST_UNCHECKED}
    DetailPrint "*** Skipping Injection config because CryptoAPI Injection support was rejected."
    Return
  ${EndIf}

  DetailPrint "*** Configuring cert store permissions"
  File /oname=$PLUGINSDIR\regpermrun.ps1 regpermrun.ps1
  File /oname=$PLUGINSDIR\regperm.ps1 regperm.ps1
  FileOpen $4 "$PLUGINSDIR\regpermrun.cmd" w
  FileWrite $4 'powershell -executionpolicy bypass -noninteractive -file "$PLUGINSDIR\regpermrun.ps1" install < nul'
  FileClose $4
  ${ExecToLog} '"$PLUGINSDIR\regpermrun.cmd"'
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
  ${ExecToLog} '"$PLUGINSDIR\regpermrun.cmd"'
  Delete $PLUGINSDIR\regpermrun.cmd
  Delete $PLUGINSDIR\regpermrun.ps1
  Delete $PLUGINSDIR\regperm.ps1
FunctionEnd


#
##############################################################################
Function ConfigSections
  SectionSetFlags ${Sec_ncdns} 25
FunctionEnd
