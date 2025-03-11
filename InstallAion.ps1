# Elevar permisos si no es administrador
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Definir rutas
$aionFolder = "C:\Aion4.3"
$aionBat = "$aionFolder\Aion.bat"
$lnkFile = "$env:USERPROFILE\Desktop\Aion.lnk"
$iconFile = "$aionFolder\AionClient.ico"
$vbsFile = "$aionFolder\CrearAccesoDirecto.vbs"

# Crear la carpeta si no existe
if (-not (Test-Path $aionFolder)) {
    New-Item -ItemType Directory -Path $aionFolder | Out-Null
}

# Crear el archivo Aion.bat
@"
@echo off
:: Verifica si Aion.bin está en ejecución y lo cierra
tasklist | findstr /I "Aion.bin" >nul
if %errorlevel%==0 (
    echo Cerrando Aion...
    taskkill /F /IM Aion.bin >nul 2>&1
    timeout /t 2 /nobreak >nul
)

:: Inicia Aion
start bin64\Aion.bin -ip:26.74.116.124 -port:2106 -cc:1 -lang:enu -noweb -nowebshop -nokicks -ncg -noauthgg -charnamemenu -ingameshop -win10-mouse-fix -ncping -oncmsg -nosatab -f2p -megaphone
exit
"@ | Set-Content -Path $aionBat -Encoding ASCII

# Crear el script VBS para el acceso directo con "Iniciar en: C:\Aion4.3"
@"
Set oWS = WScript.CreateObject("WScript.Shell")
Set oLink = oWS.CreateShortcut("$lnkFile")
oLink.TargetPath = "$aionBat"
oLink.WorkingDirectory = "$aionFolder"
oLink.IconLocation = "$iconFile"
oLink.Save
"@ | Set-Content -Path $vbsFile -Encoding ASCII

# Ejecutar el script VBS para generar el acceso directo
Start-Process "wscript.exe" -ArgumentList "`"$vbsFile`"" -NoNewWindow -Wait

# Verificar si el acceso directo se creó correctamente
if (Test-Path $lnkFile) {
    Write-Output "Acceso directo creado con éxito en el escritorio."
} else {
    Write-Output "Error al crear el acceso directo."
}

# Eliminar el script VBS después de ejecutarlo
Remove-Item -Path $vbsFile -Force

Write-Output "Proceso completado."
Exit
