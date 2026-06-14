# Ghost Architect

Upload UI screenshots → PostgreSQL schema + Mermaid ER diagram via Gemini API. No GPU needed.

## What it does

Upload 3–6 screenshots of a web application. Ghost Architect analyzes all screens together and generates:

- PostgreSQL schema with UUID PKs, FK constraints, indexes, and enums
- Mermaid ER diagram rendered as interactive HTML
- Design decisions explanation
- Download as `.sql`, `.mermaid`, or Markdown report

## Architecture

```
User Browser → Streamlit App → Gemini API (8-model fallback chain)
```

The app is fully API-driven. Each output is validated for `=== SQL ===` and `=== MERMAID ===` markers before display.

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

## Project history

Ghost Architect started as an ML research project: fine-tuning **Gemma-3-12B-IT** with QLoRA + DoRA + rsLoRA on UI→SQL examples. The trained LoRA adapter is preserved in `final_adapter/` as a research artifact.

The live app uses the **Gemini API** instead — no GPU, instant cold start, deployable on Streamlit Cloud free tier.

### Why GitHub shows large repo size

The git history contains ~210MB from the ML research phase: training datasets, screenshots, tokenizer files, and historical artifacts. These are not used by the current app.

## Files

| File | Purpose |
|---|---|
| `src/app.py` | Streamlit app — Gemini integration, prompt, format validation |
| `final_adapter/` | Trained Gemma-3 LoRA adapter (research artifact, requires GPU) |
| `docs/` | Architecture, deployment, quickstart guides |

## License

MIT — see [LICENSE](LICENSE)
