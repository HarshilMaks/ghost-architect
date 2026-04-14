#!/usr/bin/env python3
"""Test model inference with a dummy image."""

import sys
sys.path.insert(0, 'src')

print("🧪 Testing Model Inference (CLI)\n")

print("📦 Loading model and processor...")
from app import load_model, load_processor
model = load_model()
processor = load_processor()
print("✓ Model loaded successfully!\n")

print("🖼️ Creating test image...")
from PIL import Image
import torch
test_image = Image.new('RGB', (448, 448), color='blue')
print(f"✓ Test image created: {test_image.size}\n")

print("⚙️ Preprocessing image...")
processed = processor(
    images=test_image,
    text="Analyze this UI and generate a database schema.",
    return_tensors="pt"
)
print(f"✓ Image preprocessed")
print(f"  - pixel_values shape: {processed['pixel_values'].shape}")
print(f"  - input_ids shape: {processed['input_ids'].shape}\n")

print("🧠 Running model inference...")
print("   (This takes 10-15 seconds)...\n")
with torch.no_grad():
    outputs = model.generate(
        **processed,
        max_length=512,
        temperature=0.7,
        top_p=0.9
    )
print("✓ Inference completed!\n")

print("📝 Decoding output to SQL...")
from transformers import AutoTokenizer
tokenizer = AutoTokenizer.from_pretrained("output/adapters/trinity_kaggle")
sql = tokenizer.decode(outputs[0], skip_special_tokens=True)
print("✓ SQL generated!\n")

print("🎯 Generated Schema (first 500 characters):")
print("─" * 70)
print(sql[:500])
print("─" * 70)
print()

# Check if it looks like SQL
if "CREATE TABLE" in sql or "CREATE" in sql:
    print("✅ Inference test PASSED - Generated valid SQL!")
else:
    print("⚠️ Output doesn't look like SQL - check model output")
