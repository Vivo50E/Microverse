# 🎯 Get Started - Choose Your Platform

Welcome to the Microverse Experiment Tools! Choose your platform below to get started.

---

## 🖥️ Windows + NVIDIA GPU

### Step 1: Run Quick Test

**Open PowerShell in this folder and run:**

```powershell
.\quick_test.bat
```

Or just **double-click** `quick_test.bat` in File Explorer

---

### Step 2: If Ollama Not Installed

**Right-click and "Run as Administrator":**

```powershell
.\install_ollama.bat
```

---

### Step 3: If "Command Not Found" Error

**Right-click and "Run as Administrator":**

```powershell
.\setup_environment.bat
```

Then **close and reopen** PowerShell

---

### Step 4: Run Detailed Tests

```powershell
# Full NVIDIA GPU test
.\test_nvidia_gpu.bat

# Python advanced benchmark
python test_advanced.py
```

---

## 🍎 Mac M-series

### Step 1: Open Terminal

```bash
cd /path/to/Microverse/experiment_tools
chmod +x quick_test.sh
./quick_test.sh
```

---

### Step 2: Install Ollama (if needed)

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

---

### Step 3: Run Advanced Test

```bash
python3 test_advanced.py
```

---

## 🐧 Linux

Same as Mac:

```bash
cd /path/to/Microverse/experiment_tools
chmod +x quick_test.sh
./quick_test.sh
```

---

## 📚 Documentation

### Quick Guides
- **[Quick_Start_Guide.md](Quick_Start_Guide.md)** - 3-minute setup ⚡
- **[README.md](README.md)** - Tool overview 📖

### Platform-Specific
- **NVIDIA_RTX_Guide.md** - RTX GPU optimization 🚀
- **Mac_M_Chip_Guide.md** - Apple Silicon setup 🍎

---

## 🔧 Troubleshooting Matrix

| Problem | Windows Solution | Mac/Linux Solution |
|---------|-----------------|-------------------|
| Command not found | Run `setup_environment.bat` | Add to PATH manually |
| Service not starting | `ollama serve` | `ollama serve` |
| API connection failed | Check port 11434 | Check port 11434 |
| Slow performance | Check GPU usage | Check Metal acceleration |
| Out of memory | Use Q4 models | Use Q4 models |

---

## ✅ Success Checklist

After running tests, verify:

- [ ] `ollama --version` works
- [ ] `ollama list` shows models
- [ ] API responds at http://localhost:11434
- [ ] Test inference completes < 5 seconds
- [ ] (Windows) GPU usage shows in nvidia-smi
- [ ] (Mac) Metal acceleration enabled

---

## 🎮 Next: Integrate with Godot

After all tests pass:

1. Open Microverse in Godot
2. Press F5 to run
3. Press ESC for settings
4. Configure API:
   - Type: Ollama
   - URL: http://localhost:11434/v1/chat/completions
   - Model: mistral:7b-instruct

5. Start experimenting! 🚀

---

## 💡 Quick Tips

### Download Models

```bash
# Fast model (Recommended)
ollama pull mistral:7b-instruct

# High quality
ollama pull llama2:13b-chat

# Code specialized
ollama pull codellama:13b-instruct
```

### Monitor Performance

**Windows:**
```powershell
nvidia-smi -l 1
```

**Mac:**
```bash
sudo powermetrics --samplers cpu_power,gpu_power --show-process-coalition
```

### Check Service Status

```bash
# All platforms
ollama list
curl http://localhost:11434/api/tags
```

---

## 📞 Need Help?

1. Check the relevant guide in `experiment_tools/`
2. Run `quick_test.bat` or `quick_test.sh` for diagnostics
3. Check GitHub Issues: https://github.com/KsanaDock/Microverse/issues

---

**Ready? Start with the quick test for your platform!** 🎉

Windows: `.\quick_test.bat`  
Mac/Linux: `./quick_test.sh`

