# MTP Model Toggle -- swap between 35B-A3B (quality) and 8B (speed/long ctx)
# Hasznalat: & "C:\AI\scripts\switch-mtp-model.ps1" [-To35B] [-To8B]
param(
    [switch]$To35B,
    [switch]$To8B
)

$server35B = "C:\AI\scripts\start-mtp-server.ps1"
$server8B  = "C:\AI\scripts\start-mtp-8b-server.ps1"

function Get-MtpProcess {
    Get-Process -Name llama-server -EA SilentlyContinue
}

function Show-Status {
    $procs = Get-MtpProcess
    if (-not $procs) {
        Write-Host "  Nincs futo llama-server" -ForegroundColor Gray
        return
    }
    foreach ($p in $procs) {
        $mb = [math]::Round($p.WorkingSet64/1MB, 0)
        Write-Host ("  PID {0} | RAM: {1} MB | fut: {2} perce" -f $p.Id, $mb, [math]::Round((Get-Date - $p.StartTime).TotalMinutes, 0)) -ForegroundColor Cyan
    }
}

function Get-FreeRAM {
    $os = Get-CimInstance Win32_OperatingSystem
    return [math]::Round($os.FreePhysicalMemory/1KB, 0)
}

function Stop-MtpServer {
    $procs = Get-MtpProcess
    if ($procs) {
        Write-Host "Leallitas..." -ForegroundColor Yellow
        $procs | Stop-Process -Force
        Start-Sleep -Seconds 3
        Write-Host "OK  llama-server leallitva" -ForegroundColor Green
    } else {
        Write-Host "  Nem fut llama-server, nincs mit leallitani" -ForegroundColor Gray
    }
}

# --- Interaktiv menu ha nincs flag ---
if (-not $To35B -and -not $To8B) {
    Write-Host ""
    Write-Host "=== MTP Model Toggle ===" -ForegroundColor Magenta
    Write-Host "Jelenlegi allapot:" -ForegroundColor Cyan
    Show-Status
    $freeGB = [math]::Round((Get-FreeRAM), 0)
    Write-Host ("Szabad RAM: {0} GB" -f $freeGB) -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] Valtas 35B-A3B-re  (miniseg, 16K ctx, ~22 GB RAM)" -ForegroundColor White
    Write-Host "  [2] Valtas 8B-re       (gyors, 32K ctx, ~10 GB RAM)"   -ForegroundColor White
    Write-Host "  [3] Mindketto leallitasa"                                -ForegroundColor White
    Write-Host "  [Q] Kilepes"                                             -ForegroundColor White
    Write-Host ""
    $choice = Read-Host "Valasztas"

    switch ($choice) {
        "1" { $To35B = $true }
        "2" { $To8B  = $true }
        "3" { Stop-MtpServer; exit 0 }
        default { Write-Host "Kilepes" -ForegroundColor Gray; exit 0 }
    }
}

# --- Vegrehajtas ---
Write-Host ""
if ($To35B) {
    Write-Host "=== Valtas: 35B-A3B (miniseg, 16K ctx) ===" -ForegroundColor Magenta
    Stop-MtpServer
    Write-Host "Inditasa: start-mtp-server.ps1 ..." -ForegroundColor Cyan
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$server35B`"" -WindowStyle Normal
    Start-Sleep -Seconds 5
    Write-Host "OK  35B-A3B szerver elindult (port 8081)" -ForegroundColor Green
    Write-Host "    Varj ~30 masodpercet amig betolt" -ForegroundColor Gray
}

if ($To8B) {
    Write-Host "=== Valtas: Qwen3-8B (gyors, 32K ctx) ===" -ForegroundColor Magenta
    Stop-MtpServer
    Write-Host "Inditasa: start-mtp-8b-server.ps1 ..." -ForegroundColor Cyan
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$server8B`"" -WindowStyle Normal
    Start-Sleep -Seconds 5
    Write-Host "OK  8B szerver elindult (port 8082)" -ForegroundColor Green
    Write-Host "    Varj ~10 masodpercet amig betolt" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Szabad RAM most: $([math]::Round((Get-FreeRAM),0)) GB" -ForegroundColor Cyan
