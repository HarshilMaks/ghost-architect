#!/usr/bin/env python3
"""
Download Gemma-3-12B-IT BNB-4bit model from Hugging Face
This script prepares the model for offline use in Kaggle RTX Pro 6000
"""

import os
import sys
from pathlib import Path
from huggingface_hub import snapshot_download

# Configuration
# This is the SAME model we use in src/modal_train.py (line 202)
REPO_ID = "unsloth/gemma-3-12b-it-unsloth-bnb-4bit"
OUTPUT_DIR = Path("/home/harshil/ghost_architect_gemma3/output/gemma3_model")
ZIP_NAME = "gemma3_model.zip"

def download_model():
    """Download the Gemma-3 model from Hugging Face"""
    
    print(f"📦 Downloading Gemma-3 model...")
    print(f"   Repository: {REPO_ID}")
    print(f"   Output: {OUTPUT_DIR}")
    
    # Create output directory
    OUTPUT_DIR.parent.mkdir(parents=True, exist_ok=True)
    
    try:
        print(f"\n⏳ Starting download (this may take 10-15 minutes)...")
        
        snapshot_download(
            repo_id=REPO_ID,
            local_dir=str(OUTPUT_DIR),
            cache_dir=None,  # Don't use cache
            force_download=False,  # Skip if already exists
        )
        
        print(f"\n✅ Model downloaded successfully!")
        
        # List downloaded files
        files = list(OUTPUT_DIR.rglob("*"))
        print(f"\n📂 Downloaded files ({len(files)} items):")
        
        total_size = 0
        for f in sorted([x for x in files if x.is_file()])[:10]:
            size_mb = f.stat().st_size / 1024 / 1024
            total_size += f.stat().st_size
            print(f"   - {f.relative_to(OUTPUT_DIR)} ({size_mb:.1f} MB)")
        
        if len([x for x in files if x.is_file()]) > 10:
            print(f"   ... and {len([x for x in files if x.is_file()]) - 10} more files")
        
        total_size_gb = total_size / 1024 / 1024 / 1024
        print(f"\n💾 Total size: {total_size_gb:.2f} GB")
        
        return True
        
    except Exception as e:
        print(f"\n❌ Download failed: {e}")
        return False

def create_zip():
    """Create a ZIP file for Kaggle upload"""
    
    if not OUTPUT_DIR.exists():
        print(f"❌ Model directory not found: {OUTPUT_DIR}")
        return False
    
    zip_path = OUTPUT_DIR.parent / ZIP_NAME
    
    print(f"\n📦 Creating ZIP file...")
    print(f"   Source: {OUTPUT_DIR}")
    print(f"   ZIP: {zip_path}")
    
    try:
        import shutil
        
        # Create ZIP (might be large, but needed for Kaggle)
        shutil.make_archive(
            str(zip_path.with_suffix("")),  # Remove .zip extension
            "zip",
            OUTPUT_DIR.parent,
            OUTPUT_DIR.name
        )
        
        zip_size_gb = zip_path.stat().st_size / 1024 / 1024 / 1024
        print(f"✅ ZIP created: {zip_path.name} ({zip_size_gb:.2f} GB)")
        
        return True
        
    except Exception as e:
        print(f"❌ ZIP creation failed: {e}")
        return False

def main():
    print("=" * 70)
    print("GEMMA-3-12B MODEL DOWNLOAD FOR KAGGLE")
    print("=" * 70)
    
    # Check internet connection
    try:
        import urllib.request
        urllib.request.urlopen("https://huggingface.co", timeout=5)
        print("\n✅ Internet connection OK\n")
    except:
        print("\n❌ No internet connection. Cannot download model.")
        sys.exit(1)
    
    # Step 1: Download model
    if not download_model():
        sys.exit(1)
    
    # Step 2: Create ZIP
    print("\n" + "=" * 70)
    if not create_zip():
        print("⚠️  ZIP creation failed, but model is available at:")
        print(f"   {OUTPUT_DIR}")
        sys.exit(1)
    
    # Summary
    print("\n" + "=" * 70)
    print("✅ SUCCESS!")
    print("=" * 70)
    print(f"\n📁 Model location: {OUTPUT_DIR}")
    print(f"📦 ZIP file: {OUTPUT_DIR.parent / ZIP_NAME}")
    
    print("\n📋 NEXT STEPS FOR KAGGLE:")
    print(f"\n1. Upload the ZIP to Kaggle as a dataset:")
    print(f"   - Go to https://www.kaggle.com/datasets")
    print(f"   - Click 'Create new dataset'")
    print(f"   - Upload: {OUTPUT_DIR.parent / ZIP_NAME}")
    print(f"   - Name it: 'gemma-3-model-offline'")
    print(f"\n2. In your Kaggle notebook, add it as input")
    print(f"\n3. In CELL 1 (after pip install), add:")
    print(f"""
!unzip -q /kaggle/input/gemma-3-model-offline/{ZIP_NAME}
!mv gemma3_model /kaggle/working/gemma3_model
""")
    
    print(f"\n4. Update CELL 3 to use local model:")
    print(f"""
model, tokenizer = FastLanguageModel.from_pretrained(
    model_name="/kaggle/working/gemma3_model",  # Use local path
    max_seq_length=2048,
    load_in_4bit=True,
    dtype=None,
)
""")
    
    print("\n" + "=" * 70)

if __name__ == "__main__":
    main()
