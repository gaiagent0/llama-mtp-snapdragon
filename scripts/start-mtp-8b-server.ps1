# MTP llama-server -- Qwen3-8B
# Snapdragon X Elite ARM64, 12 Oryon cores, CPU-only
# Build: version 9142, Clang 22.1.4
# Port: 8082 (a 35B-A3B a 8081-en van)
#
# RAM becslés: ~8.5 GB (Q8) vagy ~4.5 GB (Q4) -- nagy kontextus lehetseges
# Hasznalat: hosszu kontextus (32K+), gyors valasz, cron agent feladatok
#
#   -fa                : Flash Attention
#   --cache-type-k q4_0: 4-bites KV K (agressziv, de 32K+ ctx-hez kell)
#   --cache-type-v q8_0: V marad 8-bites (jobb minoseg)
#   -c 32768           : 32K kontextus
#   -np 1              : egyfelhasznalo, max sebesség
#   --mlock            : ne pagelejen ki

$server = "C:\Users\istva\SnapdragonNPU_Build\install-mtp\llama-server.exe"

# Automatikusan megkeresi a letöltött modellt
$modelDir = "E:\models\new_models"
$modelFile = Get-ChildItem $modelDir -Filter "*.gguf" -Recurse -EA SilentlyContinue |
             Sort-Object Length -Descending | Select-Object -First 1

if (-not $modelFile) {
    Write-Host "HIBA: Qwen3-8B modell nem talalhato: $modelDir" -ForegroundColor Red
    Write-Host "Toltsd le: hf download unsloth/Qwen3-8B-GGUF --include '*UD-Q8*' --local-dir E:\models\new_models" -ForegroundColor Yellow
    exit 1
}

$model = $modelFile.FullName
Write-Host "MTP szerver inditasa (Qwen3-8B, gyors)..." -ForegroundColor Cyan
Write-Host "Modell: $model ($([math]::Round($modelFile.Length/1GB,1)) GB)" -ForegroundColor Gray
Write-Host "API:    http://localhost:8082/v1" -ForegroundColor Green
Write-Host "Flash Attention + q4/q8 KV cache + 32K context" -ForegroundColor Yellow

& $server `
    -m $model `
    --spec-type draft-mtp `
    --spec-draft-n-max 3 `
    -t 12 `
    -tb 4 `
    --flash-attn on `
    --cache-type-k q4_0 `
    --cache-type-v q8_0 `
    -c 32768 `
    -np 1 `
    --mlock `
    --host 127.0.0.1 `
    --port 8082
