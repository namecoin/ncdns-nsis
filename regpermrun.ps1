$sp = split-path -parent $MyInvocation.MyCommand.Definition

if ($env:PROCESSOR_ARCHITEW6432 -eq "AMD64") {
  # 32-on-64
  $ps64 = $PSHOME.tolower().replace("syswow64","sysnative").replace("system32","sysnative")
  $ps32 = $PSHOME
  &"$ps64\powershell.exe" -executionpolicy bypass -noninteractive -file "$sp\regperm.ps1" $args[0]
  &"$ps32\powershell.exe" -executionpolicy bypass -noninteractive -file "$sp\regperm.ps1" $args[0]
} elseif ($env:PROCESSOR_ARCHITECTURE -eq "AMD64") {
  # 64-on-64
  $ps64 = $PSHOME
  $ps32 = $PSHOME.tolower().replace("system32","syswow64").replace("sysnative","syswow64")
  &"$ps64\powershell.exe" -executionpolicy bypass -noninteractive -file "$sp\regperm.ps1" $args[0]
  &"$ps32\powershell.exe" -executionpolicy bypass -noninteractive -file "$sp\regperm.ps1" $args[0]
} else {
  # 32-on-32
  $ps32 = $PSHOME
  &"$ps32\powershell.exe" -executionpolicy bypass -noninteractive -file "$sp\regperm.ps1" $args[0]
}
