.PHONY: help venv install validate dataset-check train export test clean modal-dry-1 modal-dry-10 modal-train app app-prod inference-test unit-test all-tests kill-app check-gpu

VENV := .venv
PYTHON := $(VENV)/bin/python
UV := uv
CONFIG := configs/training_config.yaml
DATASET := data/dataset.json
STREAMLIT_PORT := 8501

help:
	@echo "╔════════════════════════════════════════════════════════════════╗"
	@echo "║           Ghost Architect - Make Commands                      ║"
	@echo "╚════════════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "🚀 TESTING & RUNNING:"
	@echo "  make app             - Start Streamlit frontend (http://localhost:8501)"
	@echo "  make app-prod        - Start Streamlit with prod settings"
	@echo "  make inference-test  - Test model inference (CLI, no UI)"
	@echo "  make unit-test       - Run unit tests only"
	@echo "  make all-tests       - Run all tests (unit + inference)"
	@echo "  make check-gpu       - Verify GPU and CUDA availability"
	@echo "  make kill-app        - Stop Streamlit server if running"
	@echo ""
	@echo "🔧 SETUP & INSTALLATION:"
	@echo "  make venv            - Create local virtual environment with uv"
	@echo "  make install         - Install project dependencies"
	@echo "  make validate        - Validate environment and GPU readiness"
	@echo "  make dataset-check   - Validate dataset JSON file"
	@echo ""
	@echo "📚 TRAINING (Reference - not needed for testing):"
	@echo "  make train           - Run training entrypoint"
	@echo "  make modal-dry-1     - Modal training smoke test on 1 sample"
	@echo "  make modal-dry-10    - Modal dry run on 10 samples"
	@echo "  make modal-train     - Modal full training run"
	@echo "  make export          - Run export entrypoint (GGUF + Modelfile)"
	@echo ""
	@echo "🧹 MAINTENANCE:"
	@echo "  make test            - Run project tests (pytest)"
	@echo "  make clean           - Remove Python cache files"
	@echo ""
	@echo 💡 QUICK START:"
	@echo "  make install && make check-gpu && make app"

venv:
	@test -x $(PYTHON) || $(UV) venv

install: venv
	$(UV) pip install --python $(PYTHON) -r requirements.txt

validate:
	$(PYTHON) scripts/validate_environment.py

dataset-check:
	@$(PYTHON) scripts/validate_dataset.py

train:
	$(PYTHON) src/train.py --config $(CONFIG) --dataset $(DATASET)

modal-dry-1:
	$(UV) tool run modal run src/modal_train.py::main --dry-run-limit 1

modal-dry-10:
	$(UV) tool run modal run src/modal_train.py::main --dry-run-limit 10

modal-train:
	$(UV) tool run modal run src/modal_train.py::main

export:
	$(PYTHON) src/export.py --adapter-dir "$${ADAPTER_DIR:-output/adapters/trinity_a10g}" --output-dir output/gguf --model-name ghost-architect-v1

test:
	$(PYTHON) -m pytest -q

clean:
	find . -type d -name "__pycache__" -prune -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete

# ════════════════════════════════════════════════════════════════════════════
# TESTING & RUNNING COMMANDS
# ════════════════════════════════════════════════════════════════════════════

.PHONY: app app-prod inference-test unit-test all-tests check-gpu kill-app

check-gpu:
	@echo "🔍 Checking GPU availability..."
	@$(UV) run python << 'EOF'
import torch
print(f"✓ PyTorch version: {torch.__version__}")
print(f"✓ CUDA available: {torch.cuda.is_available()}")
if torch.cuda.is_available():
	print(f"✓ GPU: {torch.cuda.get_device_name(0)}")
	print(f"✓ VRAM: {torch.cuda.get_device_properties(0).total_memory / 1e9:.1f} GB")
	print(f"✓ CUDA version: {torch.version.cuda}")
else:
	print("⚠ No GPU found - model will run on CPU (very slow)")
EOF

app:
	@echo "🚀 Starting Ghost Architect (Streamlit Frontend)..."
	@echo "📍 Open browser to: http://localhost:$(STREAMLIT_PORT)"
	@echo "🛑 Press Ctrl+C to stop"
	@echo ""
	@$(UV) run streamlit run src/app.py

app-prod:
	@echo "🚀 Starting Ghost Architect (Production Mode)..."
	@echo "📍 Open browser to: http://localhost:$(STREAMLIT_PORT)"
	@$(UV) run streamlit run src/app.py \
		--logger.level=warning \
		--client.showErrorDetails=false \
		--server.runOnSave=false

inference-test:
	@echo "🧪 Testing Model Inference (CLI)..."
	@echo "   This will load the model and test a dummy image"
	@echo ""
	@$(UV) run python << 'EOF'
import sys
sys.path.insert(0, 'src')

print("📦 Loading model and processor...")
from app import load_model, load_processor
model = load_model()
processor = load_processor()
print("✓ Model loaded successfully!")
print("")

print("🖼️ Creating test image...")
from PIL import Image
import torch
test_image = Image.new('RGB', (448, 448), color='blue')
print(f"✓ Test image created: {test_image.size}")
print("")

print("⚙️ Preprocessing image...")
processed = processor(
	images=test_image,
	text="Analyze this UI and generate a database schema.",
	return_tensors="pt"
)
print(f"✓ Image preprocessed")
print(f"  - pixel_values shape: {processed['pixel_values'].shape}")
print(f"  - input_ids shape: {processed['input_ids'].shape}")
print("")

print("🧠 Running model inference...")
print("   (This takes 10-15 seconds on first run)...")
with torch.no_grad():
	outputs = model.generate(
		**processed,
		max_length=512,
		temperature=0.7,
		top_p=0.9
	)
print("✓ Inference completed!")
print("")

print("📝 Decoding output to SQL...")
from transformers import AutoTokenizer
tokenizer = AutoTokenizer.from_pretrained("output/adapters/trinity_kaggle")
sql = tokenizer.decode(outputs[0], skip_special_tokens=True)
print("✓ SQL generated!")
print("")
print("🎯 Generated Schema (first 500 characters):")
print("─" * 70)
print(sql[:500])
print("─" * 70)
print("")
print("✅ Inference test PASSED!")
EOF

unit-test:
	@echo "🧪 Running Unit Tests..."
	@$(UV) run pytest tests/test_export.py -v
	@echo ""
	@echo "✅ Unit tests completed!"

all-tests: unit-test inference-test
	@echo ""
	@echo "════════════════════════════════════════════════════════════════"
	@echo "✅ ALL TESTS PASSED!"
	@echo "════════════════════════════════════════════════════════════════"
	@echo ""
	@echo "📊 Test Summary:"
	@echo "  ✓ Unit tests (export, path resolution): PASSED"
	@echo "  ✓ Model inference (dummy image): PASSED"
	@echo ""
	@echo "Next step: Start the app with: make app"
	@echo "Then upload UI screenshots and generate schemas!"

kill-app:
	@echo "🛑 Stopping Streamlit server..."
	@pkill -f "streamlit run src/app.py" 2>/dev/null || echo "No Streamlit process found"
	@sleep 1
	@echo "✓ Streamlit stopped (port $(STREAMLIT_PORT) should be free now)"
