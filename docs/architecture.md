# Ghost Architect: System Architecture

## Overview

Ghost Architect converts UI screenshots into production-ready PostgreSQL schemas using the Google Gemini API. No local model, no GPU — fully API-driven.

## Architecture

```
┌──────────────┐     ┌──────────────────┐     ┌──────────────┐
│  User Uploads │────▶│   Streamlit App   │────▶│  Gemini API  │
│  3-6 PNG/JPG  │     │   src/app.py      │     │  8-model     │
└──────────────┘     │   827 lines       │     │  fallback     │
                     │   facade UI       │     └──────┬───────┘
                     └──────────────────┘            │
                           │                         │
                           ▼                         ▼
                     ┌────────────────────────────────────┐
                     │        Output Validation           │
                     │  Checks for === SQL === markers    │
                     │  Checks for === MERMAID === markers│
                     └────────────────────────────────────┘
                           │
                           ▼
                     ┌────────────────────────────────────┐
                     │        Schema Output               │
                     │  ├─ Mermaid ER Diagram (interactive)│
                     │  ├─ PostgreSQL DDL (copy-paste)     │
                     │  └─ Design decisions (narrative)    │
                     └────────────────────────────────────┘
```

## Key Components

### Prompt Engineering (`SCHEMA_PROMPT`)
- Microsoft senior architect persona
- Screenshot analysis protocol (list view, form, detail)
- UI-to-data-type mapping rules
- FK/index/constraint generation rules
- Strict `=== MERMAID ===` / `=== SQL ===` / `=== EXPLANATION ===` output format

### Model Fallback Chain
8 models tried in order. Each must produce valid format markers or is rejected.

### Format Validation
`split_consolidated_output()` parses the three sections. Missing markers cause fallback to next model.

### Session State
- `request_count`: 3-per-session limit
- `last_mermaid` / `last_sql` / `last_model`: persist for full-width viewer
- `user_api_key`: optional user-provided key

### UI (streamlit-facade)
- Dark theme (`#0a0a0f` background, `#3B82F6` accent)
- Badge row, expander-based full-width viewer
- Download buttons for SQL, Mermaid, and combined report

## Data Flow

1. User uploads 3-6 screenshots
2. Click generate → images + prompt sent to Gemini API
3. API returns parsed output with three sections
4. App validates format, renders ER diagram + SQL
5. User can view full-size, download, or toggle tabs
