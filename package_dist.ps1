$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$rel = Join-Path $root "build\windows\x64\runner\Release"
$dist = Join-Path $root "dist"
$targetDir = Join-Path $dist "JA_Translate"

# Determine version from pubspec.yaml
$pubspecPath = Join-Path $root "pubspec.yaml"
$version = "1.1.0"
if (Test-Path $pubspecPath) {
    $content = Get-Content $pubspecPath -Raw
    if ($content -match 'version:\s*([0-9]+\.[0-9]+\.[0-9]+)') {
        $version = $matches[1]
    }
}
Write-Host "Packaging JA_Translate v$version..." -ForegroundColor Cyan

Write-Host "Closing running instances of ja_translate.exe and llama-server.exe..."
Stop-Process -Name "ja_translate" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "llama-server" -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

Write-Host "Creating dist directory..."
if (Test-Path $dist) {
    Remove-Item -Path $dist -Recurse -Force
}
New-Item -ItemType Directory -Path $targetDir -Force | Out-Null

Write-Host "Copying Release binary files..."
Copy-Item -Path (Join-Path $rel "*") -Destination $targetDir -Recurse -Force

Write-Host "Copying documentation, configurations, and installer suite..."
$docs = @("config.ini", "update_config.json", "debug.bat", "install.bat", "uninstall.bat", "uninstall.ps1", "README.md", "CHANGELOG.md", "USERGUIDE.md", "RELEASE_NOTES.md", "ABOUT.txt")
foreach ($doc in $docs) {
    $src = Join-Path $root $doc
    if (Test-Path $src) {
        Copy-Item -Path $src -Destination (Join-Path $targetDir $doc) -Force
        # Also copy installer & launcher scripts to dist root for convenience
        if ($doc -in @("debug.bat", "install.bat", "uninstall.bat", "uninstall.ps1")) {
            Copy-Item -Path $src -Destination (Join-Path $dist $doc) -Force
        }
    }
}

Write-Host "Copying bin directory (llama-server and runtime DLLs)..."
$binPath = Join-Path $root "bin"
if ((Test-Path $binPath) -and -not (Test-Path (Join-Path $root "native/runtime/gguf/ja_gguf.dll"))) {
    Copy-Item -Path $binPath -Destination $targetDir -Recurse -Force
}

Write-Host "Creating models directory in dist..."
$targetModels = Join-Path $targetDir "models"
if (-not (Test-Path $targetModels)) {
    New-Item -ItemType Directory -Path $targetModels -Force | Out-Null
}
$devModels = Join-Path $root "models"
if ((Test-Path $devModels) -and -not (Test-Path (Join-Path $root "native/runtime/gguf/ja_gguf.dll"))) {
    Get-ChildItem -Path $devModels -Filter "*.gguf" | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $targetModels -Force
    }
}

Write-Host "Packaging ZIP archive with nested parent directory..." -ForegroundColor Cyan
$packDirName = "JA_Translate_v${version}_Windows_x64"
$distPack = Join-Path $root "dist_pack"
$nestedDir = Join-Path $distPack $packDirName

if (Test-Path $distPack) {
    Remove-Item -Path $distPack -Recurse -Force
}
New-Item -ItemType Directory -Path $nestedDir -Force | Out-Null

Copy-Item -Path (Join-Path $targetDir "*") -Destination $nestedDir -Recurse -Force

$zipPath = Join-Path $dist "${packDirName}.zip"
Write-Host "Compressing to $zipPath..."
Compress-Archive -Path $nestedDir -DestinationPath $zipPath -Force

Remove-Item -Path $distPack -Recurse -Force

Write-Host "Generating SHA256 checksum..." -ForegroundColor Cyan
$hash = (Get-FileHash -Path $zipPath -Algorithm SHA256).Hash.ToLower()
$checksumFile = Join-Path $dist "SHA256SUMS.txt"
"${hash}  ${packDirName}.zip" | Out-File -FilePath $checksumFile -Encoding utf8 -Force

Write-Host "Generating version.json for LAN OTA update metadata..." -ForegroundColor Cyan
$versionJsonPath = Join-Path $dist "version.json"
$releaseNotesText = "JA Translate v${version}"
$releaseNotesPath = Join-Path $root "RELEASE_NOTES.md"
if (Test-Path $releaseNotesPath) {
    $rnContent = [System.IO.File]::ReadAllText($releaseNotesPath, [System.Text.Encoding]::UTF8)
    if ($rnContent -match '(?m)^TITLE=(.+)$') {
        $releaseNotesText = $matches[1].Trim()
    }
}
$verData = [ordered]@{
    version = $version
    fileName = "${packDirName}.zip"
    releaseDate = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    releaseNotes = $releaseNotesText
}
$verJsonContent = $verData | ConvertTo-Json -Compress
[System.IO.File]::WriteAllText($versionJsonPath, $verJsonContent, [System.Text.Encoding]::UTF8)
Copy-Item -Path $versionJsonPath -Destination (Join-Path $targetDir "version.json") -Force

Write-Host "Dist packaging completed successfully!" -ForegroundColor Green
Get-ChildItem -Path $dist
