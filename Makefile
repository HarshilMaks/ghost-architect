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
	@echo "💡 QUICK START:"
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

