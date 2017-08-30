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
Var /GLOBAL Reinstalling
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

Var /GLOBAL CurChromium_TransportSecurity
Var /GLOBAL CurChromium_lockfile
Var /GLOBAL ChromiumFound
Var /GLOBAL ChromiumRejected
Var /GLOBAL JREPath
Var /GLOBAL JREDetected

# PRELAUNCH CHECKS
##############################################################################
!Include WinVer.nsh

Function .onInit
  ${IfNot} ${AtLeastWinVista}
    MessageBox "MB_OK|MB_ICONSTOP" "ncdns requires Windows Vista or later."
    Abort
  ${EndIf}

  SetShellVarContext all

  # Make sections mandatory.
  Call ConfigSections

  # Detect already installed dependencies.
  Call DetectVC8 # aborts on failure
  Call DetectNamecoinCore
  Call DetectUnbound
  Call DetectJRE
FunctionEnd

Function un.onInit
  SetShellVarContext all
FunctionEnd

Function DetectVC8
  # Check that MSVC8 runtime is installed for dnssec-keygen.
  FindFirst $0 $1 $WINDIR\WinSxS\x86_microsoft.vc80.crt_1fc8b3b9a1e18e3b_8.*
  StrCmp $1 "" notfound
  Goto found

notfound:
  FindClose $0
  MessageBox "MB_OK|MB_ICONSTOP" "ncdns for Windows requires the Microsoft Visual C 8.0 runtime.$\n$\nYou can download it from:$\nhttps://www.microsoft.com/en-us/download/details.aspx?id=5638"
  ExecShell "open" "https://www.microsoft.com/en-us/download/details.aspx?id=5638"
  Abort

found:
  FindClose $0
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

  StrCpy $DetectJRE_W "SOFTWARE\JavaSoft\Java Runtime Environment"
  Call DetectJREUnder

  ${If} $JREDetected == 1
    Return
  ${EndIf}

  StrCpy $DetectJRE_W "SOFTWARE\Wow6432Node\JavaSoft\Java Runtime Environment"
  Call DetectJREUnder
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
    ${If} $JREDetected == 1
      ${NSD_SetText} $hCtl_components_dialog_NamecoinCore_SPV "Install and use the BitcoinJ SPV client instead"
    ${Else}
      ${NSD_SetText} $hCtl_components_dialog_NamecoinCore_SPV "Cannot use BitcoinJ SPV client (Java must be installed)"
      EnableWindow $hCtl_components_dialog_NamecoinCore_SPV 0
    ${EndIf}
    ${NSD_SetText} $hCtl_components_dialog_NamecoinCore_No "I will configure Namecoin Core myself (manual configuration required)"

    # Use Namecoin Core by default if it's already installed.
    ${NSD_SetState} $hCtl_components_dialog_NamecoinCore_Yes ${BST_CHECKED}
  ${Else}
    ${NSD_SetText} $hCtl_components_dialog_NamecoinCore_Status "An existing Namecoin Core installation was not detected."
    ${If} $JREDetected == 1
      ${NSD_SetText} $hCtl_components_dialog_NamecoinCore_Yes "Install and configure Namecoin Core"
      ${NSD_SetText} $hCtl_components_dialog_NamecoinCore_SPV "Install and use the BitcoinJ SPV client (recommended)"
    ${Else}
      ${NSD_SetText} $hCtl_components_dialog_NamecoinCore_Yes "Install and configure Namecoin Core (recommended)"
      ${NSD_SetText} $hCtl_components_dialog_NamecoinCore_SPV "Cannot use BitcoinJ SPV client (Java must be installed)"
      EnableWindow $hCtl_components_dialog_NamecoinCore_SPV 0
      ${NSD_SetState} $hCtl_components_dialog_NamecoinCore_Yes ${BST_CHECKED}
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
  Call ReinstallCheck
  Call Reg
  Call DNSSECTrigger
  Call NamecoinCoreConfig
  Call NamecoinCore
  Call Service
  Call Files
  Call BitcoinJ
  Call TrustConfig
  Call FilesSecurePre
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
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ncdns" "ncdns_InstalledDNSSECTrigger" 1
  ExecWait $TEMP\dnssec_trigger_setup.exe
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
    Return
  ${EndIf}

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
FunctionEnd


# NAMECOIN CORE CHAIN INSTALLATION
##############################################################################
Function NamecoinCore
!ifndef NO_NAMECOIN_CORE
  ${If} $NamecoinCoreDetected == 1
    # Already have Namecoin Core
    Return
  ${EndIf}
  ${If} $SkipNamecoinCore == ${BST_CHECKED}
    Return
  ${EndIf}

  # Install Namecoin Core
  DetailPrint "Installing Namecoin Core..."
  File /oname=$TEMP\namecoin-setup-unsigned.exe ${ARTIFACTS}\${NAMECOIN_FN}
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ncdns" "ncdns_InstalledNamecoinCore" 1
  ExecWait $TEMP\namecoin-setup-unsigned.exe
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
  CreateShortcut "$SMPROGRAMS\BitcoinJ.lnk" "$INSTDIR\BitcoinJ\Launch BitcoinJ.cmd"
  CreateShortcut "$DESKTOP\BitcoinJ.lnk" "$INSTDIR\BitcoinJ\Launch BitcoinJ.cmd"
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
  Delete "$SMPROGRAMS\BitcoinJ.lnk"
  Delete "$DESKTOP\BitcoinJ.lnk"
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

Function FilesSecurePre
  nsExec::ExecToLog 'icacls "$INSTDIR\etc" /inheritance:r /T /grant "NT SERVICE\ncdns:(OI)(CI)R" "SYSTEM:(OI)(CI)F" "Administrators:(OI)(CI)F"'
FunctionEnd

Function FilesSecure
  # Ensure only ncdns service and administrators can read ncdns.conf.
  Call FilesSecurePre
  nsExec::ExecToLog 'icacls "$INSTDIR\etc\ncdns.conf" /reset'
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

  Delete $INSTDIR\etc\ncdns.conf
  Delete $INSTDIR\etc\ksk\bit.private
  Delete $INSTDIR\bit.key
  Delete $INSTDIR\etc\zsk\bit.private
  Delete $INSTDIR\etc\zsk\bit.key
  RMDir $INSTDIR\bin
  RMDir $INSTDIR\etc\ksk
  RMDir $INSTDIR\etc\zsk
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
  ${If} $Reinstalling = 1
    nsExec::Exec 'net stop ncdns'
    nsExec::ExecToLog 'sc delete ncdns'
  ${EndIf}

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
  StrCpy $CurChromium_TransportSecurity "$LOCALAPPDATA\Google\Chrome\User Data\Default\TransportSecurity"
  StrCpy $CurChromium_lockfile "$LOCALAPPDATA\Google\Chrome\User Data\lockfile"
  Call ChromiumConfigAtLoc
  StrCpy $CurChromium_TransportSecurity "$LOCALAPPDATA\Chromium\User Data\Default\TransportSecurity"
  StrCpy $CurChromium_lockfile "$LOCALAPPDATA\Chromium\User Data\lockfile"
  Call ChromiumConfigAtLoc
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


# REINSTALL TESTING
##############################################################################
Function ReinstallCheck
  StrCpy $Reinstalling 1
  ClearErrors
  ReadRegStr $0 HKLM "System\CurrentControlSet\Services\ncdns" "ImagePath"
  IfErrors 0 reinstalling
  StrCpy $Reinstalling 0 ;; new install
reinstalling:
FunctionEnd


#
##############################################################################
Function ConfigSections
  SectionSetFlags ${Sec_ncdns} 25
FunctionEnd
