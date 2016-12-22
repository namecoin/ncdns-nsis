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

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

!insertmacro MUI_LANGUAGE English

InstallDir $PROGRAMFILES\ncdns
InstallDirRegKey HKLM "Software\Namecoin\ncdns" "InstallPath"
ShowInstDetails show
ShowUninstDetails show

RequestExecutionLevel admin
XPStyle on
CRCCheck on

# Branding.
Name "ncdns Windows Installer"
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
VIAddVersionKey "LegalCopyright" "2016 Hugo Landau <hlandau@devever.net>"
VIAddVersionKey "LegalTrademarks" "ncdns, Namecoin"
VIAddVersionKey "Comments" "ncdns Installer"

# PRELAUNCH CHECKS
##############################################################################
!Include WinVer.nsh

Function .onInit
  ${IfNot} ${AtLeastWinXP}
    ## This is always firing. Why?
    #MessageBox "MB_OK|MB_ICONSTOP" "ncdns requires Windows Vista or later."
    #Abort
  ${EndIf}

  # Make sections mandatory.
  SectionSetFlags ${Sec_ncdns} 25
FunctionEnd

# INSTALL SECTIONS
##############################################################################
Var /GLOBAL Reinstalling
Var /GLOBAL UnboundConfPath
Var /GLOBAL UnboundFragmentLocation

Section "ncdns" Sec_ncdns
  #SectionIn RO

  SetOutPath $INSTDIR
  InitPluginsDir
  Call ReinstallCheck
  Call Reg
  Call Service
  Call Files
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


# FILE INSTALLATION/UNINSTALLATION
##############################################################################
Function Files
  WriteUninstaller "uninst.exe"
  CreateDirectory $INSTDIR\bin
  CreateDirectory $INSTDIR\etc
  File /oname=$INSTDIR\namecoin.ico media\namecoin.ico
  File /oname=$INSTDIR\bin\ncdns.exe artifacts\ncdns.exe
  File /oname=$INSTDIR\etc\ncdns.conf artifacts\ncdns.conf
FunctionEnd

Function FilesSecure
  # Ensure only ncdns service and administrators can read ncdns.conf.
  nsExec::ExecToLog 'icacls "$INSTDIR\etc" /inheritance:r /T /grant "NT SERVICE\ncdns:(OI)(CI)R" "SYSTEM:(OI)(CI)F" "Administrators:(OI)(CI)F"'
  nsExec::ExecToLog 'icacls "$INSTDIR\etc\ncdns.conf" /reset'
FunctionEnd

Function un.Files
  Delete $INSTDIR\bin\ncdns.exe
  Delete $INSTDIR\etc\ncdns.conf
  RMDir $INSTDIR\bin
  RMDir $INSTDIR\etc
  Delete $INSTDIR\namecoin.ico
  Delete $INSTDIR\uninst.exe
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
  # Detect dnssec-trigger installation.
  ClearErrors
  ReadRegStr $UnboundConfPath HKLM "Software\Wow6432Node\DnssecTrigger" "InstallLocation"
  IfErrors 0 found
  ReadRegStr $UnboundConfPath HKLM "Software\DnssecTrigger" "InstallLocation"
  IfErrors 0 found
not_found:
  StrCpy $UnboundConfPath ""
  Return

  # dnssec-trigger is installed. Adapt the Unbound config to include from a
  # directory.
found:
  IfFileExists "$UnboundConfPath\unbound.conf" 0 not_found
  CreateDirectory "$UnboundConfPath\unbound.conf.d"

  # Unbound on Windows doesn't appear to support globbing include directives,
  # contrary to the documentation. So use this kludge instead.
  File /oname=$UnboundConfPath\rebuild-confd-list.cmd rebuild-confd-list.cmd
  nsExec::ExecToLog '"$UnboundConfPath\rebuild-confd-list.cmd"'

  File /oname=$PLUGINSDIR\configunbound.ps1 configunbound.ps1
  # We execute the script via a dynamically written batch file because Windows
  # command line escaping is very strange and has been behaving strangely if
  # done directly from NSIS. This behaves consistently.
  FileOpen $4 "$PLUGINSDIR\configunbound.cmd" w
  FileWrite $4 'powershell -executionpolicy bypass -noninteractive -file "$PLUGINSDIR\configunbound.ps1" '
  FileWrite $4 '"$UnboundConfPath\unbound.conf" "$UnboundConfPath\confd-list.conf" < nul'
  FileClose $4
  nsExec::ExecToLog '$PLUGINSDIR\configunbound.cmd'
  Delete $PLUGINSDIR\configunbound.ps1
  Delete $PLUGINSDIR\configunbound.cmd

  # Add a config fragment in the newly configured directory.
  WriteRegStr HKLM "Software\Namecoin\ncdns" "UnboundFragmentLocation" "$UnboundConfPath\unbound.conf.d"
  File /oname=$UnboundConfPath\unbound.conf.d\ncdns-inst.conf ncdns-inst.conf
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
  Return

found:
  MessageBox MB_ICONQUESTION|MB_YESNO "You currently have Chromium or Google Chrome installed.  ncdns can enable HTTPS for Namecoin websites in Chromium/Chrome.  This will protect your communications with Namecoin-enabled websites from being easily wiretapped or tampered with in transit.  Doing this requires giving ncdns permission to modify Windows's root certificate authority list.  ncdns will not intentionally add any certificate authorities to Windows, but if an attacker were able to exploit ncdns, they might be able to wiretap or tamper with your Internet traffic (both Namecoin and non-Namecoin websites).  If you plan to access Namecoin-enabled websites on this computer from any web browser other than Chromium, Chrome, Firefox, or Tor Browser, you should not enable HTTPS for Namecoin websites in Chromium/Chrome.$\n$\nWould you like to enable HTTPS for Namecoin websites in Chromium/Chrome?" /SD IDNO IDYES chose_yes IDNO chose_no
chose_no:
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
