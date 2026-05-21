# llama.cpp MTP — Snapdragon X Elite — README
# vivo2 gép, 2026-05-15

## Fontos: MTP hivatalosan merged (2026-05-16)

llama.cpp MTP upstream master-be beolvasztva 2026-05-16-an.
PR #22673 branch merge tobbe nem szukseges — egyszeru git pull + ujraforditas eleg:

  cd C:\Users\istva\SnapdragonNPU_Build\llama-mtp
  git checkout master
  git pull
  & "C:\AI\npu\build-mtp-llama.ps1" -SkipDownload

## Hardver
- CPU: Snapdragon X Elite (12 Oryon mag)
- RAM: 32 GB LPDDR5X
- GPU/NPU: Adreno — llama.cpp-ben NEM használható (Vulkan crashel, NPU csak ONNX)
- OS: Windows 11 ARM64

## Build
- Repo: C:\Users\istva\SnapdragonNPU_Build\llama-mtp\
- Build dir: C:\Users\istva\SnapdragonNPU_Build\llama-mtp-build\
- Install: C:\Users\istva\SnapdragonNPU_Build\install-mtp\
- Verzió: 9142, Clang 22.1.4, ARM64 CPU-only
- PR #22673 (MTP Support) merge-elve — https://github.com/ggml-org/llama.cpp/pull/22673
- Rebuild szkript: C:\AI\npu\build-mtp-llama.ps1

### cmake paraméterek
```
cmake -S . -B build -G Ninja
  -DCMAKE_C_COMPILER="C:\Program Files\LLVM\bin\clang-cl.exe"
  -DCMAKE_CXX_COMPILER="C:\Program Files\LLVM\bin\clang-cl.exe"
  -DCMAKE_MAKE_PROGRAM=C:\tools\ninja.exe
  -DCMAKE_C_FLAGS="/O2 /arch:ARMv8.2 /EHsc"
  -DCMAKE_CXX_FLAGS="/O2 /arch:ARMv8.2 /EHsc"
  -DGGML_CUDA=OFF -DGGML_VULKAN=OFF -DGGML_OPENCL=OFF
  -DGGML_OPENMP=OFF -DGGML_NATIVE=OFF -DLLAMA_AVX=OFF
  -DLLAMA_BUILD_SERVER=ON -DLLAMA_BUILD_TESTS=OFF
  -DLLAMA_BUILD_EXAMPLES=ON -DLLAMA_CURL=OFF
```

## Modellek

### Aktiv modellek
| Fajl | Meret | Helye | MTP | Context | Hasznalat |
|---|---|---|---|---|---|
| Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf | 21.28 GB | E:\models\mtp\ | 3 reteg | 262K | Minoseg, agent, 8081 |
| Qwen3.5-9B-MTP-UD-Q4_K_XL.gguf  | ~5.5 GB  | E:\models\mtp-small\ | 6 reteg | 262K | Gyors, nagy ctx, 8082 |
| Qwen3.5-4B-MTP-UD-Q4_K_XL.gguf  | ~2.5 GB  | E:\models\mtp-small\ | 6 reteg | 262K | Hermes, mindig fut, 8083 |
| Qwen3.5-2B-MTP-UD-Q4_K_XL.gguf  | ~1.3 GB  | E:\models\mtp-small\ | 6 reteg | 262K | Nagyon gyors, kis feladat |

### TOROLT / NEM MTP
| Fajl | Oka |
|---|---|
| Qwen3-8B-UD-Q8_K_XL.gguf | NEM MTP — sima Qwen3-8B, 32K ctx, draft-mtp flag hibat adott |

### Letoltes parancsok
```powershell
$hf = "C:\Users\istva\AppData\Local\Programs\Python\Python313-arm64\Scripts\hf.exe"

# 9B MTP (csere a regi 8B helyett)
& $hf download unsloth/Qwen3.5-9B-MTP-GGUF --include "*UD-Q4_K_XL*" --local-dir E:\models\mtp-small

# 4B MTP (Hermes, kis feladatok, elfér 35B mellett)
& $hf download unsloth/Qwen3.5-4B-MTP-GGUF --include "*UD-Q4_K_XL*" --local-dir E:\models\mtp-small

# 2B MTP (opcionalis, nagyon gyors)
& $hf download unsloth/Qwen3.5-2B-MTP-GGUF --include "*UD-Q4_K_XL*" --local-dir E:\models\mtp-small
```

### Parhuzamos futasi lehetosegek (32 GB RAM)
| Kombó | RAM | Megj. |
|---|---|---|
| 35B-A3B + 4B-MTP | ~23.5 GB | FERHET EGYUTT |
| 35B-A3B + 9B-MTP | ~26.5 GB | FERHET EGYUTT |
| 9B-MTP + 4B-MTP  | ~8 GB    | Boven fer, Hermes stack |

Forras: unsloth/Qwen3.5-*-MTP-GGUF (HuggingFace)
Letolto: C:\Users\istva\AppData\Local\Programs\Python\Python313-arm64\Scripts\hf.exe

## Indítás

### 35B-A3B (minoseg, 262K ctx, ~22 GB RAM) — port 8081
Szkript: C:\AI\scripts\start-mtp-server.ps1
```
llama-server.exe -m E:\models\mtp\Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf
  --spec-type draft-mtp --spec-draft-n-max 3
  -t 12 -tb 4 --flash-attn on
  --cache-type-k q8_0 --cache-type-v q8_0
  -c 16384 -np 1 --mlock
  --host 127.0.0.1 --port 8081
```

### Qwen3.5-9B-MTP (gyors, 262K ctx, ~5.5 GB RAM) — port 8082
Szkript: C:\AI\scripts\start-mtp-9b-server.ps1
```
llama-server.exe -m E:\models\mtp-small\Qwen3.5-9B-MTP-UD-Q4_K_XL.gguf
  --spec-type draft-mtp --spec-draft-n-max 6
  -t 12 -tb 4 --flash-attn on
  --cache-type-k q4_0 --cache-type-v q8_0
  -c 65536 -np 1 --mlock
  --host 127.0.0.1 --port 8082
```

### Qwen3.5-4B-MTP (Hermes, 262K ctx, ~2.5 GB RAM) — port 8083
Szkript: C:\AI\scripts\start-mtp-4b-server.ps1
Megjegyzés: elfér a 35B-A3B MELLETT egyutt (23.5 GB ossz)
```
llama-server.exe -m E:\models\mtp-small\Qwen3.5-4B-MTP-UD-Q4_K_XL.gguf
  --spec-type draft-mtp --spec-draft-n-max 6
  -t 8 -tb 4 --flash-attn on
  --cache-type-k q4_0 --cache-type-v q4_0
  -c 32768 -np 2 --mlock
  --host 127.0.0.1 --port 8083
```

### Toggle (switch-mtp-model.ps1) — csak 35B/9B egymashoz
Szkript: C:\AI\scripts\switch-mtp-model.ps1
```powershell
& "C:\AI\scripts\switch-mtp-model.ps1"        # interaktiv menu
& "C:\AI\scripts\switch-mtp-model.ps1" -To35B
& "C:\AI\scripts\switch-mtp-model.ps1" -To8B  # -> 9B-re frissitendo
```

## Paraméterek magyarázata
| Paraméter | Ertek | Miert |
|---|---|---|
| --spec-type | draft-mtp | MTP backend (NEM 'mtp' — az hibat ad!) |
| --spec-draft-n-max | 3 | Qwen3.6-35B-A3B: 3 MTP reteg |
| --spec-draft-n-max | 6 | Qwen3.5-9B/4B/2B-MTP: 6 MTP reteg (nagyobb gyorsulas) |
| -t | 12 | 12 Oryon mag (35B, 9B) |
| -t | 8 | 8 Oryon mag (4B, 2B — nem kell tobb) |
| -tb | 4 | batch thread — prefill memory-bound, 4 eleg |
| --flash-attn on | on | gyorsabb prefill, KV kvantizaciohoz kell |
| --cache-type-k/v | q8_0 | KV cache tomorities: 2-3x kisebb, ~0 minosegvesztes |
| --cache-type-k/v | q4_0 | Kis modelleknel + nagy ctx-nel: 4x kisebb |
| -c | 16384/65536 | context meret — Qwen3.5 MTP 262K tamogat |
| -np | 1 | 1 parallel slot = max egyedi sebesseg (nagy model) |
| -np | 2 | 2 slot (4B-nel OK, elfér a RAM-ban) |
| --mlock | — | RAM-ba zarja a modellt, nem lapoz ki |

## Teljesitmeny (mert adatok — Qwen3.6-35B-A3B)
- MTP elfogadási arány: 95-96% (kiváló)
- Eval tok/s: 14.8 (rövid ctx) → 9.8 (3K ctx) — CPU memory-bound
- Prompt eval (prefill): 32-43 tok/s
- RAM: 22.7 GB (modell 21.78 GB + KV 411 MB + compute 501 MB)
- KV cache q8_0-val: 170 MiB (volt 411 MiB f16-tal)

## Control Center integráció
- http://127.0.0.1:5757 → MTP kártya a sidebar tetején
- /api/mtp/status — ram_used_gb, active: '35b'/'8b'/'none'
- /api/mtp/switch/{35b|8b} POST — peer leállítás + indítás + auto browser open
- Indítás után automatikusan megnyitja a WebUI-t (8081 vagy 8082)

## Újrafordítás (ha PR merge-elve a masterbe)
```powershell
& "C:\AI\npu\build-mtp-llama.ps1" -SkipDownload
```
Ha már nincs szükség a PR branch-re (upstream merged):
```powershell
cd C:\Users\istva\SnapdragonNPU_Build\llama-mtp
git checkout master && git pull
& "C:\AI\npu\build-mtp-llama.ps1" -SkipDownload
```

## Kisebb modell alternativak (ha nagyobb ctx kell)
| Modell | RAM (Q4) | tok/s becsles | Max ctx | MTP | Statusz |
|---|---|---|---|---|---|
| Qwen3.5-9B-MTP Q4 | ~5.5 GB | 30-40 | 262K | 6 reteg | LETOLTENDO |
| Qwen3.5-4B-MTP Q4 | ~2.5 GB | 50-70 | 262K | 6 reteg | LETOLTENDO |
| Qwen3.5-2B-MTP Q4 | ~1.3 GB | 80-120 | 262K | 6 reteg | Opcionalis |
| Qwen3.6-35B-A3B Q4 (megvan) | 21.28 GB | 10-15 | 262K | 3 reteg | AKTIV |

## QNN/NPU állapot (2026-05-15)
- Qwen3.6-35B-A3B QNN változat: NEM LÉTEZIK
- Qualcomm AI Hub: csak Qwen3-4B érhető el NPU-ra
- MoE + Gated DeltaNet architektúra → QNN konverzió nem triviális
- Várható: hónapok múlva esetleg

## Hibakeresés / Troubleshooting

### "unknown speculative type: mtp"
```
--spec-type mtp  →  HELYTELEN
--spec-type draft-mtp  →  HELYES
```
A flag neve `draft-mtp`, nem `mtp`. A llama-server --help kilistázza a lehetséges értékeket.

### "-fa" flag elnyeli a következő argumentumot
```
-fa --cache-type-k q8_0  →  HELYTELEN (a -fa "on" helyett --cache-type-k-t vesz fel értékként)
--flash-attn on --cache-type-k q8_0  →  HELYES
```

### "git: Already on 'master'" leállítja a szkriptet
A git információs üzeneteket stderr-re ír, és a PowerShell $ErrorActionPreference=Stop
ezt hibának kezeli. Megoldás: git parancsokat cmd /c "git ..." formában kell hívni,
vagy $ErrorActionPreference = "Continue" blokkba tenni.

### Build DOTPROD/SVE/MATMUL_INT8 "Failed" warning
Nem hiba — csak azt jelzi, hogy a clang-cl MSVC módban nem futtatja ezeket a teszteket.
Az Oryon mag hardveresen támogatja mindhárom funkciót, futásidőben detektálja.

### --mlock "failed to mlock" hiba
Szükséges a Windows "Lock pages in memory" jog. Adminisztrátorként indítva megoldja,
vagy: Local Security Policy → User Rights Assignment → Lock pages in memory → hozzáad user.

### Modell letöltés "exit code 1" a hf.exe-nél
A hf.exe UTF-8 karaktert (✓) ír a konzolra amit a PowerShell hibakódnak vesz.
A letöltés valójában sikeres — ellenőrizd a fájlt: dir E:\models\mtp\*.gguf

### Szerver lassan tölt be (30-60 mp)
Normális — 21 GB modell betöltése RAM-ba. --mlock nélkül még lassabb lenne.
A Control Center "wait_ms: 8000" késleltetéssel vár a port ellenőrzés előtt.

### 92%+ RAM kihasználtság
A 35B-A3B + OS + egyéb processek ~30 GB-ot töltenek. A 8B-t SOHA ne indítsd
egyszerre a 35B-vel. A switch-mtp-model.ps1 automatikusan leállítja a peer modellt.

---

## Ismert korlátok

- **Csak CPU**: Snapdragon X Elite Adreno GPU Vulkan driver crashel llama.cpp-ben.
  NPU csak ONNX modellekhez használható (Qualcomm AI Hub), GGUF-hoz nem.
- **Nincs egyidejű kérés**: -np 1 miatt csak 1 párhuzamos slot. Ha több kell: -np 2
  de RAM igény nő és tok/s csökken.
- **PR #22673 MERGED 2026-05-16**: Tobbe nem kell branch merge — git pull + ujraforditas eleg.
- **Qwen3-8B TOROLT**: A Qwen3-8B-UD-Q8_K_XL.gguf NEM MTP — nincs benne draft reteg.
  Helyette Qwen3.5-9B-MTP vagy Qwen3.5-4B-MTP hasznalando.
- **context > 16K a 35B-nel**: q8_0 KV cache-szel ~20K ctx fer el 32 GB-ban.
  Ha tobb kell: cache-type-k q4_0-ra valt (minosegvesztessel), vagy hasznald a 9B-t (262K ctx).

---

## Jövőbeli fejlesztések / TODO

- [x] PR #22673 merge es build — KESZ
- [x] Qwen3.6-35B-A3B-MTP letoltes — KESZ
- [x] Flash Attention + q8_0 KV cache optimalizacio — KESZ
- [x] Control Center MTP kartya + /api/mtp/* endpointok — KESZ
- [x] Qwen3.5-9B/4B/2B-MTP letoltes — KESZ
- [x] llama.cpp ujraforditas (MTP merged masterbe 2026-05-16) — TODO: git pull + rebuild
- [ ] switch-mtp-model.ps1 frissitese: -To9B es -To4B flagek hozzaadasa
- [ ] Control Center: mtp-9b (8082) es mtp-4b (8083) service bejegyzes
- [ ] start-mtp-9b-server.ps1 es start-mtp-4b-server.ps1 szkriptek letrehozasa
- [ ] 4B szerver tesztelese parhuzamosan a 35B-vel
- [ ] Qwen3.5 MTP elfogadasi arany meres (6 reteg → nagyobb gyorsulas varható mint 35B-nel)
- [ ] ARM64 DOTPROD/SVE explicit cmake flag: -DGGML_CPU_ARM_ARCH=armv8.7-a
- [ ] WSL2-bol eleres: szerver 127.0.0.1-en hallgat, WSL-bol 172.25.16.1:8081

---

## Gyors referencia kártya

```
# === ELLENŐRZÉS ===
# Fut-e?
(Invoke-WebRequest http://localhost:8081/health).StatusCode  # 200 = OK

# RAM helyzet
Get-Process llama-server | Select Name, @{N='GB';E={[math]::Round($_.WorkingSet64/1GB,1)}}

# Modell info
(Invoke-WebRequest http://localhost:8081/api/tags).Content

# === INDÍTÁS ===
& "C:\AI\scripts\start-mtp-server.ps1"    # 35B, port 8081
& "C:\AI\scripts\start-mtp-8b-server.ps1" # 8B,  port 8082

# === VÁLTÁS ===
& "C:\AI\scripts\switch-mtp-model.ps1"        # menü
& "C:\AI\scripts\switch-mtp-model.ps1" -To8B  # közvetlen

# === LEÁLLÍTÁS ===
Stop-Process -Name llama-server -Force

# === ÚJRAFORDÍTÁS (csak build, modell megmarad) ===
& "C:\AI\npu\build-mtp-llama.ps1" -SkipDownload

# === ÚJ MODELL LETÖLTÉS ===
$hf = "C:\Users\istva\AppData\Local\Programs\Python\Python313-arm64\Scripts\hf.exe"
& $hf download unsloth/Qwen3-14B-GGUF --include "*UD-Q4_K_XL*" --local-dir E:\models\new_models

# === API TESZT ===
$body = '{"model":"qwen3","messages":[{"role":"user","content":"Hello!"}],"stream":false}'
Invoke-WebRequest -Uri http://localhost:8081/v1/chat/completions -Method POST `
  -ContentType "application/json" -Body $body | Select-Object -Expand Content
```

---

## Fájlok és szkriptek áttekintése

```
C:\AI\
├── npu\
│   ├── MTP-README.md              ← ez a fájl
│   ├── build-mtp-llama.ps1        ← teljes build + letöltés szkript
│   └── llama-cpp-snapdragon-build.md ← korábbi build notes
├── scripts\
│   ├── start-mtp-server.ps1       ← 35B inditas (port 8081)
│   ├── start-mtp-9b-server.ps1    ← 9B inditas (port 8082) — TODO: letrehozni
│   ├── start-mtp-4b-server.ps1    ← 4B inditas (port 8083) — TODO: letrehozni
│   └── switch-mtp-model.ps1       ← toggle szkript — TODO: -To9B/-To4B flagek
└── apps\control-center\
    └── backend\main.py            ← mtp-35b + mtp-9b + mtp-4b service + /api/mtp/* endpointok

C:\Users\istva\SnapdragonNPU_Build\
├── llama-mtp\                     ← git repo (master + mtp-pr branch merge)
├── llama-mtp-build\               ← cmake build output
└── install-mtp\                   ← binárisok: llama-server.exe, llama-cli.exe, stb.

E:\models\
├── mtp\
│   └── Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf   (21.28 GB) — AKTIV 8081
└── mtp-small\
    ├── Qwen3.5-9B-MTP-UD-Q4_K_XL.gguf    (~5.5 GB)  — 8082
    ├── Qwen3.5-4B-MTP-UD-Q4_K_XL.gguf    (~2.5 GB)  — 8083, Hermes
    └── Qwen3.5-2B-MTP-UD-Q4_K_XL.gguf    (~1.3 GB)  — opcionalis
```

---
_Utolsó frissítés: 2026-05-21 | llama.cpp MTP merged | Snapdragon X Elite Windows ARM64_
