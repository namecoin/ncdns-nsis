# Usage: Synopsis: configunbound.ps1 "C:\...\Unbound\" "C:\Program Files (x86)\ncdns\"
$unbound_path = $args[0]
$config_file = "$unbound_path\unbound.conf"
$include_file = "$unbound_path\confd-list.conf"
$ncdns_path = $args[1]
$einclude_file = [Regex]::Escape($include_file)
echo cfg: $config_file
echo include: $include_file
echo ncdns: $ncdns_path

# Ensure unbound.conf contains an appropriate include directive.
if (!((get-content -path $config_file) -match "include:\s*`"$einclude_file`"" -and 1)) {
  [IO.File]::AppendAllText($config_file, "include: `"$include_file`"`n")
}

# Edit the config file to point to the ncdns keyfile.
(Get-Content "$unbound_path\unbound.conf.d\ncdns-inst.conf.in") -replace "@NCDNS_PATH@", "$ncdns_path" | Set-Content "$unbound_path\unbound.conf.d\ncdns-inst.conf"
Remove-Item "$unbound_path\unbound.conf.d\ncdns-inst.conf.in"
