param([string]$CMake = 'cmake', [string]$Python = '.local_ai_tools/venv/Scripts/python.exe')
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Set-Location -LiteralPath $root
function Invoke-Checked([string]$Program, [string[]]$Arguments) {
    & $Program @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Program exited with $LASTEXITCODE" }
}
$tools = Join-Path $root '.local_ai_tools'
New-Item -ItemType Directory -Path $tools -Force | Out-Null
if (-not (Test-Path "$tools/CTranslate2/.git")) {
    Invoke-Checked git @('clone', '--depth', '1', '--branch', 'v4.6.0', 'https://github.com/OpenNMT/CTranslate2.git', "$tools/CTranslate2")
}
$revision = & git -C "$tools/CTranslate2" rev-parse HEAD
if ($revision -ne '617405f4b050e994e829d527da6caa0e0030afe7') { throw 'Unexpected CTranslate2 revision' }
Invoke-Checked git @('-C', "$tools/CTranslate2", 'submodule', 'update', '--init', '--recursive', 'third_party/cpu_features', 'third_party/spdlog', 'third_party/ruy')
if (-not (Test-Path "$tools/sentencepiece/.git")) {
    Invoke-Checked git @('clone', '--depth', '1', '--branch', 'v0.2.1', 'https://github.com/google/sentencepiece.git', "$tools/sentencepiece")
}
$revision = & git -C "$tools/sentencepiece" rev-parse HEAD
if ($revision -ne '31646a467d2051eb904e0b45de3a73e91fe1c1e3') { throw 'Unexpected SentencePiece revision' }
Invoke-Checked $Python @('-X', 'utf8', 'scripts/patch_ct2_windows.py')
Invoke-Checked $CMake @('-S', "$tools/CTranslate2", '-B', "$tools/ct2-build", '-A', 'x64', '-DWITH_MKL=OFF', '-DWITH_RUY=ON', '-DWITH_CUDA=OFF', '-DWITH_CUDNN=OFF', '-DOPENMP_RUNTIME=NONE', '-DBUILD_CLI=OFF', '-DBUILD_TESTS=OFF', '-DBUILD_SHARED_LIBS=ON', '-DCMAKE_CXX_FLAGS=/utf-8', '-DCMAKE_POLICY_VERSION_MINIMUM=3.5')
Invoke-Checked $CMake @('--build', "$tools/ct2-build", '--config', 'Release', '--parallel', '6')
Invoke-Checked $CMake @('-S', "$tools/sentencepiece", '-B', "$tools/spm-build", '-A', 'x64', '-DSPM_ENABLE_SHARED=OFF', '-DSPM_BUILD_TEST=OFF', '-DCMAKE_CXX_FLAGS=/utf-8', '-DCMAKE_POLICY_VERSION_MINIMUM=3.5')
Invoke-Checked $CMake @('--build', "$tools/spm-build", '--config', 'Release', '--target', 'sentencepiece-static', '--parallel', '6')
Invoke-Checked $CMake @('-S', 'native/local_translation', '-B', "$tools/bridge-build", '-A', 'x64')
Invoke-Checked $CMake @('--build', "$tools/bridge-build", '--config', 'Release')
New-Item -ItemType Directory -Path native/runtime/licenses -Force | Out-Null
Copy-Item -LiteralPath "$tools/ct2-build/Release/ctranslate2.dll" -Destination native/runtime/ctranslate2.dll -Force
Copy-Item -LiteralPath "$tools/bridge-build/Release/ja_translation.dll" -Destination native/runtime/ja_translation.dll -Force
foreach ($item in @(@('CTranslate2', 'LICENSE'), @('sentencepiece', 'LICENSE'), @('CTranslate2/third_party/ruy', 'LICENSE'), @('CTranslate2/third_party/cpu_features', 'LICENSE'), @('CTranslate2/third_party/spdlog', 'LICENSE'), @('CTranslate2/third_party/ruy/third_party/cpuinfo', 'LICENSE'), @('CTranslate2/third_party/ruy/third_party/cpuinfo/deps/clog', 'LICENSE'))) {
    $name = ($item[0] -split '/')[-1]
    Copy-Item -LiteralPath "$tools/$($item[0])/$($item[1])" -Destination "native/runtime/licenses/$name.txt" -Force
}
Write-Host 'Embedded CPU translator built. Prepare model packs separately.'
