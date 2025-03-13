# Elevar permisos si no es administrador
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Script para verificar e instalar la última versión de DirectX

# Función para verificar la versión de DirectX
function Get-DirectXVersion {
    $dxdiag = Start-Process -FilePath "dxdiag" -ArgumentList "/t dxdiag.txt" -Wait -PassThru
    $dxdiagOutput = Get-Content -Path "dxdiag.txt"
    $versionLine = $dxdiagOutput | Select-String -Pattern "DirectX Version"
    $version = $versionLine -replace "DirectX Version: ", ""
    Remove-Item -Path "dxdiag.txt"
    return $version
}

# URL de descarga del instalador de DirectX
$directxUrl = "https://download.microsoft.com/download/1/7/1/1718CCC4-6315-4D8E-9543-8E28A4E18C4C/dxwebsetup.exe"

# Ruta donde se guardará el instalador
$installerPath = "$env:TEMP\directx_installer.exe"

# Verificar la versión de DirectX instalada
$currentVersion = Get-DirectXVersion
Write-Host "Versión actual de DirectX: $currentVersion"

# Última versión de DirectX disponible
$latestVersion = "DirectX 12"  # Actualiza esto según la última versión disponible

# Comparar versiones y descargar e instalar si es necesario
if ($currentVersion -ne $latestVersion) {
    Write-Host "Actualizando a la última versión de DirectX..."
    # Descargar el instalador
    Invoke-WebRequest -Uri $directxUrl -OutFile $installerPath

    # Ejecutar el instalador
    Start-Process -FilePath $installerPath -ArgumentList "/silent" -Wait

    # Eliminar el instalador después de la instalación
    Remove-Item -Path $installerPath
    Write-Host "DirectX actualizado a la última versión."
} else {
    Write-Host "Ya tienes la última versión de DirectX instalada."
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
