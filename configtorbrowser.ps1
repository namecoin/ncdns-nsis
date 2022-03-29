$sp = split-path -parent $MyInvocation.MyCommand.Definition

$Dirs = & "$sp\detecttorbrowser.ps1"
$StemNSOpt = "__LeaveStreamsUnattached 1"

foreach ($TorBrowserDir in $Dirs) {
  Write-Host "Found Tor Browser in: $TorBrowserDir"

  Write-Host "Configuring torrc..."
  $ConfigPath = $TorBrowserDir + "\Browser\TorBrowser\Data\Tor\torrc"
  $AlreadyConfigured = Select-String -Pattern "$StemNSOpt" -SimpleMatch -Quiet -Path "$ConfigPath"
  if (-Not $AlreadyConfigured) {
    Add-Content -Value "$StemNSOpt" -Path "$ConfigPath"
  }

  Write-Host "Configuring torrc-defaults..."
  $ConfigPath = $TorBrowserDir + "\Browser\TorBrowser\Data\Tor\torrc-defaults"
  $AlreadyConfigured = Select-String -Pattern "$StemNSOpt" -SimpleMatch -Quiet -Path "$ConfigPath"
  if (-Not $AlreadyConfigured) {
    Add-Content -Value "$StemNSOpt" -Path "$ConfigPath"
  }

  Write-Host "Granting StemNS read permssions for cookie..."
  & icacls "$TorBrowserDir\Browser\TorBrowser\Data\Tor" /T /grant "NT SERVICE\stemns:(OI)(CI)R"
}
