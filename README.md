# Ghost Architect

Upload UI screenshots → production-ready PostgreSQL schema + Mermaid ER diagram. Zero GPU, zero setup.

[Live Demo →](https://ghost-architect.streamlit.app)

## What it does

Upload 3–6 screenshots of any web application. Ghost Architect analyzes all screens together and generates:

- A complete PostgreSQL schema with UUID PKs, FK constraints, and indexes
- A Mermaid ER diagram rendered as interactive HTML
- Plain-English explanation of design decisions
- Download as `.sql`, `.mermaid`, or full Markdown report

## Architecture

```
User Browser → Streamlit App → Gemini API (8-model fallback chain)
```

The app is fully API-driven. No GPU, no local model. Each output is validated for proper format markers before being displayed.

## Run locally

```bash
git clone https://github.com/HarshilMaks/ghost_architect_gemma3
cd ghost_architect_gemma3
pip install -r requirements.txt

# Add your Gemini API key (free at aistudio.google.com)
mkdir -p .streamlit
echo 'GEMINI_API_KEY = "your_key"' > .streamlit/secrets.toml

streamlit run src/app.py
```

## Files

| File | Purpose |
|------|---------|
| `src/app.py` | Streamlit app — Gemini API integration, prompt, format validation |
| `scripts/test_inference.py` | Gemini API smoke test (text + vision) |
| `final_adapter/` | Fine-tuned Gemma-3-12B LoRA adapter (research artifact, requires GPU) |
| `docs/` | Architecture docs and deployment guides |

## Training

The fine-tuned adapter (`final_adapter/`) was trained on 5,287 UI→SQL examples (287 real screenshots + 5,000 synthetic) using QLoRA + DoRA + rsLoRA on Gemma-3-12B-IT. This is a separate ML research artifact — the live app uses Gemini API.

## License

MIT
