Get-Process tor
if ($?) {
  # Tor is running
  exit 1
}

# Tor is not running
exit 0
