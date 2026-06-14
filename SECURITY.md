# Security Guide: API Key Management

**Never commit API keys to GitHub.** The project uses the Google Gemini API.

## Setup

### 1. Copy the Template
```bash
cp .env.example .env
```

### 2. Add Your API Key
Edit `.env`:
```
GEMINI_API_KEY=your_actual_gemini_api_key_here
```

### 3. Get a Gemini API Key
1. Go to https://aistudio.google.com/app/apikey
2. Click "Create API Key"
3. Free tier: 60 requests/minute, unlimited per day

### 4. Verify
```bash
streamlit run src/app.py
```

## Security Best Practices

**Do:**
- Use `.env` or `.streamlit/secrets.toml` for credentials
- Rotate API keys regularly
- Monitor API usage in Google AI Studio

**Don't:**
- Hardcode API keys in Python files
- Commit `.env` to Git (in `.gitignore`)
- Share API keys in GitHub Issues/Discussions
- Log API keys in error messages

## File Layout

```
ghost-architect/
├── .env                   # YOUR ACTUAL KEYS (NEVER COMMIT)
├── .env.example           # Template (safe to commit)
├── .gitignore             # Already includes .env
└── src/
    └── app.py             # Loads via st.secrets
```

## GitHub History Warning

This repo's git history contains a `copilot-session-*.md` file with exposed API keys from the research phase. Those keys have been rotated. To fully purge sensitive files from git history, use `git filter-branch` or `bfg`:
```bash
java -jar bfg.jar --delete-files copilot-session-*.md
git reflog expire --expire=now --all && git gc --prune=now --aggressive
git push --force
```

## Questions?

See `.env.example` for template, `src/app.py` for secure API loading via `st.secrets`.
