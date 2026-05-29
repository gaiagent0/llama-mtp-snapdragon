# ============================================================
# MTP llama.cpp build + Qwen3.6-35B-A3B-MTP-GGUF download
# Platform: Snapdragon X Elite, Windows ARM64
# clang-cl: C:\Program Files\LLVM\bin\clang-cl.exe
# ninja:    C:\tools\ninja.exe
# VS:       2026 Community
# ============================================================
param(
    [switch]$SkipBuild,
    [switch]$SkipDownload,
    [string]$ModelDir   = "E:\models\mtp",
    [string]$BuildRoot  = "C:\AI\apps\llama-mtp",
    [string]$InstallDir = "C:\AI\apps\llama-mtp\install-mtp"
)

$ErrorActionPreference = "Stop"
$StartTime = Get-Date

function Log  { param([string]$m,[string]$c="Cyan")  Write-Host "[$(Get-Date -f 'HH:mm:ss')] $m" -ForegroundColor $c }
function OK   { param([string]$m) Log "OK  $m" "Green"  }
function WARN { param([string]$m) Log "!!  $m" "Yellow" }
function ERR  { param([string]$m) Log "XX  $m" "Red"; throw $m }

$CLANG_CL = "C:\Program Files\LLVM\bin\clang-cl.exe"
$NINJA    = "C:\tools\ninja.exe"
$VCVARS   = "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvarsarm64.bat"

# ---- 1. PREREQ CHECK ----
Log "=== PREREQ CHECK ===" "Magenta"

foreach ($item in @(
    @{ Name="clang-cl"; Path=$CLANG_CL },
    @{ Name="ninja";    Path=$NINJA    },
    @{ Name="vcvars";   Path=$VCVARS   }
)) {
    if (Test-Path $item.Path) { OK "$($item.Name): $($item.Path)" }
    else { ERR "$($item.Name) NOT FOUND: $($item.Path)" }
}

$env:PATH = "C:\Program Files\LLVM\bin;C:\tools;" + $env:PATH

OK ("git:    " + (git   --version 2>&1 | Select-Object -First 1))
OK ("cmake:  " + (cmake --version 2>&1 | Select-Object -First 1))
OK ("python: " + (python --version 2>&1))

# VS 2026 ARM64 env load
Log "Loading VS 2026 ARM64 env..."
$envLines = cmd /c ('"' + $VCVARS + '" 2>nul && set')
foreach ($line in $envLines) {
    if ($line -match '^([^=]+)=(.+)$') {
        Set-Item -Path "env:$($Matches[1])" -Value $Matches[2] -Force -EA SilentlyContinue
    }
}
OK "MSVC ARM64 env loaded"

# ---- 2. GIT CLONE + PR #22673 ----
if (-not $SkipBuild) {
    Log "=== LLAMA.CPP SOURCE ===" "Magenta"

    $llamaSrc = Join-Path $BuildRoot "llama-src"
    $llamaBld = Join-Path $BuildRoot "llama-build"

    $ErrorActionPreference = "Continue"
    if (Test-Path (Join-Path $llamaSrc ".git")) {
        Log "Existing repo found, resetting to master..."
        Push-Location $llamaSrc
        git fetch origin 2>$null
        git checkout master 2>$null
        git reset --hard origin/master 2>$null
        Pop-Location
        OK "Repo updated"
    } else {
        Log "Cloning llama.cpp (depth 1)..."
        git clone --depth 1 https://github.com/ggml-org/llama.cpp.git $llamaSrc
        if ($LASTEXITCODE -ne 0) { ERR "git clone failed" }
        OK "Cloned: $llamaSrc"
    }

    Log "Fetching PR #22673 (MTP Support)..."
    Push-Location $llamaSrc

    Log "Unshallowing repo (needed for merge)..."
    cmd /c "git fetch --unshallow" | Out-Null

    Log "Fetching PR #22673 branch..."
    cmd /c "git fetch origin pull/22673/head:mtp-pr"
    if ($LASTEXITCODE -ne 0) { ERR "PR #22673 fetch failed (exit $LASTEXITCODE)" }
    OK "PR #22673 fetched"

    $logOut = (cmd /c "git log --oneline -10") -join " "
    if ($logOut -match "22673|MTP Support") {
        OK "MTP PR already merged, skipping"
    } else {
        Log "Merging MTP PR..."
        cmd /c "git merge --no-ff mtp-pr -m `"Merge PR #22673: llama + spec: MTP Support`""
        if ($LASTEXITCODE -ne 0) {
            cmd /c "git merge --abort"
            WARN "Merge conflict -- using mtp-pr branch directly"
            cmd /c "git checkout mtp-pr"
        } else {
            OK "MTP PR merged successfully"
        }
    }
    Pop-Location

    # ---- 3. CMAKE CONFIG ----
    Log "=== CMAKE CONFIG ===" "Magenta"

    if (Test-Path $llamaBld) {
        Log "Removing old build dir..."
        Remove-Item -Recurse -Force $llamaBld
    }
    New-Item -ItemType Directory -Path $llamaBld -Force | Out-Null

    $cmakeArgs = @(
        "-S", $llamaSrc,
        "-B", $llamaBld,
        "-G", "Ninja",
        "-DCMAKE_MAKE_PROGRAM=$NINJA",
        "-DCMAKE_BUILD_TYPE=Release",
        "-DCMAKE_C_COMPILER=$CLANG_CL",
        "-DCMAKE_CXX_COMPILER=$CLANG_CL",
        "-DCMAKE_C_FLAGS=/O2 /arch:ARMv8.2 /EHsc",
        "-DCMAKE_CXX_FLAGS=/O2 /arch:ARMv8.2 /EHsc",
        "-DGGML_CUDA=OFF",
        "-DGGML_VULKAN=OFF",
        "-DGGML_OPENCL=OFF",
        "-DGGML_OPENMP=OFF",
        "-DGGML_NATIVE=OFF",
        "-DLLAMA_AVX=OFF",
        "-DLLAMA_BUILD_SERVER=ON",
        "-DLLAMA_BUILD_TESTS=OFF",
        "-DLLAMA_BUILD_EXAMPLES=ON",
        "-DLLAMA_CURL=OFF"
    )

    Log "Running cmake configure..."
    & cmake @cmakeArgs
    if ($LASTEXITCODE -ne 0) { ERR "CMake configure FAILED (exit $LASTEXITCODE)" }
    OK "CMake configure done"

    # ---- 4. BUILD ----
    Log "=== BUILD (12 cores, ~15-20 min) ===" "Magenta"
    & cmake --build $llamaBld --config Release --parallel 12
    if ($LASTEXITCODE -ne 0) { ERR "Build FAILED" }
    OK "Build complete!"

    # ---- 5. INSTALL ----
    Log "=== INSTALL ===" "Magenta"
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null

    $binCandidates = @(
        (Join-Path $llamaBld "bin"),
        $llamaBld
    )
    $binSrc = $null
    foreach ($c in $binCandidates) {
        if (Test-Path (Join-Path $c "llama-server.exe")) { $binSrc = $c; break }
    }
    if (-not $binSrc) { ERR "llama-server.exe not found in build output" }

    Get-ChildItem $binSrc -Filter "*.exe" | Copy-Item -Destination $InstallDir -Force
    Get-ChildItem $binSrc -Filter "*.dll" | Copy-Item -Destination $InstallDir -Force
    OK "Binaries installed: $InstallDir"

    $verOut = & "$InstallDir\llama-cli.exe" --version 2>&1 | Select-Object -First 2
    OK "llama-cli: $($verOut -join ' | ')"

    $helpOut = & "$InstallDir\llama-server.exe" --help 2>&1
    if ($helpOut -match "spec-type") {
        OK "--spec-type flag FOUND -> MTP build SUCCESS!"
    } else {
        WARN "--spec-type NOT FOUND -> check PR #22673 merge"
    }
}

# ---- 6. MODEL DOWNLOAD ----
if (-not $SkipDownload) {
    Log "=== MODEL DOWNLOAD ===" "Magenta"
    New-Item -ItemType Directory -Path $ModelDir -Force | Out-Null

    $existing = Get-ChildItem $ModelDir -Filter "*Q4_K*.gguf" -Recurse -EA SilentlyContinue |
                Sort-Object Length -Descending | Select-Object -First 1
    if ($existing) {
        OK "Model already downloaded: $($existing.FullName) ($([math]::Round($existing.Length/1GB,1)) GB)"
    } else {
        Log "Downloading: unsloth/Qwen3.6-35B-A3B-MTP-GGUF  [UD-Q4_K_XL ~20 GB]"
        Log "Target: $ModelDir"
        Log "This will take a while..."

        $hfCli = "C:\Users\istva\AppData\Local\Programs\Python\Python313-arm64\Scripts\hf.exe"
        & $hfCli download `
            unsloth/Qwen3.6-35B-A3B-MTP-GGUF `
            --include "*UD-Q4_K_XL*" `
            --local-dir $ModelDir

        if ($LASTEXITCODE -ne 0) { ERR "Model download failed" }
        OK "Model downloaded: $ModelDir"
    }
}

# ---- 7. SUMMARY ----
$elapsed = [math]::Round(((Get-Date) - $StartTime).TotalMinutes, 1)

$modelFile = Get-ChildItem $ModelDir -Filter "*Q4_K*.gguf" -Recurse -EA SilentlyContinue |
             Sort-Object Length -Descending | Select-Object -First 1
$mPath = if ($modelFile) { $modelFile.FullName } else { "$ModelDir\<model>.gguf" }

Log "" "White"
Log "============================================================" "Green"
Log " DONE! ($elapsed min)" "Green"
Log "============================================================" "Green"
Log "  Build:    $InstallDir" "White"
Log "  Model:    $mPath" "White"
Log "" "White"
Log "  START SERVER:" "Cyan"
Log "    powershell -ExecutionPolicy Bypass -File 'scripts\start-mtp-35b-server.ps1'" "Yellow"
Log "" "White"
Log "  API: http://localhost:8081/v1  (OpenAI-compatible)" "Cyan"
