# ================================
# THCS2 MENU - PowerShell
# Run:
# irm https://ice.lol/thcs | iex
# ================================

$OWNER  = "patpro28"
$REPO   = "THCS2"
$BRANCH = "main"

$API_BASE = "https://api.github.com/repos/$OWNER/$REPO/contents"
$RAW_BASE = "https://raw.githubusercontent.com/$OWNER/$REPO/$BRANCH"

$headers = @{
  "User-Agent" = "thcs2-menu"
  "Accept"     = "application/vnd.github+json"
}

$DownloadRoot = Join-Path $env:TEMP "thcs2"

function Get-Contents([string]$Path = "") {
  $uri = if ([string]::IsNullOrWhiteSpace($Path)) { $API_BASE } else { "$API_BASE/$Path" }
  Invoke-RestMethod -Headers $headers -Uri $uri -ErrorAction Stop
}

function Ensure-Dir([string]$Dir) {
  if (-not (Test-Path -LiteralPath $Dir)) {
    New-Item -ItemType Directory -Path $Dir -Force | Out-Null
  }
}

function Download-File([string]$RepoPath, [string]$LocalPath) {
  $url = "$RAW_BASE/$RepoPath"
  Ensure-Dir (Split-Path -Parent $LocalPath)

  try {
    Invoke-WebRequest -UseBasicParsing -Headers $headers -Uri $url -OutFile $LocalPath -ErrorAction Stop | Out-Null
    return $true
  } catch {
    Write-Host "[FAIL] $RepoPath" -ForegroundColor Red
    Write-Host "       $($_.Exception.Message)" -ForegroundColor DarkRed
    return $false
  }
}

function Download-Tree([string]$Path = "", [string]$LocalBase = $DownloadRoot) {
  $items = Get-Contents -Path $Path

  foreach ($it in $items) {
    if ($it.type -eq "file") {
      $repoPath  = if ([string]::IsNullOrWhiteSpace($Path)) { $it.name } else { "$Path/$($it.name)" }
      $localPath = Join-Path $LocalBase $repoPath
      [void](Download-File -RepoPath $repoPath -LocalPath $localPath)
    }
    elseif ($it.type -eq "dir") {
      $subPath = if ([string]::IsNullOrWhiteSpace($Path)) { $it.name } else { "$Path/$($it.name)" }
      Download-Tree -Path $subPath -LocalBase $LocalBase
    }
  }
}

function Load-Menu {
  try {
    $items = Get-Contents
    $cpp = $items |
      Where-Object { $_.type -eq "file" -and $_.name -like "bai*.cpp" } |
      Sort-Object name

    $menu = @()
    $i = 1
    foreach ($f in $cpp) {
      $menu += [pscustomobject]@{ Index = $i; Name = $f.name }
      $i++
    }
    return $menu
  } catch {
    Write-Host "Loi khi lay danh sach bai: $($_.Exception.Message)" -ForegroundColor Red
    return @()
  }
}

function Show-Menu($menu) {
  Clear-Host
  Write-Host "================================" -ForegroundColor Cyan
  Write-Host " THCS2 - DANH SACH BAI" -ForegroundColor Cyan
  Write-Host "================================" -ForegroundColor Cyan
  Write-Host ""

  foreach ($m in $menu) {
    "{0:00} {1}" -f $m.Index, $m.Name
  }

  Write-Host ""
  Write-Host "A - Tai toan bo ve $DownloadRoot"
  Write-Host "Q - Thoat | R - Refresh"
  Write-Host ""
}

function View-File([string]$file) {
  $url = "$RAW_BASE/$file"
  Clear-Host
  Write-Host "==========================================" -ForegroundColor Yellow
  Write-Host " $file" -ForegroundColor Yellow
  Write-Host " Source: $url"
  Write-Host "=========================================="
  Write-Host ""

  try {
    $content = Invoke-RestMethod -Uri $url -Headers $headers -ErrorAction Stop
    Write-Output $content
  } catch {
    Write-Host "Khong tai duoc file: $file" -ForegroundColor Red
    Write-Host $($_.Exception.Message) -ForegroundColor DarkRed
  }

  Write-Host ""
  Write-Host "=========================================="
  Pause
}

function Download-All {
  Clear-Host
  Write-Host "Se tai TOAN BO repo ve: $DownloadRoot" -ForegroundColor Cyan
  Write-Host "Dang tai..." -ForegroundColor Cyan
  Write-Host ""

  Ensure-Dir $DownloadRoot
  Download-Tree

  Write-Host ""
  Write-Host "Hoan tat. Thu muc: $DownloadRoot" -ForegroundColor Green
  Pause
}

# ================================
# MAIN
# ================================
$menu = Load-Menu
if (-not $menu -or $menu.Count -eq 0) {
  Write-Host "Khong lay duoc danh sach bai (bai*.cpp)." -ForegroundColor Red
  return
}

while ($true) {
  Show-Menu $menu
  $input = Read-Host "Nhap so bai (vd: 01) / A / R / Q"
  if ([string]::IsNullOrWhiteSpace($input)) { continue }

  if ($input -match '^[Qq]$') { break }
  if ($input -match '^[Rr]$') { $menu = Load-Menu; continue }
  if ($input -match '^[Aa]$') { Download-All; continue }

  if ($input -notmatch '^\d+$') {
    Write-Host "Lua chon khong hop le!" -ForegroundColor Red
    Start-Sleep 1
    continue
  }

  $num = [int]$input
  $item = $menu | Where-Object { $_.Index -eq $num } | Select-Object -First 1
  if (-not $item) {
    Write-Host "Khong co bai so $num" -ForegroundColor Red
    Start-Sleep 1
    continue
  }

  View-File $item.Name
}
