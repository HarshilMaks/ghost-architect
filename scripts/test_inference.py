"""
test_inference.py — Tests the Gemini API inference pipeline.
Run: python scripts/test_inference.py
Requires: GEMINI_API_KEY set in .streamlit/secrets.toml
"""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

from google import genai
import PIL.Image
import toml

secrets = toml.load(".streamlit/secrets.toml")
client = genai.Client(api_key=secrets["GEMINI_API_KEY"])

def test_gemini_text():
    response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents="Say 'Ghost Architect is working.' and nothing else.",
    )
    assert "Ghost Architect is working" in response.text
    print("✓ Gemini text generation works")

def test_gemini_vision_with_test_image():
    img = PIL.Image.new("RGB", (100, 100), color=(100, 150, 200))
    response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=["Describe this image in one sentence.", img],
    )
    assert response.text
    print(f"✓ Gemini vision works: {response.text[:80]}")

if __name__ == "__main__":
    test_gemini_text()
    test_gemini_vision_with_test_image()
    print("\n✓ All tests passed. App is ready to deploy.")
