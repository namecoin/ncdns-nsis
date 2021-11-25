Param (
  $data_dir,
  [switch]$use_tor
)

$config_file = $data_dir + "\namecoin.conf"

# Ensure file exists.
if (!(test-path $config_file)) {
  [IO.File]::AppendAllText($config_file, "")
}

# Ensure file contains 'server=1'.
if (!((get-content -path $config_file) -match "^\s*server\s*=\s*1" -and 1)) {
  [IO.File]::AppendAllText($config_file, "`nserver=1`n")
}

# Ensure file contains 'rpccookiefile'
if (!((get-content -path $config_file) -match "^\s*rpccookiefile\s*=C:\\ProgramData\\NamecoinCookie\\\.cookie" -and 1)) {
  [IO.File]::AppendAllText($config_file, "`nrpccookiefile=C:\ProgramData\NamecoinCookie\.cookie`n")
}

# Ensure file contains 'proxy'.
if ($use_tor) {
  if (!((get-content -path $config_file) -match "^\s*proxy\s*=\s*127\\\.0\\\.0\\\.1:9150" -and 1)) {
    [IO.File]::AppendAllText($config_file, "`nproxy=127.0.0.1:9150`n")
  }
}
