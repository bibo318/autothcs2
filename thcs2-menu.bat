@echo off
setlocal EnableExtensions

set "OWNER=patpro28"
set "REPO=THCS2"
set "BRANCH=main"

set "API=https://api.github.com/repos/%OWNER%/%REPO%/contents"
set "RAW=https://raw.githubusercontent.com/%OWNER%/%REPO%/%BRANCH%"
set "LIST=%TEMP%\thcs2_list.txt"

del /q "%LIST%" 2>nul

REM === Fetch & cache menu list ===
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop';" ^
  "$h=@{'User-Agent'='cmd-menu';'Accept'='application/vnd.github+json'};" ^
  "$items=Invoke-RestMethod -Headers $h -Uri '%API%';" ^
  "$cpp=$items | Where-Object { $_.type -eq 'file' -and $_.name -like 'bai*.cpp' } | Sort-Object name;" ^
  "if(-not $cpp){ exit 2 }" ^
  "$out=@(); $i=1; foreach($f in $cpp){ $out += ('{0:00} {1}' -f $i,$f.name); $i++ }" ^
  "Set-Content -LiteralPath '%LIST%' -Value $out -Encoding UTF8;"

if errorlevel 2 (
  echo Khong tim thay bai*.cpp o thu muc root cua repo.
  pause
  exit /b
)

if not exist "%LIST%" (
  echo Khong tao duoc file danh sach: %LIST%
  pause
  exit /b
)

:MENU
cls
echo ================================
echo  THCS2 - DANH SACH BAI
echo ================================
echo.

type "%LIST%"
echo.
echo Q - Thoat
echo R - Refresh
echo.

set "CHON="
set /p "CHON=Nhap so bai (vd: 01): "

if not defined CHON goto MENU
if /i "%CHON%"=="Q" goto :EOF
if /i "%CHON%"=="R" goto :REFRESH

REM === Resolve selection -> filename ===
set "FILE="
for /f "usebackq delims=" %%F in (`
  powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$c='%CHON%'.Trim();" ^
    "if($c -notmatch '^\d+$'){ exit 3 }" ^
    "$n=[int]$c;" ^
    "$lines=Get-Content -LiteralPath '%LIST%' -ErrorAction Stop;" ^
    "foreach($ln in $lines){ if($ln -match '^\s*(\d+)\s+(.+)$'){ if([int]$matches[1] -eq $n){ Write-Output $matches[2]; exit 0 } } }" ^
    "exit 4"
`) do set "FILE=%%F"

if not defined FILE (
  echo.
  echo Lua chon khong hop le: %CHON%
  pause
  goto MENU
)

REM === Download selected file ===
set "OUT=%TEMP%\%FILE%"
del /q "%OUT%" 2>nul

set "URL=%RAW%/%FILE%"

echo.
echo Dang tai: %FILE%
echo URL: %URL%
echo.

where curl >nul 2>&1
if errorlevel 1 (
  echo [WARN] Khong tim thay curl. Se dung PowerShell Invoke-WebRequest.
  powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ErrorActionPreference='Stop';" ^
    "Invoke-WebRequest -UseBasicParsing -Uri '%URL%' -OutFile '%OUT%';"
) else (
  REM show errors and HTTP details if any
  curl -f -L --retry 2 --retry-delay 1 "%URL%" -o "%OUT%"
)

if not exist "%OUT%" (
  echo.
  echo [FAIL] Tai that bai. Thu kiem tra:
  echo - Co the GitHub bi chan / proxy / TLS
  echo - Hoac curl bi loi
  echo.
  pause
  goto MENU
)

REM === View content ===
cls
echo ==========================================
echo  %FILE%
echo  Source: %URL%
echo  Local : %OUT%
echo ==========================================
echo.

type "%OUT%"
echo.
echo ==========================================
pause
goto MENU

:REFRESH
del /q "%LIST%" 2>nul
call "%~f0"
goto :EOF
