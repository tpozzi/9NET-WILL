# Verifica se o script está rodando como Administrador
function Check-Admin {
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($currentUser)
    $isAdmin = $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        Write-Host "⚠️ Este script precisa ser executado como Administrador!" -ForegroundColor Red
        Exit
    }
}
Check-Admin

# Criar pasta temporária para downloads
$downloadPath = "$env:TEMP\Instaladores"
if (!(Test-Path -Path $downloadPath)) {
    New-Item -ItemType Directory -Path $downloadPath | Out-Null
}

# Criar arquivo de log
$logFile = "$downloadPath\install_log.txt"
if (Test-Path $logFile) { Remove-Item $logFile -Force }
New-Item -ItemType File -Path $logFile | Out-Null

# Lista de programas com seus nomes e URLs de download
$programs = @(
    @{ Name="Power BI"; Check="Power BI Desktop"; URL="https://download.microsoft.com/download/8/8/0/880bca75-79dd-466a-927d-1abf1f5454b0/PBIDesktopSetup_x64.exe"; Args="/quiet /norestart"; },
    @{ Name="Java JDK 21"; Check="JDK 21"; URL="https://download.oracle.com/java/21/archive/jdk-21.0.5_windows-x64_bin.msi"; Args="/quiet /norestart"; },
    @{ Name="Python"; Check="Python"; URL="https://www.python.org/ftp/python/3.12.1/python-3.12.1-amd64.exe"; Args="/quiet InstallAllUsers=1 PrependPath=1"; },
    @{ Name="IntelliJ IDEA Community"; Check="IntelliJ IDEA Community Edition"; URL="https://download.jetbrains.com/idea/ideaIC-2023.3.3.exe"; Args="/S"; },
    @{ Name="FileZilla"; Check="FileZilla Client"; URL="https://download.filezilla-project.org/client/FileZilla_3.66.5_win64-setup.exe"; Args="/S"; },
    @{ Name="Git"; Check="Git"; URL="https://github.com/git-for-windows/git/releases/latest/download/Git-2.44.0-64-bit.exe"; Args="/SILENT"; },
    @{ Name="Visual Studio Community"; Check="Visual Studio Community"; URL="https://aka.ms/vs/17/release/vs_Community.exe"; Args="--quiet --wait --norestart --installPath C:\Program Files\Microsoft Visual Studio\2022\Community"; }
)

# Função para verificar se um programa está instalado
function Is-Installed($programName) {
    $registryPaths = @(
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    
    foreach ($path in $registryPaths) {
        $installed = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match $programName }
        if ($installed) { return $true }
    }
    return $false
}

# Baixar e instalar cada programa
foreach ($program in $programs) {
    $installerPath = "$downloadPath\$($program.Name).exe"

    if (Is-Installed $program.Check) {
        Write-Host "✔️ $($program.Name) já está instalado. Pulando instalação." -ForegroundColor Green
        Add-Content -Path $logFile -Value "$($program.Name) já instalado. Ignorado."
        Continue
    }

    Write-Host "⬇️ Baixando $($program.Name)..."
    try {
        Invoke-WebRequest -Uri $program.URL -OutFile $installerPath -ErrorAction Stop
        Write-Host "✅ Download de $($program.Name) concluído!" -ForegroundColor Cyan
        Add-Content -Path $logFile -Value "$($program.Name) baixado com sucesso."
    } catch {
        Write-Host "❌ Falha ao baixar $($program.Name). Verifique a URL." -ForegroundColor Red
        Add-Content -Path $logFile -Value "Erro ao baixar $($program.Name)."
        Continue
    }

    Write-Host "⚙️ Instalando $($program.Name)..."
    try {
        Start-Process -FilePath $installerPath -ArgumentList $program.Args -Wait -NoNewWindow
        Write-Host "✅ $($program.Name) instalado com sucesso!" -ForegroundColor Green
        Add-Content -Path $logFile -Value "$($program.Name) instalado com sucesso."
    } catch {
        Write-Host "❌ Erro ao instalar $($program.Name)." -ForegroundColor Red
        Add-Content -Path $logFile -Value "Erro ao instalar $($program.Name)."
    }
}

# Limpeza dos arquivos de instalação
Write-Host "🧹 Limpando instaladores..."
Remove-Item -Path "$downloadPath\*" -Force
Write-Host "🚀 Instalação concluída! Veja o log em $logFile" -ForegroundColor Magenta
