@echo off
chcp 65001 >nul
title Setup Ollama Environment

echo.
echo ╔════════════════════════════════════════════════════════╗
echo ║         Add Ollama to System Environment              ║
echo ╚════════════════════════════════════════════════════════╝
echo.

REM Check admin rights
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [91m✗ Administrator privileges required[0m
    echo.
    echo Please right-click this script and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

echo [92m✓ Administrator privileges confirmed[0m
echo.

echo [1/4] Searching for Ollama installation...
echo.

REM Find Ollama installation
set OLLAMA_FOUND=0
set OLLAMA_PATH=

REM Location 1: User local programs
if exist "%LOCALAPPDATA%\Programs\Ollama\ollama.exe" (
    set "OLLAMA_PATH=%LOCALAPPDATA%\Programs\Ollama"
    set OLLAMA_FOUND=1
    echo [92m✓ Found Ollama[0m
    echo    Location: %OLLAMA_PATH%
    goto :found
)

REM Location 2: Program Files
if exist "%ProgramFiles%\Ollama\ollama.exe" (
    set "OLLAMA_PATH=%ProgramFiles%\Ollama"
    set OLLAMA_FOUND=1
    echo [92m✓ Found Ollama[0m
    echo    Location: %OLLAMA_PATH%
    goto :found
)

REM Location 3: Program Files (x86)
if exist "%ProgramFiles(x86)%\Ollama\ollama.exe" (
    set "OLLAMA_PATH=%ProgramFiles(x86)%\Ollama"
    set OLLAMA_FOUND=1
    echo [92m✓ Found Ollama[0m
    echo    Location: %OLLAMA_PATH%
    goto :found
)

REM Search all drives
echo [93m⚠ Not found in common locations, searching...[0m
for %%d in (C D E F) do (
    if exist %%d:\ (
        for /f "delims=" %%i in ('dir /s /b "%%d:\ollama.exe" 2^>nul ^| findstr /i "ollama.exe$"') do (
            set "OLLAMA_PATH=%%~dpi"
            set "OLLAMA_PATH=!OLLAMA_PATH:~0,-1!"
            set OLLAMA_FOUND=1
            echo [92m✓ Found Ollama[0m
            echo    Location: !OLLAMA_PATH!
            goto :found
        )
    )
)

:found
if %OLLAMA_FOUND% equ 0 (
    echo [91m✗ Ollama installation not found[0m
    echo.
    echo Please install Ollama first:
    echo   1. Run: install_ollama.bat
    echo   2. Or visit: https://ollama.com/download/windows
    echo.
    pause
    exit /b 1
)

echo.
echo [2/4] Checking current environment variables...
echo.

REM Get current user PATH
for /f "tokens=2*" %%a in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "USER_PATH=%%b"

REM Check if already in PATH
echo %USER_PATH% | findstr /i /c:"%OLLAMA_PATH%" >nul
if %errorlevel% equ 0 (
    echo [92m✓ Ollama already in environment variables[0m
    goto :test_command
) else (
    echo [93m⚠ Ollama not in environment variables[0m
)

echo.
echo [3/4] Adding to user environment variables...
echo.

REM Add to user PATH
if defined USER_PATH (
    set "NEW_PATH=%USER_PATH%;%OLLAMA_PATH%"
) else (
    set "NEW_PATH=%OLLAMA_PATH%"
)

REM Write to registry
reg add "HKCU\Environment" /v Path /t REG_EXPAND_SZ /d "%NEW_PATH%" /f >nul 2>&1

if %errorlevel% equ 0 (
    echo [92m✓ Environment variable added successfully[0m
    echo    Added: %OLLAMA_PATH%
) else (
    echo [91m✗ Failed to add[0m
    echo Please try adding manually
    pause
    exit /b 1
)

echo.
echo [4/4] Refreshing current session...
echo.

REM Refresh current PowerShell session PATH
set "Path=%Path%;%OLLAMA_PATH%"

REM Notify system about environment variable change
powershell -Command "[System.Environment]::SetEnvironmentVariable('Path', [System.Environment]::GetEnvironmentVariable('Path', 'User'), 'User')" >nul 2>&1

echo [92m✓ Environment variables refreshed[0m

:test_command
echo.
echo ════════════════════════════════════════════════════════
echo                  Testing Ollama Command
echo ════════════════════════════════════════════════════════
echo.

REM Test command
where ollama >nul 2>&1
if %errorlevel% equ 0 (
    echo [92m✓ ollama command is available[0m
    echo.
    ollama --version
    echo.
    echo [92m✓ Setup successful![0m
) else (
    echo [93m⚠ ollama command not recognized in current window[0m
    echo.
    echo This is normal! Please:
    echo   1. Close current PowerShell window
    echo   2. Open new PowerShell
    echo   3. Run: ollama --version
    echo.
    echo New PowerShell windows will load environment variables automatically
)

echo.
echo ════════════════════════════════════════════════════════
echo                      Complete
echo ════════════════════════════════════════════════════════
echo.
echo Environment setup complete!
echo.
echo Next steps:
echo   1. Close and reopen PowerShell
echo   2. Run: ollama --version (verify)
echo   3. Run: ollama serve (start service)
echo   4. Run: quick_test.bat (full test)
echo.

pause

