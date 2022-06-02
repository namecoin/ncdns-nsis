# Usage: Synopsis: keyconfig.ps1 "C:\Program Files (x86)\ncdns"
$ErrorActionPreference = 'Stop'
$ncdns_path = $args[0]
cd "$ncdns_path\etc"

### KSK
mkdir -force ksk
cd ksk
# Cleanup old files
del Kbit.+*.key
del Kbit.+*.ds
del Kbit.+*.private
if (Test-Path "..\..\bit.key") {
  del ..\..\bit.key
}
if (Test-Path "..\..\bit.ds") {
  del ..\..\bit.ds
}
if (Test-Path "bit.private") {
  del bit.private
}
# Generate KSK
& "$ncdns_path\bin\coredns-keygen.exe" bit.
If (!$?) {
  exit 1
}
# Move KSK files
move Kbit.+*.key ..\..\bit.key
move Kbit.+*.ds ..\..\bit.ds
move Kbit.+*.private bit.private
#
cd ..

### ZSK
mkdir -force zsk
cd zsk
# Cleanup old files
del Kbit.+*.key
del Kbit.+*.ds
del Kbit.+*.private
if (Test-Path "bit.key") {
  del bit.key
}
if (Test-Path "bit.ds") {
  del bit.ds
}
if (Test-Path "bit.private") {
  del bit.private
}
# Generate ZSK
& "$ncdns_path\bin\coredns-keygen.exe" -zsk bit.
If (!$?) {
  exit 1
}
# Move ZSK files
move Kbit.+*.key bit.key
move Kbit.+*.ds bit.ds
move Kbit.+*.private bit.private
#
cd ..

# Golang's miekg/dns, used by ncdns, chokes on CRLF line endings.
# But dnssec-keygen generates them. So we have to fix that.
# This is not really necessary anymore since we switched to coredns-keygen, but
# doesn't hurt in case something unexpected has happened.
@("$ncdns_path\bit.key", "$ncdns_path\bit.ds", "$ncdns_path\etc\ksk\bit.private", "$ncdns_path\etc\zsk\bit.key", "$ncdns_path\etc\zsk\bit.ds", "$ncdns_path\etc\zsk\bit.private") | ForEach-Object {
  $c = [IO.File]::ReadAllText($_) -replace "`r`n", "`n"
  $u = New-Object System.Text.UTF8Encoding $false
  [IO.File]::WriteAllText($_, $c, $u)
}
