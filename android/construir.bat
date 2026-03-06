@echo off
setlocal enabledelayedexpansion

:: Aseguramos que el script trabaje en su propio directorio
cd /d "%~dp0"

echo ==========================================
echo    MOTOR DE COMPILACION V3 - LA TRIBU
echo ==========================================
:: Usamos echo/ en lugar de echo. para evitar bugs de consola
echo/

echo ==========================================
echo    CONFIGURANDO ANDROID SDK
echo ==========================================
echo [CFG] Forzando rutas del SDK de Android...
set "ANDROID_SDK_PATH=%LOCALAPPDATA%\Android\Sdk"
if exist "C:\Users\MINIOS\AppData\Local\Android\Sdk" set "ANDROID_SDK_PATH=C:\Users\MINIOS\AppData\Local\Android\Sdk"

:: Asegurar que las barras sean correctas para local.properties
set "SDK_PROP=!ANDROID_SDK_PATH:\=/!"
:: [REPARADO] El simbolo > va al principio para evitar espacios invisibles al final de la ruta
>local.properties echo sdk.dir=!SDK_PROP!
set "ANDROID_HOME=!ANDROID_SDK_PATH!"
set "PATH=!ANDROID_SDK_PATH!\tools;!ANDROID_SDK_PATH!\platform-tools;%PATH%"

echo ==========================================
echo    CORRIGIENDO CONFIGURACION JAVA
echo ==========================================
echo [CFG] Aplicando parches de compatibilidad Java 17...

:: Parche para capacitor.build.gradle (Mejora integrada del usuario)
if exist "app\capacitor.build.gradle" (
    powershell -Command "(Get-Content 'app\capacitor.build.gradle') -replace 'JavaVersion.VERSION_21', 'JavaVersion.VERSION_17' -replace 'apply from.*cordova.variables.gradle', '' | Set-Content 'app\capacitor.build.gradle'"
)

:: Parche para plugin capacitor-updater incompatibilidad Java 17
set "BAD_JAVA=..\node_modules\@capgo\capacitor-updater\android\src\main\java\ee\forgr\capacitor_updater\DelayUpdateUtils.java"
if exist "!BAD_JAVA!" (
    powershell -Command "$path='!BAD_JAVA!'; $txt=[System.IO.File]::ReadAllText($path); $txt=$txt -replace 'case DelayUntilNext\.', 'case '; [System.IO.File]::WriteAllText($path, $txt, (New-Object System.Text.UTF8Encoding($false)))"
)

echo ==========================================
echo    LEYENDO CONFIGURACION CENTRALIZADA
echo ==========================================
if exist "build_config.bat" (
    call build_config.bat
    echo [INFO] Datos cargados. App: !CUSTOM_NAME!
) else (
    echo [ADVERTENCIA] build_config.bat no encontrado. Usando defaults.
    set "CUSTOM_NAME=miapp"
    set "ICON_PATH="
)

:: =======================================================
:: TRADUCTOR AUTOMATICO WSL -> WINDOWS Y LIMPIADOR BASH
:: =======================================================
if not "!ICON_PATH!"=="" (
    :: 1. Quitar comillas si las tiene
    set "ICON_PATH=!ICON_PATH:"=!"
    
    :: 2. Limpiar escapes de terminal Bash (ej: logo\ \(2\).png -> logo (2).png)
    set "ICON_PATH=!ICON_PATH:\ = !"
    set "ICON_PATH=!ICON_PATH:\(=(!"
    set "ICON_PATH=!ICON_PATH:\)=)!"
    
    :: 3. Convertir ruta WSL (/mnt/c/...) a Windows (C:\...)
    echo "!ICON_PATH!" | findstr /i /c:"/mnt/" >nul
    if !errorlevel! equ 0 (
        set "ICON_PATH=!ICON_PATH:/mnt/c/=C:\!"
        set "ICON_PATH=!ICON_PATH:/mnt/C/=C:\!"
    )
    
    :: 4. Convertir slashes
    set "ICON_PATH=!ICON_PATH:/=\!"
)

echo/
echo ==========================================
echo    APLICANDO CAMBIOS VISUALES
echo ==========================================
set "STRINGS_FILE=app\src\main\res\values\strings.xml"
if exist "%STRINGS_FILE%" (
    echo [CFG] Configurando nombre visible a: !CUSTOM_NAME!
    (
        echo ^<?xml version='1.0' encoding='utf-8'?^>
        echo ^<resources^>
        echo     ^<string name="app_name"^>!CUSTOM_NAME!^</string^>
        echo     ^<string name="title_activity_main"^>!CUSTOM_NAME!^</string^>
        echo     ^<string name="package_name"^>com.miapp.local^</string^>
        echo     ^<string name="custom_url_scheme"^>com.miapp.local^</string^>
        echo ^</resources^>
    ) > "%STRINGS_FILE%"
)

if not "!ICON_PATH!"=="" (
    :: Respaldo: Si la imagen no esta en android/, buscar en la raiz (..)
    set "FOUND_ICON="
    if exist "!ICON_PATH!" (
        set "FOUND_ICON=!ICON_PATH!"
    ) else if exist "..\!ICON_PATH!" (
        set "FOUND_ICON=..\!ICON_PATH!"
    )

    if not "!FOUND_ICON!"=="" (
        echo [CFG] Procesando imagen JPG/PNG: !FOUND_ICON!
        set "FINAL_ICON=!FOUND_ICON!"
        set "IS_JPG=0"
        for %%f in ("!FOUND_ICON!") do (
            if /i "%%~xf"==".jpg" set "IS_JPG=1"
            if /i "%%~xf"==".jpeg" set "IS_JPG=1"
        )
        if "!IS_JPG!"=="1" (
            echo [AUTO] Convirtiendo JPG a PNG...
            powershell -Command "Add-Type -AssemblyName System.Drawing; try { [System.Drawing.Image]::FromFile('!FOUND_ICON!').Save('icon_temp.png', [System.Drawing.Imaging.ImageFormat]::Png) } catch { exit 1 }"
            if exist "icon_temp.png" set "FINAL_ICON=icon_temp.png"
        )
        
        echo [CFG] Reemplazando iconos en carpetas mipmap...
        set "RES_FOLDERS=mipmap-mdpi mipmap-hdpi mipmap-xhdpi mipmap-xxhdpi mipmap-xxxhdpi"
        for %%D in (!RES_FOLDERS!) do (
            if exist "app\src\main\res\%%D" (
                copy /y "!FINAL_ICON!" "app\src\main\res\%%D\ic_launcher.png" >nul
                copy /y "!FINAL_ICON!" "app\src\main\res\%%D\ic_launcher_round.png" >nul
                copy /y "!FINAL_ICON!" "app\src\main\res\%%D\ic_launcher_foreground.png" >nul
            )
        )
        
        :: [CORRECCION CLAVE] Android 8+ prioriza los XML en mipmap-anydpi-v26 sobre los PNG. 
        :: Al eliminarlos, forzamos al sistema a usar nuestros PNGs
        echo [CFG] Neutralizando iconos XML por defecto de Capacitor...
        if exist "app\src\main\res\mipmap-anydpi-v26\ic_launcher.xml" del /q "app\src\main\res\mipmap-anydpi-v26\ic_launcher.xml"
        if exist "app\src\main\res\mipmap-anydpi-v26\ic_launcher_round.xml" del /q "app\src\main\res\mipmap-anydpi-v26\ic_launcher_round.xml"

        if "!IS_JPG!"=="1" if exist "icon_temp.png" del "icon_temp.png"
        echo [OK] Iconos copiados exitosamente.
    ) else (
        echo [ERROR] No se encontro el archivo de icono en: !ICON_PATH!
    )
) else (
    echo [INFO] No se definio ICON_PATH. Se usara el logo por defecto de Capacitor.
)

echo/
echo ==========================================
echo    SINCRONIZANDO CAMBIOS WEB (CRITICO)
echo ==========================================
cd ..
echo Copiando archivos de 'www' hacia 'android'...
call npx cap sync android
cd android

echo/
echo ==========================================
echo    RESTAURANDO BUILD.GRADLE PRINCIPAL
echo ==========================================
echo [AUTO] Generando build.gradle libre de errores de consola usando PowerShell...

:: LA SOLUCION AL BUCLE INUTIL:
:: En lugar de usar 'echo' que genera "ECHO esta desactivado" en las lineas vacias,
:: usamos PowerShell para escribir el archivo directamente y sin fallos.
powershell -Command "$b = @(\"// Top-level build file\", \"\", \"buildscript {\", \"    repositories {\", \"        google()\", \"        mavenCentral()\", \"    }\", \"    dependencies {\", \"        classpath 'com.android.tools.build:gradle:8.13.0'\", \"        classpath 'com.google.gms:google-services:4.4.4'\", \"    }\", \"}\", \"\", \"apply from: 'variables.gradle'\", \"\", \"allprojects {\", \"    repositories {\", \"        google()\", \"        mavenCentral()\", \"    }\", \"\", \"    // Forzar Java 17 en todos los modulos\", \"    tasks.withType(JavaCompile) {\", \"        sourceCompatibility = JavaVersion.VERSION_17\", \"        targetCompatibility = JavaVersion.VERSION_17\", \"    }\", \"}\", \"\", \"task clean(type: Delete) {\", \"    delete rootProject.buildDir\", \"}\"); [System.IO.File]::WriteAllLines('build.gradle', $b, (New-Object System.Text.UTF8Encoding($false)))"

:: Variables gradle
>variables.gradle echo ext {
>>variables.gradle echo     minSdkVersion = 24
>>variables.gradle echo     compileSdkVersion = 35
>>variables.gradle echo     targetSdkVersion = 35
>>variables.gradle echo     javaVersion = 17
>>variables.gradle echo     androidxActivityVersion = '1.9.0'
>>variables.gradle echo     androidxAppCompatVersion = '1.6.1'
>>variables.gradle echo     androidxCoordinatorLayoutVersion = '1.2.0'
>>variables.gradle echo     androidxCoreVersion = '1.13.1'
>>variables.gradle echo     androidxFragmentVersion = '1.7.1'
>>variables.gradle echo     coreSplashScreenVersion = '1.0.1'
>>variables.gradle echo     androidxWebkitVersion = '1.11.0'
>>variables.gradle echo     junitVersion = '4.13.2'
>>variables.gradle echo     androidxJunitVersion = '1.1.5'
>>variables.gradle echo     androidxEspressoCoreVersion = '3.5.1'
>>variables.gradle echo     cordovaAndroidVersion = '13.0.0'
>>variables.gradle echo }

:: Force compat gradle
>force_compat.gradle echo allprojects {
>>force_compat.gradle echo     afterEvaluate { project -^>
>>force_compat.gradle echo         if (project.hasProperty("android")) {
>>force_compat.gradle echo             android {
>>force_compat.gradle echo                 compileOptions {
>>force_compat.gradle echo                     sourceCompatibility = JavaVersion.VERSION_17
>>force_compat.gradle echo                     targetCompatibility = JavaVersion.VERSION_17
>>force_compat.gradle echo                 }
>>force_compat.gradle echo             }
>>force_compat.gradle echo         }
>>force_compat.gradle echo     }
>>force_compat.gradle echo     configurations.all {
>>force_compat.gradle echo         resolutionStrategy {
>>force_compat.gradle echo             force 'org.jetbrains.kotlin:kotlin-stdlib:1.8.22'
>>force_compat.gradle echo             force 'org.jetbrains.kotlin:kotlin-stdlib-jdk7:1.8.22'
>>force_compat.gradle echo             force 'org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.8.22'
>>force_compat.gradle echo         }
>>force_compat.gradle echo     }
>>force_compat.gradle echo }

echo/
echo ==========================================
echo    BUSCANDO JAVA 17
echo ==========================================
set "JAVA_HOME="
for /d %%D in ("C:\Program Files\Microsoft\jdk-17*") do set "JAVA_HOME=%%~fD"
if not defined JAVA_HOME for /d %%D in ("C:\Program Files\Eclipse Adoptium\jdk-17*") do set "JAVA_HOME=%%~fD"
if not defined JAVA_HOME for /d %%D in ("C:\Program Files\Java\jdk-17*") do set "JAVA_HOME=%%~fD"

if defined JAVA_HOME (
    echo [OK] Java 17 forzado en: %JAVA_HOME%
) else (
    echo [WARN] Java 17 no encontrado en rutas estandar. Dejando que Gradle decida.
)

echo ==========================================
echo    LIMPIANDO DEMONIOS Y CACHE...
echo ==========================================
call gradlew.bat --stop
call gradlew.bat clean

echo ==========================================
echo    COMPILANDO APK...
echo ==========================================
if defined JAVA_HOME (
    call gradlew.bat assembleDebug -Dorg.gradle.java.home="%JAVA_HOME%" --init-script force_compat.gradle --no-daemon
) else (
    call gradlew.bat assembleDebug --init-script force_compat.gradle --no-daemon
)

if %ERRORLEVEL% EQU 0 (
    echo/
    echo ==========================================
    echo    EXITO - MOVIENDO A CARPETA LIMPIA
    echo ==========================================
    set "SOURCE_FILE=app\build\outputs\apk\debug\app-debug.apk"
    set "TARGET_DIR=..\apks"
    set "TARGET_FILE=!TARGET_DIR!\%CUSTOM_NAME%.apk"
    
    if not exist "!TARGET_DIR!" mkdir "!TARGET_DIR!"
    if exist "!TARGET_FILE!" del "!TARGET_FILE!"
    
    move /y "!SOURCE_FILE!" "!TARGET_FILE!" >nul
    del force_compat.gradle
    
    echo [OK] LISTO! Tu APK esta en: apks\%CUSTOM_NAME%.apk
    explorer "!TARGET_DIR!"
) else (
    echo/
    echo [ERROR] Fallo la compilacion. Revisa los errores.
)
pause