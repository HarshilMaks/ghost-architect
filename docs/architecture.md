# Gemma-3 Ghost Architect: System Architecture

## Overview
The Ghost Architect is a multimodal AI system that converts UI screenshots into database schemas using a fine-tuned Gemma-3-12B model. This document details the complete system architecture, from training pipeline to production deployment.

---

## 1. System Architecture Overview

```mermaid
graph TD
    A[UI Screenshot] --> B[Gemma-3 Vision Model]
    B --> C[SQL Schema Generator]
    C --> D[Database Schema]
    
    E[Training Data] --> F[Synthetic Generator]
    F --> G[Gemini API]
    G --> H[Quality Validation]
    H --> I[Fine-tuning Pipeline]
    I --> B
    
    J[Export] --> K[GGUF / Ollama]
    J --> L[Streamlit Demo App]
```

---

## 2. Project Structure

```
ghost_architect_gemma3/
├── configs/
│   └── training_config.yaml        # Phase 1 config (used by Makefile + src/train.py)
│
├── scripts/
│   ├── build_vision_dataset.py     # Builds dataset_vision.json from screenshots + Gemini
│   ├── download_datasets.py        # Playwright scraper for UI screenshots
│   ├── generate_training_data.py   # Generates Phase 1 starter data
│   ├── validate_dataset.py         # Validates dataset.json (make dataset-check)
│   └── validate_environment.py     # Validates GPU/deps (make validate)
│
├── src/                            # Source code
│   ├── __init__.py
│   ├── train.py                    # Phase 1: Trinity text training
│   ├── train_vision.py             # Colab T4 vision training (QLoRA+rsLoRA)
│   ├── modal_train.py              # Modal A10G vision training (full Trinity)
│   ├── inference.py                # CLI testing with rich terminal output
│   ├── app.py                      # Streamlit web app (upload screenshot → schema)
│   ├── export.py                   # GGUF export for Ollama
│   └── synthetic_generator.py      # Gemini API for SQL generation from screenshots
│
├── data/                           # Training data
│   ├── dataset.json                # Phase 1: Text training data
│   ├── dataset_vision.json         # Phase 2: 287 vision training examples
│   ├── ui_screenshots/             # 287 PNGs (107MB)
│   ├── raw_csvs/                   # Source CSVs for scraper
│   ├── synthetic_pairs/            # (empty, for future use)
│   └── validation_set/             # (empty, for future use)
│
├── output/                         # Model outputs (gitignored)
│   ├── adapters/                   # LoRA adapter weights
│   └── gguf/                       # GGUF models for Ollama
│
├── tests/
│   └── __init__.py                 # Test package (no tests yet)
│
├── notebooks/
│   └── main.ipynb                  # Colab T4 notebook
│
├── docs/                           # Documentation
├── docker/                         # Docker setup (future)
│
├── Makefile                        # Build targets
├── requirements.txt                # Python dependencies
├── README.md
├── DATASET_README.md
├── SECURITY.md
└── LICENSE
```

---

## 3. Phase 1: Trinity Architecture (Text Fine-Tuning)

### 3.1 Model Configuration
```python
# Trinity Architecture Components:

# QLoRA (4-bit Quantization)
quantization_config = BitsAndBytesConfig(
    load_in_4bit=True,
    bnb_4bit_quant_type="nf4",
    bnb_4bit_compute_dtype=torch.float16,
    bnb_4bit_use_double_quant=True
)

# DoRA (Weight-Decomposed Adaptation)
peft_config = LoraConfig(
    r=64,                    # High-rank adaptation
    lora_alpha=32,
    target_modules=[
        "q_proj", "k_proj", "v_proj", "o_proj",
        "gate_proj", "up_proj", "down_proj"
    ],
    use_dora=True,          # Enable DoRA
    use_rslora=True,        # Enable rsLoRA for stability
    lora_dropout=0.1,
    bias="none",
    task_type="CAUSAL_LM"
)
```

### 3.2 Memory Optimization Strategy
```python
# Target Memory Usage: 15.6GB on T4 GPU (16GB total)
memory_allocation = {
    "model_weights_4bit": 7.6,      # GB - Quantized model
    "gradients_rank64": 5.5,        # GB - High-rank LoRA gradients  
    "context_overhead": 2.5,        # GB - 4096 token context
    "system_buffer": 0.4,           # GB - System overhead
    "total": 15.6                   # GB - 98% GPU utilization
}

# OOM Recovery Protocol
oom_fallback_steps = [
    {"action": "reduce_context", "from": 4096, "to": 2048, "memory_saved": 2.0},
    {"action": "reduce_rank", "from": 64, "to": 32, "memory_saved": 2.8},
    {"action": "disable_dora", "memory_saved": 1.5},
    {"action": "reduce_rank", "from": 32, "to": 16, "memory_saved": 1.4}
]
```

### 3.3 Training Pipeline Architecture
```python
class TrinityTrainer:
    def __init__(self):
        self.memory_monitor = GPUMemoryMonitor()
        self.oom_recovery = OOMRecoverySystem()
        self.metrics_tracker = TrainingMetrics()
    
    def train(self):
        # Pre-training validation
        self.validate_environment()
        
        # Load model with Trinity configuration
        model = self.load_model_with_trinity()
        
        # Execute training with monitoring
        for epoch in range(max_epochs):
            self.train_epoch(model)
            self.validate_checkpoint()
            self.save_checkpoint()
```

---

## 4. Phase 2: Ghost Architect (Vision Training)

### 4.1 Two Training Paths

Ghost Architect offers two vision training paths depending on available hardware:

| | **Modal A10G** (`src/modal_train.py`) | **Colab T4** (`src/train_vision.py`) |
|---|---|---|
| **Trinity** | Full: QLoRA + DoRA + rsLoRA | QLoRA + rsLoRA only (no DoRA) |
| **Vision layers** | `finetune_vision_layers=True` | `finetune_vision_layers=False` |
| **Epochs / Context** | 3 epochs, 4096 ctx | 1 epoch, 2048 ctx |
| **Cost** | ~$1.65 (from free $30 credits) | Free |

> **DoRA bug:** PEFT's `dora.py` passes fp16 `x_eye` to fp32 `lora_A` without casting. Unsloth's Gemma3 temporary fp16 patch triggers this on T4. `modal_train.py` includes an inline monkey-patch; `train_vision.py` disables DoRA.

### 4.2 Vision Dataset Format
```python
# No top-level "images" column. Image paths embedded in messages:
{
    "messages": [
        {"role": "user", "content": [
            {"type": "image", "image": "data/ui_screenshots/example.png", "text": ""},
            {"type": "text", "text": "Analyze this UI and generate the database schema."}
        ]},
        {"role": "assistant", "content": "CREATE TABLE users (...)"}
    ]
}
# This avoids TRL's _is_vision_dataset check.
# UnslothVisionDataCollator falls back to process_vision_info() → fetch_image() → Image.open(path).
```

### 4.3 Synthetic Dataset Generation
```python
# File: src/synthetic_generator.py
# Uses Gemini API (google-generativeai) to auto-generate SQL annotations from screenshots.
# Called by scripts/build_vision_dataset.py to produce data/dataset_vision.json (287 examples).
```

---

## 5. Data Architecture

### 5.1 Training Data Structure
```python
# Phase 1: Text Fine-tuning Data (data/dataset.json)
text_training_format = [
    {
        "instruction": "Clear task instruction",
        "input": "Optional context",
        "output": "Expected response"
    }
]

# Phase 2: Vision Training Data (data/dataset_vision.json)
# 287 examples. Image paths embedded in messages (no top-level "images" column):
vision_training_format = {
    "messages": [
        {"role": "user", "content": [
            {"type": "image", "image": "data/ui_screenshots/example.png", "text": ""},
            {"type": "text", "text": "Analyze this UI and generate the database schema."}
        ]},
        {"role": "assistant", "content": "CREATE TABLE users (...)"}
    ]
}
```

### 5.2 Quality Metrics & Validation
```bash
# Validate Phase 1 dataset:
make dataset-check   # runs scripts/validate_dataset.py

# Validate/rebuild Phase 2 dataset:
python scripts/build_vision_dataset.py
```

---

## 6. Infrastructure & Deployment

### 6.1 Development Environment
```yaml
# Development Stack
development:
  platforms:
    - "Google Colab (T4 GPU, 16GB VRAM) — free"
    - "Modal (A10G GPU, 24GB VRAM) — ~$1.65 per run"
  python: "3.11+"
  cuda: "12.1+"
  
# Core Dependencies
core_dependencies:
  - unsloth==2026.1.4
  - transformers>=4.38.0
  - torch>=2.1.0
  - peft>=0.7.0
  - trl>=0.18.2,<=0.24.0,!=0.19.0
  - bitsandbytes>=0.41.0
  - accelerate>=0.25.0
  - google-generativeai          # Gemini API for synthetic SQL generation
  - streamlit                    # Interactive demo app
  # xformers is optional; do not force-install on Colab T4 if no wheel is available.
```

### 6.2 Deployment Model

The project deploys locally, not as a web API:

1. **Export to GGUF**: `python src/export.py` → `output/gguf/`
2. **Run with Ollama**: `ollama create ghost-architect -f Modelfile && ollama run ghost-architect`
3. **Interactive demo**: `streamlit run src/app.py` (upload screenshot → see schema)
4. **CLI testing**: `python src/inference.py` (rich terminal output)

> There is no FastAPI/uvicorn server. The `docker/` directory is reserved for future containerized deployment.

---

## 7. Performance Targets

```python
performance_targets = {
    "training": {
        "memory_usage": "<16GB on T4 GPU, <24GB on A10G",
        "training_speed": ">100 tokens/second",
        "convergence": "loss < 0.5 by end of training"
    },
    "inference": {
        "gguf_latency": "<5 seconds per request via Ollama",
        "accuracy": ">90% valid SQL schemas",
        "model_size": "<8GB GGUF file"
    }
}
```

---

## 8. Security

See `SECURITY.md` for full security practices. Key points:
- No hardcoded secrets; API keys loaded via environment variables
- `.env` protected in `.gitignore`
- Input validation in all scripts

---

This architecture covers the Ghost Architect system from text fine-tuning through vision training and local GGUF deployment.

---

## 7. Deployment Architecture (Current)

### Streamlit Web Application

**File:** `src/app.py` (production app)

**Architecture:**
```
User Browser
     ↓
Streamlit Web Server (port 8501)
     ├─ File Upload Handler
     ├─ Image Preprocessing
     ├─ Model Inference Pipeline
     ├─ Schema Consolidation
     └─ Visualization Engine
          ├─ Mermaid ER Diagram Generator
          ├─ PostgreSQL SQL Generator
          └─ HTML Rendering
```

**Key Features:**
1. **Multi-Image Upload** — Handle 3-6 related screenshots
2. **Per-Image Analysis** — Individual inference for each image
3. **Schema Consolidation** — Merge schemas using LLM-based conflict resolution
4. **Mermaid Visualization** — Beautiful ER diagrams with soft blue theme
5. **PostgreSQL Export** — Copy-paste ready SQL code

**Model Loading:**
```python
# Default adapter path (configurable in sidebar)
adapter_path = "output/adapters/trinity_kaggle"

# Auto-loads from HF Hub if needed
model = AutoPeftModelForCausalLM.from_pretrained(adapter_path)
processor = AutoProcessor.from_pretrained(adapter_path)
```

### Mermaid ER Visualization

**File:** `src/app.py` function `build_mermaid_html()`

**Features:**
- Self-contained HTML (no external CDN required)
- Card-based table rendering (32px shell padding, 48x56 grid gaps)
- Collision-aware relationship labels
- Soft blue color scheme (#f8fafc, #eef2ff, #2563eb)
- Collapsible sections for source and SQL statements
- Interactive zoom/pan (Mermaid-native)

**Example Output:**
```mermaid
erDiagram
    CUSTOMERS ||--o{ ORDERS : places
    ORDERS ||--o{ ORDER_ITEMS : contains
    CUSTOMERS {
        int id PK
        string email UK
        string name
        timestamp created_at
    }
    ORDERS {
        int id PK
        int customer_id FK
        decimal total_amount
        string status
        timestamp created_at
    }
    ORDER_ITEMS {
        int id PK
        int order_id FK
        int product_id FK
        int quantity
        decimal unit_price
    }
```

### Deployment Paths

**Current (Production):**
```
Streamlit + Adapter Weights
├─ No GGUF export needed
├─ Direct inference from LoRA adapter
├─ Model loaded on-demand (stays resident)
└─ Best for: Local/demo deployment
```

**Future (Optional):**
```
GGUF + Ollama (if needed)
├─ Export: python src/export.py
├─ Ollama integration: ollama create ghost-architect
└─ Best for: Offline inference, model sharing
```

---

## 8. Data Flow: UI Screenshot to PostgreSQL Schema

### Complete Inference Pipeline

```
1. User uploads 3-6 UI screenshots
   ├─ Validate file format (PNG, JPG)
   ├─ Check file size (<10MB per image)
   └─ Store in temporary cache

2. For each image:
   ├─ Preprocess
   │  ├─ Resize to standard dimensions
   │  ├─ Normalize pixel values
   │  └─ Apply vision processor transforms
   │
   ├─ Vision Encoding
   │  ├─ Pass through Gemma-3 vision encoder
   │  ├─ Extract visual features
   │  └─ Generate embedding (high-dim vector)
   │
   ├─ LLM Generation
   │  ├─ Combine embedding + prompt
   │  ├─ Pass through attention layers
   │  ├─ Generate SQL tokens auto-regressively
   │  └─ Decode to complete SQL statement
   │
   └─ Schema Extraction
      ├─ Parse CREATE TABLE statements
      ├─ Extract columns, types, constraints
      ├─ Identify foreign keys and relationships
      └─ Store in intermediate schema

3. Multi-Image Consolidation
   ├─ Collect all per-image schemas
   ├─ Detect conflicts/overlaps
   ├─ Use LLM to resolve contradictions
   ├─ Merge relationships across images
   └─ Output: Unified consolidated schema

4. Visualization
   ├─ Generate Mermaid ER diagram
   ├─ Generate PostgreSQL code
   ├─ Generate HTML with embedded CSS/JS
   └─ Render in browser

5. User Output
   ├─ Beautiful ER diagram (interactive)
   ├─ Copy-paste ready SQL
   ├─ Collapsible source views
   └─ Option to download/share
```

### Performance Characteristics

| Stage | Time | Memory | GPU |
|-------|------|--------|-----|
| Model loading (first run) | 60-90s | 8-10 GB | Yes |
| Per-image inference | 5-15s | 8-10 GB | Yes |
| Multi-image consolidation | 10-30s | 2-4 GB | Optional |
| Visualization generation | <1s | <500 MB | No |
| Total (3 images) | ~30-60s | 8-10 GB | Yes |

---

## 9. Production Readiness

- [x] Model trained on Kaggle RTX Pro 6000
- [x] Inference pipeline implemented and tested
- [x] Streamlit app deployed and functional
- [x] Mermaid visualization integrated
- [x] PostgreSQL code generation working
- [x] Multi-image consolidation implemented
- [x] Error handling and validation in place
- [x] Documentation complete
- [ ] Docker containerization (future)
- [ ] Cloud deployment (future)
- [ ] API layer (out of scope)
