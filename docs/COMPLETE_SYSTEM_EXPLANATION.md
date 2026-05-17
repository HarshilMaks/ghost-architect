╔════════════════════════════════════════════════════════════════════════════╗
║         GHOST ARCHITECT: COMPLETE END-TO-END SYSTEM EXPLANATION           ║
║                   User → Backend → Model → Database                       ║
╚════════════════════════════════════════════════════════════════════════════╝

═══════════════════════════════════════════════════════════════════════════════
PART 1: THE COMPLETE USER FLOW (What happens when someone uses the app)
═══════════════════════════════════════════════════════════════════════════════

STEP 1: USER OPENS STREAMLIT APP
─────────────────────────────────

File: src/app.py (670 lines)

What happens:
1. User runs:uv run python -m streamlit run src/app.py
2. Streamlit starts web server on port 8501
3. Browser opens: http://localhost:8501
4. App loads and shows:
   - Title: "👻 Ghost Architect"
   - Subtitle: "Fine-tuned Gemma-3-12B · Multi-image UI Evidence → PostgreSQL Schema"
   - Sidebar with options
   - Upload button: "Upload UI Evidence Pack"

Files involved so far:
├─ src/app.py — Main Streamlit application (defines UI, workflows)
└─ .venv/lib/...streamlit/ — Streamlit framework (web server)

═══════════════════════════════════════════════════════════════════════════════

STEP 2: USER UPLOADS SCREENSHOTS (3-6 images)
───────────────────────────────────────────────

User Action: Clicks upload button, selects PNG/JPG images

What happens in src/app.py (lines 200-250):

```python
# Streamlit file uploader
uploaded_files = st.file_uploader(
    "Upload UI Evidence Pack",
    type=["png", "jpg", "jpeg"],
    accept_multiple_files=True
)

if uploaded_files:
    # Validation
    for file in uploaded_files:
        if file.size > 10_000_000:  # 10MB limit
            raise error
        
        # Load image
        image = Image.open(file)  # Pillow library
        st.image(image)  # Show in UI
        
        # Store in cache
        st.session_state.uploaded_images = uploaded_files
```

Files involved:
├─ src/app.py — File handling (st.file_uploader)
├─ Pillow (PIL) — Image processing library
├─ Streamlit — File upload widget
└─ Browser — Sends files via HTTP multipart/form-data

Data at this point:
- uploaded_images: List of PIL Image objects in memory
- Each image: ~300-500 KB

═══════════════════════════════════════════════════════════════════════════════

STEP 3: USER CLICKS "GENERATE PRECISE ARCHITECTURE"
──────────────────────────────────────────────────

User Action: Clicks button "🚀 Generate Precise Architecture"

What happens in src/app.py (lines 300-400):

```python
if st.button("🚀 Generate Precise Architecture"):
    
    # 1. LOAD THE MODEL (first time only, then cached)
    with st.spinner("Loading model..."):
        model = load_model()  # Load from output/adapters/trinity_kaggle/
        processor = load_processor()
    
    # 2. FOR EACH IMAGE, RUN INFERENCE
    all_schemas = []
    
    for idx, image in enumerate(uploaded_files):
        with st.spinner(f"Analyzing image {idx+1}/{len(uploaded_files)}..."):
            
            # Preprocess image
            processed = processor(
                images=image,
                return_tensors="pt"
            )
            
            # Run model inference
            with torch.no_grad():
                outputs = model.generate(
                    **processed,
                    max_length=1024,
                    temperature=0.7
                )
            
            # Decode to SQL
            sql = tokenizer.decode(outputs[0])
            all_schemas.append(sql)
    
    # 3. CONSOLIDATE SCHEMAS
    consolidated = consolidate_schemas(all_schemas)
    
    # 4. GENERATE MERMAID + SQL
    mermaid_html = build_mermaid_html(consolidated)
    sql_code = build_sql_code(consolidated)
    
    # 5. DISPLAY RESULTS
    st.success("✅ Architecture generated!")
    st.components.v1.html(mermaid_html, height=900)
    st.code(sql_code, language="sql")
```

Files involved:
├─ src/app.py — Main orchestration logic
├─ output/adapters/trinity_kaggle/ — MODEL WEIGHTS (1.2 GB)
│  ├─ adapter_model.safetensors (1.2 GB) ← THE ACTUAL MODEL
│  ├─ adapter_config.json
│  ├─ tokenizer.json
│  └─ processor_config.json
├─ peft — Loads LoRA adapter weights
├─ transformers — Loads base model, handles inference
├─ torch — GPU computation
└─ Streamlit — UI display

═══════════════════════════════════════════════════════════════════════════════
PART 2: DEEP DIVE - WHAT HAPPENS INSIDE MODEL INFERENCE
═══════════════════════════════════════════════════════════════════════════════

THE MODEL: Gemma-3-12B with LoRA Fine-Tuning
──────────────────────────────────────────

What is it?
- Base model: Gemma-3-12B (12 billion parameters)
- Quantization: 4-bit (QLoRA) — compressed to 1/4 size
- Fine-tuning: LoRA adapter weights added on top
- Total size: 1.2 GB (adapter) + base model auto-downloaded

How does inference work?

Step 1: Image Processing (Preprocessing)
───────────────────────────────────────

File: vision_processor (part of model config)

Input: PIL Image (1280x720 pixels, RGB)
              ↓
   Resize to model input size (e.g., 448x448)
              ↓
   Normalize pixel values (subtract mean, divide by std)
              ↓
   Convert to tensor format
              ↓
Output: Tensor (1, 3, 448, 448) in GPU memory

Code in src/app.py (lines ~350):
```python
from PIL import Image
import torch

image = Image.open("ui_screenshot.png")

# processor comes from: AutoProcessor.from_pretrained("output/adapters/...")
processed = processor(
    images=image,
    text="Analyze this UI and generate the database schema.",
    return_tensors="pt"  # PyTorch tensors
)

# Returns: {
#   'pixel_values': tensor(...),
#   'input_ids': tensor(...),
#   'attention_mask': tensor(...)
# }
```

Step 2: Vision Encoding (Image Understanding)
──────────────────────────────────────────────

What happens:
1. Image tensor (1, 3, 448, 448) enters Gemma-3 vision encoder
2. Vision encoder has ~2 billion parameters that process images
3. Extracts visual features: shapes, colors, text, layout patterns
4. Outputs "image embeddings" (high-dimensional vectors)

Conceptually:
UI Screenshot (pixels)
        ↓
Vision Encoder (sees: buttons, forms, tables, text)
        ↓
Image Embeddings (e.g., shape like: [1, 1024, 4096])
        ↓
"This looks like a customer form with name field, email field, submit button"
(as high-dimensional vectors, not words)

Step 3: Language Model (Text Generation)
────────────────────────────────────────

File: Gemma-3-12B LLM + LoRA Adapter

What happens:
1. Image embeddings + text prompt combined
2. Passed through 40 transformer layers
3. Each layer refines understanding
4. LoRA adapter weights guide it toward SQL generation
5. Generates SQL tokens auto-regressively

Code conceptually:
```python
# Combine image + text
combined_input = combine(image_embeddings, text_prompt)

# Pass through 40 layers of transformers
for layer in range(40):
    output = transformer_layer(combined_input, lora_weights)
    combined_input = output

# Generate SQL tokens one by one
sql_tokens = []
for step in range(max_tokens):
    next_token = model.generate_one_token(combined_input)
    sql_tokens.append(next_token)
    combined_input = update_with_new_token(next_token)

# Decode tokens back to text
sql_code = tokenizer.decode(sql_tokens)
# Result: "CREATE TABLE customers (id INT PRIMARY KEY, ...)"
```

Step 4: Output (SQL Generation)
───────────────────────────────

Model outputs:
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id),
    total_amount DECIMAL(10, 2),
    status VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW()
);
```

Files used:
├─ src/app.py — Calls model.generate()
├─ output/adapters/trinity_kaggle/adapter_model.safetensors — LoRA weights
├─ Unsloth optimizations — Speed up inference
├─ torch — GPU operations
└─ transformers library — Model implementation

═══════════════════════════════════════════════════════════════════════════════
PART 3: MULTI-IMAGE CONSOLIDATION
═══════════════════════════════════════════════════════════════════════════════

What if user uploads 3 images?

Step 1: Get SQL from each image
───────────────────────────────

Image 1 (Customer list): 
  → Model outputs: CREATE TABLE customers, CREATE TABLE transactions

Image 2 (Create order form):
  → Model outputs: CREATE TABLE orders, CREATE TABLE items

Image 3 (Dashboard):
  → Model outputs: CREATE TABLE reports, ALTER TABLE customers ADD...

Now we have 3 different schemas with overlaps and conflicts.

Step 2: Consolidate (Merge schemas)
────────────────────────────────────

File: src/app.py, function: split_consolidated_output() (lines 400-450)

```python
def split_consolidated_output(text):
    """Extract and parse CREATE TABLE statements from model output"""
    
    # Parse each SQL statement
    tables = []
    relationships = []
    
    for statement in text.split("CREATE TABLE"):
        # Extract table name, columns, constraints
        # Build: {table_name, columns: [...], relationships: [...]}
    
    return tables, relationships


def consolidate_schemas(all_schemas):
    """Merge multiple schemas into one unified schema"""
    
    # 1. Extract tables from each schema
    all_tables = []
    for schema in all_schemas:
        tables, rels = split_consolidated_output(schema)
        all_tables.extend(tables)
    
    # 2. Deduplicate tables (same table in multiple images = 1 table)
    unique_tables = {}
    for table in all_tables:
        if table.name not in unique_tables:
            unique_tables[table.name] = table
        else:
            # Merge column definitions
            merge_columns(unique_tables[table.name], table)
    
    # 3. Merge relationships
    final_schema = build_unified_schema(unique_tables.values())
    
    return final_schema
```

Step 3: Send to LLM for Conflict Resolution
─────────────────────────────────────────────

If there are conflicts (e.g., "email VARCHAR(100)" vs "email VARCHAR(255)"):

```python
def resolve_conflicts_with_llm(conflicting_columns):
    """Use Gemini API to resolve schema conflicts"""
    
    prompt = f"""
    We have multiple UI screenshots showing the same application.
    Different images generated different column definitions:
    
    Column 'email' defined as:
    - VARCHAR(100) in image 1
    - VARCHAR(255) in image 2
    
    Which is more likely correct?
    """
    
    response = genai.GenerativeAI().generate(prompt)
    # Response: "VARCHAR(255) is safer for email addresses"
    
    return use_largest_or_safest_definition()
```

File: src/app.py uses google.generativeai library

Step 4: Final Consolidated Schema
──────────────────────────────────

Result:
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255),
    email VARCHAR(255) UNIQUE,
    created_at TIMESTAMP
);

CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id),
    total_amount DECIMAL(10,2),
    status VARCHAR(50)
);

CREATE TABLE items (
    id SERIAL PRIMARY KEY,
    order_id INT REFERENCES orders(id),
    product_id INT,
    quantity INT
);
```

═══════════════════════════════════════════════════════════════════════════════
PART 4: VISUALIZATION (BEAUTIFUL MERMAID ER DIAGRAM)
═══════════════════════════════════════════════════════════════════════════════

File: src/app.py, function: build_mermaid_html() (lines 244-430)

Step 1: Parse consolidated schema into structured format
─────────────────────────────────────────────────────────

consolidated_sql = """
CREATE TABLE users (id INT PRIMARY KEY, email VARCHAR);
CREATE TABLE orders (id INT PRIMARY KEY, user_id INT REFERENCES users(id));
"""

Parsed into:
schema_dict = {
    'users': {
        'columns': [
            {'name': 'id', 'type': 'INT', 'is_pk': True},
            {'name': 'email', 'type': 'VARCHAR', 'is_pk': False}
        ],
        'pk': 'id'
    },
    'orders': {
        'columns': [
            {'name': 'id', 'type': 'INT', 'is_pk': True},
            {'name': 'user_id', 'type': 'INT', 'is_pk': False}
        ],
        'pk': 'id',
        'fk': [{'column': 'user_id', 'references': ('users', 'id')}]
    }
}

Step 2: Generate Mermaid syntax
────────────────────────────────

Output Mermaid code:

erDiagram
    USERS ||--o{ ORDERS : has
    
    USERS {
        int id PK
        string email
    }
    
    ORDERS {
        int id PK
        int user_id FK
    }

Step 3: Wrap in beautiful HTML with CSS styling
─────────────────────────────────────────────────

File: src/app.py, build_mermaid_html() (300+ lines)

HTML structure:
- DOCTYPE html
- Head: Mermaid CDN, CSS styling
- Body: Container div with diagram
- Script: Initialize Mermaid rendering
- Styling: Blue gradient background, card-based layout, soft colors

Step 4: Display in Streamlit
──────────────────────────────

File: src/app.py (line ~781)

st.components.v1.html(html_preview, height=900, scrolling=True)

═══════════════════════════════════════════════════════════════════════════════
PART 5: FILE STRUCTURE - WHAT GOES WHERE
═══════════════════════════════════════════════════════════════════════════════

Project directory structure:

ghost_architect_gemma3/
├── src/
│   ├── app.py (670 lines) — MAIN FILE
│   │   └─ Lines 1-50: Imports
│   │   └─ Lines 50-100: Config loading
│   │   └─ Lines 100-200: Model loading (cached)
│   │   └─ Lines 200-250: File upload UI
│   │   └─ Lines 300-400: Inference loop
│   │   └─ Lines 400-450: Schema consolidation
│   │   └─ Lines 550-650: Mermaid HTML generation
│   │   └─ Lines 650-670: Display results
│   │
│   ├── inference.py — CLI version (same logic, no Streamlit UI)
│   ├── export.py — Convert model to GGUF format (optional)
│   ├── modal_train.py — Training script (reference only)
│   └── train_vision.py — Training script (reference only)
│
├── output/
│   ├── adapters/
│   │   └── trinity_kaggle/
│   │       ├─ adapter_model.safetensors (1.2 GB) ← THE MODEL
│   │       ├─ adapter_config.json
│   │       ├─ tokenizer.json
│   │       ├─ processor_config.json
│   │       └─ special_tokens_map.json
│   │
│   ├── gguf/
│   │   └─ (empty, for GGUF export if needed)
│   │
│   └── inference/
│       └─ (sample outputs)
│
├── data/
│   ├── dataset_merged.json (5,287 training examples)
│   ├── ui_screenshots/ (287 real UI images)
│   └─ (other data)
│
├── configs/
│   └── training_config.yaml (Trinity parameters)
│
├── requirements.txt
│   ├─ torch>=2.1.0 — GPU computation
│   ├─ transformers>=4.38.0 — Model loading
│   ├─ peft>=0.7.0 — LoRA adapter loading
│   ├─ streamlit>=1.32.0 — Web UI
│   ├─ pillow>=10.0.0 — Image processing
│   ├─ google-generativeai>=0.3.0 — LLM conflict resolution
│   └─ (others)
│
├── README.md
├── LICENSE
└── .gitignore

═══════════════════════════════════════════════════════════════════════════════
PART 6: DATA FLOW DIAGRAM (Complete Journey)
═══════════════════════════════════════════════════════════════════════════════

USER → BROWSER:
   User opens browser, navigates to http://localhost:8501

BROWSER → STREAMLIT SERVER:
   GET / → Streamlit returns HTML/CSS/JS for web interface

USER → FILE UPLOAD:
   User selects 3-6 PNG/JPG files via file picker

BROWSER → STREAMLIT:
   POST /upload (multipart/form-data)
   Data: Binary image files (3-6 × 300-500 KB each)

STREAMLIT → MEMORY:
   Files stored in st.session_state.uploaded_images
   Format: List[PIL.Image objects]

USER → CLICK BUTTON:
   User clicks "🚀 Generate Precise Architecture"

STREAMLIT → DISK:
   Load model weights from: output/adapters/trinity_kaggle/adapter_model.safetensors

DISK → RAM/GPU:
   1.2 GB model weights loaded into GPU memory
   (First load: 60-90 seconds, cached after)

STREAMLIT → MODEL (Loop for each image):
   For Image 1:
     Load PIL Image (1280x720 pixels)
     Vision Processor: Resize → Normalize → Convert to tensor
     GPU: Run through vision encoder
     GPU: Run through 40 transformer layers + LoRA adapter
     Generate SQL tokens auto-regressively
     Output: CREATE TABLE statements
   
   For Image 2, 3: (same process)

SCHEMAS → CONSOLIDATION:
   Parse 3 SQL statements into table structures
   Deduplicate tables (users appears in all 3)
   Merge column definitions
   If conflicts exist:
     Send to Gemini API for resolution
   Output: Single unified schema

UNIFIED SCHEMA → MERMAID HTML:
   Parse CREATE TABLE statements
   Extract tables, columns, relationships
   Generate Mermaid ER syntax
   Wrap in HTML with CSS styling
   Output: Beautiful interactive diagram

MERMAID HTML → BROWSER:
   Streamlit renders HTML in web component
   Browser renders Mermaid diagram using client-side JavaScript

SQL CODE → BROWSER:
   Display in code block with syntax highlighting
   User can copy-paste into PostgreSQL

═══════════════════════════════════════════════════════════════════════════════
PART 7: THE MODEL - HOW IT WAS TRAINED
═══════════════════════════════════════════════════════════════════════════════

Where did adapter_model.safetensors come from?

Training History:
─────────────────

Original plan:
  Phase 1: Train text model on Colab T4 (16GB VRAM) → ❌ Skipped
  Phase 2a: Train vision model on Modal A10G → ❌ Failed (hit credit limit)
  Phase 2b: Train vision model on Kaggle RTX Pro 6000 → ✅ SUCCESS

What actually happened:

Training on Kaggle RTX Pro 6000:
────────────────────────────────

File: ga-gemma3.ipynb (Jupyter notebook, the actual training code)

Step 1: Download base model
```python
from transformers import AutoTokenizer, AutoModelForCausalLM

# Download Gemma-3-12B in 4-bit quantization (7.6 GB)
model = AutoModelForCausalLM.from_pretrained(
    "unsloth/gemma-3-12b-it-bnb-4bit",
    device_map="auto"
)
```

Step 2: Setup LoRA adapter (Trinity stack)
```python
from peft import get_peft_model, LoraConfig

config = LoraConfig(
    r=64,  # Rank (learning capacity)
    lora_alpha=32,  # Scaling
    target_modules=["q_proj", "k_proj", "v_proj", "o_proj", "gate_proj", "up_proj", "down_proj"],
    use_dora=True,  # DoRA: Magnitude + Direction separation
    use_rsLora=True,  # rsLoRA: Rank stabilization
    task_type="CAUSAL_LM"
)

model = get_peft_model(model, config)
```

Step 3: Load training data
```python
import json

with open("data/dataset_merged.json", "r") as f:
    dataset = json.load(f)

# 5,287 examples:
# - 287 real UI screenshots + SQL schemas
# - 5,000 synthetic UI-SQL pairs (generated by Gemini API)

# Format:
# {
#   "messages": [
#     {"role": "user", "content": [...image..., ...text...]},
#     {"role": "assistant", "content": "CREATE TABLE ..."}
#   ]
# }
```

Step 4: Training loop
```python
from transformers import TrainingArguments, SFTTrainer

args = TrainingArguments(
    output_dir="output/adapters",
    num_train_epochs=1,
    max_steps=60,
    per_device_train_batch_size=1,
    gradient_accumulation_steps=4,
    learning_rate=2e-4,
    optimizer="adamw_8bit",  # Memory efficient
    warmup_steps=10,
    fp16=True,  # Mixed precision
    save_strategy="steps",
    save_steps=10,
)

trainer = SFTTrainer(
    model=model,
    args=args,
    train_dataset=dataset,
    tokenizer=tokenizer,
)

trainer.train()  # Training happens here (4-6 hours on RTX Pro 6000)
```

Step 5: Save adapter weights
```python
model.save_pretrained("output/adapters/trinity_kaggle")
# Saves:
# - adapter_model.safetensors (1.2 GB)
# - adapter_config.json
# - tokenizer.json
# - etc.
```

═══════════════════════════════════════════════════════════════════════════════
PART 8: DEPENDENCIES - WHAT EVERY LIBRARY DOES
═══════════════════════════════════════════════════════════════════════════════

requirements.txt breakdown:

Core ML Stack:
──────────────

torch>=2.1.0
  PyTorch: GPU computation library
  Used for: Running neural networks on GPU

transformers>=4.38.0
  Hugging Face: Pre-trained model library
  Used for: Loading Gemma-3-12B model, tokenizer, processor

peft>=0.7.0
  Parameter Efficient Fine-Tuning: LoRA implementation
  Used for: Loading LoRA adapter weights

accelerate>=0.25.0
  Distributed training: Multi-GPU/device handling
  Used for: device_map="auto"

Web Framework:
──────────────

streamlit>=1.32.0
  Web UI framework (no HTML/CSS/JS needed)
  Used for: Creating web interface

Image Processing:
──────────────────

pillow>=10.0.0
  Image library
  Used for: Loading PNG/JPG files

LLM Consolidation:
───────────────────

google-generativeai>=0.3.0
  Google Gemini API client
  Used for: LLM-based conflict resolution

SQL Processing:
────────────────

sqlparse>=0.4.4
  SQL parser and formatter
  Used for: Parsing and validating generated SQL

═══════════════════════════════════════════════════════════════════════════════
PART 9: PERFORMANCE BREAKDOWN
═══════════════════════════════════════════════════════════════════════════════

First load (model downloads and loads):
────────────────────────────────────────

Time: 60-90 seconds

1. Download base model: 30-40 seconds
   - Gemma-3-12B base model (~7 GB)
   - Downloaded once, cached

2. Load adapter weights: 15-20 seconds
   - adapter_model.safetensors (1.2 GB)
   - From: output/adapters/trinity_kaggle/

3. Load tokenizer: 5-10 seconds
   - tokenizer.json (33 MB)

Total GPU memory: ~10-12 GB
Total RAM: ~4-6 GB

Per-image inference:
────────────────────

Time: 5-15 seconds per image

Memory:
- Model weights resident: 10-12 GB
- Image tensor: ~50 MB
- Output tensor: ~200 MB
- Total peak: ~10-12 GB

Multi-image workflow (3 images):
────────────────────────────────

Total time: 30-60 seconds

- Image 1 inference: 10 seconds
- Image 2 inference: 10 seconds
- Image 3 inference: 10 seconds
- Schema consolidation: 5-10 seconds
- Mermaid HTML generation: <1 second
- Display: <1 second

═══════════════════════════════════════════════════════════════════════════════
PART 10: ERROR HANDLING & EDGE CASES
═══════════════════════════════════════════════════════════════════════════════

What can go wrong:

1. User uploads >10MB file
   Caught at: File upload validation
   Error: "File too large (>10MB)"

2. GPU out of memory
   Caught at: torch.no_grad() inference
   Error: "CUDA out of memory"

3. Invalid image format
   Caught at: Image.open(file)
   Error: "Cannot identify image file"

4. Model not found
   Caught at: AutoPeftModelForCausalLM.from_pretrained()
   Error: "Directory not found"

5. SQL parsing fails
   Caught at: split_consolidated_output()
   Error: Invalid CREATE TABLE syntax
   Fix: Fall back to raw SQL output

6. Gemini API quota exceeded
   Caught at: genai.GenerativeAI().generate()
   Error: "Quota exceeded"
   Fix: Use deterministic resolution

═══════════════════════════════════════════════════════════════════════════════
COMPLETE FLOW SUMMARY
═══════════════════════════════════════════════════════════════════════════════

User Action                    →  Internal Process              →  Output
─────────────────────────────────────────────────────────────────────────────

1. Open app                    →  Streamlit server starts      →  Web UI
2. Upload 3-6 images           →  Files stored in memory       →  File list shown
3. Click "Generate"            →  Load model (60s first time)   →  "Loading..." spinner
4. Model processes each image  →  Vision encoder → LLM         →  SQL per image
5. Consolidate schemas         →  Merge & deduplicate         →  Unified schema
6. Generate Mermaid            →  Parse SQL → Diagram syntax   →  ER diagram HTML
7. Display results             →  Render in browser            →  Beautiful visualization

That's the complete system flow from user perspective through all backend processes!

═══════════════════════════════════════════════════════════════════════════════
