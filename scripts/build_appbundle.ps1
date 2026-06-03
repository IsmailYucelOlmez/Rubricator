$ErrorActionPreference = "Stop"

$envFile = Join-Path $PSScriptRoot "..\env.production.json"
if (-not (Test-Path $envFile)) {
    Write-Error @"
env.production.json bulunamadi.
env.example.json dosyasini kopyalayip Supabase URL ve anahtarinizi girin.
"@
}

Set-Location (Join-Path $PSScriptRoot "..")

flutter build appbundle --release --dart-define-from-file=env.production.json @args
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$aab = "build\app\outputs\bundle\release\app-release.aab"
if (-not (Test-Path $aab)) {
    Write-Error "AAB olusturulamadi: $aab"
}

$projectHost = (Get-Content $envFile -Raw | ConvertFrom-Json).SUPABASE_URL
$hostMarker = ([uri]$projectHost).Host.Split(".")[0]
$tmp = Join-Path $env:TEMP "bookapp-aab-env-check"
if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
Copy-Item $aab "$tmp.zip"
Expand-Archive "$tmp.zip" $tmp -Force

$found = Get-ChildItem $tmp -Recurse -Filter "libapp.so" | ForEach-Object {
    [System.IO.File]::ReadAllText($_.FullName).Contains($hostMarker)
} | Where-Object { $_ } | Select-Object -First 1

if (-not $found) {
    Write-Error @"
AAB icinde Supabase URL bulunamadi ($hostMarker).
Build --dart-define-from-file olmadan alinmis olabilir.
"@
}

Write-Host ""
Write-Host "AAB hazir: $((Resolve-Path $aab).Path)"
Write-Host "Supabase env dogrulandi: $hostMarker"
