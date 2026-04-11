# Ghost Architect: Quick Start Guide

Get the Streamlit app running and generate database schemas from UI screenshots in 5 minutes.

---

## Prerequisites

- Python 3.10+
- Dependencies installed: `uv pip install -r requirements.txt`
- Pre-trained model: `output/adapters/trinity_kaggle/` (included in repo)

---

## Run the App

```bash
cd /home/harshil/ghost_architect_gemma3
uv run python -m streamlit run src/app.py
```

**Expected output:**
```
You can now view your Streamlit app in your browser.
Local URL: http://localhost:8501
```

The browser should open automatically. If not, visit: **http://localhost:8501**

---

## Using the App

### Step 1: Upload Screenshots

Click **"Upload UI Evidence Pack"** and select 3-6 PNG/JPG images from the same web app.

**Examples:**
- Dashboard view
- List/table view
- Create/edit form
- Detail page
- Settings panel

### Step 2: Generate Schema

Click **"🚀 Generate Precise Architecture"** and wait 30-60 seconds while the model processes your images.

Progress updates appear in real-time:
- ⏳ Loading model...
- ⏳ Analyzing image_1.png...
- ⏳ Consolidating schemas...
- ✅ Done!

### Step 3: View Results

Two tabs appear:

**📊 Visual Architecture** (default)
- Beautiful Mermaid ER diagram showing all tables and relationships
- Collapsible sections for Mermaid source and SQL statements
- Interactive rendering

**💻 PostgreSQL Code**
- Copy-paste ready CREATE TABLE statements
- Foreign key constraints
- Index suggestions

---

## Example Workflow

### Scenario: Generate schema for Stripe-like payment app

1. Take screenshots of:
   - Dashboard (shows customers, transactions, balance)
   - New transaction form
   - Customer list view
   - Transaction detail page

2. Upload all 4 images

3. Click generate

4. See schema:
   ```sql
   CREATE TABLE customers (
     id SERIAL PRIMARY KEY,
     name VARCHAR(255),
     email VARCHAR(255) UNIQUE,
     created_at TIMESTAMP DEFAULT NOW()
   );

   CREATE TABLE transactions (
     id SERIAL PRIMARY KEY,
     customer_id INT REFERENCES customers(id),
     amount DECIMAL(10,2),
     status VARCHAR(50),
     created_at TIMESTAMP DEFAULT NOW()
   );
   ```

---

## Troubleshooting

### "Streamlit not found"
Make sure you're using `uv run`:
```bash
uv run python -m streamlit run src/app.py
```

### App takes too long to start
First run loads the model (~1.2GB). Wait 60+ seconds on first load. Subsequent requests are faster.

### Model inference fails
- Check that `output/adapters/trinity_kaggle/adapter_model.safetensors` exists
- Ensure you have enough RAM (16GB minimum recommended)
- Try uploading fewer, clearer images

### "Connection refused" on localhost:8501
- Streamlit server crashed. Check terminal output
- Try restarting: Press Ctrl+C, then run the command again

---

## Next Steps

- **Deploy to cloud**: See `docs/DEPLOYMENT_GUIDE.md`
- **Understand the model**: See `docs/MODEL_TRAINING_SUMMARY.md`
- **Learn Trinity architecture**: See `docs/learning-guide.md`
- **Extend the system**: See `docs/architecture.md`

---

## Tips for Best Results

✅ **DO:**
- Use 3-6 related screenshots (same app/domain)
- Include different types of pages (forms, lists, details)
- Use clear, well-designed UI mockups
- Include navigation elements if present

❌ **DON'T:**
- Mix screenshots from completely different apps
- Use blurry or low-resolution images
- Upload more than 10 images at once
- Mix mobile and desktop screenshots

---

**Questions?** Check `README.md` or the full documentation in `docs/`.
