$sp = split-path -parent $MyInvocation.MyCommand.Definition

$Dirs = & "$sp\detecttorbrowser.ps1"
$StemNSOpt = "__LeaveStreamsUnattached 1"

foreach ($TorBrowserDir in $Dirs) {
  $ConfigPath = $TorBrowserDir + "\Browser\TorBrowser\Data\Tor\torrc"
  $AlreadyConfigured = Select-String -Pattern "$StemNSOpt" -SimpleMatch -Quiet -Path "$ConfigPath"
  if ($AlreadyConfigured) {
    ((Get-Content -Path "$ConfigPath") -Replace "$StemNSOpt", "") | Set-Content -Path "$ConfigPath"
  }

  $ConfigPath = $TorBrowserDir + "\Browser\TorBrowser\Data\Tor\torrc-defaults"
  $AlreadyConfigured = Select-String -Pattern "$StemNSOpt" -SimpleMatch -Quiet -Path "$ConfigPath"
  if ($AlreadyConfigured) {
    ((Get-Content -Path "$ConfigPath") -Replace "$StemNSOpt", "") | Set-Content -Path "$ConfigPath"
  }
}
