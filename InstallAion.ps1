# Elevar permisos si no es administrador
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Verificar si winget está instalado
function Test-Winget {
    return Get-Command winget -ErrorAction SilentlyContinue
}

# Función para verificar la versión de DirectX
function Get-DirectXVersion {
    $dxdiag = Start-Process -FilePath "dxdiag" -ArgumentList "/t dxdiag.txt" -Wait -PassThru
    $dxdiagOutput = Get-Content -Path "dxdiag.txt"
    $versionLine = $dxdiagOutput | Select-String -Pattern "DirectX Version"
    $version = $versionLine -replace "DirectX Version: ", ""
    Remove-Item -Path "dxdiag.txt"
    return $version
}

# Verificar la versión de DirectX instalada
$currentVersion = Get-DirectXVersion
Write-Host "Versión actual de DirectX: $currentVersion"

# Última versión de DirectX esperada
$latestVersion = "DirectX 12"  # Ajustar si es necesario

# Si la versión es diferente y Winget está disponible, instalar DirectX con Winget
if ($currentVersion -ne $latestVersion) {
    if (Test-Winget) {
        Write-Host "Winget detectado. Instalando DirectX..."
        Start-Process -FilePath "winget" -ArgumentList "install Microsoft.DirectX" -Wait -NoNewWindow
        Write-Host "DirectX instalado correctamente con Winget."
    } else {
        Write-Host "Winget no encontrado. Instalación manual no disponible en este momento."
    }
} else {
    Write-Host "Ya tienes la última versión de DirectX instalada."
}

# Definir rutas
$aionFolder = "C:\Aion4.3"
$aionBat = "$aionFolder\Aion.bat"
$lnkFile = "$env:USERPROFILE\Desktop\Aion.lnk"
$iconFile = "$aionFolder\AionClient.ico"
$vbsFile = "$aionFolder\CrearAccesoDirecto.vbs"

# Si el acceso directo ya existe, omitir la creación
if (Test-Path $lnkFile) {
    Write-Host "El acceso directo ya existe. Omitiendo su creación."
    Exit
}

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

# Crear el script VBS para el acceso directo
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
