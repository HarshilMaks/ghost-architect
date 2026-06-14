.PHONY: help install app test-inference deploy-check clean

PYTHON := .venv/bin/python3
UV := uv
STREAMLIT_PORT := 8501

help:
	@echo "╔════════════════════════════════════════════════════════════════╗"
	@echo "║           Ghost Architect - Make Commands                      ║"
	@echo "╚════════════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "🚀 RUNNING:"
	@echo "  make app             - Start Streamlit frontend (http://localhost:8501)"
	@echo "  make test-inference  - Test Gemini API inference (requires API key)"
	@echo ""
	@echo "🔧 SETUP:"
	@echo "  make install         - Install project dependencies"
	@echo "  make deploy-check    - Verifies no GPU packages in requirements.txt"
	@echo ""
	@echo "🧹 MAINTENANCE:"
	@echo "  make clean           - Remove Python cache files"
	@echo "  make help            - Show this help message"
	@echo ""
	@echo "💡 QUICK START:"
	@echo "  1. Get API key: aistudio.google.com"
	@echo "  2. echo 'GEMINI_API_KEY = \"your_key\"' > .streamlit/secrets.toml"
	@echo "  3. make install"
	@echo "  4. make app"

install:
	$(UV) pip install -r requirements.txt

app:
	@echo "🚀 Starting Ghost Architect (Streamlit Frontend)..."
	@echo "📍 Open browser to: http://localhost:$(STREAMLIT_PORT)"
	@echo "🛑 Press Ctrl+C to stop"
	@echo ""
	$(UV) run streamlit run src/app.py --server.port $(STREAMLIT_PORT)

test-inference:
	$(UV) run python scripts/test_inference.py

deploy-check:
	@echo "Checking requirements.txt for GPU dependencies..."
	@grep -E "torch|transformers|unsloth|peft|bitsandbytes" requirements.txt && \
		echo "ERROR: GPU packages found — will break Streamlit Cloud" || \
		echo "✓ requirements.txt is clean for Streamlit Cloud"

clean:
	find . -type d -name "__pycache__" -prune -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
