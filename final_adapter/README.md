---
license: mit
language:
- en
tags:
- gemma-3
- peft
- qlora
- dora
- rslora
- database
- schema
- sql
- vision
- unsloth
- trinity
pipeline_tag: text-generation
base_model: google/gemma-3-12b-it
library_name: peft
---

# Ghost Architect — Gemma-3-12B Adapter

Fine-tuned Gemma-3-12B-IT vision adapter for converting UI screenshots into PostgreSQL database schemas.

Trained with the Trinity stack: QLoRA (4-bit) + DoRA + rsLoRA on 5,287 UI→SQL examples.

## Usage

```python
import torch
from PIL import Image
from transformers import AutoProcessor
from peft import AutoPeftModelForCausalLM

model = AutoPeftModelForCausalLM.from_pretrained(
    "harshilmaks/ghost-architect-gemma3-adapter",
    device_map="auto"
)
processor = AutoProcessor.from_pretrained("harshilmaks/ghost-architect-gemma3-adapter")

image = Image.open("screenshot.png")
messages = [
    {"role": "user", "content": [
        {"type": "image", "image": image},
        {"type": "text", "text": "Generate the database schema for this UI."}
    ]}
]
inputs = processor.apply_chat_template(
    messages, tokenize=True, add_generation_prompt=True,
    return_tensors="pt"
).to("cuda")

outputs = model.generate(**inputs, max_new_tokens=2048)
print(processor.decode(outputs[0], skip_special_tokens=True))
```

## Training

| Detail | Value |
|--------|-------|
| Base model | `google/gemma-3-12b-it` |
| Training examples | 5,287 (287 real screenshots + 5,000 synthetic) |
| Quantization | 4-bit NF4 (QLoRA) |
| Rank | 64 |
| LoRA alpha | 32 |
| DoRA | Enabled |
| rsLoRA | Enabled |
| Target modules | q_proj, k_proj, v_proj, o_proj, gate_proj, up_proj, down_proj |
| Context length | 2048 tokens |
| Hardware | Kaggle RTX Pro 6000 (24GB VRAM), also trained on T4 (16GB) |
| Framework | Unsloth + PEFT + TRL |
| License | MIT |

## Live App

The Streamlit app using Gemini API (not this adapter) is live at:
https://ghost-architect.streamlit.app

This adapter is the **original research artifact** — the live demo uses Gemini API for zero-setup access.
