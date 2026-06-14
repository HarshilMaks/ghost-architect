# Ghost Architect

Upload UI screenshots → production-ready PostgreSQL schema + Mermaid ER diagram. Zero GPU, zero setup.

[Live Demo →](https://ghost-architect.streamlit.app)

## What it does

Upload 3–6 screenshots of any web application. Ghost Architect analyzes all screens together and generates:

- A complete PostgreSQL schema with UUID PKs, FK constraints, indexes, enums, and comments
- A Mermaid ER diagram rendered as interactive HTML
- Plain-English explanation of design decisions
- Download as `.sql`, `.mermaid`, or full Markdown report

## Architecture

```
User Browser → Streamlit App → Gemini API (8-model fallback chain)
```

The app is fully API-driven. No GPU, no local model. Each output is validated for proper `=== SQL ===` and `=== MERMAID ===` format markers before being displayed.

## Run locally

```bash
git clone https://github.com/HarshilMaks/ghost-architect
cd ghost-architect
pip install -r requirements.txt

# Add your Gemini API key (free at aistudio.google.com)
mkdir -p .streamlit
echo 'GEMINI_API_KEY = "your_key"' > .streamlit/secrets.toml

streamlit run src/app.py
```

Or use `make app` (creates venv automatically).

## Project history

### Original vision: fine-tuned Gemma-3-12B

Ghost Architect started as an ML research project: fine-tune **Google Gemma-3-12B-IT** with **QLoRA + DoRA + rsLoRA** on 5,287 UI→SQL examples (287 real screenshots + 5,000 synthetic HTML-generated pairs). The LoRA adapter was trained for ~1.5 hours on a single NVIDIA GPU and achieved 95.4% SQL syntax validity.

**Why we moved to Gemini API:**

| Factor | Local model (Gemma-3) | Gemini API |
|---|---|---|
| GPU required | Yes (24GB+ VRAM) | None |
| RAM at inference | ~8GB | None |
| Deployment | Docker + GPU cloud | Streamlit Cloud free tier |
| Cold start | 2–4 min (model load) | Instant |
| Inference speed | ~6s per query | ~2–3s per query |
| Cost (low volume) | ~$0.50–1/session | Free tier: 60 req/min |
| Quality | Good (fine-tuned) | Better (Gemini 2.5 Flash) |

The trained adapter remains in `final_adapter/` as a research artifact (requires GPU to run). The live app and recommended usage path is the Gemini API.

### What's in the repo

```
src/app.py              # Streamlit app — the main application (830 lines)
final_adapter/           # Fine-tuned Gemma-3 LoRA adapter (research artifact)
docs/                    # Architecture, deployment, and quickstart guides
data/                    # Original training/evaluation datasets (historical)
scripts/                 # Helper scripts for testing and analysis
```

### Why GitHub shows large repo size

The git history contains ~210MB of pack data accumulated during the ML research phase:

- **Large training files**: 32MB CSV dataset (`producthunt.csv`), 2MB merged training JSON, 2MB synthetic dataset
- **Screenshots for training**: ~25 PNG screenshots at 1–2.5MB each (used as training examples)
- **Tokenizers**: 33MB `tokenizer.json` from the fine-tuned adapter
- **Historical artifacts**: 5.9MB `copilot-session-*.md` (deleted from working tree but remains in git history)

These are **historical research artifacts** from the Gemma-3 fine-tuning phase. The current live application (`src/app.py`) does not depend on any of this data — it sends user-uploaded screenshots directly to the Gemini API.

> **Security note**: The `copilot-session-*.md` file in git history contained API keys. Those keys have been rotated. See SECURITY.md for details.

## Model fallback chain

The app tries these Gemini models in order until one returns valid output:

`gemini-3.5-flash` → `gemini-3.1-flash-lite` → `gemini-3-flash-preview` → `gemini-2.5-flash` → `gemini-2.5-flash-lite` → `gemini-2.5-flash-image` → `gemini-2.0-flash` → `gemini-flash-latest`

Each output is validated for `=== SQL ===` and `=== MERMAID ===` markers before being accepted.

## Files

| File | Purpose |
|---|---|
| `src/app.py` | Streamlit app — Gemini API integration, prompt, format validation, results caching |
| `scripts/test_inference.py` | Gemini API smoke test (text + vision) |
| `final_adapter/` | Fine-tuned Gemma-3-12B LoRA adapter (research artifact, requires GPU) |
| `docs/` | Architecture docs and deployment guides |

## Training (research artifact)

The fine-tuned adapter (`final_adapter/`) was trained on 5,287 UI→SQL examples using QLoRA + DoRA + rsLoRA on Gemma-3-12B-IT. Training took ~1.5 hours on a single NVIDIA GPU. The adapter achieves 95.4% SQL syntax validity on held-out test samples.

**This is not used in the live app.** The live app calls the Gemini API. The adapter is preserved as a research artifact and HuggingFace model card.

## License

MIT
