param()

$root = $PSScriptRoot
$src = "$root\src"
$srcGames = "$src\games"
$deployGames = "$root\games"

function Compile-ModularGame($folderPath, $outputFile) {
	$parts = @()

	# base.lua first
	$baseFile = Join-Path $folderPath "base.lua"
	if (Test-Path $baseFile) {
		$parts += Get-Content $baseFile -Raw
	}

	# then each subfolder's .lua files, alphabetically by folder then by file
	$subDirs = Get-ChildItem -Path $folderPath -Directory | Sort-Object Name
	foreach ($dir in $subDirs) {
		$luaFiles = Get-ChildItem -Path $dir.FullName -Filter "*.lua" | Sort-Object Name
		foreach ($f in $luaFiles) {
			$parts += (Get-Content $f.FullName -Raw)
		}
	}

	$outPath = Join-Path $deployGames $outputFile
	($parts -join "`n") | Set-Content -Path $outPath -NoNewline
	Write-Host "  $outputFile ($([math]::Round((Get-Item $outPath).Length / 1KB)) KB)" -ForegroundColor Green
}

Write-Host "Compiling modular src/ -> flat games/" -ForegroundColor Cyan

# Clean old flat game files (keep only what we compile)
$oldFiles = Get-ChildItem -Path $deployGames -Filter "*.lua" -File
foreach ($f in $oldFiles) {
	Remove-Item $f.FullName -Force
}

# Bedwars game (6872274481)
$bwGame = "$srcGames\bedwars\6872274481 - game"
if (Test-Path $bwGame) {
	Compile-ModularGame $bwGame "6872274481.lua"
}

# Bedwars lobby (6872265039)
$bwLobby = "$srcGames\bedwars\6872265039 - lobby"
if (Test-Path $bwLobby) {
	Compile-ModularGame $bwLobby "6872265039.lua"
}

# Bedwars mega (already flat)
$megaSrc = "$srcGames\bedwars\8444591321 - mega.lua"
if (Test-Path $megaSrc) {
	Copy-Item $megaSrc "$deployGames\8444591321.lua" -Force
	$sz = [math]::Round((Get-Item "$deployGames\8444591321.lua").Length / 1KB)
	Write-Host "  8444591321.lua ($sz KB) [flat]" -ForegroundColor Green
}

# Bedwars micro (already flat)
$microSrc = "$srcGames\bedwars\8560631822 - micro.lua"
if (Test-Path $microSrc) {
	Copy-Item $microSrc "$deployGames\8560631822.lua" -Force
	$sz = [math]::Round((Get-Item "$deployGames\8560631822.lua").Length / 1KB)
	Write-Host "  8560631822.lua ($sz KB) [flat]" -ForegroundColor Green
}

# Universal
$universal = "$srcGames\universal - base"
if (Test-Path $universal) {
	Compile-ModularGame $universal "universal.lua"
}

# Copy libraries
Copy-Item "$src\libraries\*" "$root\libraries" -Force
Write-Host "  Libraries copied" -ForegroundColor Green

# Copy guis (skip binary assets if already present)
if (-not (Test-Path "$root\guis\new")) { New-Item -ItemType Directory -Path "$root\guis\new" -Force | Out-Null }
Copy-Item "$src\guis\new.lua" "$root\guis\new.lua" -Force
foreach ($sub in @('base.lua', 'init.lua')) {
	Copy-Item "$src\guis\$sub" "$root\guis\$sub" -Force
}
foreach ($subdir in @('components', 'libraries', 'overlays')) {
	Copy-Item "$src\guis\$subdir" "$root\guis\$subdir" -Recurse -Force
}
if (-not (Test-Path "$root\guis\new\assets")) {
	Copy-Item "$src\guis\new\assets" "$root\guis\new\assets" -Recurse -Force
}
Copy-Item "$src\guis\new\base.lua" "$root\guis\new\base.lua" -Force
Copy-Item "$src\guis\new\init.lua" "$root\guis\new\init.lua" -Force
Write-Host "  GUIs copied" -ForegroundColor Green

# Copy loader + main
Copy-Item "$src\loader.lua" "$root\loader.lua" -Force
Copy-Item "$src\main.lua" "$root\main.lua" -Force
Write-Host "  loader.lua + main.lua copied" -ForegroundColor Green

Write-Host "`nDone!" -ForegroundColor Cyan
