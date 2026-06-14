# Ghost Architect: Quick Start

Run the Streamlit app and generate database schemas from UI screenshots.

## Setup

```bash
uv venv .venv
source .venv/bin/activate
uv pip install -r requirements.txt
```

Add your Gemini API key to `.streamlit/secrets.toml`:
```toml
GEMINI_API_KEY="your-key-here"
```

## Run

```bash
make app
```

Opens at `http://localhost:8501`.

## Usage

1. Upload 3-6 PNG/JPG screenshots from the same web app
2. Click **Generate Schema**
3. View ER diagram + SQL in the output tabs

## Requirements

- Python 3.10+
- Gemini API key (free at https://aistudio.google.com)
- No GPU needed
