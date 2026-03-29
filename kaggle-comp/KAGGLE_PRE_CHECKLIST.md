# ✅ PRE-KAGGLE CHECKLIST

Complete these steps BEFORE starting Kaggle training.

---

## 1️⃣ DOWNLOAD GEMMA-3 MODEL LOCALLY

```bash
cd /home/harshil/ghost_architect_gemma3
python tmp.py
```

**Expected output**:
```
✅ Model downloaded successfully!
📂 Downloaded files (XXX items):
   - config.json (10.5 KB)
   - model.safetensors (12.4 GB)
   ... (more files)
💾 Total size: 12.52 GB

📦 Creating ZIP file...
✅ ZIP created: gemma3_model.zip (10.23 GB)
```

**Verify**:
- ✅ `output/gemma3_model/` exists
- ✅ `output/gemma3_model.zip` exists (~10 GB)

---

## 2️⃣ UPLOAD GEMMA-3 ZIP TO KAGGLE

1. Go to: https://www.kaggle.com/datasets
2. Click: **"Create new dataset"**
3. Upload: `output/gemma3_model.zip`
4. Fill in:
   - **Name**: `gemma-3-model-offline`
   - **Title**: `Gemma-3-12B-IT Offline Model (Unsloth BNB-4bit)`
   - **Visibility**: Private (so no public browser downloads)
5. **Create** the dataset
6. **Wait** for processing to complete (~5-10 min)

**Verify in Kaggle**:
- ✅ Dataset shows in your datasets list
- ✅ Status shows "Active" (not "Processing")

---

## 3️⃣ VERIFY YOU HAVE OTHER DATASETS

In Kaggle, go to your **Datasets** page. You should see:

1. ✅ `ghost-architect-data` (dataset_merged.json + ui_screenshots)
   - Size: ~300 MB
   - Contains: 5,287 examples + 287 PNGs

2. ✅ `unsloth-offline-wheels` (pre-built Python wheels)
   - Contains: unsloth, trl, xformers, bitsandbytes
   - Already uploaded by you

3. ✅ `gemma-3-model-offline` (just uploaded)
   - Size: ~10-11 GB
   - Contains: model.safetensors + config files

**If any are missing**: Upload them first!

---

## 4️⃣ CREATE KAGGLE NOTEBOOK

1. Go to: https://www.kaggle.com/code
2. Click: **"New Notebook"**
3. Select: **Python** (not R)
4. Select GPU: **P100 / V100 / RTX Pro 6000** (whichever is available)
5. **Select "No Internet"** (this is critical!)

**Important**: If "No Internet" option doesn't exist, Kaggle will auto-disable it after adding datasets.

---

## 5️⃣ ADD DATASETS TO NOTEBOOK

In your new notebook, click **"+ Input"** (or look for "Add Input" button):

Add these datasets:
1. `ghost-architect-data`
2. `unsloth-offline-wheels`
3. `gemma-3-model-offline`

**Verify**:
- ✅ Right panel shows all 3 datasets
- ✅ Internet is disabled: ❌ (should be OFF)

---

## 6️⃣ COPY NOTEBOOK CELLS

Option A: **Copy from file**
```
File: KAGGLE_NOTEBOOK_PRODUCTION.ipynb
```

Option B: **Copy-paste cells one by one**
- Start with CELL 1: Install Dependencies
- Then CELL 2: Unzip Model
- Continue through CELL 13

---

## 7️⃣ GPU VERIFICATION CELL (Before CELL 1)

Add this cell to verify you have RTX Pro 6000:

```python
import torch
print(f"GPU: {torch.cuda.get_device_name(0)}")
print(f"VRAM: {torch.cuda.get_device_properties(0).total_memory / 1024**3:.1f} GB")
print(f"CUDA: {torch.version.cuda}")

# Should output something like:
# GPU: NVIDIA RTX 6000 Ada
# VRAM: 24.0 GB
# CUDA: 12.1
```

**If VRAM < 24 GB**: 
- ❌ Wrong GPU selected
- Restart notebook, select RTX Pro 6000 explicitly

---

## 8️⃣ DRY RUN: TEST CELL 1-5

Before committing to training:

1. Run CELL 1: Install dependencies (should complete in 2 min)
2. Run CELL 2: Unzip model (should complete in 1 min)
3. Run CELL 3: GPU setup (should output GPU info)
4. Run CELL 4: Load dataset (should show split: 5000 text + 287 vision)
5. Run CELL 5: Load Gemma model (should output "✅ Base model loaded")

**Expected time**: ~10 minutes total

**If any cell fails**:
- ❌ Don't proceed to training
- Debug and fix it first
- Report the error

---

## 9️⃣ STORAGE CHECK

Kaggle gives you **~10 GB** storage in `/kaggle/working/`:

- Gemma model unzipped: ~12 GB
- Checkpoints: ~500 MB
- Final adapter: ~500 MB
- **Total needed: ~13 GB**

⚠️ **Storage may be tight!**

**Solution**:
- Delete checkpoints after training completes
- Keep only final_adapter for download

---

## 🔟 READY TO TRAIN?

Before you press "Run":

- ✅ GPU verified (RTX Pro 6000, 24GB VRAM)
- ✅ All 3 datasets added
- ✅ Internet disabled
- ✅ Cells 1-5 test passed
- ✅ You have ~2 hours free
- ✅ You understand the training will take ~70 minutes

---

## 📋 DURING TRAINING

Monitor these things:

### Phase 1 (Text-Only, ~40 min):
```
Log example:
[625/625 00:40:15] loss=1.23 learning_rate=1.5e-4
```

Watch for:
- ✅ Loss decreases smoothly
- ✅ GPU memory stable (~18 GB)
- ✅ Speed: ~3-5 samples/sec
- ❌ Loss increasing: Something wrong, stop and debug
- ❌ OOM errors: Gradient accumulation too high

### Phase 2 (Vision, ~30 min):
```
Log example:
[150/150 00:30:05] loss=1.15 learning_rate=4.5e-5
```

Watch for:
- ✅ Loss continues to decrease (lower LR = slower)
- ✅ GPU memory stable (~18 GB)
- ✅ Speed: ~2-4 samples/sec
- ❌ Loss flat/unchanged: Vision images may not load properly

---

## 📥 AFTER TRAINING COMPLETE

**Download the adapter**:
1. Go to your notebook
2. Click: "...More" → "Open in file browser"
3. Navigate to: `/kaggle/working/final_adapter/`
4. Download the entire folder

**Verify downloaded**:
```bash
ls -lh final_adapter/
# Should have: adapter_config.json, adapter_model.bin, processor_config.json, etc.
# Total size: ~500 MB
```

---

## 🚀 NEXT STEPS (After Download)

```bash
# 1. Move adapter locally
cp -r ~/Downloads/final_adapter ~/ghost_architect_gemma3/output/adapters/trinity_kaggle/

# 2. Export to GGUF
cd ~/ghost_architect_gemma3
make export --adapter-dir output/adapters/trinity_kaggle/

# 3. Test with Ollama
ollama create ghost-architect -f output/gguf/Modelfile

# 4. Test with Streamlit
streamlit run src/app.py
```

---

## ❓ TROUBLESHOOTING

### Issue: "CUDA out of memory"
```python
# In CELL 7 and CELL 10, reduce:
gradient_accumulation_steps=4  # from 8 in Phase 1
gradient_accumulation_steps=2  # from 4 in Phase 2
```

### Issue: "Image not found"
- Run CELL 4 again, check "✅ Sample vision example"
- If it shows 0 vision samples, dataset didn't load
- Verify dataset is added to notebook

### Issue: "Model not found at /kaggle/working/gemma3_model"
- CELL 2 unzip may have failed
- Run: `!ls -la /kaggle/working/ | grep gemma`
- If no gemma3_model folder: Rerun CELL 2

### Issue: "No datasets found"
- Click "Add Input" in your notebook
- Add the 3 datasets explicitly
- Don't skip this step!

---

## 🎯 SUCCESS CRITERIA

You're done when:

1. ✅ CELL 7 completes (Phase 1 training done)
2. ✅ CELL 10 completes (Phase 2 training done)
3. ✅ CELL 11 shows adapter saved (~500 MB)
4. ✅ Can download final_adapter folder
5. ✅ `make export` succeeds locally
6. ✅ GGUF file created (~4-6 GB)

---

## 📞 SUPPORT

If stuck:

1. Check the training logs in CELL 7 or CELL 10
2. Look for "✅" markers (expected output) vs "❌" errors
3. Compare with expected memory usage (~18 GB)
4. If loss is increasing: LR too high, reduce and retry
5. If images not loading: Check CELL 4 output first

---

**YOU'RE READY!** 🚀

Next: Go to Kaggle and run the notebook!
