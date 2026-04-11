# Ghost Architect: Gemma-3-12B Fine-Tuning Project

## Overview
This is a multimodal Gemma-3 fine-tuning project that converts UI screenshots into PostgreSQL database schemas.

- **Phase 1 (Foundation):** Trinity text fine-tuning on Colab T4 using **QLoRA + rsLoRA + DoRA**.
- **Phase 2 (Vision):** Multimodal UI-to-SQL training on 287 screenshot–schema pairs, with two training paths (Modal A10G and Colab T4).

The pipeline goes: **train → test → export GGUF + Modelfile → run with Ollama**, plus a Streamlit app (`src/app.py`) for interactive demos.

## Trinity Architecture

The training stack combines three methods for optimal fine-tuning on consumer GPUs:

1. **QLoRA (4-bit NF4 quantization)** — Compresses model weights so Gemma-3-12B fits on 16GB GPU.
2. **rsLoRA (rank-stabilized scaling)** — Stabilizes high-rank adaptation and enables rank 64.
3. **DoRA (weight decomposition)** — Improves update precision by separating magnitude and direction.

### Current Implementation (Kaggle RTX Pro 6000)
The Kaggle-trained model used full Trinity: QLoRA + DoRA + rsLoRA with:
- **Model:** Unsloth-optimized Gemma-3-12B vision
- **Sequence length:** 2048–4096 context
- **LoRA rank:** 64, **alpha:** 32
- **Target modules:** q_proj, k_proj, v_proj, o_proj, gate_proj, up_proj, down_proj
- **Batch size:** 1, **Gradient accumulation:** 4
- **Learning rate:** 2e-4, **Optimizer:** adamw_8bit
- **Training data:** 5,287 UI-SQL pairs
- **GPU:** RTX Pro 6000 (95GB VRAM available)

### Default Config (`configs/training_config.yaml`)
- **Model:** `unsloth/gemma-3-12b-it-bnb-4bit`
- **Sequence length:** `4096`
- **LoRA rank:** `64`, **alpha:** `32`
- **Target modules:** `q_proj, k_proj, v_proj, o_proj, gate_proj, up_proj, down_proj`
- **Batch size:** `1`, **Gradient accumulation:** `4`
- **Learning rate:** `2e-4`, **Optimizer:** `adamw_8bit`
- **Max steps:** `60`

### OOM Recovery Protocol
Apply in order if CUDA OOM occurs:
1. Reduce `max_seq_length`: `4096 → 2048`
2. Reduce LoRA rank: `64 → 32`
3. Disable DoRA: `use_dora: false.`
4. Reduce target modules to `["q_proj", "v_proj"]`

## Quick Start

### 1) Local setup (project/dev workflow)
```bash
uv venv .venv
source .venv/bin/activate
uv pip install -r requirements.txt
```

### 2) Run Streamlit app (current workflow)
```bash
cd /home/harshil/ghost_architect_gemma3
uv run python -m streamlit run src/app.py
# Browser opens at http://localhost:8501
# Upload 3-6 UI screenshots → see Mermaid ER diagram + PostgreSQL code
```

### 3) Interactive demo (CLI)
```bash
python src/inference.py            # CLI testing with rich output
```

### Precision upload guide (Streamlit)
- Upload screenshots from the **same product/web app flow**.
- Use **3-6 images** for best accuracy (minimum 3).
- Include at least:
  - one **list/table** view,
  - one **create/edit form** view,
  - one **detail/dashboard** view.
- The app runs inference per image, then merges evidence into one schema.

## Make Targets
```bash
make venv           # create .venv
make install        # install dependencies with uv
make clean          # remove Python cache files
```

> Note: Training targets (`make train`, `make export`) are reference only. The production model is pre-trained and stored in `output/adapters/trinity_kaggle/`.

## Dataset

### Current Training Data (Phase 2 Vision)
`data/dataset_merged.json` — **5,287 UI-SQL pairs**:
- **287 real** — actual UI screenshots from various web applications
- **5,000 synthetic** — generated via Gemini API for additional diversity

This dataset is **fixed and finalized**. Model has been trained on Kaggle RTX Pro 6000 and is ready for production use.

### Format
Vision training examples use this message format:
```json
{
  "messages": [
    {"role": "user", "content": [
      {"type": "image", "image": "data/ui_screenshots/example.png", "text": ""},
      {"type": "text", "text": "Analyze this UI and generate the database schema."}
    ]},
    {"role": "assistant", "content": "CREATE TABLE products (...)"}
  ]
}
```

### Data Directory
```
data/
├── dataset_merged.json              # 5,287 training examples (finalized)
├── ui_screenshots/                  # 287 real UI screenshots (107MB)
├── synthetic_pairs/                 # (reference, not used in current pipeline)
└── validation_set/                  # (reference, reserved for future)

## Project Tree
```text
ghost_architect_gemma3/
├── configs/
│   └── training_config.yaml        # Phase 1 config (used by Makefile + src/train.py)
├── scripts/
│   ├── build_vision_dataset.py     # Builds dataset_vision.json from screenshots + Gemini
│   ├── download_datasets.py        # Playwright scraper for UI screenshots
│   ├── generate_training_data.py   # Generates Phase 1 starter data
│   ├── validate_dataset.py         # Validates dataset.json (make dataset-check)
│   └── validate_environment.py     # Validates GPU/deps (make validate)
├── src/
│   ├── __init__.py
│   ├── modal_train.py              # Modal A10G training (full Trinity)
│   ├── train_vision.py             # Colab T4 vision training (QLoRA+rsLoRA)
│   ├── train.py                    # Phase 1 text training
│   ├── inference.py                # CLI testing with rich terminal output
│   ├── app.py                      # Streamlit app (multi-image evidence → consolidated schema)
│   ├── export.py                   # GGUF export for Ollama
│   └── synthetic_generator.py      # Gemini API for SQL generation from screenshots
├── data/
│   ├── dataset.json                # Phase 1 training data
│   ├── dataset_vision.json         # 287 vision training examples
│   ├── ui_screenshots/             # 287 PNGs
│   ├── raw_csvs/                   # Source CSVs for scraper
│   ├── synthetic_pairs/            # (empty, for future use)
│   └── validation_set/             # (empty, for future use)
├── tests/
│   └── __init__.py                 # Test package (no tests yet)
├── notebooks/
│   └── main.ipynb                  # Colab T4 notebook
├── docs/                           # Documentation
├── docker/                         # Docker setup (future)
├── output/                         # Generated adapters + GGUF (gitignored)
├── Makefile
├── requirements.txt
├── README.md
├── DATASET_README.md
├── SECURITY.md
└── LICENSE
```

## Documentation Map
- `docs/QUICKSTART.md` — Get up and running in 5 minutes
- `docs/DEPLOYMENT_GUIDE.md` — Current production setup and model loading
- `docs/MODEL_TRAINING_SUMMARY.md` — What actually trained (Kaggle path, not Modal)
- `docs/plan.md` — Original implementation plan vs actual execution
- `docs/learning-guide.md` — Deep dive into Trinity architecture and fine-tuning theory
- `docs/architecture.md` — Complete system architecture and design
- `docs/prd.md` — Product boundaries and requirements
- `docs/ai_rules.md` — Development quality guardrails

## Current Status
- **Phase 1** (text fine-tuning): Skipped. Project proceeded directly to multimodal vision training.
- **Phase 2** (vision training): **Complete**. Model trained on Kaggle RTX Pro 6000 with 5,287 UI-SQL pairs (287 real + 5,000 synthetic). Trained adapter exported to `output/adapters/trinity_kaggle/`.
- **Phase 3** (deployment): **Complete**. Streamlit app (`src/app.py`) running with beautiful Mermaid ER visualization. Model loads directly from adapter weights (no GGUF export required).
- **Production ready**: Upload UI screenshots → consolidated schema generation → Mermaid diagram + PostgreSQL code.

## License
MIT (see `LICENSE.md`).
