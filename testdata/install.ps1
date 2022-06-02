# VCPP is no longer needed since BIND dependency was removed.
#$should_succeed = $Env:INSTALL_VCPP -eq "1"
$should_succeed = $True

try {
  # Pipe to Out-Null so that PowerShell waits for the program to exit.
  & ncdns--win64-install.exe /S | Out-Null
  $success = $?

  if ( ( $success ) -ne ( $should_succeed ) ) {
    Write-Host "Install test failed.  Log below:"
    Get-Content "C:\Program Files\ncdns\install.log"
    exit 111
  }
}
catch {
  if ( $should_succeed ) {
    Write-Host "Install test failed: $Error.  Log below:"
    Get-Content "C:\Program Files\ncdns\install.log"
    exit 111
  }
  else {
    Write-Host "Good, install did not complete: $Error.  Log below:"
    Get-Content "C:\Program Files\ncdns\install.log"
    exit 0
  }
}

Write-Host "Good; install test passed.  Log below:"
Get-Content "C:\Program Files\ncdns\install.log"
exit 0
