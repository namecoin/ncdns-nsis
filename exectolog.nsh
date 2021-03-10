Var /GLOBAL ExecToLogReturnCode
Var /GLOBAL ExecToLogOutput

!define ExecToLog "!insertmacro ExecToLog"

!macro ExecToLog Path
  ${If} ${Silent}
    # If in silent mode, log via DetailPrint, which only shows the first 1024
    # bytes of output and doesn't display in real-time, but appears in
    # install.log.
    nsExec::ExecToStack '${Path}'
    Pop $ExecToLogReturnCode
    Pop $ExecToLogOutput
    DetailPrint '$ExecToLogOutput'
    Push $ExecToLogReturnCode
  ${Else}
    # If in GUI mode, log via ExecToLog, which shows GUI output in real-time but
    # doesn't appear in install.log.
    nsExec::ExecToLog '${Path}'
  ${EndIf}
!macroend
