# MTP llama-server -- Qwen3.6-35B-A3B -- OPTIMALIZALT
# Snapdragon X Elite ARM64, 12 Oryon cores, CPU-only
# Build: version 9142, Clang 22.1.4
#
# Parameterek magyarazata:
#   -t 12              : 12 Oryon mag (ne tobb! efficiency core-ok lassan)
#   -tb 4              : batch threadek: prefillnel elegendo 4 (memory-bound)
#   -fa                : Flash Attention -- gyorsabb prefill, kell a KV kvantizaciohoz
#   --cache-type-k q8_0: KV cache K reszet 8-bitre kvantizalja (fele a memoria, alig veszit minosegbol)
#   --cache-type-v q8_0: KV cache V resze is 8-bites (egyutt ~2x kontextus fer el)
#   -c 16384           : 16K context (q8_0 KV-vel elfér a RAM-ban; alapból 8K volt)
#   -np 1              : csak 1 parallel slot (egyfelhasznalo, jobb egyedi sebesseg)
#   --spec-draft-n-max 3: 3 MTP reteg (modell tamogatja)
#   --mlock            : RAM-ba zarja a modellt, nem pagel ki (fontos CPU inferencial!)

$server = "C:\Users\istva\SnapdragonNPU_Build\install-mtp\llama-server.exe"
$model  = "E:\models\mtp\Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf"

Write-Host "MTP szerver inditasa (optimalizalt)..." -ForegroundColor Cyan
Write-Host "Modell: $model" -ForegroundColor Gray
Write-Host "API:    http://localhost:8081/v1" -ForegroundColor Green
Write-Host "Flash Attention + q8_0 KV cache + 16K context" -ForegroundColor Yellow

& $server `
    -m $model `
    --spec-type draft-mtp `
    --spec-draft-n-max 3 `
    -t 12 `
    -tb 4 `
    --flash-attn on `
    --cache-type-k q8_0 `
    --cache-type-v q8_0 `
    -c 16384 `
    -np 1 `
    --mlock `
    --host 127.0.0.1 `
    --port 8081
