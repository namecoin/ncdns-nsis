Param (
  [switch]$use_tor
)

$PSNativeCommandUseErrorActionPreference = $true
$ErrorActionPreference = 'Stop'

$InstDir = Get-ItemProperty -Path HKCU:\Software\Electrum-NMC | Select-Object -ExpandProperty '(Default)'

$ElectrumExeSearch = Get-ChildItem "$InstDir" -Recurse -Force -Include electrum-nmc-*.exe

$ElectrumExeName = $ElectrumExeSearch[0].Name

$ElectrumExe = "$InstDir\$ElectrumExeName"

& "$ElectrumExe" --offline setconfig rpcport 8336 | Out-Null
Start-Sleep -Seconds 5

# Generate random 32-byte hex password
$RpcUser = -join ( 1..64 | ForEach-Object { (48..57) + (65..70) | Get-Random | % {[char]$_} } )
$RpcPassword = -join ( 1..64 | ForEach-Object { (48..57) + (65..70) | Get-Random | % {[char]$_} } )

& "$ElectrumExe" --offline setconfig rpcuser "$RpcUser" | Out-Null
Start-Sleep -Seconds 5

& "$ElectrumExe" --offline setconfig rpcpassword "$RpcPassword" | Out-Null
Start-Sleep -Seconds 5

if ($use_tor) {
  & "$ElectrumExe" --offline setconfig proxy "socks5:127.0.0.1:9150:::1" | Out-Null
  Start-Sleep -Seconds 5
}

echo 'namecoinrpcaddress="127.0.0.1:8336"'
echo "namecoinrpcusername=`"$RpcUser`""
echo "namecoinrpcpassword=`"$RpcPassword`""
