$InstDir = Get-ItemProperty -Path HKCU:\Software\Electrum-NMC | Select-Object -ExpandProperty '(Default)'

$ElectrumExeSearch = Get-ChildItem "$InstDir" -Recurse -Force -Include electrum-nmc-*.exe

$ElectrumExeName = $ElectrumExeSearch[0].Name

$ElectrumExe = "$InstDir\$ElectrumExeName"

& "$ElectrumExe" setconfig rpcport 8336 | Out-Null
Start-Sleep -Seconds 5

# Generate random 32-byte hex password
$RpcUser = -join ( 1..64 | ForEach-Object { (48..57) + (65..70) | Get-Random | % {[char]$_} } )
$RpcPassword = -join ( 1..64 | ForEach-Object { (48..57) + (65..70) | Get-Random | % {[char]$_} } )

& "$ElectrumExe" setconfig rpcuser "$RpcUser" | Out-Null
Start-Sleep -Seconds 5

& "$ElectrumExe" setconfig rpcpassword "$RpcPassword" | Out-Null
Start-Sleep -Seconds 5

echo '[ncdns]'
echo ''
echo 'namecoinrpcaddress="127.0.0.1:8336"'
echo "namecoinrpcusername=`"$RpcUser`""
echo "namecoinrpcpassword=`"$RpcPassword`""
# Electrum-NMC can take a few seconds to run name_show; the default 1500 ms
# timeout isn't long enough.
echo 'namecoinrpctimeout="5000"'
