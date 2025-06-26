"""
Braille API Client Example
=========================

This module demonstrates how to interact with the Braille Translation API
from Python or can be adapted for Flutter/Dart HTTP requests.
"""

import requests
import json
from typing import Dict, Any, Optional

class BrailleAPIClient:
    """Client for interacting with the Braille Translation API"""
    
    def __init__(self, base_url: str = "http://localhost:5000"):
        self.base_url = base_url.rstrip('/')
    
    def health_check(self) -> Dict[str, Any]:
        """Check if the API is healthy"""
        try:
            response = requests.get(f"{self.base_url}/health")
            return response.json()
        except Exception as e:
            return {"error": str(e)}
    
    def translate(self, 
                 text: str, 
                 standard: str = "grade1",
                 language: str = "en",
                 reverse: bool = False,
                 format_output: bool = True,
                 include_metadata: bool = False) -> Dict[str, Any]:
        """Translate text to/from Braille"""
        payload = {
            "text": text,
            "standard": standard,
            "language": language,
            "reverse": reverse,
            "format_output": format_output,
            "include_metadata": include_metadata
        }
        
        try:
            response = requests.post(
                f"{self.base_url}/api/braille/translate",
                json=payload,
                headers={"Content-Type": "application/json"}
            )
            return response.json()
        except Exception as e:
            return {"error": str(e)}
    
    def get_standards(self) -> Dict[str, Any]:
        """Get supported Braille standards"""
        try:
            response = requests.get(f"{self.base_url}/api/braille/standards")
            return response.json()
        except Exception as e:
            return {"error": str(e)}
    
    def get_languages(self) -> Dict[str, Any]:
        """Get supported languages"""
        try:
            response = requests.get(f"{self.base_url}/api/braille/languages")
            return response.json()
        except Exception as e:
            return {"error": str(e)}
    
    def demo(self) -> Dict[str, Any]:
        """Get demo translations"""
        try:
            response = requests.get(f"{self.base_url}/api/braille/demo")
            return response.json()
        except Exception as e:
            return {"error": str(e)}

def main():
    """Example usage of the Braille API client"""
    client = BrailleAPIClient()
    
    print("=== Braille Translation API Client Demo ===\n")
    
    # Health check
    print("1. Health Check:")
    health = client.health_check()
    print(json.dumps(health, indent=2))
    print()
    
    # Get supported standards
    print("2. Supported Standards:")
    standards = client.get_standards()
    print(json.dumps(standards, indent=2))
    print()
    
    # Get supported languages
    print("3. Supported Languages:")
    languages = client.get_languages()
    print(json.dumps(languages, indent=2))
    print()
    
    # Text to Braille translation
    print("4. Text to Braille Translation:")
    text_to_braille = client.translate(
        text="Hello World",
        standard="grade1",
        include_metadata=True
    )
    print(json.dumps(text_to_braille, indent=2))
    print()
    
    # Braille to text translation (reverse)
    if text_to_braille.get("success"):
        braille_result = text_to_braille["result"].replace(" ", "")  # Remove formatting spaces
        print("5. Braille to Text Translation (Reverse):")
        braille_to_text = client.translate(
            text=braille_result,
            standard="grade1",
            reverse=True,
            include_metadata=True
        )
        print(json.dumps(braille_to_text, indent=2))
        print()
    
    # Grade 2 translation
    print("6. Grade 2 Braille Translation:")
    grade2_translation = client.translate(
        text="The quick brown fox and the lazy dog",
        standard="grade2",
        include_metadata=True
    )
    print(json.dumps(grade2_translation, indent=2))
    print()
    
    # Demo translations
    print("7. Demo Translations:")
    demo = client.demo()
    print(json.dumps(demo, indent=2))

if __name__ == "__main__":
    main()
