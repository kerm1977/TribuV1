@echo off
setlocal enabledelayedexpansion

:: Aseguramos que el script trabaje en la carpeta 'ios'
cd /d "%~dp0"

echo ==========================================
echo    PREPARACION DE TU APP iOS (APPLE)
echo ==========================================

:: 1. PREGUNTA EL NOMBRE
set /p CUSTOM_NAME="--> Nombre de tu App en iPhone (Ej: MiTienda): "
if "%CUSTOM_NAME%"=="" set CUSTOM_NAME=TribuPlay

:: 2. PREGUNTA POR EL ICONO (CON SI/NO)
echo.
echo Desea cambiar el icono de la aplicacion en iOS?
set /p ASK_ICON="--> Escribe S (Si) o N (No): "

set "ICON_PATH="
if /i "%ASK_ICON%"=="S" goto :REQUEST_ICON
if /i "%ASK_ICON%"=="SI" goto :REQUEST_ICON
goto :SKIP_ICON_INPUT

:REQUEST_ICON
echo.
echo [INFO] Arrastra aqui tu imagen (Soporta PNG/JPG. Ideal 1024x1024px):
set /p ICON_PATH="--> Archivo: "
:: Limpiamos las comillas que Windows pone al arrastrar
set "ICON_PATH=!ICON_PATH:"=!"

:SKIP_ICON_INPUT

echo.
echo ==========================================
echo    APLICANDO CAMBIOS VISUALES (iOS)
echo ==========================================

:: --- A. CAMBIAR NOMBRE VISIBLE (Info.plist) ---
set "PLIST_FILE=App\App\Info.plist"

if exist "%PLIST_FILE%" (
    echo [CFG] Configurando nombre visible a: %CUSTOM_NAME%
    :: Usamos un Regex en PowerShell para inyectar el nombre en el XML de Apple
    powershell -Command "$content = Get-Content '%PLIST_FILE%' -Raw; $content = $content -replace '(?s)<key>CFBundleDisplayName</key>\s*<string>.*?</string>', '<key>CFBundleDisplayName</key><string>%CUSTOM_NAME%</string>'; Set-Content '%PLIST_FILE%' -Value $content -Encoding UTF8"
) else (
    echo [WARN] No se encontro Info.plist. El nombre interno no cambiara.
)

:: --- B. CAMBIAR ICONOS (CON REDIMENSIONAMIENTO PARA APPLE) ---
if not "%ICON_PATH%"=="" (
    if exist "%ICON_PATH%" (
        echo [CFG] Generando las 9 resoluciones exactas para iPhone...
        set "IOS_ICON_DIR=App\App\Assets.xcassets\AppIcon.appiconset"
        
        if exist "!IOS_ICON_DIR!" (
            :: Usamos PowerShell para crear multiples imagenes en alta calidad al instante
            powershell -Command "Add-Type -AssemblyName System.Drawing; try { $img = [System.Drawing.Image]::FromFile('%ICON_PATH%'); function Resize($s, $n) { $b = New-Object System.Drawing.Bitmap $s, $s; $g = [System.Drawing.Graphics]::FromImage($b); $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic; $g.DrawImage($img, 0, 0, $s, $s); $b.Save(\"!IOS_ICON_DIR!\$n\", [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $b.Dispose(); }; Resize 40 'AppIcon-20x20@2x.png'; Resize 60 'AppIcon-20x20@3x.png'; Resize 58 'AppIcon-29x29@2x.png'; Resize 87 'AppIcon-29x29@3x.png'; Resize 80 'AppIcon-40x40@2x.png'; Resize 120 'AppIcon-40x40@3x.png'; Resize 120 'AppIcon-60x60@2x.png'; Resize 180 'AppIcon-60x60@3x.png'; Resize 1024 'AppIcon-512@2x.png'; $img.Dispose(); } catch { exit 1 }"
            
            echo [OK] Iconos actualizados exitosamente en formato Apple.
        ) else (
            echo [ERROR] No se encontro la carpeta AppIcon.appiconset.
        )
    ) else (
        echo [ERROR] No encontre el archivo de imagen. Se usara el icono original.
    )
)

echo.
echo ==========================================
echo    SINCRONIZANDO CAMBIOS WEB A IOS
echo ==========================================
echo Copiando archivos de 'www' hacia la estructura de Mac...
cd ..
call npx cap sync ios
cd ios

echo.
echo ==========================================
echo    ESTADO: LISTO PARA EXPORTAR A MAC
echo ==========================================
echo.
echo [ ALERTA DE COMPILACION ]
echo Apple NO permite compilar el instalable final (.ipa) desde Windows.
echo.
echo TU PROYECTO ESTA CONFIGURADO. Siguientes pasos:
echo 1. Pasa la carpeta de tu proyecto (o subela a GitHub) hacia una Mac.
echo 2. En la Mac, abre el archivo "ios\App\App.xcworkspace" usando Xcode.
echo 3. Dale al boton "Play" para emular, o a "Product > Archive" para exportar.
echo.
echo Opciones si no tienes una computadora Mac fisica:
echo - Instalar una Maquina Virtual con macOS (Hackintosh/VMware).
echo - Alquilar una Mac online (MacinCloud).
echo - Usar la nube oficial de Ionic (Ionic Appflow) para compilar.
echo.
pause