$pv = (get-item ($args[0]+"\artifacts\ncdns.exe")).VersionInfo.ProductVersion
echo ("!define ncdns_prodver " + $pv) > _ver.nsi
