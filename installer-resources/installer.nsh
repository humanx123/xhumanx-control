!macro customInstall
  DetailPrint "Preparando XHumanX Control y el puente local..."
  nsExec::ExecToLog '"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "$INSTDIR\resources\installer-resources\setup-bridge.ps1"'
!macroend
