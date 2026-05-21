# llama.cpp MTP — Snapdragon X Elite — README
# vivo2 gép, 2026-05-15 | Frissítve: 2026-05-21

## Fontos: MTP hivatalosan merged (2026-05-16)

llama.cpp MTP upstream master-be beolvasztva 2026-05-16-án.
PR #22673 branch merge többé nem szükséges — egyszerű git pull + újrafordítás elég:

```powershell
cd C:\Users\istva\SnapdragonNPU_Build\llama-mtp
git checkout master
git pull
& "C:\AI\npu\build-mtp-llama.ps1" -SkipDownload
```

---

## Hardver
- CPU: Snapdragon X Elite (12 Oryon mag)
- RAM: 32 GB LPDDR5X
- GPU/NPU: Adreno — llama.cpp-ben NEM használható (Vulkan crashel, NPU csak ONNX)
- OS: Windows 11 ARM64

---

## Build
- Repo: `C:\Users\istva\SnapdragonNPU_Build\llama-mtp\`
- Build dir: `C:\Users\istva\SnapdragonNPU_Build\llama-mtp-build\`
- Install: `C:\Users\istva\SnapdragonNPU_Build\install-mtp\`
- Verzió: 9142, Clang 22.1.4, ARM64 CPU-only
- PR #22673 (MTP Support) merge-elve — https://github.com/ggml-org/llama.cpp/pull/22673

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

---

## Modellek

### Aktív modellek
| Fájl | Méret | Hely | MTP | Context | Port |
|---|---|---|---|---|---|
| Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf | 21.28 GB | E:\models\mtp\ | 3 réteg | 262K | 8081 |
| Qwen3.5-9B-MTP-UD-Q4_K_XL.gguf  | ~5.5 GB  | E:\models\mtp-small\ | 6 réteg | 262K | 8082 |
| Qwen3.5-4B-MTP-UD-Q4_K_XL.gguf  | ~2.5 GB  | E:\models\mtp-small\ | 6 réteg | 262K | 8082 |
| Qwen3.5-2B-MTP-UD-Q4_K_XL.gguf  | ~1.3 GB  | E:\models\mtp-small\ | 6 réteg | 262K | 8082 |

### Párhuzamos futási lehetőségek (32 GB RAM)
| Kombó | RAM | Megjegyzés |
|---|---|---|
| 35B-A3B + 4B-MTP | ~23.5 GB | ELFÉR EGYÜTT |
| 35B-A3B + 9B-MTP | ~26.5 GB | ELFÉR EGYÜTT |
| 9B-MTP + 4B-MTP  | ~8 GB    | Bőven fér |

### Letöltés parancsok
```powershell
$hf = "C:\Users\istva\AppData\Local\Programs\Python\Python313-arm64\Scripts\hf.exe"

# 9B MTP
& $hf download unsloth/Qwen3.5-9B-MTP-GGUF --include "*UD-Q4_K_XL*" --local-dir E:\models\mtp-small

# 4B MTP
& $hf download unsloth/Qwen3.5-4B-MTP-GGUF --include "*UD-Q4_K_XL*" --local-dir E:\models\mtp-small

# 2B MTP (opcionális)
& $hf download unsloth/Qwen3.5-2B-MTP-GGUF --include "*UD-Q4_K_XL*" --local-dir E:\models\mtp-small
```

---

## Indítás — összes parancs

### 35B-A3B (minőség, 262K ctx, ~22 GB RAM) — port 8081
```powershell
& "C:\AI\scripts\start-mtp-35b-server.ps1"
# vagy egyedi modell úttal:
& "C:\AI\scripts\start-mtp-35b-server.ps1" -ModelPath "E:\models\mtp\Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf"
```

### 9B MTP (gyors, 65K ctx, ~5.5 GB RAM) — port 8082
```powershell
& "C:\AI\scripts\start-mtp-9b-server.ps1"
# egyedi paraméterekkel:
& "C:\AI\scripts\start-mtp-9b-server.ps1" -ModelPath "E:\models\mtp-small\Qwen3.5-9B-MTP-UD-Q4_K_XL.gguf" -ContextSize 32768
```

### 4B MTP (leggyorsabb, 32K ctx, ~2.5 GB RAM) — port 8082
```powershell
& "C:\AI\scripts\start-mtp-4b-server.ps1"
# egyedi paraméterekkel:
& "C:\AI\scripts\start-mtp-4b-server.ps1" -ModelPath "E:\models\mtp-small\Qwen3.5-4B-MTP-UD-Q4_K_XL.gguf" -ContextSize 16384
```

### Modellváltó szkript (interaktív menü)
```powershell
# Interaktív menü (leállítja a régit, elindítja a választottat):
& "C:\AI\scripts\switch-mtp-model.ps1"

# Közvetlen váltás paraméterrel:
& "C:\AI\scripts\switch-mtp-model.ps1" -To 35B
& "C:\AI\scripts\switch-mtp-model.ps1" -To 9B
& "C:\AI\scripts\switch-mtp-model.ps1" -To 4B
```

### Szerver leállítás
```powershell
# Minden llama-server folyamat leállítása:
Stop-Process -Name llama-server -Force

# Csak ellenőrzés, hogy fut-e:
Get-Process -Name llama-server -ErrorAction SilentlyContinue
```

### Állapot ellenőrzés
```powershell
# Fut-e a szerver? (200 = OK)
(Invoke-WebRequest http://localhost:8081/health -UseBasicParsing).StatusCode   # 35B
(Invoke-WebRequest http://localhost:8082/health -UseBasicParsing).StatusCode   # 9B / 4B

# RAM használat
Get-Process llama-server | Select Name, @{N='GB';E={[math]::Round($_.WorkingSet64/1GB,1)}}

# Modell info (melyik modell fut)
(Invoke-WebRequest http://localhost:8081/v1/models -UseBasicParsing).Content
```

### API teszt (chat)
```powershell
# 35B szerver tesztelése (port 8081):
$body = '{"model":"qwen3","messages":[{"role":"user","content":"Hello!"}],"stream":false}'
Invoke-WebRequest -Uri http://localhost:8081/v1/chat/completions -Method POST `
  -ContentType "application/json" -Body $body -UseBasicParsing | Select-Object -Expand Content

# 9B / 4B szerver tesztelése (port 8082):
Invoke-WebRequest -Uri http://localhost:8082/v1/chat/completions -Method POST `
  -ContentType "application/json" -Body $body -UseBasicParsing | Select-Object -Expand Content
```

### Újrafordítás (ha új llama.cpp verzió kell)
```powershell
# Gyors rebuild (modell marad, csak bináris frissül):
& "C:\AI\npu\build-mtp-llama.ps1" -SkipDownload

# Teljes rebuild (git pull + cmake + install):
cd C:\Users\istva\SnapdragonNPU_Build\llama-mtp
git checkout master && git pull
& "C:\AI\npu\build-mtp-llama.ps1" -SkipDownload
```

---

## Web UI — megnyitás és használat

A llama-server tartalmaz egy beépített chat Web UI-t. Nincs külön telepítés — a szerver indítása után azonnal elérhető böngészőből.

### Megnyitás

| Szerver | URL |
|---|---|
| 35B-A3B | http://localhost:8081 |
| 9B MTP  | http://localhost:8082 |
| 4B MTP  | http://localhost:8082 |

Böngészőben (Chrome / Edge / Firefox) nyisd meg a megfelelő URL-t. A szerver indulása után kb. **5-10 másodperccel** lesz elérhető (35B-nél 30-60 mp betöltési idő normális).

### A Web UI felülete

```
┌─────────────────────────────────────────────┐
│  [llama.cpp]          ⚙ Settings            │
│─────────────────────────────────────────────│
│                                             │
│  (üzenetek helye)                           │
│                                             │
│─────────────────────────────────────────────│
│  [ Üzenet írása...              ] [Küldés]  │
└─────────────────────────────────────────────┘
```

### Alapfunkciók

**Chat indítása:**
1. Böngészőben nyisd meg az URL-t
2. Az alsó beviteli mezőbe írd az üzeneted
3. Enter vagy a Küldés gomb
4. A válasz streamelve jelenik meg (szó szó után)

**System prompt beállítása (⚙ Settings):**
- `System prompt` mezőbe írj instrukciót, pl.: `You are a helpful coding assistant. Answer in Hungarian.`
- Ez minden üzenet elé bekerül, meghatározza a modell viselkedését

**Fontos beállítások a Settings panelban:**

| Beállítás | Ajánlott érték | Leírás |
|---|---|---|
| Temperature | 0.7 | Kreativitás (0 = determinisztikus, 1+ = kreatívabb) |
| Top-P | 0.9 | Szó-valószínűség szűrő |
| Max tokens | 2048–4096 | Maximális válaszhossz |
| Context size | automatikus | Nem kell állítani, a szerver kezeli |

**Thinking mód (Qwen3 specifikus):**
A Qwen3 modellek támogatják a `/think` és `/no_think` prefixeket:
```
/think Milyen algoritmus a legjobb erre a problémára?
/no_think Fordítsd le angolra: "Szia világ"
```
A `/think` mód lassabb de mélyebb elemzést ad, `/no_think` gyorsabb azonnali válasz.

**Kontextus törlése (új téma kezdése):**
- A `🗑 Clear` gomb vagy az oldal újratöltése (F5) törli a kontextust
- Ha a szerver elkezd lassulni, valószínűleg tele van a context window — törlés ajánlott

**Streaming ki-/bekapcsolás:**
- Settings → `Stream` toggle
- Ha ki van kapcsolva, a teljes válasz egyszerre jelenik meg (hasznos copy-paste-hez)

### Több ablak / párhuzamos használat

Ha a 35B és egy kis modell egyszerre fut (pl. 35B + 4B):
- Két böngészőfület nyiss meg: `localhost:8081` és `localhost:8082`
- Egyszerre mindkettővel lehet chattelni
- A switch szkript ilyenkor csak a kis modellt váltja, a 35B fut tovább

### Hasznos tippek

- **Hosszú válasznál** ne frissítsd az oldalt, a stream megszakad
- **Ha a UI lefagy**: ellenőrizd a szerver állapotát: `http://localhost:8081/health`
- **Másolás**: a válasz szövegre kattintva jelölhető, vagy Settings → Stream off módban egyszerre másolható
- **Markdown megjelenítés**: a Web UI automatikusan rendereli a kódot, táblázatokat, listákat
- **Modell betöltési idő**: 35B esetén 30-60 másodperc az első induláskor — ez normális

---

## Paraméterek magyarázata
| Paraméter | Érték | Miért |
|---|---|---|
| --spec-type | draft-mtp | MTP backend (NEM 'mtp' — az hibát ad!) |
| --spec-draft-n-max | 3 | Qwen3.6-35B-A3B: 3 MTP réteg |
| --spec-draft-n-max | 6 | Qwen3.5-9B/4B/2B-MTP: 6 MTP réteg |
| -t | 12 | 12 Oryon mag (35B, 9B) |
| -t | 8 | 8 Oryon mag (4B) |
| -tb | 4 | batch thread — 4 elég |
| --flash-attn on | on | gyorsabb prefill, KV kvantizációhoz kell |
| --cache-type-k/v | q8_0 | KV cache tömörítés: 2-3x kisebb, ~0 minőségvesztes |
| --cache-type-k/v | q4_0 | Kis modelleknél: 4x kisebb, mérsékelt memóriahasználat |
| -c | 65536 | context méret (9B) |
| -c | 32768 | context méret (4B) |
| -np | 1 | 1 parallel slot = max egyedi sebesség |
| -np | 2 | 2 slot (4B-nél OK) |
| --mlock | — | RAM-ba zárja a modellt, nem lapoz ki |
| --no-mmap | — | Stabilabb GGUF betöltés Snapdragon driverekkel |

---

## Teljesítmény (mért adatok — Qwen3.6-35B-A3B)
- MTP elfogadási arány: 95-96% (kiváló)
- Eval tok/s: 14.8 (rövid ctx) → 9.8 (3K ctx) — CPU memory-bound
- Prompt eval (prefill): 32-43 tok/s
- RAM: 22.7 GB (modell 21.78 GB + KV 411 MB + compute 501 MB)
- KV cache q8_0-val: 170 MiB (volt 411 MiB f16-tal)

---

## Hibakeresés / Troubleshooting

### "unknown speculative type: mtp"
```
--spec-type mtp       →  HELYTELEN
--spec-type draft-mtp →  HELYES
```

### "-fa" flag elnyeli a következő argumentumot
```
-fa --cache-type-k q8_0            →  HELYTELEN
--flash-attn on --cache-type-k q8_0 →  HELYES
```

### "git: Already on 'master'" leállítja a szkriptet
A git információs üzeneteket stderr-re ír, és a PowerShell `$ErrorActionPreference=Stop` ezt hibának kezeli.
Megoldás: git parancsokat `cmd /c "git ..."` formában kell hívni, vagy `$ErrorActionPreference = "Continue"` blokkba tenni.

### Build DOTPROD/SVE/MATMUL_INT8 "Failed" warning
Nem hiba — csak azt jelzi, hogy a clang-cl MSVC módban nem futtatja ezeket a teszteket.
Az Oryon mag hardveresen támogatja mindhárom funkciót, futásidőben detektálja.

### --mlock "failed to mlock" hiba
Szükséges a Windows "Lock pages in memory" jog. Adminisztrátorként indítva megoldja,
vagy: Local Security Policy → User Rights Assignment → Lock pages in memory → hozzáad user.

### Web UI nem töltődik be
```powershell
# 1. Ellenőrizd fut-e a szerver:
Get-Process llama-server -ErrorAction SilentlyContinue

# 2. Health check:
(Invoke-WebRequest http://localhost:8081/health -UseBasicParsing).StatusCode

# 3. Ha 35B: várj 30-60 mp-et betöltésre, az normális
# 4. Ha tűzfal blokkolja: Windows Security → Firewall → llama-server engedélyezése
```

### Modell letöltés "exit code 1" a hf.exe-nél
A hf.exe UTF-8 karaktert (✓) ír a konzolra amit a PowerShell hibakódnak vesz.
A letöltés valójában sikeres — ellenőrizd: `dir E:\models\mtp-small\*.gguf`

### Szerver lassan tölt be (30-60 mp)
Normális — 21 GB modell betöltése RAM-ba. `--mlock` nélkül még lassabb lenne.

### 92%+ RAM kihasználtság
A 35B-A3B + OS + egyéb processek ~30 GB-ot töltenek. A 9B-t / 4B-t ne indítsd egyszerre
a 35B-vel (kivéve a 4B-t — az elfér). A `switch-mtp-model.ps1` automatikusan leállítja a peer modellt.

---

## Ismert korlátok

- **Csak CPU**: Snapdragon X Elite Adreno GPU Vulkan driver crashel llama.cpp-ben.
  NPU csak ONNX modellekhez használható (Qualcomm AI Hub), GGUF-hoz nem.
- **Nincs egyidejű kérés**: `-np 1` miatt csak 1 párhuzamos slot. Ha több kell: `-np 2`
  de RAM igény nő és tok/s csökken.
- **PR #22673 MERGED 2026-05-16**: Többé nem kell branch merge — git pull + újrafordítás elég.
- **Qwen3-8B TÖRÖLVE**: A Qwen3-8B-UD-Q8_K_XL.gguf NEM MTP — nincs benne draft réteg.
  Helyette Qwen3.5-9B-MTP vagy Qwen3.5-4B-MTP használandó.
- **context > 16K a 35B-nél**: q8_0 KV cache-szel ~20K ctx fér el 32 GB-ban.
  Ha több kell: `cache-type-k q4_0`-ra vált, vagy használd a 9B-t (262K ctx).

---

## TODO / Jövőbeli fejlesztések

- [x] PR #22673 merge és build — KÉSZ
- [x] Qwen3.6-35B-A3B-MTP letöltés — KÉSZ
- [x] Flash Attention + q8_0 KV cache optimalizáció — KÉSZ
- [x] Control Center MTP kártya + /api/mtp/* endpointok — KÉSZ
- [x] Qwen3.5-9B/4B/2B-MTP letöltés — KÉSZ
- [x] start-mtp-9b-server.ps1 létrehozva — KÉSZ
- [x] start-mtp-4b-server.ps1 létrehozva — KÉSZ
- [x] switch-mtp-model.ps1 frissítve: -To9B és -To4B flagek — KÉSZ
- [x] Web UI útmutató a README-ben — KÉSZ
- [ ] Control Center: mtp-9b (8082) és mtp-4b service bejegyzés
- [ ] 4B szerver tesztelése párhuzamosan a 35B-vel
- [ ] Qwen3.5 MTP elfogadási arány mérés (6 réteg → nagyobb gyorsulás várható)
- [ ] ARM64 DOTPROD/SVE explicit cmake flag: `-DGGML_CPU_ARM_ARCH=armv8.7-a`
- [ ] WSL2-ből elérés: szerver 127.0.0.1-en hallgat, WSL-ből 172.25.16.1:8081

---

## Fájlok és szkriptek áttekintése

```
C:\AI\
├── npu\
│   ├── build-mtp-llama.ps1            ← teljes build + letöltés szkript
│   └── llama-cpp-snapdragon-build.md  ← korábbi build notes
└── scripts\
    ├── start-mtp-35b-server.ps1       ← 35B indítás (port 8081)
    ├── start-mtp-9b-server.ps1        ← 9B indítás (port 8082)
    ├── start-mtp-4b-server.ps1        ← 4B indítás (port 8082)
    └── switch-mtp-model.ps1           ← modellváltó (35B/9B/8B/4B)

C:\Users\istva\SnapdragonNPU_Build\
├── llama-mtp\                         ← git repo (master)
├── llama-mtp-build\                   ← cmake build output
└── install-mtp\                       ← binárisok: llama-server.exe stb.

E:\models\
├── mtp\
│   └── Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf   (21.28 GB) — port 8081
└── mtp-small\
    ├── Qwen3.5-9B-MTP-UD-Q4_K_XL.gguf    (~5.5 GB)  — port 8082
    ├── Qwen3.5-4B-MTP-UD-Q4_K_XL.gguf    (~2.5 GB)  — port 8082
    └── Qwen3.5-2B-MTP-UD-Q4_K_XL.gguf    (~1.3 GB)  — opcionális
```

---

## Gyors referencia kártya

```powershell
# === INDÍTÁS ===
& "C:\AI\scripts\start-mtp-35b-server.ps1"   # 35B → port 8081
& "C:\AI\scripts\start-mtp-9b-server.ps1"    # 9B  → port 8082
& "C:\AI\scripts\start-mtp-4b-server.ps1"    # 4B  → port 8082

# === VÁLTÁS ===
& "C:\AI\scripts\switch-mtp-model.ps1"          # interaktív menü
& "C:\AI\scripts\switch-mtp-model.ps1" -To 35B  # közvetlen
& "C:\AI\scripts\switch-mtp-model.ps1" -To 9B
& "C:\AI\scripts\switch-mtp-model.ps1" -To 4B

# === WEB UI ===
Start-Process "http://localhost:8081"  # 35B
Start-Process "http://localhost:8082"  # 9B vagy 4B

# === ÁLLAPOT ===
(Invoke-WebRequest http://localhost:8081/health -UseBasicParsing).StatusCode
Get-Process llama-server | Select Name, @{N='GB';E={[math]::Round($_.WorkingSet64/1GB,1)}}

# === LEÁLLÍTÁS ===
Stop-Process -Name llama-server -Force

# === ÚJRAFORDÍTÁS ===
& "C:\AI\npu\build-mtp-llama.ps1" -SkipDownload
```

---
_Utolsó frissítés: 2026-05-21 | llama.cpp MTP merged | Snapdragon X Elite Windows ARM64_
