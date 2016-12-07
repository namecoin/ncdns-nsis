# Usage: Synopsis: configunbound.ps1 "C:\...\Unbound\unbound.conf" "C:\...\Unbound\unbound.conf.d\*.conf"
$config_file = $args[0]
$glob_pattern = $args[1]
$eglob_pattern = [Regex]::Escape($glob_pattern)
echo cfg: $config_file
echo glob: $glob_patterh

if (!((get-content -path $config_file) -match "include:\s*`"$eglob_pattern`"" -and 1)) {
  [IO.File]::AppendAllText($config_file, "include: `"$glob_pattern`"`n")
}
