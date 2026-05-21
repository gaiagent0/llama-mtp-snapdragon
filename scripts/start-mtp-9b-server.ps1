# start-mtp-9b-server.ps1
# Llama / Qwen3.5-9B-MTP szerver indítása Snapdragon X Elite-en
# Port: 8082 | Flash-Attn: igen | KV cache: q8_0

param(
    [string]$ModelPath = "E:\models\mtp-small\Qwen3.5-9B-MTP-UD-Q4_K_XL.gguf",
    [int]$Port = 8082,
    [int]$ContextSize = 65536,
    [int]$Threads = 12,
    [int]$GpuLayers = 0
)

$ErrorActionPreference = "Stop"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Qwen3.5 MTP 9B - Snapdragon szerver" -ForegroundColor Cyan
Write-Host "  Port: $Port | Ctx: $ContextSize" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

if (-not (Test-Path $ModelPath)) {
    Write-Host "[HIBA] Model nem talalhato: $ModelPath" -ForegroundColor Red
    Write-Host "Adj meg eleresi utat: -ModelPath <ut>" -ForegroundColor Yellow
    exit 1
}

$llamaBin = "C:\Users\istva\SnapdragonNPU_Build\install-mtp\bin\llama-server.exe"
if (-not (Test-Path $llamaBin)) {
    $llamaBin = (Get-Command "llama-server" -ErrorAction SilentlyContinue)?.Source
}
if (-not $llamaBin -or -not (Test-Path $llamaBin)) {
    Write-Host "[HIBA] llama-server nem talalhato. Futtasd elobb: build-mtp-llama.ps1" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Model: $ModelPath" -ForegroundColor Green
Write-Host "[OK] Szerver: $llamaBin" -ForegroundColor Green
Write-Host ""
Write-Host "Szerver indul... (Ctrl+C a leallitashoz)" -ForegroundColor Yellow
Write-Host "Web UI: http://localhost:$Port" -ForegroundColor Green
Write-Host ""

& $llamaBin `
    --model $ModelPath `
    --port $Port `
    --host 127.0.0.1 `
    --ctx-size $ContextSize `
    --threads $Threads `
    --spec-type draft-mtp `
    --spec-draft-n-max 6 `
    --flash-attn on `
    --cache-type-k q8_0 `
    --cache-type-v q8_0 `
    --no-mmap `
    -np 1 `
    --mlock `
    --log-disable
