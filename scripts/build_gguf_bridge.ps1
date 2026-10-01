param([string]$CMake = 'cmake', [string]$MsvcBin = 'C:/Program Files (x86)/Microsoft Visual Studio/18/BuildTools/VC/Tools/MSVC/14.51.36231/bin/Hostx64/x64')
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Set-Location -LiteralPath $root
$sourceRevision = '3d82ef62d47fd74e18f36c5eccbdcf965b617b17'
if ((& git -C .local_ai_tools/llama.cpp rev-parse HEAD) -ne $sourceRevision) { throw 'Wrong llama.cpp headers; fetch the pinned revision first' }
$expectedHash = 'DEACE0903AAF21493B8DDF425DF07A60C5BCFFEAF1F88E04B4F11F1233C4D1E8'
if ((Get-FileHash bin/llama.dll -Algorithm SHA256).Hash -ne $expectedHash) { throw 'Existing llama DLL differs from the verified ABI version' }
$contract = Get-Content -LiteralPath native/gguf_translation/runtime_contract.json -Raw | ConvertFrom-Json
foreach ($entry in $contract.files.PSObject.Properties) {
    if ((Get-FileHash -LiteralPath "bin/$($entry.Name)" -Algorithm SHA256).Hash -ne $entry.Value) {
        throw "Runtime ABI contract changed: $($entry.Name)"
    }
}
New-Item -ItemType Directory -Path .local_ai_tools/gguf-import -Force | Out-Null
foreach ($name in @('llama', 'ggml')) {
    $exports = & "$MsvcBin/dumpbin.exe" /exports "bin/$name.dll"
    if ($LASTEXITCODE -ne 0) { throw 'dumpbin failed' }
    $symbols = @($exports | ForEach-Object { if ($_ -match '^\s+\d+\s+[0-9A-F]+\s+[0-9A-F]+\s+(\w+)') { $Matches[1] } })
    if ($symbols.Count -eq 0) { throw 'No DLL exports found' }
    @("LIBRARY $name.dll", 'EXPORTS') + $symbols | Set-Content -Encoding ascii ".local_ai_tools/gguf-import/$name.def"
    & "$MsvcBin/lib.exe" "/def:.local_ai_tools/gguf-import/$name.def" /machine:x64 "/out:.local_ai_tools/gguf-import/$name.lib" | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Import library generation failed' }
}
& $CMake -S native/gguf_translation -B .local_ai_tools/gguf-bridge-build -A x64
if ($LASTEXITCODE -ne 0) { throw 'GGUF bridge configuration failed' }
& $CMake --build .local_ai_tools/gguf-bridge-build --config Release
if ($LASTEXITCODE -ne 0) { throw 'GGUF bridge build failed' }
New-Item -ItemType Directory -Path native/runtime/gguf -Force | Out-Null
Copy-Item -LiteralPath .local_ai_tools/gguf-bridge-build/Release/ja_gguf.dll -Destination native/runtime/gguf/ja_gguf.dll -Force
foreach ($name in @('llama.dll', 'ggml.dll', 'ggml-base.dll', 'ggml-cpu-x64.dll', 'ggml-cpu-haswell.dll', 'libomp.dll')) {
    Copy-Item -LiteralPath "bin/$name" -Destination "native/runtime/gguf/$name" -Force
}
Copy-Item -LiteralPath .local_ai_tools/llama.cpp/LICENSE -Destination native/runtime/gguf/LICENSE-llama.txt -Force
@{ source_revision=$sourceRevision; llama_sha256=$expectedHash; backend='CPU x64 + optional AVX2'; server=$false } | ConvertTo-Json | Set-Content -Encoding utf8 native/runtime/gguf/provenance.json
if (-not (Test-Path .local_ai_tools/LICENSE-LLVM.txt)) {
    Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/llvm/llvm-project/llvmorg-20.1.8/LICENSE.TXT' -OutFile .local_ai_tools/LICENSE-LLVM.txt
}
Copy-Item -LiteralPath .local_ai_tools/LICENSE-LLVM.txt -Destination native/runtime/gguf/LICENSE-LLVM.txt -Force
Write-Host 'GGUF embedded bridge prepared; no server binaries included.'
