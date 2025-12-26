# ================================
# THCS2 MENU - PowerShell Loader
# Run with:
# irm https://ice.lol/thcs | iex
# ================================

$OWNER  = "patpro28"
$REPO   = "THCS2"
$BRANCH = "main"

$API = "https://api.github.com/repos/$OWNER/$REPO/contents"
$RAW = "https://raw.githubusercontent.com/$OWNER/$REPO/$BRANCH"

$headers = @{
    "User-Agent" = "thcs2-menu"
    "Accept"     = "application/vnd.github+json"
}

function Load-Menu {
    try {
        $items = Invoke-RestMethod -Headers $headers -Uri $API -ErrorAction Stop
        $cpp = $items |
            Where-Object { $_.type -eq "file" -and $_.name -like "bai*.cpp" } |
            Sort-Object name

        if (-not $cpp) {
            Write-Error "Khong tim thay bai*.cpp"
            return @()
        }

        $menu = @()
        $i = 1
        foreach ($f in $cpp) {
            $menu += [pscustomobject]@{
                Index = $i
                Name  = $f.name
            }
            $i++
        }
        return $menu
    }
    catch {
        Write-Error "Loi khi lay danh sach bai: $_"
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
    Write-Host "Q - Thoat | R - Refresh"
    Write-Host ""
}

function View-File($file) {
    $url = "$RAW/$file"
    Clear-Host
    Write-Host "==========================================" -ForegroundColor Yellow
    Write-Host " $file" -ForegroundColor Yellow
    Write-Host " Source: $url"
    Write-Host "=========================================="
    Write-Host ""

    try {
        $content = Invoke-RestMethod -Uri $url -Headers $headers -ErrorAction Stop
        Write-Output $content
    }
    catch {
        Write-Error "Khong tai duoc file $file"
    }

    Write-Host ""
    Write-Host "=========================================="
    Pause
}

# ================================
# MAIN LOOP
# ================================

$menu = Load-Menu
if (-not $menu) { return }

while ($true) {
    Show-Menu $menu
    $input = Read-Host "Nhap so bai (vd: 01)"

    if ([string]::IsNullOrWhiteSpace($input)) { continue }

    if ($input -match '^[Qq]$') { break }
    if ($input -match '^[Rr]$') {
        $menu = Load-Menu
        continue
    }

    if ($input -notmatch '^\d+$') {
        Write-Host "Lua chon khong hop le!" -ForegroundColor Red
        Start-Sleep 1
        continue
    }

    $num = [int]$input
    $item = $menu | Where-Object { $_.Index -eq $num }

    if (-not $item) {
        Write-Host "Khong co bai so $num" -ForegroundColor Red
        Start-Sleep 1
        continue
    }

    View-File $item.Name
}
