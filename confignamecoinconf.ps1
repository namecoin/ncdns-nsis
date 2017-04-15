# Usage: Synopsis: confignamecoinconf.ps1 <NamecoinDataDir>
$data_dir = $args[0]
$config_file = $data_dir + "\namecoin.conf"

# Ensure file exists.
if (!(test-path $config_file)) {
  [IO.File]::AppendAllText($config_file, "")
}

# Ensure file contains 'server=1'.
if (!((get-content -path $config_file) -match "^\s*server\s*=\s*1" -and 1)) {
  [IO.File]::AppendAllText($config_file, "`nserver=1`n")
}
