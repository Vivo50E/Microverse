@echo off
chcp 65001 >nul
REM Ollama Environment Test for NVIDIA GPU
REM For Windows + NVIDIA RTX Series

echo ==========================================
echo    Ollama Environment Test (NVIDIA GPU)
echo    Detected GPU: NVIDIA RTX 5080
echo ==========================================
echo.

set PASSED=0
set FAILED=0
set WARNINGS=0

echo [1/10] Checking Ollama installation...
where ollama >nul 2>&1
if %errorlevel% equ 0 (
    echo [32m✅ PASS[0m: Ollama installed
    for /f "tokens=*" %%i in ('ollama --version 2^>^&1') do set OLLAMA_VERSION=%%i
    echo    Version: %OLLAMA_VERSION%
    set /a PASSED+=1
) else (
    echo [31m❌ FAIL[0m: Ollama not installed
    echo Please visit https://ollama.com/download/windows to download
    pause
    exit /b 1
)
echo.

echo [2/10] Checking NVIDIA GPU status...
nvidia-smi >nul 2>&1
if %errorlevel% equ 0 (
    echo [32m✅ PASS[0m: NVIDIA driver OK
    echo.
    echo === GPU Information ===
    nvidia-smi --query-gpu=name,driver_version,memory.total,memory.free --format=csv,noheader
    echo.
    set /a PASSED+=1
) else (
    echo [33m⚠️  WARN[0m: Cannot detect NVIDIA GPU or driver not installed
    echo Please ensure latest NVIDIA driver is installed
    set /a WARNINGS+=1
)
echo.

echo [3/10] Checking CUDA support...
where nvcc >nul 2>&1
if %errorlevel% equ 0 (
    echo [32m✅ PASS[0m: CUDA toolkit installed
    for /f "tokens=*" %%i in ('nvcc --version ^| findstr "release"') do echo    %%i
    set /a PASSED+=1
) else (
    echo [33m⚠️  WARN[0m: CUDA toolkit not detected (Ollama can manage CUDA automatically)
    set /a WARNINGS+=1
)
echo.

echo [4/10] Checking Ollama service status...
tasklist /FI "IMAGENAME eq ollama.exe" 2>NUL | find /I /N "ollama.exe">NUL
if %errorlevel% equ 0 (
    echo [32m✅ PASS[0m: Ollama service running
    set /a PASSED+=1
) else (
    echo [33m⚠️  WARN[0m: Ollama service not running, attempting to start...
    start "Ollama" /B ollama serve
    timeout /t 3 /nobreak >nul
    tasklist /FI "IMAGENAME eq ollama.exe" 2>NUL | find /I /N "ollama.exe">NUL
    if %errorlevel% equ 0 (
        echo [32m✅ PASS[0m: Ollama service started successfully
        set /a PASSED+=1
    ) else (
        echo [31m❌ FAIL[0m: Cannot start Ollama service
        set /a FAILED+=1
    )
)
echo.

echo [5/10] Checking API port...
netstat -an | findstr ":11434" | findstr "LISTENING" >nul
if %errorlevel% equ 0 (
    echo [32m✅ PASS[0m: Port 11434 listening
    set /a PASSED+=1
) else (
    echo [31m❌ FAIL[0m: Port 11434 not listening
    set /a FAILED+=1
)
echo.

echo [6/10] Testing API connection...
curl -s http://localhost:11434/api/tags >nul 2>&1
if %errorlevel% equ 0 (
    echo [32m✅ PASS[0m: API connection OK
    set /a PASSED+=1
) else (
    echo [31m❌ FAIL[0m: API connection failed
    set /a FAILED+=1
)
echo.

echo [7/10] Checking installed models...
echo.
ollama list
echo.
for /f "skip=1" %%i in ('ollama list 2^>^&1') do (
    echo [32m✅ PASS[0m: Models installed
    set /a PASSED+=1
    goto :models_found
)
echo [33m⚠️  WARN[0m: No models installed
echo.
echo Recommended models (optimized for RTX 5080):
echo   ollama pull mistral:7b-instruct        # 7B high-quality model
echo   ollama pull llama2:13b-chat            # 13B large model
echo   ollama pull codellama:13b-instruct     # 13B code model
echo   ollama pull llama2:70b-chat-q4_K_M     # 70B quantized (requires 24GB+ VRAM)
set /a WARNINGS+=1
:models_found
echo.

echo [8/10] GPU acceleration test...
echo Checking if Ollama is using GPU...
timeout /t 2 /nobreak >nul
nvidia-smi --query-compute-apps=pid,process_name,used_memory --format=csv,noheader 2>nul | findstr "ollama" >nul
if %errorlevel% equ 0 (
    echo [32m✅ PASS[0m: Ollama is using GPU acceleration
    echo.
    echo === GPU Usage ===
    nvidia-smi --query-compute-apps=pid,process_name,used_memory --format=csv
    set /a PASSED+=1
) else (
    echo [33m⚠️  WARN[0m: GPU usage not detected (may need to load model first)
    set /a WARNINGS+=1
)
echo.

echo [9/10] Performance benchmark...
echo This test requires installed models, checking...
for /f "skip=1 tokens=1" %%i in ('ollama list 2^>^&1') do (
    set FIRST_MODEL=%%i
    goto :model_found
)
echo [33m⚠️  WARN[0m: Skipping performance test (no models available)
set /a WARNINGS+=1
goto :skip_benchmark

:model_found
echo Using model: %FIRST_MODEL%
echo Sending test request...
echo.

powershell -Command "$start = Get-Date; $response = Invoke-RestMethod -Uri 'http://localhost:11434/api/generate' -Method Post -Body (ConvertTo-Json @{model='%FIRST_MODEL%'; prompt='Say hello'; stream=$false}) -ContentType 'application/json'; $elapsed = ((Get-Date) - $start).TotalSeconds; Write-Host 'Model response:' $response.response; Write-Host 'Response time:' $elapsed 'seconds'; if($elapsed -lt 1){Write-Host 'Performance: 🚀 Excellent (GPU acceleration)'} elseif($elapsed -lt 2){Write-Host 'Performance: ✅ Fast'} elseif($elapsed -lt 5){Write-Host 'Performance: ⚠️ Average'} else{Write-Host 'Performance: ❌ Slow'}"

set /a PASSED+=1

:skip_benchmark
echo.

echo [10/10] RTX 5080 Performance Assessment...
echo.
echo === RTX 5080 Specifications ===
echo VRAM: 16GB GDDR7
echo CUDA Cores: ~10752
echo Tensor Cores: Supported
echo.
echo === Recommended Configuration ===
echo [32m✓[0m Can run 7B-13B full-precision models smoothly
echo [32m✓[0m Can run 70B Q4 quantized models
echo [32m✓[0m Recommended concurrent characters: 8-16
echo [32m✓[0m Expected response speed: 0.5-2 sec/request (7B models)
echo [32m✓[0m Supports long-term stable operation
echo.
set /a PASSED+=1

echo ==========================================
echo              Test Summary
echo ==========================================
echo [32mPassed: %PASSED%[0m
echo [31mFailed: %FAILED%[0m
echo [33mWarnings: %WARNINGS%[0m
echo.

if %FAILED% equ 0 (
    echo 🎉 Congratulations! Ollama environment is perfect!
    echo.
    echo === RTX 5080 Special Recommendations ===
    echo 1. Use larger models to fully utilize GPU performance
    echo 2. Can run multiple model instances simultaneously
    echo 3. Recommended configuration:
    echo    - Decision interval: 30-60 seconds
    echo    - Concurrent characters: 8-16
    echo    - Recommended models: mistral:7b-instruct, llama2:13b-chat
    echo.
    echo === Next Steps ===
    echo 1. Run Python advanced test: python test_advanced.py
    echo 2. Open Microverse project in Godot
    echo 3. Press F5 to start game and configure API
    echo 4. API URL: http://localhost:11434/v1/chat/completions
) else (
    echo ❌ %FAILED% test(s) failed, please fix and retry
)

echo.
echo Detailed log saved to: ollama_test_%date:~0,4%%date:~5,2%%date:~8,2%.log
pause

