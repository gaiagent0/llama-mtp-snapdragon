# MTP llama-server -- Qwen3.5-8B -- Snapdragon X Elite ARM64

$server = "C:\Users\istva\SnapdragonNPU_Build\install-mtp\llama-server.exe"
$model  = "E:\models\mtp-models\mtp-small\Qwen3.5-8B-UD-Q4_K_XL.gguf"

if (-not (Test-Path $server)) { Write-Host "llama-server.exe not found. Run build-mtp-llama.ps1 first." -ForegroundColor Red; exit 1 }
if (-not (Test-Path $model))  { Write-Host "Model not found: $model" -ForegroundColor Red; exit 1 }

Write-Host "MTP szerver inditasa (8B)..." -ForegroundColor Cyan
Write-Host "  Model: $model" -ForegroundColor Gray
Write-Host "  API:   http://localhost:8082/v1" -ForegroundColor Green

& $server `
    -m $model `
    --spec-type draft-mtp `
    --spec-draft-n-max 3 `
    -t 12 `
    -tb 4 `
    --flash-attn on `
    --cache-type-k q8_0 `
    --cache-type-v q8_0 `
    -c 8192 `
    -np 1 `
    --mlock `
    --host 127.0.0.1 `
    --port 8082
