# switch-mtp-model.ps1
# MTP modell váltó — leállítja az aktuálisat, elindítja a kiválasztottat

param(
    [ValidateSet("27B", "35B", "9B", "8B", "4B", "")]
    [string]$To = ""
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Stop-LlamaServer {
    $procs = Get-Process -Name "llama-server" -ErrorAction SilentlyContinue
    if ($procs) {
        Write-Host "[STOP] llama-server leallitasa..." -ForegroundColor Yellow
        $procs | Stop-Process -Force
        Start-Sleep -Milliseconds 800
        Write-Host "[OK] Leallitva." -ForegroundColor Green
    } else {
        Write-Host "[INFO] Nem fut llama-server folyamat." -ForegroundColor Gray
    }
}

function Show-Menu {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "  MTP Model Valto - Snapdragon X Elite" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "  [1] Qwen3.6 MTP 27B  (ajanlott, port 8081)" -ForegroundColor White
    Write-Host "  [2] Qwen3.6 MTP 35B  (nagy, port 8081)" -ForegroundColor White
    Write-Host "  [3] Qwen3.5 MTP 9B   (gyors, port 8082)" -ForegroundColor White
    Write-Host "  [4] Qwen3.5 MTP 8B   (kozepes, port 8082)" -ForegroundColor White
    Write-Host "  [5] Qwen3.5 MTP 4B   (leggyorsabb, port 8082)" -ForegroundColor White
    Write-Host "  [Q] Kilepes" -ForegroundColor Gray
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    $choice = Read-Host "Valasztas"
    return $choice
}

function Start-Model {
    param([string]$Model)

    $scripts = @{
        "27B" = "start-mtp-27b-server.ps1"
        "35B" = "start-mtp-35b-server.ps1"
        "9B"  = "start-mtp-9b-server.ps1"
        "8B"  = "start-mtp-8b-server.ps1"
        "4B"  = "start-mtp-4b-server.ps1"
    }
    $portMap = @{
        "27B" = 8081
        "35B" = 8081
        "9B"  = 8082
        "8B"  = 8082
        "4B"  = 8082
    }

    $script = Join-Path $ScriptDir $scripts[$Model]

    if (-not (Test-Path $script)) {
        Write-Host "[HIBA] Szkript nem talalhato: $script" -ForegroundColor Red
        return
    }

    Write-Host ""
    Write-Host "[START] $Model szerver indul (port: $($portMap[$Model]))..." -ForegroundColor Green
    Write-Host "Web UI: http://localhost:$($portMap[$Model])" -ForegroundColor Cyan
    Write-Host ""

    & $script
}

# --- Fő logika ---

if ($To -ne "") {
    Stop-LlamaServer
    Start-Model -Model $To
} else {
    Stop-LlamaServer
    $choice = Show-Menu
    switch ($choice.ToUpper()) {
        "1" { Start-Model -Model "27B" }
        "2" { Start-Model -Model "35B" }
        "3" { Start-Model -Model "9B" }
        "4" { Start-Model -Model "8B" }
        "5" { Start-Model -Model "4B" }
        "Q" { Write-Host "Kilepes." -ForegroundColor Gray; exit 0 }
        default { Write-Host "[HIBA] Ervenytelen valasztas: $choice" -ForegroundColor Red }
    }
}
