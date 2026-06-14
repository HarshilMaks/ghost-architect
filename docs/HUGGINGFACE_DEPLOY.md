# HuggingFace Deployment

## 1. HF Space (Streamlit App)

Deploy the app on HuggingFace Spaces as an alternative to Streamlit Cloud.

### Steps

1. Go to https://huggingface.co/new-space
2. Set Space name: `ghost-architect`
3. License: MIT
4. SDK: **Streamlit**
5. Space SDK version: `1.40.0` (or latest)
6. Create Space

### Push the code

```bash
# Add HF Space as remote
git remote add hf-space https://huggingface.co/spaces/YOUR_USERNAME/ghost-architect

# Push main branch
git push hf-space main
```

### Set Secrets

In the HF Space settings → Repository Secrets → New secret:
- `GEMINI_API_KEY`: your Gemini API key

The app will auto-detect it via `st.secrets`.

### Space README

HF Spaces read the repo's `README.md` — you can add YAML frontmatter:

```yaml
---
title: Ghost Architect
emoji: 👻
colorFrom: gray
colorTo: blue
sdk: streamlit
sdk_version: 1.40.0
app_file: src/app.py
pinned: false
---
```

(Insert this at the top of `README.md` before pushing to HF Space.)

---

## 2. HF Model (Adapter Card)

The adapter model is at:
https://huggingface.co/harshilmaks/ghost-architect-gemma3-adapter

### Update the model card

The card is at `final_adapter/README.md` in this repo. To update:

```bash
# Install huggingface-hub
uv pip install huggingface-hub

# Upload README to model repo
huggingface-cli upload harshilmaks/ghost-architect-gemma3-adapter final_adapter/README.md README.md

# Or use the Web UI:
# Go to the model page → "Files and versions" → "Add file" → "Upload file"
```

### Upload adapter weights (if not already there)

```bash
huggingface-cli upload harshilmaks/ghost-architect-gemma3-adapter final_adapter/ adapter/
```

This uploads the full adapter directory (1.2GB).
