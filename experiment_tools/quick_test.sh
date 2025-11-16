#!/bin/bash

# Ollama Quick Test Script for Mac/Linux
# For Apple M-series and Linux systems

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║         Ollama Environment Quick Test                 ║"
echo "║         For Mac M-series / Linux                       ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0
WARNINGS=0

# Test functions
test_pass() {
    echo -e "${GREEN}✅ PASS${NC}: $1"
    ((PASSED++))
}

test_fail() {
    echo -e "${RED}❌ FAIL${NC}: $1"
    ((FAILED++))
}

test_warn() {
    echo -e "${YELLOW}⚠️  WARN${NC}: $1"
    ((WARNINGS++))
}

echo "Starting tests..."
echo ""

# Test 1: Check Ollama installation
echo "[1/5] Checking Ollama installation..."
if command -v ollama &> /dev/null; then
    OLLAMA_VERSION=$(ollama --version 2>&1 | head -n 1)
    test_pass "Ollama installed: $OLLAMA_VERSION"
else
    test_fail "Ollama not installed"
    echo ""
    echo "Install Ollama:"
    echo "  curl -fsSL https://ollama.com/install.sh | sh"
    exit 1
fi
echo ""

# Test 2: Check system architecture
echo "[2/5] Checking system architecture..."
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    test_pass "Detected Apple Silicon (ARM64)"
elif [ "$ARCH" = "x86_64" ]; then
    test_warn "Detected Intel architecture"
else
    test_warn "Unknown architecture: $ARCH"
fi
echo ""

# Test 3: Check system memory
echo "[3/5] Checking system memory..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    TOTAL_MEM=$(sysctl -n hw.memsize)
    TOTAL_MEM_GB=$((TOTAL_MEM / 1024 / 1024 / 1024))
    echo "Total memory: ${TOTAL_MEM_GB}GB"
    
    if [ $TOTAL_MEM_GB -ge 16 ]; then
        test_pass "Sufficient memory (${TOTAL_MEM_GB}GB), can run 7B-13B models"
    elif [ $TOTAL_MEM_GB -ge 8 ]; then
        test_warn "Memory is ${TOTAL_MEM_GB}GB, recommend 7B-Q4 models"
    else
        test_fail "Insufficient memory (${TOTAL_MEM_GB}GB), need at least 8GB"
    fi
else
    TOTAL_MEM=$(free -g | awk '/^Mem:/{print $2}')
    if [ $TOTAL_MEM -ge 16 ]; then
        test_pass "Sufficient memory (${TOTAL_MEM}GB)"
    else
        test_warn "Memory is ${TOTAL_MEM}GB, recommend 16GB+"
    fi
fi
echo ""

# Test 4: Check Ollama service
echo "[4/5] Checking Ollama service..."
if pgrep -x "ollama" > /dev/null; then
    test_pass "Ollama service is running"
    echo "  Process ID: $(pgrep -x ollama)"
else
    test_warn "Ollama service not running, attempting to start..."
    echo "  Running: ollama serve"
    ollama serve > /dev/null 2>&1 &
    sleep 3
    if pgrep -x "ollama" > /dev/null; then
        test_pass "Ollama service started successfully"
    else
        test_fail "Cannot start Ollama service"
    fi
fi
echo ""

# Test 5: Check API port
echo "[5/5] Checking API port..."
if lsof -Pi :11434 -sTCP:LISTEN -t >/dev/null 2>&1; then
    test_pass "Port 11434 is listening"
else
    test_fail "Port 11434 not listening, API unavailable"
fi
echo ""

# Test API connection
echo "════════════════════════════════════════════════════════"
echo "              Testing API Connection"
echo "════════════════════════════════════════════════════════"
echo ""

API_RESPONSE=$(curl -s http://localhost:11434/api/tags 2>&1)
if echo "$API_RESPONSE" | grep -q "models"; then
    test_pass "API connection successful"
else
    test_fail "API connection failed"
fi
echo ""

# List installed models
echo "════════════════════════════════════════════════════════"
echo "              Installed Models"
echo "════════════════════════════════════════════════════════"
echo ""

MODELS=$(ollama list 2>&1)
echo "$MODELS"
echo ""

MODEL_COUNT=$(echo "$MODELS" | tail -n +2 | wc -l | tr -d ' ')
if [ "$MODEL_COUNT" -gt 0 ]; then
    test_pass "Found $MODEL_COUNT model(s)"
else
    test_warn "No models installed"
    echo ""
    echo "Recommended models (choose one):"
    echo "  ollama pull mistral:7b-instruct-q4_K_M   # Fastest (Recommended)"
    echo "  ollama pull llama2:7b-chat-q4_K_M        # Classic model"
    echo "  ollama pull gemma:7b-instruct-q4_K_M     # Google model"
fi
echo ""

# Inference test
if [ "$MODEL_COUNT" -gt 0 ]; then
    echo "════════════════════════════════════════════════════════"
    echo "              Inference Speed Test"
    echo "════════════════════════════════════════════════════════"
    echo ""
    
    FIRST_MODEL=$(ollama list 2>&1 | tail -n +2 | head -n 1 | awk '{print $1}')
    
    if [ -n "$FIRST_MODEL" ] && [ "$FIRST_MODEL" != "NAME" ]; then
        echo "Testing with model: $FIRST_MODEL"
        echo "Sending test request..."
        echo ""
        
        START_TIME=$(date +%s.%N)
        INFERENCE_RESPONSE=$(curl -s http://localhost:11434/api/generate -d '{
            "model": "'"$FIRST_MODEL"'",
            "prompt": "Say hello in one word",
            "stream": false
        }')
        END_TIME=$(date +%s.%N)
        
        ELAPSED=$(echo "$END_TIME - $START_TIME" | bc)
        
        if echo "$INFERENCE_RESPONSE" | grep -q "response"; then
            RESPONSE_TEXT=$(echo "$INFERENCE_RESPONSE" | grep -o '"response":"[^"]*"' | cut -d'"' -f4)
            test_pass "Model inference successful"
            echo "  Response time: ${ELAPSED}s"
            echo "  Model reply: $RESPONSE_TEXT"
            
            # Performance rating
            if (( $(echo "$ELAPSED < 3" | bc -l) )); then
                echo "  Performance: 🚀 Excellent"
            elif (( $(echo "$ELAPSED < 5" | bc -l) )); then
                echo "  Performance: ✅ Good"
            elif (( $(echo "$ELAPSED < 10" | bc -l) )); then
                echo "  Performance: ⚠️ Average"
            else
                echo "  Performance: ❌ Slow"
            fi
        else
            test_fail "Model inference failed"
        fi
    fi
    echo ""
fi

# Summary
echo "════════════════════════════════════════════════════════"
echo "                    Test Summary"
echo "════════════════════════════════════════════════════════"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo "🎉 Congratulations! Ollama environment is ready!"
    echo ""
    echo "Next steps:"
    echo "  1. Open Microverse project in Godot"
    echo "  2. Press F5 to run the game"
    echo "  3. Press ESC to open settings"
    echo "  4. Configure API:"
    echo "     - API Type: Ollama"
    echo "     - URL: http://localhost:11434/v1/chat/completions"
    if [ -n "$FIRST_MODEL" ]; then
        echo "     - Model: $FIRST_MODEL"
    fi
else
    echo "❌ $FAILED test(s) failed, please fix and retry"
fi

echo ""
echo "Run Python advanced test: python3 test_advanced.py"
echo ""

