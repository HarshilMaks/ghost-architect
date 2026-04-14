#!/usr/bin/env python3
"""Check GPU availability and CUDA setup."""

import torch

print("🔍 Checking GPU availability...\n")

print(f"✓ PyTorch version: {torch.__version__}")
print(f"✓ CUDA available: {torch.cuda.is_available()}")

if torch.cuda.is_available():
    print(f"✓ GPU: {torch.cuda.get_device_name(0)}")
    props = torch.cuda.get_device_properties(0)
    vram_gb = props.total_memory / 1e9
    print(f"✓ VRAM: {vram_gb:.1f} GB")
    print(f"✓ CUDA version: {torch.version.cuda}")
    
    if vram_gb >= 16:
        print("\n✅ GPU has sufficient VRAM for model inference!")
    else:
        print(f"\n⚠️  GPU VRAM is {vram_gb:.1f} GB (recommended: 16+ GB)")
else:
    print("\n⚠️  No GPU found - model will run on CPU (very slow)")
