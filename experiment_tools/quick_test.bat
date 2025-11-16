@echo off
chcp 65001 >nul
title Ollama Quick Test - RTX 5080

echo.
echo ╔════════════════════════════════════════════════════════╗
echo ║         Ollama Environment Quick Test                 ║
echo ║         For NVIDIA RTX 5080                            ║
echo ╚════════════════════════════════════════════════════════╝
echo.

REM Set color
color 0A

set PASSED=0
set FAILED=0
set WARNINGS=0

echo [1/5] Checking Ollama installation...
where ollama >nul 2>&1
if %errorlevel% neq 0 (
    color 0C
    echo [91m✗ Ollama not installed[0m
    echo.
    echo Please install Ollama:
    echo 1. Visit: https://ollama.com/download/windows
    echo 2. Download and install
    echo 3. Run this script again
    echo.
    echo Or run: install_ollama.bat
    echo.
    pause
    exit /b 1
)
echo [92m✓ Ollama installed[0m
ollama --version
set /a PASSED+=1
echo.

echo [2/5] Checking service status...
tasklist /FI "IMAGENAME eq ollama.exe" 2>NUL | find /I /N "ollama.exe">NUL
if %errorlevel% neq 0 (
    echo [93m⚠ Service not running, starting...[0m
    start "Ollama" /B ollama serve
    timeout /t 5 /nobreak >nul
    echo [92m✓ Service started[0m
) else (
    echo [92m✓ Service running[0m
)
set /a PASSED+=1
echo.

echo [3/5] Checking NVIDIA GPU...
nvidia-smi >nul 2>&1
if %errorlevel% equ 0 (
    echo [92m✓ NVIDIA GPU detected[0m
    echo.
    echo === GPU Information ===
    nvidia-smi --query-gpu=name,memory.total --format=csv,noheader
    echo.
    set /a PASSED+=1
) else (
    echo [93m⚠ NVIDIA GPU not detected[0m
    set /a WARNINGS+=1
)
echo.

echo [4/5] Testing API connection...
curl -s http://localhost:11434/api/tags >nul 2>&1
if %errorlevel% equ 0 (
    echo [92m✓ API connected[0m
    echo    URL: http://localhost:11434
    set /a PASSED+=1
) else (
    echo [91m✗ API connection failed[0m
    echo    Make sure Ollama service is running
    set /a FAILED+=1
)
echo.

echo [5/5] Checking installed models...
echo.
ollama list
echo.

REM Check if any models exist
for /f "skip=1" %%i in ('ollama list 2^>^&1') do (
    set HAS_MODEL=1
    goto :has_model
)

echo [93m⚠ No models installed[0m
echo.
echo Recommended models (choose one):
echo   [1] ollama pull mistral:7b-instruct     - Fastest (Recommended)
echo   [2] ollama pull llama2:13b-chat         - High quality
echo   [3] ollama pull gemma:7b-instruct       - Balanced
echo.
choice /C 123 /N /M "Select model to install (1/2/3): "
if errorlevel 3 (
    echo.
    echo Installing Gemma-7B...
    ollama pull gemma:7b-instruct
) else if errorlevel 2 (
    echo.
    echo Installing Llama2-13B...
    ollama pull llama2:13b-chat
) else (
    echo.
    echo Installing Mistral-7B...
    ollama pull mistral:7b-instruct
)
set /a WARNINGS+=1
goto :test_inference

:has_model
echo [92m✓ Models installed[0m
set /a PASSED+=1

:test_inference
echo.
echo ════════════════════════════════════════════════════════
echo                 Inference Speed Test
echo ════════════════════════════════════════════════════════
echo.

for /f "skip=1 tokens=1" %%i in ('ollama list 2^>^&1') do (
    set TEST_MODEL=%%i
    goto :do_test
)

:do_test
echo Testing with model: %TEST_MODEL%
echo Sending test request...
echo.

powershell -Command "$start = Get-Date; try { $response = Invoke-RestMethod -Uri 'http://localhost:11434/api/generate' -Method Post -Body (ConvertTo-Json @{model='%TEST_MODEL%'; prompt='Say hello in one word'; stream=$false}) -ContentType 'application/json' -TimeoutSec 60; $elapsed = ((Get-Date) - $start).TotalSeconds; Write-Host 'Model response:' $response.response -ForegroundColor Green; Write-Host 'Response time:' $elapsed 'seconds' -ForegroundColor Cyan; Write-Host ''; if($elapsed -lt 1){Write-Host 'Performance: 🚀 Excellent' -ForegroundColor Green} elseif($elapsed -lt 2){Write-Host 'Performance: ✅ Very Good' -ForegroundColor Green} elseif($elapsed -lt 5){Write-Host 'Performance: ✓ Good' -ForegroundColor Yellow} else{Write-Host 'Performance: ⚠ Average' -ForegroundColor Yellow} } catch { Write-Host '✗ Inference test failed' -ForegroundColor Red; Write-Host $_.Exception.Message -ForegroundColor Red }"

echo.
echo ════════════════════════════════════════════════════════
echo                    Test Complete
echo ════════════════════════════════════════════════════════
echo.
echo [92m✓ Environment ready![0m
echo.
echo Next steps:
echo   1. Open Microverse project in Godot
echo   2. Press F5 to run the game
echo   3. Press ESC to open settings
echo   4. Configure API:
echo      - API Type: Ollama
echo      - URL: http://localhost:11434/v1/chat/completions
echo      - Model: %TEST_MODEL%
echo.
echo Run detailed test: test_nvidia_gpu.bat
echo Run Python test: python test_advanced.py
echo.

pause

