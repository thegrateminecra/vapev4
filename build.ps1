param(
    [switch]$Test
)

$repo = "thegrateminecra/vapev4"
$branch = "main"
$root = $PSScriptRoot
$outDir = "$root\dist"
$zip = "$root\vapev4.zip"

Write-Host "Vape V4 Build" -ForegroundColor Cyan
Write-Host "-------------"

# verify no stale URLs
Write-Host "`n[1/4] Checking for stale URLs..." -ForegroundColor Yellow
$stale = Get-ChildItem -Path $root -Recurse -Include *.lua,*.md -ErrorAction SilentlyContinue |
    Select-String -Pattern "itzdxsire|7GrandDadPGN/VapeV4" |
    Where-Object { $_.Path -notmatch "\.git\\" -and $_.Path -notmatch "REFERENCE\.md$" }

if ($stale) {
    Write-Host "FAIL - found stale references:" -ForegroundColor Red
    $stale | ForEach-Object { Write-Host "  $($_.Path):$($_.LineNumber)" }
    exit 1
}
Write-Host "  All clean" -ForegroundColor Green

# verify critical files exist
Write-Host "`n[2/4] Checking critical files..." -ForegroundColor Yellow
$required = @("NewMainScript.lua", "main.lua", "loader.lua", "loadstring")
$missing = $required | Where-Object { -not (Test-Path "$root\$_") }
if ($missing) {
    Write-Host "FAIL - missing: $($missing -join ', ')" -ForegroundColor Red
    exit 1
}
Write-Host "  All present" -ForegroundColor Green

# verify bedwars modules exist and have no kick
Write-Host "`n[3/4] Checking Bedwars modules..." -ForegroundColor Yellow
$bwFiles = @("6872274481.lua", "6872265039.lua", "8444591321.lua", "8560631822.lua")
foreach ($f in $bwFiles) {
    $path = "$root\games\$f"
    if (-not (Test-Path $path)) {
        Write-Host "  WARN - $f not found" -ForegroundColor DarkYellow
        continue
    }
    $kick = Select-String -Path $path -Pattern "no longer supported|lplr.Kick|lplr:Kick|game:Shutdown" -CaseSensitive
    if ($kick) {
        Write-Host "  FAIL - $f contains a kick/shutdown!" -ForegroundColor Red
        exit 1
    }
    Write-Host "  $f - OK" -ForegroundColor Green
}

# package dist
Write-Host "`n[4/4] Packaging dist..." -ForegroundColor Yellow
if (Test-Path $outDir) { cmd /c "rd /s /q `"$outDir`"" }
if (Test-Path $zip) { cmd /c "del /f `"$zip`"" }
New-Item -ItemType Directory -Path $outDir -Force | Out-Null

$copy = @(
    "NewMainScript.lua", "main.lua", "loader.lua", "loadstring",
    "README.md", "LICENSE", "CONTRIBUTING.md", ".gitignore"
)
foreach ($f in $copy) {
    if (Test-Path "$root\$f") { Copy-Item "$root\$f" "$outDir\$f" }
}
@("games", "guis", "libraries", "assets") | ForEach-Object {
    if (Test-Path "$root\$_") { Copy-Item "$root\$_" "$outDir\$_" -Recurse }
}

Compress-Archive -Path "$outDir\*" -DestinationPath $zip -Force
cmd /c "rd /s /q `"$outDir`""

$size = [math]::Round((Get-Item $zip).Length / 1KB, 1)
Write-Host "`nDone!" -ForegroundColor Cyan
Write-Host "  Output: vapev4.zip ($size KB)"
Write-Host "  Loadstring:"
Write-Host "  loadstring(game:HttpGet(`"https://raw.githubusercontent.com/$repo/$branch/NewMainScript.lua`", true))()" -ForegroundColor DarkGray

if ($Test) {
    Write-Host "`n--- Dry run complete, no files uploaded ---" -ForegroundColor DarkYellow
}
