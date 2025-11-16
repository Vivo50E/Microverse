# Ollama Environment Setup Script
# PowerShell Version

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         Add Ollama to System Environment              ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check admin rights
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "✗ Administrator privileges required" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please run PowerShell as administrator:"
    Write-Host "  1. Press Win + X"
    Write-Host "  2. Select 'Windows PowerShell (Admin)'"
    Write-Host "  3. Run this script again"
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "✓ Administrator privileges confirmed" -ForegroundColor Green
Write-Host ""

# Find Ollama installation
Write-Host "[1/4] Searching for Ollama installation..." -ForegroundColor Yellow
Write-Host ""

$ollamaPath = $null
$searchPaths = @(
    "$env:LOCALAPPDATA\Programs\Ollama",
    "$env:ProgramFiles\Ollama",
    "${env:ProgramFiles(x86)}\Ollama"
)

foreach ($path in $searchPaths) {
    if (Test-Path "$path\ollama.exe") {
        $ollamaPath = $path
        Write-Host "✓ Found Ollama" -ForegroundColor Green
        Write-Host "   Location: $ollamaPath" -ForegroundColor Gray
        break
    }
}

# If not found, search entire system
if (-not $ollamaPath) {
    Write-Host "⚠ Not found in common locations, searching..." -ForegroundColor Yellow
    
    $found = Get-ChildItem -Path "C:\" -Filter "ollama.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    
    if ($found) {
        $ollamaPath = $found.DirectoryName
        Write-Host "✓ Found Ollama" -ForegroundColor Green
        Write-Host "   Location: $ollamaPath" -ForegroundColor Gray
    }
}

if (-not $ollamaPath) {
    Write-Host "✗ Ollama installation not found" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install Ollama first:"
    Write-Host "  winget install Ollama.Ollama"
    Write-Host "  or visit: https://ollama.com/download/windows"
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "[2/4] Checking current environment variables..." -ForegroundColor Yellow
Write-Host ""

# Get current user PATH
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")

# Check if already in PATH
if ($currentPath -like "*$ollamaPath*") {
    Write-Host "✓ Ollama already in environment variables" -ForegroundColor Green
} else {
    Write-Host "⚠ Ollama not in environment variables" -ForegroundColor Yellow
    
    Write-Host ""
    Write-Host "[3/4] Adding to user environment variables..." -ForegroundColor Yellow
    Write-Host ""
    
    # Add to PATH
    if ($currentPath) {
        $newPath = "$currentPath;$ollamaPath"
    } else {
        $newPath = $ollamaPath
    }
    
    try {
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        Write-Host "✓ Environment variable added successfully" -ForegroundColor Green
        Write-Host "   Added: $ollamaPath" -ForegroundColor Gray
    } catch {
        Write-Host "✗ Failed to add: $_" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
}

Write-Host ""
Write-Host "[4/4] Refreshing current session..." -ForegroundColor Yellow
Write-Host ""

# Refresh current session PATH
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

Write-Host "✓ Environment variables refreshed" -ForegroundColor Green

Write-Host ""
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "                  Testing Ollama Command" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Test command
try {
    $version = ollama --version 2>&1
    Write-Host "✓ ollama command is available" -ForegroundColor Green
    Write-Host ""
    Write-Host $version
    Write-Host ""
    Write-Host "✓ Setup successful!" -ForegroundColor Green
} catch {
    Write-Host "⚠ ollama command not recognized in current window" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "This is normal! Please:"
    Write-Host "  1. Close current PowerShell window"
    Write-Host "  2. Open new PowerShell"
    Write-Host "  3. Run: ollama --version"
    Write-Host ""
    Write-Host "New PowerShell windows will load environment variables automatically"
}

Write-Host ""
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "                      Complete" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Environment setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Close and reopen PowerShell" -ForegroundColor Yellow
Write-Host "  2. Run: ollama --version (verify)" -ForegroundColor Yellow
Write-Host "  3. Run: ollama serve (start service)" -ForegroundColor Yellow
Write-Host "  4. Run: .\quick_test.bat (full test)" -ForegroundColor Yellow
Write-Host ""

Read-Host "Press Enter to exit"

