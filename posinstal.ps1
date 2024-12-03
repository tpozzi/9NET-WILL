# Definicao de pastas base
$pastaBase = "C:\WILL"
$pastaApp = Join-Path -Path $pastaBase -ChildPath "APP"
$pastaScripts = Join-Path -Path $pastaBase -ChildPath "Scripts"

# Funcao para criar as pastas iniciais
function CriarEstruturaPastas {
    foreach ($pasta in @($pastaApp, $pastaScripts)) {
        if (!(Test-Path -Path $pasta)) {
            Write-Host "Criando pasta: $pasta" -ForegroundColor Cyan
            New-Item -Path $pasta -ItemType Directory | Out-Null
        } else {
            Write-Host "Pasta ja existe: $pasta" -ForegroundColor Yellow
        }
    }
}

# Funcao para renomear o hostname
function ConfigurarHostname {
    Write-Host "Verificando o hostname atual..." -ForegroundColor Cyan
    $hostnameAtual = (Get-ComputerInfo).CsName
    Write-Host "Hostname atual: $hostnameAtual" -ForegroundColor Yellow

    # Regex para verificar o padrao
    $regexPadrao = '^NB-WILL(\d{4}|\d{6})$'

    if ($hostnameAtual -match $regexPadrao) {
        Write-Host "O hostname ja esta no padrao: $hostnameAtual. Continuando..." -ForegroundColor Green
        return
    }

    # Solicitar o numero do patrimonio da empresa
    do {
        $numeroPatrimonio = Read-Host "Insira o numero do patrimonio (4 ou 6 digitos)"
        if ($numeroPatrimonio -match '^\d{4}$|^\d{6}$') {
            break
        } else {
            Write-Host "Numero invalido! Por favor, insira exatamente 4 ou 6 digitos." -ForegroundColor Red
        }
    } while ($true)

    # Gerar o novo hostname
    $novoHostname = "NB-WILL" + $numeroPatrimonio

    Write-Host "Hostname sera alterado para: $novoHostname" -ForegroundColor Cyan
    Rename-Computer -NewName $novoHostname -Force

    Write-Host "O hostname foi alterado. O sistema sera reiniciado..." -ForegroundColor Red
    Restart-Computer -Force
}

# Funcao para instalar o Ninite
function InstalarNinite {
    # URL do instalador do Ninite gerado no site
    $urlNinite = "https://ninite.com/.net4.8-.net9-.netx9-7zip-adoptjavax21-chrome-firefox-googledrivefordesktop-klitecodecs-libreoffice-notepadplusplus-zoom/ninite.exe"

    # Caminho onde o instalador sera salvo
    $caminhoArquivo = Join-Path -Path $pastaApp -ChildPath "NiniteInstaller.exe"

    Write-Host "Baixando o instalador do Ninite..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $urlNinite -OutFile $caminhoArquivo

    # Verificar se o arquivo foi baixado
    if (Test-Path $caminhoArquivo) {
        Write-Host "Instalador do Ninite baixado com sucesso: $caminhoArquivo" -ForegroundColor Green
        
        # Executar o instalador
        Write-Host "Executando o instalador do Ninite..." -ForegroundColor Cyan
        Start-Process -FilePath $caminhoArquivo -ArgumentList "/silent" -Wait
        Write-Host "Instalacao do Ninite concluida." -ForegroundColor Green
    } else {
        Write-Host "Falha ao baixar o instalador do Ninite." -ForegroundColor Red
    }
}

# Funcao para instalar o JumpCloud
function InstalarJumpCloud {
    param (
        [string]$JumpCloudConnectKey
    )
    Write-Host "Instalando o JumpCloud com a chave fornecida..." -ForegroundColor Cyan

    # Definir o caminho temporario para o script
    $tempPath = $env:temp
    $scriptPath = Join-Path -Path $tempPath -ChildPath "InstallWindowsAgent.ps1"

    # Baixar o script do JumpCloud
    Invoke-RestMethod -Method Get -Uri "https://raw.githubusercontent.com/TheJumpCloud/support/master/scripts/windows/InstallWindowsAgent.ps1" -OutFile $scriptPath

    # Executar o script com a chave fornecida
    if (Test-Path $scriptPath) {
        Write-Host "Script baixado com sucesso. Executando instalacao..." -ForegroundColor Green
        Invoke-Expression "$scriptPath -JumpCloudConnectKey '$JumpCloudConnectKey'"
        Write-Host "Instalacao do JumpCloud concluida." -ForegroundColor Green
    } else {
        Write-Host "Falha ao baixar o script do JumpCloud." -ForegroundColor Red
    }
}

# Funcao principal para instalar aplicativos
function InstalarAplicativos {
    Write-Host "Iniciando a instalacao de aplicativos..." -ForegroundColor Cyan
    
    # Chamada para instalar o Ninite
    InstalarNinite

    # Chamada para instalar o JumpCloud (substitua a chave pelo valor correto)
    InstalarJumpCloud -JumpCloudConnectKey "ff1bc9fb3510e7499582b58e298a84e41552ddab"
}

# Executar o script
Write-Host "Inicializando o processo..." -ForegroundColor Cyan

# 1. Configurar o hostname (obrigatorio)
ConfigurarHostname

# 2. Criar a estrutura de pastas
CriarEstruturaPastas

# 3. Iniciar a instalacao de aplicativos
InstalarAplicativos

Write-Host "Processo concluido!" -ForegroundColor Green
