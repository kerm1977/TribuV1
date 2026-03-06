# =============================================================================
#  ANDROID BUILDER GUI PRO v3.0
#  Requiere Windows con PowerShell (Instalado por defecto)
# =============================================================================
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- CONFIGURACIÓN INICIAL ---
$scriptPath = $PSScriptRoot
Set-Location $scriptPath

# Rutas clave
$stringsXml = Join-Path $scriptPath "app\src\main\res\values\strings.xml"
$resFolder = Join-Path $scriptPath "app\src\main\res"

# --- DISEÑO DE LA VENTANA ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "Android Builder Studio PRO"
$form.Size = New-Object System.Drawing.Size(500, 520)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(245, 247, 250)

# Estilo de fuente
$fontTitle = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$fontNormal = New-Object System.Drawing.Font("Segoe UI", 10)
$fontSmall = New-Object System.Drawing.Font("Segoe UI", 8)

# 1. SECCIÓN NOMBRE
$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "Configuración de la App"
$lblTitle.Location = New-Object System.Drawing.Point(20, 20)
$lblTitle.AutoSize = $true
$lblTitle.Font = $fontTitle
$lblTitle.ForeColor = [System.Drawing.Color]::FromArgb(45, 55, 72)
$form.Controls.Add($lblTitle)

$lblApp = New-Object System.Windows.Forms.Label
$lblApp.Text = "Nombre de la Aplicación:"
$lblApp.Location = New-Object System.Drawing.Point(25, 60)
$lblApp.AutoSize = $true
$lblApp.Font = $fontNormal
$form.Controls.Add($lblApp)

$txtName = New-Object System.Windows.Forms.TextBox
$txtName.Location = New-Object System.Drawing.Point(25, 85)
$txtName.Size = New-Object System.Drawing.Size(430, 30)
$txtName.Font = $fontNormal
$txtName.Text = "MiApp"
$form.Controls.Add($txtName)

# 2. SECCIÓN ICONO
$grpIcon = New-Object System.Windows.Forms.GroupBox
$grpIcon.Text = "Icono Personalizado"
$grpIcon.Location = New-Object System.Drawing.Point(25, 130)
$grpIcon.Size = New-Object System.Drawing.Size(430, 120)
$grpIcon.Font = $fontNormal
$form.Controls.Add($grpIcon)

$btnSelect = New-Object System.Windows.Forms.Button
$btnSelect.Text = "Seleccionar Imagen (PNG)..."
$btnSelect.Location = New-Object System.Drawing.Point(20, 30)
$btnSelect.Size = New-Object System.Drawing.Size(200, 35)
$btnSelect.BackColor = [System.Drawing.Color]::White
$grpIcon.Controls.Add($btnSelect)

$lblIconPath = New-Object System.Windows.Forms.Label
$lblIconPath.Text = "Ningún archivo seleccionado"
$lblIconPath.Location = New-Object System.Drawing.Point(20, 75)
$lblIconPath.Size = New-Object System.Drawing.Size(250, 40)
$lblIconPath.Font = $fontSmall
$lblIconPath.ForeColor = [System.Drawing.Color]::Gray
$grpIcon.Controls.Add($lblIconPath)

$picPreview = New-Object System.Windows.Forms.PictureBox
$picPreview.Location = New-Object System.Drawing.Point(340, 20)
$picPreview.Size = New-Object System.Drawing.Size(80, 80)
$picPreview.SizeMode = "Zoom"
$picPreview.BorderStyle = "FixedSingle"
$picPreview.BackColor = [System.Drawing.Color]::White
$grpIcon.Controls.Add($picPreview)

# Variable global para guardar la ruta de la imagen
$global:selectedIconPath = $null

$btnSelect.Add_Click({
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Filter = "Imágenes PNG|*.png|Todos los archivos|*.*"
    $openFileDialog.Title = "Selecciona el icono de tu App (Preferiblemente 1024x1024)"
    
    if ($openFileDialog.ShowDialog() -eq "OK") {
        $global:selectedIconPath = $openFileDialog.FileName
        $lblIconPath.Text = $openFileDialog.SafeFileName
        
        # Cargar vista previa
        try {
            $img = [System.Drawing.Image]::FromFile($global:selectedIconPath)
            $picPreview.Image = $img
        } catch {
            $lblIconPath.Text = "Error al cargar imagen"
        }
    }
})

# 3. SECCIÓN PROGRESO
$txtLog = New-Object System.Windows.Forms.TextBox
$txtLog.Location = New-Object System.Drawing.Point(25, 270)
$txtLog.Size = New-Object System.Drawing.Size(430, 100)
$txtLog.Multiline = $true
$txtLog.ScrollBars = "Vertical"
$txtLog.ReadOnly = $true
$txtLog.Font = New-Object System.Drawing.Font("Consolas", 8)
$txtLog.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$txtLog.ForeColor = [System.Drawing.Color]::FromArgb(0, 255, 0)
$txtLog.Text = "Listo para compilar..."
$form.Controls.Add($txtLog)

# 4. BOTÓN COMPILAR
$btnBuild = New-Object System.Windows.Forms.Button
$btnBuild.Text = "GENERAR APK AHORA"
$btnBuild.Location = New-Object System.Drawing.Point(25, 390)
$btnBuild.Size = New-Object System.Drawing.Size(430, 50)
$btnBuild.BackColor = [System.Drawing.Color]::FromArgb(79, 70, 229) # Indigo
$btnBuild.ForeColor = [System.Drawing.Color]::White
$btnBuild.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$btnBuild.FlatStyle = "Flat"
$form.Controls.Add($btnBuild)

# --- FUNCIONES DE LÓGICA ---

function Log-Message($msg) {
    $txtLog.AppendText("`r`n> $msg")
    $txtLog.SelectionStart = $txtLog.Text.Length
    $txtLog.ScrollToCaret()
    $form.Update() # Forzar refresco UI
}

function Resize-Image($srcPath, $destPath, $size) {
    try {
        $srcImage = [System.Drawing.Image]::FromFile($srcPath)
        $newBitmap = New-Object System.Drawing.Bitmap($size, $size)
        $graphics = [System.Drawing.Graphics]::FromImage($newBitmap)
        
        # Alta calidad
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        
        $graphics.DrawImage($srcImage, 0, 0, $size, $size)
        $newBitmap.Save($destPath, [System.Drawing.Imaging.ImageFormat]::Png)
        
        $graphics.Dispose()
        $newBitmap.Dispose()
        $srcImage.Dispose()
    } catch {
        Log-Message "Error redimensionando imagen: $_"
    }
}

$btnBuild.Add_Click({
    $btnBuild.Enabled = $false
    $btnBuild.Text = "Procesando... Espere"
    $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    
    # 1. ACTUALIZAR NOMBRE
    $appName = $txtName.Text
    Log-Message "Configurando nombre: $appName"
    
    if (Test-Path $stringsXml) {
        $xmlContent = @"
<?xml version='1.0' encoding='utf-8'?>
<resources>
    <string name=""app_name"">$appName</string>
    <string name=""title_activity_main"">$appName</string>
    <string name=""package_name"">com.miapp.local</string>
    <string name=""custom_url_scheme"">com.miapp.local</string>
</resources>
"@
        Set-Content -Path $stringsXml -Value $xmlContent -Encoding UTF8
    }

    # 2. PROCESAR ICONOS (REDIMENSIONADO INTELIGENTE)
    if ($global:selectedIconPath) {
        Log-Message "Generando iconos..."
        
        # Mapa de resoluciones Android
        $sizes = @{
            "mipmap-mdpi"    = 48
            "mipmap-hdpi"    = 72
            "mipmap-xhdpi"   = 96
            "mipmap-xxhdpi"  = 144
            "mipmap-xxxhdpi" = 192
        }
        
        foreach ($folder in $sizes.Keys) {
            $targetDir = Join-Path $resFolder $folder
            $size = $sizes[$folder]
            
            if (Test-Path $targetDir) {
                # Generar Launcher normal
                Resize-Image $global:selectedIconPath (Join-Path $targetDir "ic_launcher.png") $size
                # Generar Redondo
                Resize-Image $global:selectedIconPath (Join-Path $targetDir "ic_launcher_round.png") $size
                # Generar Foreground (para adaptativos)
                Resize-Image $global:selectedIconPath (Join-Path $targetDir "ic_launcher_foreground.png") $size
                Log-Message " - $folder ($size px) OK"
            }
        }
    }

    # 3. BUSCAR JAVA (Lógica portada del .bat)
    Log-Message "Buscando Java 17..."
    $javaLocations = @(
        "C:\Program Files\Eclipse Adoptium",
        "C:\Program Files\Java",
        "C:\Program Files\Microsoft"
    )
    $targetJava = $null
    
    foreach ($loc in $javaLocations) {
        if (Test-Path $loc) {
            $found = Get-ChildItem -Path $loc -Filter "jdk-17*" -Directory -ErrorAction SilentlyContinue
            if ($found) {
                $targetJava = Join-Path $found[0].FullName "bin\java.exe"
                $targetJavaHome = $found[0].FullName
                break
            }
        }
    }
    
    if (-not $targetJava) {
        # Fallback Java 21
        foreach ($loc in $javaLocations) {
            if (Test-Path $loc) {
                $found = Get-ChildItem -Path $loc -Filter "jdk-21*" -Directory -ErrorAction SilentlyContinue
                if ($found) {
                    $targetJava = Join-Path $found[0].FullName "bin\java.exe"
                    $targetJavaHome = $found[0].FullName
                    break
                }
            }
        }
    }

    if ($targetJava) {
        Log-Message "Java encontrado en: $targetJavaHome"
        
        # 4. PREPARAR SCRIPT DE COMPATIBILIDAD (force_compat.gradle)
        $compatScript = @"
allprojects {
    afterEvaluate { project ->
        if (project.hasProperty("android")) {
            android {
                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_17
                    targetCompatibility = JavaVersion.VERSION_17
                }
            }
        }
    }
    configurations.all {
        resolutionStrategy {
            force 'org.jetbrains.kotlin:kotlin-stdlib:1.8.22'
            force 'org.jetbrains.kotlin:kotlin-stdlib-jdk7:1.8.22'
            force 'org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.8.22'
        }
    }
}
"@
        Set-Content -Path "force_compat.gradle" -Value $compatScript

        # 5. EJECUTAR GRADLE
        Log-Message "Iniciando compilación... (Esto puede tardar)"
        
        $gradleCmd = ".\gradlew.bat"
        $argsList = "assembleDebug", "-Dorg.gradle.java.home=`"$targetJavaHome`"", "--init-script", "force_compat.gradle", "--no-daemon"
        
        $processInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processInfo.FileName = $gradleCmd
        $processInfo.Arguments = $argsList -join " "
        $processInfo.RedirectStandardOutput = $true
        $processInfo.RedirectStandardError = $true
        $processInfo.UseShellExecute = $false
        $processInfo.CreateNoWindow = $true
        
        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $processInfo
        
        # Capturar salida en tiempo real (Simplificado para evitar bloqueo UI)
        $process.Start() | Out-Null
        $process.WaitForExit()
        
        if ($process.ExitCode -eq 0) {
            Log-Message "COMPILACIÓN EXITOSA!"
            
            # Mover archivo
            $sourceApk = "app\build\outputs\apk\debug\app-debug.apk"
            $destDir = "..\apks"
            if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir | Out-Null }
            
            $finalName = "$appName.apk"
            $destFile = Join-Path $destDir $finalName
            
            if (Test-Path $sourceApk) {
                Copy-Item -Path $sourceApk -Destination $destFile -Force
                Log-Message "APK guardado en: apks\$finalName"
                [System.Diagnostics.Process]::Start("explorer.exe", $destDir)
            }
        } else {
            Log-Message "ERROR EN LA COMPILACIÓN"
            Log-Message "Revisa la consola para más detalles."
        }
        
        # Limpieza
        if (Test-Path "force_compat.gradle") { Remove-Item "force_compat.gradle" }
        
    } else {
        Log-Message "ERROR: No se encontró Java 17. Instálalo primero."
        [System.Windows.Forms.MessageBox]::Show("Por favor instala JDK 17", "Error", "OK", "Error")
    }

    $btnBuild.Text = "GENERAR APK AHORA"
    $btnBuild.Enabled = $true
    $form.Cursor = [System.Windows.Forms.Cursors]::Default
})

$form.ShowDialog()