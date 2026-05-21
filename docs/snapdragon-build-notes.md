# llama.cpp — Snapdragon X Elite natív ARM64 build (Windows)

**Platform:** Windows 11 ARM64 · Snapdragon X Elite X1E78100 · Qualcomm Oryon CPU  
**Eredmény:** Natív ARM64 binárisok, clang-cl 22.x, CPU backend — működik  
**NPU (Hexagon HTP) backend:** upstream llama.cpp-ben broken/hiányos — lásd alább

---

## Stack

| Komponens | Verzió | Path |
|---|---|---|
| Visual Studio | 2026 Community 18.5 | `C:\Program Files\Microsoft Visual Studio\18\Community` |
| CMake | 4.3.1 | System PATH |
| LLVM/Clang | 22.1.4 | `C:\Program Files\LLVM\bin\` |
| QNN SDK | 2.45.40.260406 | `C:\Qualcomm\AIStack\QAIRT\2.45.40.260406` |
| Hexagon SDK | 6.5.0.1 | `C:\Qualcomm\Hexagon_SDK\6.5.0.1` |
| Build root | — | `%USERPROFILE%\SnapdragonNPU_Build\` |
| Install dir | — | `%USERPROFILE%\SnapdragonNPU_Build\install\` |

---

## Hibák és fixek (session összefoglaló)

### 1. Execution Policy
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
# Permanens (ajánlott):
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

### 2. clang.exe vs clang-cl.exe — fő hiba

**Tünet:**
```
clang++: error: no such file or directory: '/O2'
clang++: error: no such file or directory: '/arch:ARMv8.2'
```

**Ok:** A script `clang.exe`-t (GNU frontend) választott, de MSVC-stílusú flageket (`/O2`, `/arch:ARMv8.2`) adott át. A vcvarsarm64.bat már be volt töltve, MSVC env aktív volt.

**Fix:** Compiler selection prioritás megfordítása — `clang-cl` előnyt kap `clang` felett:

```powershell
# Snapdragon_NPU_Build.ps1 ~line 508
# ELŐTTE:
if ($clangCmd) {
    $clangTool = @{ Name = 'clang'; Path = $clangCmd.Path }
} elseif ($clangClCmd) { ... }

# UTÁNA:
if ($clangClCmd) {
    $clangTool = @{ Name = 'clang-cl'; Path = $clangClCmd.Path }
} elseif ($clangCmd) {
    $clangTool = @{ Name = 'clang'; Path = $clangCmd.Path }
} else {
    $llvmBin     = 'C:\Program Files\LLVM\bin'
    $llvmClangCl = Join-Path $llvmBin 'clang-cl.exe'
    $llvmClang   = Join-Path $llvmBin 'clang.exe'
    if     (Test-Path $llvmClangCl) { $clangTool = @{ Name = 'clang-cl'; Path = $llvmClangCl } }
    elseif (Test-Path $llvmClang)   { $clangTool = @{ Name = 'clang';    Path = $llvmClang   } }
}
```

### 3. CMAKE_CXX_FLAGS duplikáció + CMAKE_C_FLAGS hiánya

A script kétszer adta át ugyanazt a flag blokkot, és `CMAKE_C_FLAGS` hiányzott.

```powershell
# UTÁNA (~line 583) — egyszer, compiler-függő, C_FLAGS is:
if ($BuildType -eq "Release") {
    if ($clangTool.Name -eq 'clang-cl') {
        $cmakeArgs += "-DCMAKE_C_FLAGS=/O2 /arch:ARMv8.2 /EHsc"
        $cmakeArgs += "-DCMAKE_CXX_FLAGS=/O2 /arch:ARMv8.2 /EHsc"
    } else {
        $cmakeArgs += "-DCMAKE_C_FLAGS=-O2 -march=armv8.2-a"
        $cmakeArgs += "-DCMAKE_CXX_FLAGS=-O2 -march=armv8.2-a"
    }
    $cmakeArgs += "-DLLAMA_AVX=OFF"
    $cmakeArgs += "-DGGML_NATIVE=OFF"
}
```

### 4. OpenCL hiánya

**Tünet:** `Could NOT find OpenCL`  
**Fix:** `-DGGML_OPENCL=OFF` (Hexagon NPU-hoz nem szükséges)

### 5. C++ exceptions disabled

**Tünet:** `cannot use 'try' with exceptions disabled`  
**Ok:** clang-cl alapból `-fno-exceptions`, az `/EHsc` flag hiányzott  
**Fix:** `/EHsc` hozzáadása a CMAKE_CXX_FLAGS-hez (lásd #3 fix)

### 6. Install-Binaries bug (cosmetic)

A `Build-LlamaCPP` return value-ba belekerül a cmake stdout, amit `Install-Binaries` drive-névként értelmez. A build ettől függetlenül sikeres — manuális copy szükséges:

```powershell
$src = "$env:USERPROFILE\SnapdragonNPU_Build\llama.cpp-build\bin"
$dst = "$env:USERPROFILE\SnapdragonNPU_Build\install"
New-Item -ItemType Directory -Path $dst -Force
Copy-Item "$src\*.exe" $dst -Force
Copy-Item "$src\*.dll" $dst -Force
```

---

## Végeredmény — működő CPU build

```
C:\Users\istva\SnapdragonNPU_Build\install\llama-cli.exe --version
version: 9009 (0754b7b6f)
built with Clang 22.1.4 for Windows ARM64
```

Natív ARM64, 12 Oryon mag, ~3-4x gyorsabb mint x86 emuláción.

---

## NPU backend helyzet

### ggml-hexagon (Hexagon SDK alapú)

- **Linux:** cross-compile Android-ra — nem fut Linux ARM64 hoston
- **Windows:** CMake konfig broken — hiányzó `addons/wos/build/cmake/windows_fun.cmake` a Hexagon SDK 6.5.0.1-ből (WoS addon nem része az alap SDK-nak)
- **Állapot:** upstream kísérleti, nem production-ready Windows-on

### ggml-qnn (QNN SDK alapú)

- **Állapot:** nincs upstream llama.cpp-ben (main branch)
- **Alternatíva:** fork-ok léteznek, de nem maintained

### Platform NPU support összefoglaló

| Platform | Hexagon HTP inference | Megjegyzés |
|---|---|---|
| Android | ✅ | QNN SDK + ADB |
| Windows ARM64 | ⚠️ | QnnHtp.dll megvan, llama.cpp integráció broken |
| Linux ARM64 | ❌ | Nincs publikus HTP driver |
| WSL2 | ❌ | Nincs driver passthrough |

### Ajánlott NPU alternatíva vivo2-n

**GenieAPIService** (`:8912`) — már fut, Llama 3.1 8B QNN 2.38, natív NPU inference.  
LiteLLM proxy-ban `local-npu` aliasként bekötve.

---

## Következő lépések

### Vulkan backend (Adreno X1-85 GPU)

```powershell
winget install KhronosGroup.VulkanSDK
# Majd scriptben: -DGGML_VULKAN=ON
# Clean rebuild szükséges
```

### llama-server bekötése LiteLLM-be

```yaml
# litellm config-ban:
- model_name: local-cpu-arm64
  litellm_params:
    model: openai/llama3
    api_base: http://localhost:8081/v1
    api_key: none
```

```powershell
# Indítás:
$install = "$env:USERPROFILE\SnapdragonNPU_Build\install"
& "$install\llama-server.exe" -m "C:\AI\models\model.gguf" --host 127.0.0.1 --port 8081 -t 12
```

---

## Quick reference — újrabuildelés

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
cd C:\AI\npu
.\Snapdragon_NPU_Build.ps1 -BuildLlamaCPP -Clean

# Ha sikeres (Install-Binaries hibát ignoráld):
$src = "$env:USERPROFILE\SnapdragonNPU_Build\llama.cpp-build\bin"
$dst = "$env:USERPROFILE\SnapdragonNPU_Build\install"
Copy-Item "$src\*.exe" $dst -Force
Copy-Item "$src\*.dll" $dst -Force
& "$dst\llama-cli.exe" --version
```
