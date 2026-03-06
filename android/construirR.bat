@echo off
setlocal enabledelayedexpansion

:: Aseguramos que el script trabaje en su propio directorio
cd /d "%~dp0"

echo ==========================================
echo    PERSONALIZACION DE TU APP
echo ==========================================

:: 1. PREGUNTA EL NOMBRE
set /p CUSTOM_NAME="--> Nombre de tu App (Ej: MiTienda): "
if "%CUSTOM_NAME%"=="" set CUSTOM_NAME=miapp

:: 2. PREGUNTA POR EL ICONO (CON SI/NO)
echo.
echo Desea cambiar el icono de la aplicacion?
set /p ASK_ICON="--> Escribe S (Si) o N (No): "

set "ICON_PATH="
if /i "%ASK_ICON%"=="S" goto :REQUEST_ICON
if /i "%ASK_ICON%"=="SI" goto :REQUEST_ICON
goto :SKIP_ICON_INPUT

:REQUEST_ICON
echo.
echo [INFO] Arrastra aqui tu imagen (Soporta PNG y JPG):
set /p ICON_PATH="--> Archivo: "
:: Limpiamos las comillas que Windows pone al arrastrar archivos
set "ICON_PATH=!ICON_PATH:"=!"

:SKIP_ICON_INPUT

echo.
echo ==========================================
echo    APLICANDO CAMBIOS VISUALES
echo ==========================================

:: --- A. CAMBIAR NOMBRE VISIBLE (strings.xml) ---
set "STRINGS_FILE=app\src\main\res\values\strings.xml"

if exist "%STRINGS_FILE%" (
    echo [CFG] Configurando nombre visible a: %CUSTOM_NAME%
    (
        echo ^<?xml version='1.0' encoding='utf-8'?^>
        echo ^<resources^>
        echo     ^<string name="app_name"^>%CUSTOM_NAME%^</string^>
        echo     ^<string name="title_activity_main"^>%CUSTOM_NAME%^</string^>
        echo     ^<string name="package_name"^>com.miapp.local^</string^>
        echo     ^<string name="custom_url_scheme"^>com.miapp.local^</string^>
        echo ^</resources^>
    ) > "%STRINGS_FILE%"
) else (
    echo [WARN] No se encontro strings.xml, el nombre interno no cambiara.
)

:: --- B. CAMBIAR ICONOS (CON CONVERSION AUTOMATICA) ---
if not "%ICON_PATH%"=="" (
    if exist "%ICON_PATH%" (
        echo [CFG] Procesando imagen...
        
        :: Detectamos si es JPG para convertirlo
        set "FINAL_ICON=%ICON_PATH%"
        set "IS_JPG=0"
        
        for %%f in ("%ICON_PATH%") do (
            if /i "%%~xf"==".jpg" set "IS_JPG=1"
            if /i "%%~xf"==".jpeg" set "IS_JPG=1"
        )
        
        if "!IS_JPG!"=="1" (
            echo [AUTO] Detectado JPG. Convirtiendo a PNG para Android...
            :: Usamos PowerShell para convertir la imagen real a PNG sin perder calidad
            powershell -Command "Add-Type -AssemblyName System.Drawing; try { [System.Drawing.Image]::FromFile('%ICON_PATH%').Save('icon_temp.png', [System.Drawing.Imaging.ImageFormat]::Png) } catch { exit 1 }"
            
            if exist "icon_temp.png" (
                set "FINAL_ICON=icon_temp.png"
            ) else (
                echo [ERROR] No se pudo convertir el JPG. Se intentara usar el original.
            )
        )
        
        :: Reemplazamos en todas las calidades
        if exist "!FINAL_ICON!" (
            echo [CFG] Reemplazando iconos en carpetas mipmap...
            set "RES_FOLDERS=mipmap-mdpi mipmap-hdpi mipmap-xhdpi mipmap-xxhdpi mipmap-xxxhdpi"
            
            for %%D in (!RES_FOLDERS!) do (
                set "TARGET_DIR=app\src\main\res\%%D"
                if exist "!TARGET_DIR!" (
                    copy /y "!FINAL_ICON!" "!TARGET_DIR!\ic_launcher.png" >nul
                    copy /y "!FINAL_ICON!" "!TARGET_DIR!\ic_launcher_round.png" >nul
                    copy /y "!FINAL_ICON!" "!TARGET_DIR!\ic_launcher_foreground.png" >nul
                )
            )
            
            :: Si creamos un temporal, lo borramos
            if "!IS_JPG!"=="1" del "icon_temp.png"
            echo [OK] Iconos actualizados exitosamente.
        )
        
    ) else (
        echo [ERROR] No encontre el archivo de imagen. Se usara el icono original.
    )
)

echo.
echo ==========================================
echo    SINCRONIZANDO CAMBIOS WEB (CRITICO)
echo ==========================================
echo Copiando archivos de 'www' hacia 'android'...
cd ..
call npx cap sync android
cd android

echo.
echo ==========================================
echo    BUSCANDO JAVA (PRIORIDAD: 17 LTS)
echo ==========================================

set "JAVA_HOME="
set "DETECTED_VER=0"

:: --- 1. BUSQUEDA PRIORITARIA ---
set "LOCATIONS="C:\Program Files\Eclipse Adoptium" "C:\Program Files\Java" "C:\Program Files\Microsoft""
set "STABLE_VERSIONS=17 21"

for %%V in (%STABLE_VERSIONS%) do (
    for %%L in (%LOCATIONS%) do (
        if not defined JAVA_HOME (
            for /d %%D in ("%%~L\jdk-%%V*") do (
                if exist "%%~fD\bin\javac.exe" (
                    set "JAVA_HOME=%%~fD"
                    echo [AUTO] Encontrado Java %%V: %%~fD
                    goto :VERIFY_VERSION
                )
            )
        )
    )
)

:: --- 2. FALLBACK SISTEMA ---
if not defined JAVA_HOME (
    for /f "delims=" %%i in ('where javac 2^>nul') do set "SYSTEM_JAVAC=%%i"
    if defined SYSTEM_JAVAC (
        for %%F in ("!SYSTEM_JAVAC!\..\..") do set "JAVA_HOME=%%~fF"
    )
)

:VERIFY_VERSION
if not defined JAVA_HOME (
    echo [ERROR] No se encontro Java 17.
    pause
    exit
)

set PATH=%JAVA_HOME%\bin;%PATH%
for /f "tokens=3" %%g in ('java -version 2^>^&1 ^| findstr "version"') do set "JAVA_VER_RAW=%%g"
set "JAVA_VER_RAW=!JAVA_VER_RAW:"=!"
for /f "delims=." %%v in ("!JAVA_VER_RAW!") do set "DETECTED_VER=%%v"

echo [OK] Usando Java %DETECTED_VER% en: %JAVA_HOME%

:: --- 3. REPARAR VARIABLES.GRADLE (SDK 35 / JAVA 17) ---
if exist variables.gradle (
    echo [CFG] Asegurando variables.gradle correcto...
    echo ext { > variables.gradle
    echo     minSdkVersion = 24 >> variables.gradle
    echo     compileSdkVersion = 35 >> variables.gradle
    echo     targetSdkVersion = 35 >> variables.gradle
    echo     javaVersion = 17 >> variables.gradle
    echo     androidxActivityVersion = '1.9.0' >> variables.gradle
    echo     androidxAppCompatVersion = '1.6.1' >> variables.gradle
    echo     androidxCoordinatorLayoutVersion = '1.2.0' >> variables.gradle
    echo     androidxCoreVersion = '1.13.1' >> variables.gradle
    echo     androidxFragmentVersion = '1.7.1' >> variables.gradle
    echo     coreSplashScreenVersion = '1.0.1' >> variables.gradle
    echo     androidxWebkitVersion = '1.11.0' >> variables.gradle
    echo     junitVersion = '4.13.2' >> variables.gradle
    echo     androidxJunitVersion = '1.1.5' >> variables.gradle
    echo     androidxEspressoCoreVersion = '3.5.1' >> variables.gradle
    echo     cordovaAndroidVersion = '13.0.0' >> variables.gradle
    echo } >> variables.gradle
)

:: --- 4. GENERAR SCRIPT DE FORZADO ---
echo [CFG] Creando script de anulacion de version Java y correccion Kotlin...

echo allprojects { > force_compat.gradle
echo     afterEvaluate { project -^> >> force_compat.gradle
echo         if (project.hasProperty("android")) { >> force_compat.gradle
echo             android { >> force_compat.gradle
echo                 compileOptions { >> force_compat.gradle
echo                     sourceCompatibility = JavaVersion.VERSION_17 >> force_compat.gradle
echo                     targetCompatibility = JavaVersion.VERSION_17 >> force_compat.gradle
echo                 } >> force_compat.gradle
echo             } >> force_compat.gradle
echo         } >> force_compat.gradle
echo     } >> force_compat.gradle
echo     configurations.all { >> force_compat.gradle
echo         resolutionStrategy { >> force_compat.gradle
echo             force 'org.jetbrains.kotlin:kotlin-stdlib:1.8.22' >> force_compat.gradle
echo             force 'org.jetbrains.kotlin:kotlin-stdlib-jdk7:1.8.22' >> force_compat.gradle
echo             force 'org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.8.22' >> force_compat.gradle
echo         } >> force_compat.gradle
echo     } >> force_compat.gradle
echo } >> force_compat.gradle

echo ==========================================
echo    LIMPIANDO DEMONIOS...
echo ==========================================
call gradlew.bat --stop

echo ==========================================
echo    COMPILANDO APK...
echo ==========================================

call gradlew.bat assembleDebug -Dorg.gradle.java.home="%JAVA_HOME%" --init-script force_compat.gradle --no-daemon

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ==========================================
    echo    EXITO - MOVIENDO A CARPETA LIMPIA
    echo ==========================================
    
    set "SOURCE_FILE=app\build\outputs\apk\debug\app-debug.apk"
    set "TARGET_DIR=..\apks"
    set "TARGET_FILE=!TARGET_DIR!\%CUSTOM_NAME%.apk"
    
    if not exist "!TARGET_DIR!" (
        echo [INFO] Creando carpeta apks...
        mkdir "!TARGET_DIR!"
    )
    
    if exist "!TARGET_FILE!" del "!TARGET_FILE!"
    
    move /y "!SOURCE_FILE!" "!TARGET_FILE!" >nul
    del force_compat.gradle
    
    echo.
    echo [OK] LISTO! Tu APK esta en: miapp\apks\%CUSTOM_NAME%.apk
    explorer "!TARGET_DIR!"
) else (
    echo.
    echo [ERROR] Fallo la compilacion. Revisa los errores.
)

pause