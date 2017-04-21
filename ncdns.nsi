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
OutFile "build\ncdns-install.exe"

# Jeremy Rand thinks people shouldn't change this because it might affect build
# determinism, so any PR which changes this should probably highlight him or
# something.
SetCompressor /SOLID lzma

!define MUI_ICON "media\namecoin.ico"
!define MUI_FINISHPAGE_NOAUTOCLOSE
!define MUI_UNFINISHPAGE_NOAUTOCLOSE

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
Var /GLOBAL SkipDNSSECTrigger

Var /GLOBAL NamecoinCoreDetected
Var /GLOBAL DNSSECTriggerDetected


# PRELAUNCH CHECKS
##############################################################################
!Include WinVer.nsh

Function .onInit
  ${IfNot} ${AtLeastWinVista}
    MessageBox "MB_OK|MB_ICONSTOP" "ncdns requires Windows Vista or later."
    Abort
  ${EndIf}

  # Make sections mandatory.
  Call ConfigSections

  # Detect already installed dependencies.
  Call DetectVC8 # aborts on failure
  Call DetectNamecoinCore
  Call DetectDNSSECTrigger
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

Function DetectDNSSECTrigger
  ClearErrors
  ReadRegDWORD $0 HKLM "System\CurrentControlSet\Services\DNSSECTrigger" "Type"
  IfErrors absent 0
  Push 1
  Pop $DNSSECTriggerDetected
  Return
absent:
  Push 0
  Pop $DNSSECTriggerDetected
FunctionEnd


# COMPONENT SELECTION DIALOG HELPERS
##############################################################################
Function ComponentDialogCreate
  Call fnc_components_dialog_Create

  ${If} $NamecoinCoreDetected == 1
    ${NSD_SetText} $hCtl_components_dialog_NamecoinCore_Status "An existing Namecoin Core installation was detected."
    ${NSD_SetText} $hCtl_components_dialog_NamecoinCore_Yes "Automatically configure Namecoin Core (recommended)"
    ${NSD_SetText} $hCtl_components_dialog_NamecoinCore_No "I will configure Namecoin Core myself (manual configuration required)"
  ${Else}
    ${NSD_SetText} $hCtl_components_dialog_NamecoinCore_Status "An existing Namecoin Core installation was not detected."
    ${NSD_SetText} $hCtl_components_dialog_NamecoinCore_Yes "Install and configure Namecoin Core (recommended)"
    ${NSD_SetText} $hCtl_components_dialog_NamecoinCore_No "I will provide my own Namecoin node (manual configuration required)"
  ${EndIf}

  ${If} $DNSSECTriggerDetected == 1
    ${NSD_SetText} $hCtl_components_dialog_DNSSECTrigger_Status "An existing DNSSEC Trigger installation was detected."
    ${NSD_SetText} $hCtl_components_dialog_DNSSECTrigger_Yes "Automatically configure DNSSEC Trigger (recommended)"
    ${NSD_SetText} $hCtl_components_dialog_DNSSECTrigger_No "I will configure DNSSEC Trigger myself (manual configuration required)"
  ${Else}
    ${NSD_SetText} $hCtl_components_dialog_DNSSECTrigger_Status "An existing DNSSEC Trigger installation was not detected."
    ${NSD_SetText} $hCtl_components_dialog_DNSSECTrigger_Yes "Install and configure DNSSEC Trigger (recommended)"
    ${NSD_SetText} $hCtl_components_dialog_DNSSECTrigger_No "I will provide my own DNS resolver (manual configuration required)"
  ${EndIf}

  nsDialogs::Show
FunctionEnd

Function ComponentDialogLeave
  ${NSD_GetState} $hCtl_components_dialog_NamecoinCore_No $SkipNamecoinCore
  ${NSD_GetState} $hCtl_components_dialog_DNSSECTrigger_No $SkipDNSSECTrigger
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
  Call KeyConfig
  Call TrustConfig
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
  ${If} $DNSSECTriggerDetected == 1
    # Already have DNSSEC Trigger
    Return
  ${EndIf}
  ${If} $SkipDNSSECTrigger == ${BST_CHECKED}
    Return
  ${EndIf}

  # Install DNSSEC Trigger
  DetailPrint "Installing DNSSEC Trigger..."
  File /oname=$TEMP\dnssec_trigger_setup.exe artifacts\dnssec_trigger_setup.exe
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
!ifdef NCDNS_64BIT
  File /oname=$TEMP\namecoin-setup-unsigned.exe artifacts\namecoin-win64-setup-unsigned.exe
!else
  File /oname=$TEMP\namecoin-setup-unsigned.exe artifacts\namecoin-win32-setup-unsigned.exe
!endif
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
  DetailPrint "Uninstalling Namecoin Core... $NamecoinCoreUninstallCommand"
  ExecWait $NamecoinCoreUninstallCommand
  DeleteRegValue HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ncdns" "ncdns_InstalledNamecoinCore"

done:
  # Didn't install Namecoin Core.
!endif
FunctionEnd


# FILE INSTALLATION/UNINSTALLATION
##############################################################################
Function Files
  WriteUninstaller "uninst.exe"
  CreateDirectory $INSTDIR\bin
  CreateDirectory $INSTDIR\etc
  File /oname=$INSTDIR\namecoin.ico media\namecoin.ico
  File /oname=$INSTDIR\bin\ncdns.exe artifacts\ncdns.exe
  File /oname=$INSTDIR\etc\ncdns.conf artifacts\ncdns.conf

  File /oname=$INSTDIR\bin\dnssec-keygen.exe artifacts\dnssec-keygen.exe
  File /oname=$INSTDIR\bin\libisc.dll artifacts\libisc.dll
  File /oname=$INSTDIR\bin\libdns.dll artifacts\libdns.dll
  File /oname=$INSTDIR\bin\libeay32.dll artifacts\libeay32.dll
  File /oname=$INSTDIR\bin\libxml2.dll artifacts\libxml2.dll

#!if /FileExists "artifacts\ncdt.exe"
# This is listed in NSIS.chm but doesn't appear to be supported on the POSIX
# makensis version I'm using. Bleh.
#!endif

  File /nonfatal /oname=$INSTDIR\bin\ncdt.exe artifacts\ncdt.exe
  File /nonfatal /oname=$INSTDIR\bin\ncdumpzone.exe artifacts\ncdumpzone.exe
  File /nonfatal /oname=$INSTDIR\bin\generate_nmc_cert.exe artifacts\generate_nmc_cert.exe
  File /nonfatal /oname=$INSTDIR\bin\q.exe artifacts\q.exe
FunctionEnd

Function FilesSecure
  # Ensure only ncdns service and administrators can read ncdns.conf.
  nsExec::ExecToLog 'icacls "$INSTDIR\etc" /inheritance:r /T /grant "NT SERVICE\ncdns:(OI)(CI)R" "SYSTEM:(OI)(CI)F" "Administrators:(OI)(CI)F"'
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
  ${If} $SkipDNSSECTrigger == 1
    Return
  ${EndIf}

  # Detect dnssec-trigger installation.
  ClearErrors
  ReadRegStr $UnboundConfPath HKLM "Software\Wow6432Node\DnssecTrigger" "InstallLocation"
  IfErrors 0 found
  ReadRegStr $UnboundConfPath HKLM "Software\DnssecTrigger" "InstallLocation"
  IfErrors 0 found
not_found:
  DetailPrint "*** dnssec-trigger installation was NOT found, not configuring Unbound."
  StrCpy $UnboundConfPath ""
  Return

  # dnssec-trigger is installed. Adapt the Unbound config to include from a
  # directory.
found:
  DetailPrint "*** dnssec-trigger installation WAS found, configuring Unbound."
  IfFileExists "$UnboundConfPath\unbound.conf" 0 not_found
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
  IfFileExists "$LOCALAPPDATA\Google\Chrome\User Data" found 0
  IfFileExists "$LOCALAPPDATA\Chromium\User Data" found 0
  DetailPrint "*** Chrome/Chromium NOT detected, not configuring trust."
  Return

found:
  MessageBox MB_ICONQUESTION|MB_YESNO "You currently have Chromium or Google Chrome installed.  ncdns can enable HTTPS for Namecoin websites in Chromium/Chrome.  This will protect your communications with Namecoin-enabled websites from being easily wiretapped or tampered with in transit.  Doing this requires giving ncdns permission to modify Windows's root certificate authority list.  ncdns will not intentionally add any certificate authorities to Windows, but if an attacker were able to exploit ncdns, they might be able to wiretap or tamper with your Internet traffic (both Namecoin and non-Namecoin websites).  If you plan to access Namecoin-enabled websites on this computer from any web browser other than Chromium, Chrome, Firefox, or Tor Browser, you should not enable HTTPS for Namecoin websites in Chromium/Chrome.$\n$\nWould you like to enable HTTPS for Namecoin websites in Chromium/Chrome?" /SD IDNO IDYES chose_yes IDNO chose_no
chose_no:
  DetailPrint "*** Chrome/Chromium was detected, but user elected not to configure it."
  Return

found_again:
  Delete "$PLUGINSDIR\tutorial-confirm"
  Goto found

chose_yes:
  Delete $PLUGINSDIR\tutorial-confirm
  IfFileExists $PLUGINSDIR\tutorial-confirm found 0
  File /oname=$PLUGINSDIR\tutorial.ps1 tutorial.ps1
  File /oname=$PLUGINSDIR\tutorial.html tutorial.html
  FileOpen $4 "$PLUGINSDIR\tutorial.cmd" w
  FileWrite $4 'powershell -executionpolicy bypass -noninteractive -sta -file "$PLUGINSDIR\tutorial.ps1" "$PLUGINSDIR\tutorial.html" "$PLUGINSDIR\tutorial-confirm" < nul'
  FileClose $4
  nsExec::ExecToLog '"$PLUGINSDIR\tutorial.cmd"'

  Delete $PLUGINSDIR\tutorial.cmd
  Delete $PLUGINSDIR\tutorial.ps1
  Delete $PLUGINSDIR\tutorial.html
  IfFileExists "$PLUGINSDIR\tutorial-confirm" 0 found_again
  Delete $PLUGINSDIR\tutorial-confirm

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

  DetailPrint "*** Chrome/Chromium WAS configured after user confirmation."
FunctionEnd

Function un.TrustConfig
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
