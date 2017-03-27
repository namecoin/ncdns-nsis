# Usage: Synopsis: keyconfig.ps1 "C:\Program Files (x86)\ncdns"
$ncdns_path = $args[0]
cd "$ncdns_path\etc"
del Kbit.+*.key
del Kbit.+*.private
if (Test-Path "..\bit.key") {
  del ..\bit.key
}
if (Test-Path "bit.private") {
  del bit.private
}

& "$ncdns_path\bin\dnssec-keygen.exe" -a ECDSAP256SHA256 -3 bit.
move Kbit.+*.key ..\bit.key
move Kbit.+*.private bit.private

# Golang's miekg/dns, used by ncdns, chokes on CRLF line endings.
# But dnssec-keygen generates them. So we have to fix that.
@("$ncdns_path\bit.key", "$ncdns_path\etc\bit.private") | ForEach-Object {
  $c = [IO.File]::ReadAllText($_) -replace "`r`n", "`n"
  $u = New-Object System.Text.UTF8Encoding $false
  [IO.File]::WriteAllText($_, $c, $u)
}
