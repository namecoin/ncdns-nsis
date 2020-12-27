Write-Host "----- Running TLS handshake tests -----"

Write-Host "----- DNS website -----"

& "powershell" "-ExecutionPolicy" "Unrestricted" "-File" "testdata/try-tls-handshake.ps1" "-url" "https://www.namecoin.org/"
If (!$?) {
  exit 222
}

Write-Host "----- Namecoin website, valid dehydrated certificate -----"

& "powershell" "-ExecutionPolicy" "Unrestricted" "-File" "testdata/try-tls-handshake.ps1" "-url" "https://namecoin.bit/"
If (!$?) {
  exit 222
}

# TODO: test DNS and Namecoin websites with invalid certs.

# all done
Write-Host "----- All TLS handshake tests passed -----"
exit 0
