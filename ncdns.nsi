!addplugindir "plugins"
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
    MessageBox "MB_OK|MB_ICONSTOP" "ncdns requires Windows Vista or later."
    #Abort
  ${EndIf}

  # Make sections mandatory.
  SectionSetFlags ${Sec_ncdns} 25
FunctionEnd

# INSTALL SECTIONS
##############################################################################
Var /GLOBAL Reinstalling

Section "ncdns" Sec_ncdns
  #SectionIn RO

  SetOutPath $INSTDIR
  Call ReinstallCheck
  Call Reg
  Call Service
  Call Files
  Call ServiceStart
  AddSize 12288  # Disk space estimation.
SectionEnd


# UNINSTALL SECTIONS
##############################################################################
Section "Uninstall"
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

  # Ensure only ncdns service and administrators can read ncdns.conf.
  AccessControl::DisableFileInheritance "$INSTDIR\etc\ncdns.conf"
  AccessControl::ClearOnFile "$INSTDIR\etc\ncdns.conf" "SYSTEM" "FullAccess"
  AccessControl::GrantOnFile "$INSTDIR\etc\ncdns.conf" "Administrators" "FullAccess"
  AccessControl::GrantOnFile "$INSTDIR\etc\ncdns.conf" "NT SERVICE\ncdns" "GenericRead"
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
    nsExec::Exec 'sc stop ncdns'
    nsExec::ExecToLog 'sc delete ncdns'
  ${EndIf}

  nsExec::ExecToLog 'sc create ncdns binPath= "ncdns.tmp" start= auto error= normal obj= "NT AUTHORITY\LocalService" DisplayName= "ncdns"'
  # Use service SID.
  nsExec::ExecToLog 'sc sidtype ncdns restricted'
  nsExec::ExecToLog 'sc description ncdns "Namecoin ncdns daemon"'
  # Restrict privileges. 'sc privs' interprets an empty list as meaning no
  # privilege restriction... this one seems low-risk.
  nsExec::ExecToLog 'sc privs ncdns "SeCreateGlobalPrivilege"'
  # Set the proper image path manually rather than try to escape it properly
  # above.
  WriteRegStr HKLM "System\CurrentControlSet\Services\ncdns" "ImagePath" '"$INSTDIR\bin\ncdns.exe" "-conf=$INSTDIR\etc\ncdns.conf"'
FunctionEnd

Function ServiceStart
  nsExec::Exec 'sc start ncdns'
FunctionEnd

Function un.Service
  nsExec::Exec 'sc stop ncdns'
  nsExec::ExecToLog 'sc delete ncdns'
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
