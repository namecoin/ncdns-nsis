Param (
  $Channel
)

$CandidateDesktopPath = [Environment]::GetFolderPath("Desktop") + "\Tor Browser" + $Channel

if (Test-Path -Path ($CandidateDesktopPath)) {
  echo $CandidateDesktopPath
}

$CandidateStartMenuPath = [Environment]::GetFolderPath("Programs") + "\Start Tor Browser" + $Channel + ".lnk"
if (Test-Path -Path ($CandidateStartMenuPath)) {
  $Sh = New-Object -ComObject WScript.Shell
  $Shortcut = $Sh.CreateShortcut($CandidateStartMenuPath)
  $ShortcutWorkingDir = $Shortcut.WorkingDirectory
  $Result = Split-Path -Parent $ShortcutWorkingDir
  
  echo $Result
}
