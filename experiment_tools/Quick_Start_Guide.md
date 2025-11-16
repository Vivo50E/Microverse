# 🚀 Quick Start Guide - RTX 5080

## 3-Minute Setup

### Step 1: Install Ollama (2 minutes)

Open PowerShell (Administrator mode):

```powershell
# Method 1: Using winget (Recommended)
winget install Ollama.Ollama

# Method 2: Manual download
# Visit https://ollama.com/download/windows
# Download and run installer
```

### Step 2: Start Service & Download Model (1 minute)

```powershell
# Ollama starts automatically after installation
# Verify service status
ollama --version

# Download fastest model (3-4GB, ~1-2 minutes)
ollama pull mistral:7b-instruct
```

### Step 3: Run Test Script

```powershell
# Navigate to tools directory
cd W:\Microverse\experiment_tools

# Run automated test
.\quick_test.bat

# Or run Python advanced test
python test_advanced.py
```

---

## 🎯 Recommended Configuration (Out of the Box)

### Configuration A - Beginner Friendly ⭐⭐⭐⭐⭐

```powershell
# Only one model needed to start
ollama pull mistral:7b-instruct

# Expected performance
Model: Mistral-7B
Response speed: 0.5s
Concurrent characters: 8
Virtual time: 24 hours
Real time: 6 hours
Difficulty: ★☆☆☆☆
```

**Configure in Godot:**
1. Open Microverse project
2. Press F5 to run
3. Press ESC to open settings
4. Configure:
   - API Type: `Ollama`
   - API URL: `http://localhost:11434/v1/chat/completions`
   - Model: `mistral:7b-instruct`
5. Save and start game!

---

### Configuration B - Standard Experiment ⭐⭐⭐⭐

```powershell
# Download two models for comparison
ollama pull mistral:7b-instruct
ollama pull llama2:13b-chat

# Expected performance
Model combo: Mistral-7B + Llama2-13B
Avg response: 0.8s
Concurrent characters: 8
Virtual time: 48 hours
Real time: 24 hours
Difficulty: ★★☆☆☆
```

---

### Configuration C - Advanced ⭐⭐⭐⭐⭐

```powershell
# Download multiple models
ollama pull mistral:7b-instruct
ollama pull llama2:13b-chat
ollama pull mixtral:8x7b-instruct-q4_K_M

# Expected performance
Model combo: 3 model comparison
Avg response: 1.5s
Concurrent characters: 16
Virtual time: 7 days
Real time: 3-4 days
Difficulty: ★★★★☆
```

---

## ⚡ Performance Comparison

| Your Setup | Cloud Service (A100) | Mac M2 Pro | Speed Boost |
|-----------|---------------------|------------|-------------|
| **RTX 5080** | - | - | - |
| 7B inference | 0.3s | 2.5s | **8x** |
| Concurrent capacity | 32 | 4 | **8x** |
| Cost (72h) | $5 electricity | $2160 | **430x** |
| Portability | ❌ | ✅ | - |
| **Overall** | **9/10** | **10/10** | **7/10** |

**Conclusion: RTX 5080 is the cost-performance king!** 💪

---

## 🔍 Verify GPU Acceleration

Run this simple test:

```powershell
# In one PowerShell window, run the model
ollama run mistral:7b-instruct "Count to 100"

# In another window, monitor GPU
nvidia-smi -l 1
```

**If you see GPU usage spike to 90%+, acceleration is working!** ✅

---

## 📊 Real-time Monitoring

### Method 1: nvidia-smi real-time monitoring

```powershell
# Simple version
nvidia-smi -l 1

# Detailed version (Recommended)
nvidia-smi dmon -s ucmt
```

### Method 2: GPU-Z (Graphical)

Download: https://www.techpowerup.com/gpuz/

---

## 🎮 Test in Microverse

### Simplest Test Flow

1. **Ensure Ollama is running:**
   ```powershell
   # Check service
   Get-Service "Ollama Service"
   
   # If not running, start manually
   ollama serve
   ```

2. **Open Godot project:**
   - Launch Godot 4.3+
   - Import `W:\Microverse\project.godot`
   - Press F5 to run

3. **Configure API:**
   - Press ESC in game
   - Select API settings
   - Fill in:
     ```
     API Type: Ollama
     URL: http://localhost:11434/v1/chat/completions
     Model: mistral:7b-instruct
     ```

4. **Start testing:**
   - Select a character (click)
   - Press T to start conversation
   - Observe AI response speed

---

## 💡 Common Issues Quick Reference

### Q1: Command 'ollama' not found

**Solution:**
```powershell
# Restart PowerShell
# Or manually add to PATH
$env:Path += ";C:\Users\$env:USERNAME\AppData\Local\Programs\Ollama"
```

### Q2: Not enough VRAM

**Solution:**
```powershell
# Use smaller quantization
ollama pull mistral:7b-instruct-q4_K_M  # Default is Q4
ollama pull llama2:13b-chat-q3_K_M      # Q3 is smaller
```

### Q3: Slow speed

**Check:**
```powershell
# 1. Confirm GPU is being used
nvidia-smi

# 2. Check if using CPU (error)
# If no ollama process in nvidia-smi, it's using CPU

# 3. Reinstall Ollama (ensure GPU version)
```

### Q4: API connection failed

**Solution:**
```powershell
# Check port
netstat -an | findstr "11434"

# Should see:
# TCP    0.0.0.0:11434    0.0.0.0:0    LISTENING

# If not, restart service
Stop-Process -Name ollama -Force
ollama serve
```

---

## 🎉 Success Indicators

When you see the following, configuration is successful:

✅ `quick_test.bat` all tests passed  
✅ `nvidia-smi` shows ollama process  
✅ GPU usage 80%+  
✅ 7B model response time < 1s  
✅ Microverse characters can converse normally  

---

## 📦 Complete Test Command

```powershell
# One-click test script (copy and paste)

# 1. Check Ollama
ollama --version

# 2. Start service (if not running)
Start-Process ollama -ArgumentList "serve" -WindowStyle Hidden

# 3. Download model
ollama pull mistral:7b-instruct

# 4. Test inference
ollama run mistral:7b-instruct "Say hello"

# 5. Test API
$body = @{
    model = "mistral:7b-instruct"
    messages = @(
        @{
            role = "user"
            content = "Hi"
        }
    )
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:11434/v1/chat/completions" -Method Post -Body $body -ContentType "application/json"

# 6. Run complete test
cd W:\Microverse\experiment_tools
.\quick_test.bat
```

---

## 🚀 Next Steps

After testing passes:

1. 📖 Read [NVIDIA_RTX_Guide.md](NVIDIA_RTX_Guide.md) for advanced configuration
2. 🧪 Run `python test_advanced.py` for deep testing
3. 🎮 Start your AI social experiments in Microverse
4. 📊 Use monitoring tools to track performance

---

**Expected to complete all configuration and start experiments within 15 minutes!** ⏱️

For troubleshooting, check logs:
```powershell
Get-Content "$env:USERPROFILE\.ollama\logs\server.log" -Tail 20
```

