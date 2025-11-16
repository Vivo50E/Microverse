# Microverse + Ollama Configuration Guide

## 🎯 Quick Start (3 Steps)

### Step 1: Verify Ollama is Running
```bash
ollama list
```
You should see: `mistral:7b-instruct`

### Step 2: Configure Microverse API

Open `W:\Microverse\project.godot` and configure the API settings:

#### Option A: Using In-Game Settings UI
1. Launch Microverse
2. Open Settings → AI Configuration
3. Set:
   - Provider: `Custom` or `OpenAI`
   - Base URL: `http://localhost:11434/v1/chat/completions`
   - Model: `mistral:7b-instruct`
   - API Key: (leave empty)

#### Option B: Direct Code Configuration

Edit `script/ai/APIManager.gd` to add Ollama endpoint:

```gdscript
# In APIManager.gd
func _ready():
    # Add Ollama configuration
    add_provider_config("ollama", {
        "base_url": "http://localhost:11434/v1",
        "api_key": "",  # Not needed for local
        "model": "mistral:7b-instruct"
    })
```

### Step 3: Test with One Character

1. Start the game
2. Click on one character (e.g., Alice)
3. Watch the console for API calls
4. Verify character responds intelligently

## 📊 Verified Performance

Based on your RTX 5080 test results:

| Metric | Value | Status |
|--------|-------|--------|
| **Response Time** | 2-9 seconds | ✅ Good |
| **Token Speed** | 44.87 tok/s | 🚀 Fast |
| **Concurrent Capacity** | 8 characters | ✅ Excellent |
| **GPU Memory** | 4GB/16GB used | ✅ Plenty headroom |
| **Success Rate** | 100% (7/7) | ✅ Perfect |

## 🧪 Experiment Configuration

### For Long-term Memory Research

#### 1. Memory System Enhancement

Add memory persistence in `script/ai/memory/MemoryManager.gd`:

```gdscript
# Enhanced memory with decay
func add_memory(character_name: String, content: String, importance: float = 0.5):
    var memory = {
        "content": content,
        "timestamp": Time.get_unix_time_from_system(),
        "importance": importance,
        "access_count": 0,
        "decay_factor": 0.0  # For Ebbinghaus curve
    }
    character_memories[character_name].append(memory)
    
    # Apply forgetting curve
    _apply_forgetting_curve(character_name)
```

#### 2. Ebbinghaus Forgetting Curve

```gdscript
func _apply_forgetting_curve(character_name: String):
    var current_time = Time.get_unix_time_from_system()
    
    for memory in character_memories[character_name]:
        var time_elapsed = current_time - memory["timestamp"]
        var days = time_elapsed / 86400.0
        
        # R = e^(-t/S), S is memory strength
        var retention = exp(-days / (memory["importance"] * 10))
        memory["decay_factor"] = 1.0 - retention
        
        # Remove memories below threshold
        if retention < 0.1 and memory["importance"] < 0.3:
            character_memories[character_name].erase(memory)
```

#### 3. Social Network Tracking

```gdscript
# Add to CharacterManager.gd
var social_network = {}

func update_relationship(char1: String, char2: String, interaction_type: String):
    if not social_network.has(char1):
        social_network[char1] = {}
    
    if not social_network[char1].has(char2):
        social_network[char1][char2] = {
            "affinity": 0.5,
            "interactions": 0,
            "last_interaction": 0
        }
    
    var rel = social_network[char1][char2]
    rel["interactions"] += 1
    rel["last_interaction"] = Time.get_unix_time_from_system()
    
    # Update affinity based on interaction
    match interaction_type:
        "positive": rel["affinity"] = min(1.0, rel["affinity"] + 0.1)
        "negative": rel["affinity"] = max(0.0, rel["affinity"] - 0.1)
        "neutral": rel["affinity"] = rel["affinity"] * 0.99  # Slight decay
```

### For Multi-Agent Experiments

#### Recommended Starting Configuration

```gdscript
# In your experiment initialization
var experiment_config = {
    "num_characters": 6,  # Start with 6, scale to 8
    "update_interval": 5.0,  # Seconds between AI decisions
    "memory_capacity": 100,  # Max memories per character
    "social_update_frequency": 10,  # Updates before relationship changes
    "logging_enabled": true
}
```

#### Concurrent Request Management

```gdscript
# Batch API requests to avoid overwhelming
var api_queue = []
var max_concurrent_requests = 4  # Conservative start

func process_character_decisions():
    var active_characters = get_active_characters()
    
    # Process in batches
    for i in range(0, active_characters.size(), max_concurrent_requests):
        var batch = active_characters.slice(i, i + max_concurrent_requests)
        await process_batch(batch)
        await get_tree().create_timer(0.5).timeout  # Small delay between batches
```

## 📈 Data Collection Setup

### 1. Create Experiment Logger

Create `script/ExperimentLogger.gd`:

```gdscript
extends Node

var log_file: FileAccess
var experiment_start_time: float

func _ready():
    experiment_start_time = Time.get_unix_time_from_system()
    var filename = "experiment_log_%s.json" % Time.get_datetime_string_from_system()
    log_file = FileAccess.open("user://logs/" + filename, FileAccess.WRITE)

func log_event(event_type: String, data: Dictionary):
    var entry = {
        "timestamp": Time.get_unix_time_from_system() - experiment_start_time,
        "type": event_type,
        "data": data
    }
    log_file.store_line(JSON.stringify(entry))
    log_file.flush()

func log_conversation(char1: String, char2: String, content: String):
    log_event("conversation", {
        "participants": [char1, char2],
        "content": content
    })

func log_memory_added(character: String, memory: Dictionary):
    log_event("memory_add", {
        "character": character,
        "memory": memory
    })

func log_relationship_change(char1: String, char2: String, old_val: float, new_val: float):
    log_event("relationship", {
        "pair": [char1, char2],
        "old_affinity": old_val,
        "new_affinity": new_val
    })
```

### 2. Metrics to Track

```gdscript
var metrics = {
    "api_calls": 0,
    "successful_responses": 0,
    "failed_responses": 0,
    "avg_response_time": 0.0,
    "conversations_initiated": 0,
    "memories_created": 0,
    "memories_forgotten": 0,
    "personality_shifts": 0
}

func update_metrics():
    # Calculate averages
    var total_calls = metrics["successful_responses"] + metrics["failed_responses"]
    if total_calls > 0:
        metrics["success_rate"] = float(metrics["successful_responses"]) / total_calls
    
    # Save snapshot every 5 minutes
    if Time.get_ticks_msec() % 300000 < 100:
        save_metrics_snapshot()
```

## 🎮 Running Experiments

### Experiment 1: Memory Impact on Personality

```bash
# Terminal 1: Monitor GPU
watch -n 1 nvidia-smi

# Terminal 2: Monitor Ollama
ollama ps

# Terminal 3: Run Microverse
cd W:\Microverse
# Launch Godot and start experiment
```

### Experiment 2: Social Network Evolution

1. Initialize 8 characters with different personalities
2. Set up interaction triggers every 30 seconds
3. Run for 2 hours (virtual time)
4. Analyze social network graph

### Experiment 3: Model Comparison

Test different models for different characters:

```bash
# Download alternative models
ollama pull llama3:8b
ollama pull gemma:7b
ollama pull phi3:mini
```

Then assign:
- Characters 1-2: mistral:7b-instruct (baseline)
- Characters 3-4: llama3:8b (comparison)
- Characters 5-6: gemma:7b (comparison)

## 📊 Expected Performance

Based on your RTX 5080 specs:

### Conservative (Recommended Start)
- **6 characters active**
- **Decision interval: 5 seconds**
- **Expected FPS: 45-60**
- **GPU Usage: ~40%**

### Optimal (After Tuning)
- **8 characters active**
- **Decision interval: 3 seconds**
- **Expected FPS: 30-45**
- **GPU Usage: ~60%**

### Maximum (Stress Test)
- **8 characters active**
- **Decision interval: 1 second**
- **Expected FPS: 20-30**
- **GPU Usage: ~80%**

## 🐛 Troubleshooting

### Issue: Slow Responses

**Solution**: Increase decision interval
```gdscript
var decision_interval = 8.0  # Increase from 5.0
```

### Issue: GPU Memory Error

**Check current usage**:
```bash
nvidia-smi
```

**Solution**: Reduce concurrent characters or use smaller model
```bash
ollama pull phi3:mini  # Only 2.3GB
```

### Issue: API Connection Failed

**Check Ollama status**:
```bash
ollama list
ollama ps
```

**Restart if needed**:
```bash
# Just run any ollama command to auto-restart
ollama run mistral:7b-instruct "test"
```

## 📖 Additional Resources

### Ollama Model Library
- Browse: https://ollama.ai/library
- Your current: `mistral:7b-instruct` (4.4GB)
- Recommended alternatives:
  - `llama3:8b` - Better reasoning
  - `phi3:mini` - Faster responses
  - `gemma:7b` - Good balance

### Microverse AI Configuration
- API Manager: `script/ai/APIManager.gd`
- Dialog System: `script/ai/DialogManager.gd`
- Memory System: `script/ai/memory/MemoryManager.gd`
- Agent Logic: `script/ai/AIAgent.gd`

### Performance Monitoring
```bash
# GPU monitoring
nvidia-smi -l 1

# Ollama monitoring
ollama ps

# Check running models
ollama list
```

## ✅ Pre-flight Checklist

Before starting your experiment:

- [ ] Ollama service is running (`ollama list`)
- [ ] Model is downloaded (`mistral:7b-instruct`)
- [ ] GPU is detected (`nvidia-smi`)
- [ ] API endpoint configured in Microverse
- [ ] Test with 1 character first
- [ ] Logging is enabled
- [ ] Backup your project
- [ ] Monitor tools are ready

## 🚀 Start Your Experiment!

You're all set! Your RTX 5080 is configured perfectly for running multi-agent AI experiments with Ollama.

**Quick start command**:
```bash
cd W:\Microverse\experiment_tools
./quick_test.bat  # Verify everything is working
```

Then launch Microverse and enjoy your AI-powered virtual world! 🎉

---

**Last Updated**: November 5, 2024  
**Test Status**: ✅ All systems operational  
**Performance**: 🚀 Excellent (44.87 tokens/sec)

