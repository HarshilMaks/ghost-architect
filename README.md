# Ghost Architect

**Upload UI screenshots → Get a production-ready PostgreSQL schema + Mermaid ER diagram.**

[Live Demo →](https://ghost-architect.streamlit.app) | [Fine-tuned Model →](https://huggingface.co/harshilmaks/ghost-architect-gemma3-adapter)

## What it does

Upload 3–6 screenshots of any web application. Ghost Architect analyzes all screens together and generates:
- A complete PostgreSQL schema with UUID PKs, FK constraints, and indexes
- A Mermaid ER diagram rendered as an interactive HTML view
- A plain-English explanation of the design decisions
- Download as `.sql`, `.mermaid`, or a full Markdown report

## Architecture

**Live app:** Gemini 2.5 Flash API (vision) → Streamlit Cloud (free tier)

**ML research artifact:** Fine-tuned Gemma 3 12B with QLoRA + DoRA + rsLoRA (Trinity stack) trained on 5,287 UI→SQL examples (287 real screenshots + 5,000 synthetic). Adapter on [HuggingFace](https://huggingface.co/harshilmaks/ghost-architect-gemma3-adapter). Requires A10G/L4 GPU for inference (not used in live demo).

## Run locally

```bash
git clone https://github.com/HarshilMaks/ghost_architect_gemma3
cd ghost_architect_gemma3
pip install -r requirements.txt

# Add your Gemini API key (free at aistudio.google.com)
echo 'GEMINI_API_KEY = "your_key"' > .streamlit/secrets.toml

streamlit run src/app.py
```

## Training details (Gemma 3 12B adapter)

| Detail | Value |
|---|---|
| Base model | Gemma 3 12B IT (4-bit) |
| Adapter technique | QLoRA + DoRA + rsLoRA |
| LoRA rank | 64 |
| Trainable params | 299M (2.4% of 12.4B) |
| Training platform | Kaggle (RTX Pro 6000, 95GB VRAM) |
| Training examples | 5,287 (287 real + 5,000 synthetic) |
| Dataset | UI screenshots → PostgreSQL DDL |

The fine-tuned adapter is a proof of ML engineering capability. The live demo uses Gemini API for production-quality inference.

## Files

| File | Purpose |
|---|---|
| `src/app.py` | Streamlit UI with Gemini API integration |
| `scripts/test_inference.py` | Gemini API smoke test |
| `output/adapters/trinity_kaggle/` | Fine-tuned LoRA adapter weights |
| `ga-gemma3.ipynb` | Kaggle training notebook |
| `data/dataset_merged.json` | 5,287 UI→SQL training examples |
| `docs/` | Architecture docs and deployment guides |

## License

MIT
