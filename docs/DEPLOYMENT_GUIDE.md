# Deployment Guide: Ghost Architect

## Architecture

```
User Browser → Streamlit Cloud → Gemini API (8-model fallback chain)
```

No GPU, no local model, no Docker. Entirely API-driven.

## Deploy to Streamlit Cloud

1. Push repo to GitHub
2. Go to https://streamlit.io/cloud
3. Connect repo, set main file to `src/app.py`
4. Add `GEMINI_API_KEY` to Streamlit Cloud Secrets
5. Deploy

## Local Setup

```bash
pip install -r requirements.txt
```

Create `.streamlit/secrets.toml`:
```toml
GEMINI_API_KEY="your-key-here"
```

Run:
```bash
streamlit run src/app.py
```

## Model Fallback Chain

The app tries models in order until one returns valid output:

`gemini-3.5-flash` → `gemini-3.1-flash-lite` → `gemini-3-flash-preview` → `gemini-2.5-flash` → `gemini-2.5-flash-lite` → `gemini-2.5-flash-image` → `gemini-2.0-flash` → `gemini-flash-latest`

Each output is validated for `=== SQL ===` and `=== MERMAID ===` markers.

## Rate Limits

- 3 analyses per session (free tier protection)
- User can provide their own API key in sidebar as fallback
