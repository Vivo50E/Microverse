@echo off
chcp 65001 >nul
title Ollama Auto-Installer

echo.
echo ╔════════════════════════════════════════════════════════╗
echo ║              Ollama Auto-Installer                    ║
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

REM Check if already installed
where ollama >nul 2>&1
if %errorlevel% equ 0 (
    echo [92m✓ Ollama already installed[0m
    ollama --version
    echo.
    goto :check_service
)

echo [1/3] Checking installation tools...
echo.

REM Check winget
where winget >nul 2>&1
if %errorlevel% equ 0 (
    echo [92m✓ Found winget, using winget for installation[0m
    echo.
    echo [2/3] Installing Ollama...
    echo This may take a few minutes...
    echo.
    winget install --id Ollama.Ollama --silent --accept-source-agreements --accept-package-agreements
    
    if %errorlevel% equ 0 (
        echo.
        echo [92m✓ Installation successful[0m
        goto :after_install
    ) else (
        echo [91m✗ winget installation failed[0m
        goto :manual_install
    )
)

:manual_install
echo [93m⚠ winget not found[0m
echo.
echo Opening browser to download page...
echo Please download and install OllamaSetup.exe
echo.
start https://ollama.com/download/windows
echo.
echo Press any key after installation is complete...
pause >nul
goto :after_install

:after_install
echo.
echo [3/3] Refreshing environment variables...
echo.

REM Refresh PATH
for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "SystemPath=%%b"
for /f "tokens=2*" %%a in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "UserPath=%%b"
set "Path=%SystemPath%;%UserPath%"

REM Check again
where ollama >nul 2>&1
if %errorlevel% equ 0 (
    echo [92m✓ Ollama installation successful[0m
    echo.
    ollama --version
    echo.
) else (
    echo [93m⚠ Need to restart PowerShell[0m
    echo.
    echo Please:
    echo 1. Close current PowerShell
    echo 2. Open new PowerShell
    echo 3. Run: ollama --version
    echo.
    pause
    exit /b 0
)

:check_service
echo ════════════════════════════════════════════════════════
echo                  Starting Ollama Service
echo ════════════════════════════════════════════════════════
echo.

REM Check if service is running
tasklist /FI "IMAGENAME eq ollama.exe" 2>NUL | find /I /N "ollama.exe">NUL
if %errorlevel% equ 0 (
    echo [92m✓ Ollama service already running[0m
    echo.
) else (
    echo [93m⚠ Starting Ollama service...[0m
    start "Ollama" /B ollama serve
    timeout /t 5 /nobreak >nul
    echo [92m✓ Service started[0m
    echo.
)

echo ════════════════════════════════════════════════════════
echo                  Testing Installation
echo ════════════════════════════════════════════════════════
echo.

echo Testing API connection...
timeout /t 2 /nobreak >nul
curl -s http://localhost:11434/api/tags >nul 2>&1
if %errorlevel% equ 0 (
    echo [92m✓ API connected successfully[0m
    echo.
) else (
    echo [91m✗ API connection failed[0m
    echo Please wait a moment and try again, or restart service
    echo.
)

echo ════════════════════════════════════════════════════════
echo                  Installation Complete
echo ════════════════════════════════════════════════════════
echo.
echo [92m✓ Ollama is ready![0m
echo.
echo Next steps:
echo   1. Download a model: ollama pull mistral:7b-instruct
echo   2. Run quick test: quick_test.bat
echo   3. Or run detailed test: test_nvidia_gpu.bat
echo.
echo Download model now? [Y/N]
choice /C YN /N /M ""
if errorlevel 2 goto :end
if errorlevel 1 goto :download_model

:download_model
echo.
echo Recommended models (choose one):
echo   [1] mistral:7b-instruct     - Fastest (Recommended)
echo   [2] llama2:13b-chat         - High quality
echo   [3] gemma:7b-instruct       - Balanced
echo.
choice /C 123 /N /M "Select (1/2/3): "
if errorlevel 3 (
    echo.
    echo Downloading Gemma-7B...
    ollama pull gemma:7b-instruct
) else if errorlevel 2 (
    echo.
    echo Downloading Llama2-13B...
    ollama pull llama2:13b-chat
) else (
    echo.
    echo Downloading Mistral-7B...
    ollama pull mistral:7b-instruct
)

echo.
echo [92m✓ Model download complete[0m
echo.

:end
echo Run full test now? [Y/N]
choice /C YN /N /M ""
if errorlevel 2 goto :final
if errorlevel 1 (
    echo.
    start "" "quick_test.bat"
)

:final
echo.
echo Thank you!
echo.
pause

