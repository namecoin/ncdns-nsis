$sp = split-path -parent $MyInvocation.MyCommand.Definition

& "$sp\detecttorbrowserchannel.ps1" -Channel ""
& "$sp\detecttorbrowserchannel.ps1" -Channel " Alpha"
& "$sp\detecttorbrowserchannel.ps1" -Channel " Nightly"
