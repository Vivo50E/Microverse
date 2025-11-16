# Microverse Experiment Tools 🧪

**Complete Ollama Testing & Integration Suite for RTX 5080**

## 📁 What's in This Folder?

This folder contains everything you need to test, configure, and optimize Ollama for your Microverse multi-agent AI experiments.

### Quick Start Files

| File | Purpose | Usage |
|------|---------|-------|
| `quick_test.bat` | One-click test | Double-click to verify setup |
| `install_ollama.bat` | Auto-install Ollama | Run if not installed |
| `setup_environment.bat` | Add to PATH | Run as Administrator |

### Advanced Testing

| File | Purpose | Usage |
|------|---------|-------|
| `test_nvidia_gpu.bat` | Comprehensive GPU test | Full system diagnostic |
| `test_advanced.py` | Performance benchmark | Detailed metrics & reports |
| `quick_test.sh` | Mac/Linux quick test | For Mac users |

### Documentation

| File | Description |
|------|-------------|
| `SETUP_SUCCESS.md` | ✅ Test results & system status |
| `MICROVERSE_CONFIG_GUIDE.md` | 🎯 Complete integration guide |
| `GET_STARTED.md` | 📖 How to use these tools |
| `Quick_Start_Guide.md` | 🚀 Fastest path to running |

### Generated Reports

| File Pattern | Contains |
|--------------|----------|
| `ollama_test_report_*.json` | Test results in JSON format |

## 🎉 Current Status

### ✅ Setup Complete!

Based on your latest test (November 5, 2024):

```
✓ Ollama Version: 0.12.9
✓ GPU: NVIDIA GeForce RTX 5080
✓ Driver: 581.08
✓ Model: mistral:7b-instruct (4.4GB)
✓ Performance: 44.87 tokens/sec
✓ All tests: PASSED (7/7)
```

### 🚀 Performance Summary

| Metric | Value | Rating |
|--------|-------|--------|
| Response Time | 2-9 seconds | Good |
| Token Speed | 44.87 tok/s | Very Fast 🚀 |
| Concurrent Support | 8 characters | Excellent |
| GPU Memory | 4GB/16GB (25%) | Healthy |
| Success Rate | 100% | Perfect ✅ |

## 🎯 Quick Actions

### 1. Verify Setup (30 seconds)

```bash
cd W:\Microverse\experiment_tools
quick_test.bat
```

Expected output: "✅ All tests passed!"

### 2. Start Using with Microverse (2 minutes)

Open Microverse and configure:
- **API URL**: `http://localhost:11434/v1/chat/completions`
- **Model**: `mistral:7b-instruct`
- **API Key**: (leave empty)

See detailed steps: `MICROVERSE_CONFIG_GUIDE.md`

### 3. Run Performance Test (1 minute)

```bash
python test_advanced.py
```

Generates detailed JSON report with benchmarks.

## 📚 Documentation Guide

### For First-Time Setup
1. Start here: `Quick_Start_Guide.md`
2. Verify: `quick_test.bat`
3. Results: `SETUP_SUCCESS.md`

### For Microverse Integration
1. Read: `MICROVERSE_CONFIG_GUIDE.md`
2. Follow: Step-by-step code examples
3. Test: Single character first

### For Troubleshooting
1. Check: `SETUP_SUCCESS.md` → Troubleshooting section
2. Run: `test_nvidia_gpu.bat` for diagnostics
3. Review: Generated JSON reports

### For Advanced Users
1. Script: `test_advanced.py` (edit for custom tests)
2. Benchmark: Different models and configurations
3. Monitor: GPU usage with `nvidia-smi`

## 🧪 Recommended Workflow

### Day 1: Setup & Verification
```bash
1. Run quick_test.bat
2. Verify GPU detection
3. Test with 1 character in Microverse
```

### Day 2: Small Scale Test
```bash
1. Configure 2-3 characters
2. Monitor performance
3. Adjust decision intervals
```

### Day 3: Full Experiment
```bash
1. Scale to 6-8 characters
2. Enable logging
3. Run long-term simulation
```

## 🔧 Available Commands

### Testing Commands
```bash
# Quick verification
quick_test.bat

# Full diagnostic
test_nvidia_gpu.bat

# Performance benchmark
python test_advanced.py
```

### Ollama Commands
```bash
# List models
ollama list

# Check running models
ollama ps

# Download new model
ollama pull llama3:8b

# Run interactive chat
ollama run mistral:7b-instruct

# Remove model
ollama rm <model-name>
```

### GPU Monitoring
```bash
# One-time check
nvidia-smi

# Continuous monitoring
nvidia-smi -l 1

# Detailed query
nvidia-smi --query-gpu=name,memory.used,memory.total,utilization.gpu --format=csv
```

## 📊 Performance Recommendations

### Conservative (Start Here)
- **Characters**: 4-6
- **Update Interval**: 5 seconds
- **Expected FPS**: 50-60
- **GPU Usage**: ~30%

### Optimal (Best Balance)
- **Characters**: 6-8
- **Update Interval**: 3 seconds
- **Expected FPS**: 40-50
- **GPU Usage**: ~50%

### Maximum (Stress Test)
- **Characters**: 8
- **Update Interval**: 1 second
- **Expected FPS**: 25-35
- **GPU Usage**: ~70%

## 🎓 Experiment Templates

### Template 1: Memory Impact Study
Focus: How long-term memory affects personality

**Configuration**:
- 4 characters (2 with memory, 2 without)
- Run: 4 hours
- Metrics: Personality consistency, decision patterns

**See**: `MICROVERSE_CONFIG_GUIDE.md` → Memory System Enhancement

### Template 2: Social Network Evolution
Focus: How relationships form and change

**Configuration**:
- 8 characters, random initial relationships
- Run: 8 hours
- Metrics: Network density, clique formation

**See**: `MICROVERSE_CONFIG_GUIDE.md` → Social Network Tracking

### Template 3: Model Comparison
Focus: Different LLMs = different behaviors?

**Configuration**:
- 6 characters (2 per model type)
- Models: mistral, llama3, gemma
- Run: 2 hours

**See**: `MICROVERSE_CONFIG_GUIDE.md` → Model Comparison

## 🆘 Common Issues & Solutions

### Issue: "ollama command not found"
**Solution**: Run `setup_environment.bat` as Administrator

### Issue: Slow responses (>15 seconds)
**Solution**: Increase decision interval or reduce active characters

### Issue: GPU not detected
**Solution**: 
1. Check `nvidia-smi` works
2. Update GPU drivers
3. Restart Ollama service

### Issue: Out of memory
**Solution**:
1. Use smaller model (`phi3:mini`)
2. Reduce concurrent characters
3. Check GPU usage: `nvidia-smi`

## 📖 Additional Resources

### Official Documentation
- Ollama: https://ollama.ai/
- Ollama Models: https://ollama.ai/library
- NVIDIA Drivers: https://www.nvidia.com/drivers

### Project Files
- Microverse README: `../README.md`
- API Manager: `../script/ai/APIManager.gd`
- Dialog System: `../script/ai/DialogManager.gd`

### Community
- Ollama GitHub: https://github.com/ollama/ollama
- Godot Discord: https://discord.gg/godot

## 🎯 Next Steps

1. ✅ Setup Complete - You're here!
2. 📖 Read `MICROVERSE_CONFIG_GUIDE.md`
3. 🎮 Test with 1 character
4. 📈 Scale to full experiment
5. 📊 Collect and analyze data

## 📞 Support Checklist

Before asking for help, verify:
- [ ] `ollama list` shows your model
- [ ] `nvidia-smi` shows your GPU
- [ ] `quick_test.bat` passes
- [ ] Ollama service is running
- [ ] API URL is correct in Microverse

If all checked and still issues, check:
- Windows Firewall settings
- Antivirus blocking localhost
- Port 11434 availability

## 🏆 Success Criteria

You'll know everything is working when:
- ✅ `quick_test.bat` shows all green
- ✅ Characters respond intelligently
- ✅ GPU utilization is 20-60%
- ✅ Response times are 2-9 seconds
- ✅ No API errors in console

---

**Created**: November 5, 2024  
**Hardware**: NVIDIA RTX 5080 (16GB)  
**Software**: Ollama 0.12.9  
**Status**: ✅ Ready for experiments!

**Start experimenting! 🚀**
