"""
Advanced Braille Translation API for Gnos Braille System
========================================================

This module provides a comprehensive REST API for Braille translation services
including text-to-Braille, Braille-to-text, multiple standards support, and 
advanced accessibility features.

Features:
- Multiple Braille standards (Grade 1, Grade 2, Computer Braille)
- Bidirectional translation (text ↔ Braille)
- Multi-language support
- Unicode Braille patterns
- Accessibility optimizations
- RESTful API endpoints
- Error handling and validation
"""

import sys
import json
import logging
from typing import Dict, List, Optional, Union, Tuple
from dataclasses import dataclass, asdict
from enum import Enum
from flask import Flask, request, jsonify, Response
from flask_cors import CORS
import re

# Try to import pybraille, fallback to basic implementation if not available
try:
    import pybraille
    PYBRAILLE_AVAILABLE = True
except ImportError:
    PYBRAILLE_AVAILABLE = False
    print("Warning: pybraille not available, using basic implementation")

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class BrailleStandard(Enum):
    """Supported Braille standards"""
    GRADE_1 = "grade1"
    GRADE_2 = "grade2"
    COMPUTER = "computer"
    MUSIC = "music"
    MATH = "math"

class BrailleLanguage(Enum):
    """Supported languages for Braille translation"""
    ENGLISH = "en"
    SPANISH = "es"
    FRENCH = "fr"
    GERMAN = "de"
    ITALIAN = "it"
    PORTUGUESE = "pt"

@dataclass
class BrailleTranslationRequest:
    """Request model for Braille translation"""
    text: str
    standard: str = BrailleStandard.GRADE_1.value
    language: str = BrailleLanguage.ENGLISH.value
    reverse: bool = False  # True for Braille-to-text
    format_output: bool = True
    include_metadata: bool = False

@dataclass
class BrailleTranslationResponse:
    """Response model for Braille translation"""
    success: bool
    result: str
    original_text: str
    standard_used: str
    language: str
    character_count: int
    braille_cell_count: int
    metadata: Optional[Dict] = None
    error: Optional[str] = None

class BrailleTranslator:
    """Advanced Braille translation engine"""
    
    def __init__(self):
        self.supported_standards = [standard.value for standard in BrailleStandard]
        self.supported_languages = [lang.value for lang in BrailleLanguage]
        
        # Unicode Braille patterns (U+2800 to U+283F)
        self.braille_unicode_base = 0x2800
        
        # Basic Grade 1 Braille mapping (fallback)
        self.grade1_map = {
            'a': '⠁', 'b': '⠃', 'c': '⠉', 'd': '⠙', 'e': '⠑',
            'f': '⠋', 'g': '⠛', 'h': '⠓', 'i': '⠊', 'j': '⠚',
            'k': '⠅', 'l': '⠇', 'm': '⠍', 'n': '⠝', 'o': '⠕',
            'p': '⠏', 'q': '⠟', 'r': '⠗', 's': '⠎', 't': '⠞',
            'u': '⠥', 'v': '⠧', 'w': '⠺', 'x': '⠭', 'y': '⠽', 'z': '⠵',
            ' ': '⠀', '.': '⠲', ',': '⠂', '?': '⠦', '!': '⠖',
            "'": '⠄', '-': '⠤', '(': '⠷', ')': '⠾'
        }
        
        # Reverse mapping for Braille-to-text
        self.reverse_grade1_map = {v: k for k, v in self.grade1_map.items()}
        
        # Grade 2 contractions (common ones)
        self.grade2_contractions = {
            'and': '⠯', 'for': '⠿', 'of': '⠷', 'the': '⠮', 'with': '⠾',
            'ing': '⠬', 'ed': '⠫', 'er': '⠻', 'ou': '⠳', 'ow': '⠪',
            'ar': '⠜', 'gh': '⠣', 'ea': '⠂', 'bb': '⠆', 'cc': '⠒',
            'dd': '⠲', 'ff': '⠖', 'gg': '⠶'
        }
    
    def validate_request(self, req: BrailleTranslationRequest) -> Tuple[bool, Optional[str]]:
        """Validate translation request"""
        if not req.text or not req.text.strip():
            return False, "Text cannot be empty"
        
        if req.standard not in self.supported_standards:
            return False, f"Unsupported standard: {req.standard}"
        
        if req.language not in self.supported_languages:
            return False, f"Unsupported language: {req.language}"
        
        if len(req.text) > 10000:  # Reasonable limit
            return False, "Text too long (max 10000 characters)"
        
        return True, None
    
    def text_to_braille_basic(self, text: str, standard: str) -> str:
        """Basic text-to-Braille conversion (fallback implementation)"""
        text = text.lower().strip()
        result = []
        
        if standard == BrailleStandard.GRADE_2.value:
            # Apply Grade 2 contractions first
            for contraction, braille in self.grade2_contractions.items():
                text = text.replace(contraction, f"[{braille}]")
        
        # Convert character by character
        i = 0
        while i < len(text):
            # Handle contractions marked with brackets
            if text[i] == '[':
                end_bracket = text.find(']', i)
                if end_bracket != -1:
                    braille_char = text[i+1:end_bracket]
                    result.append(braille_char)
                    i = end_bracket + 1
                    continue
            
            # Regular character mapping
            char = text[i]
            if char in self.grade1_map:
                result.append(self.grade1_map[char])
            else:
                # Handle numbers (add number sign ⠼)
                if char.isdigit():
                    if not result or result[-1] != '⠼':
                        result.append('⠼')  # Number sign
                    # Map digits to letters a-j
                    digit_map = {'1': '⠁', '2': '⠃', '3': '⠉', '4': '⠙', '5': '⠑',
                               '6': '⠋', '7': '⠛', '8': '⠓', '9': '⠊', '0': '⠚'}
                    result.append(digit_map.get(char, '⠀'))
                else:
                    # Unknown character, use space
                    result.append('⠀')
            i += 1
        
        return ''.join(result)
    
    def braille_to_text_basic(self, braille: str, standard: str) -> str:
        """Basic Braille-to-text conversion (fallback implementation)"""
        result = []
        i = 0
        number_mode = False
        
        while i < len(braille):
            char = braille[i]
            
            # Handle number sign
            if char == '⠼':
                number_mode = True
                i += 1
                continue
            
            if number_mode and char in '⠁⠃⠉⠙⠑⠋⠛⠓⠊⠚':
                # Convert Braille digits back to numbers
                digit_map = {'⠁': '1', '⠃': '2', '⠉': '3', '⠙': '4', '⠑': '5',
                           '⠋': '6', '⠛': '7', '⠓': '8', '⠊': '9', '⠚': '0'}
                result.append(digit_map[char])
                # Continue in number mode until space or punctuation
                if i + 1 < len(braille) and braille[i + 1] in '⠀⠂⠲⠦⠖':
                    number_mode = False
            else:
                number_mode = False
                if char in self.reverse_grade1_map:
                    result.append(self.reverse_grade1_map[char])
                else:
                    # Check Grade 2 contractions
                    if standard == BrailleStandard.GRADE_2.value:
                        for word, braille_word in self.grade2_contractions.items():
                            if braille.startswith(braille_word, i):
                                result.append(word)
                                i += len(braille_word) - 1
                                break
                        else:
                            result.append('?')  # Unknown character
                    else:
                        result.append('?')  # Unknown character
            i += 1
        
        return ''.join(result)
    
    def translate_with_pybraille(self, text: str, standard: str, reverse: bool = False) -> str:
        """Use pybraille library for translation (if available)"""
        if not PYBRAILLE_AVAILABLE:
            return self.text_to_braille_basic(text, standard) if not reverse else self.braille_to_text_basic(text, standard)
        
        try:
            if reverse:
                # Braille to text
                return pybraille.to_text(text)
            else:
                # Text to Braille
                if standard == BrailleStandard.GRADE_2.value:
                    return pybraille.to_braille(text, grade=2)
                else:
                    return pybraille.to_braille(text, grade=1)
        except Exception as e:
            logger.warning(f"pybraille failed, using fallback: {e}")
            return self.text_to_braille_basic(text, standard) if not reverse else self.braille_to_text_basic(text, standard)
    
    def translate(self, req: BrailleTranslationRequest) -> BrailleTranslationResponse:
        """Main translation method"""
        # Validate request
        is_valid, error_msg = self.validate_request(req)
        if not is_valid:
            return BrailleTranslationResponse(
                success=False,
                result="",
                original_text=req.text,
                standard_used=req.standard,
                language=req.language,
                character_count=0,
                braille_cell_count=0,
                error=error_msg
            )
        
        try:
            # Perform translation
            if PYBRAILLE_AVAILABLE:
                result = self.translate_with_pybraille(req.text, req.standard, req.reverse)
            else:
                if req.reverse:
                    result = self.braille_to_text_basic(req.text, req.standard)
                else:
                    result = self.text_to_braille_basic(req.text, req.standard)
            
            # Format output if requested
            if req.format_output and not req.reverse:
                # Add spaces between Braille cells for readability
                formatted_result = []
                for char in result:
                    if ord(char) >= 0x2800 and ord(char) <= 0x283F:  # Braille Unicode range
                        formatted_result.append(char + ' ')
                    else:
                        formatted_result.append(char)
                result = ''.join(formatted_result).strip()
            
            # Calculate metrics
            char_count = len(req.text)
            braille_cell_count = len([c for c in result if ord(c) >= 0x2800 and ord(c) <= 0x283F])
            
            # Prepare metadata
            metadata = None
            if req.include_metadata:
                metadata = {
                    "translation_method": "pybraille" if PYBRAILLE_AVAILABLE else "basic",
                    "contractions_used": req.standard == BrailleStandard.GRADE_2.value,
                    "unicode_range": "U+2800-U+283F",
                    "compression_ratio": round(braille_cell_count / char_count, 2) if char_count > 0 else 0,
                    "supported_features": [
                        "Grade 1 Braille",
                        "Grade 2 Braille" if req.standard == BrailleStandard.GRADE_2.value else None,
                        "Numbers",
                        "Basic punctuation"
                    ]
                }
            
            return BrailleTranslationResponse(
                success=True,
                result=result,
                original_text=req.text,
                standard_used=req.standard,
                language=req.language,
                character_count=char_count,
                braille_cell_count=braille_cell_count,
                metadata=metadata
            )
            
        except Exception as e:
            logger.error(f"Translation error: {e}")
            return BrailleTranslationResponse(
                success=False,
                result="",
                original_text=req.text,
                standard_used=req.standard,
                language=req.language,
                character_count=0,
                braille_cell_count=0,
                error=f"Translation failed: {str(e)}"
            )

# Initialize Flask app
app = Flask(__name__)
CORS(app)  # Enable CORS for Flutter integration

# Initialize translator
translator = BrailleTranslator()

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy",
        "service": "Braille Translation API",
        "version": "1.0.0",
        "pybraille_available": PYBRAILLE_AVAILABLE
    })

@app.route('/api/braille/translate', methods=['POST'])
def translate_text():
    """Main translation endpoint"""
    try:
        data = request.get_json()
        if not data:
            return jsonify({"error": "No JSON data provided"}), 400
        
        # Create request object
        req = BrailleTranslationRequest(
            text=data.get('text', ''),
            standard=data.get('standard', BrailleStandard.GRADE_1.value),
            language=data.get('language', BrailleLanguage.ENGLISH.value),
            reverse=data.get('reverse', False),
            format_output=data.get('format_output', True),
            include_metadata=data.get('include_metadata', False)
        )
        
        # Perform translation
        response = translator.translate(req)
        
        # Return response
        status_code = 200 if response.success else 400
        return jsonify(asdict(response)), status_code
        
    except Exception as e:
        logger.error(f"API error: {e}")
        return jsonify({"error": f"Internal server error: {str(e)}"}), 500

@app.route('/api/braille/standards', methods=['GET'])
def get_standards():
    """Get supported Braille standards"""
    return jsonify({
        "standards": [
            {
                "code": standard.value,
                "name": standard.name.replace('_', ' ').title(),
                "description": f"{standard.name.replace('_', ' ').title()} Braille"
            }
            for standard in BrailleStandard
        ]
    })

@app.route('/api/braille/languages', methods=['GET'])
def get_languages():
    """Get supported languages"""
    language_names = {
        'en': 'English',
        'es': 'Spanish',
        'fr': 'French',
        'de': 'German',
        'it': 'Italian',
        'pt': 'Portuguese'
    }
    
    return jsonify({
        "languages": [
            {
                "code": lang.value,
                "name": language_names.get(lang.value, lang.value.upper())
            }
            for lang in BrailleLanguage
        ]
    })

@app.route('/api/braille/demo', methods=['GET'])
def demo():
    """Demo endpoint with sample translations"""
    demo_texts = [
        "Hello World",
        "The quick brown fox jumps over the lazy dog",
        "Accessibility is important",
        "123 Main Street"
    ]
    
    results = []
    for text in demo_texts:
        req = BrailleTranslationRequest(
            text=text,
            standard=BrailleStandard.GRADE_1.value,
            include_metadata=True
        )
        response = translator.translate(req)
        results.append({
            "original": text,
            "braille": response.result,
            "success": response.success
        })
    
    return jsonify({
        "demo_translations": results,
        "note": "These are sample translations using Grade 1 Braille"
    })

def main():
    """Main entry point for command line usage"""
    if len(sys.argv) < 2:
        print("Usage: python braille_api.py <text> [standard] [reverse]")
        print("Standards: grade1, grade2, computer")
        print("Example: python braille_api.py 'Hello World' grade1")
        print("Example (reverse): python braille_api.py '⠓⠑⠇⠇⠕ ⠺⠕⠗⠇⠙' grade1 true")
        return
    
    text = sys.argv[1]
    standard = sys.argv[2] if len(sys.argv) > 2 else 'grade1'
    reverse = len(sys.argv) > 3 and sys.argv[3].lower() == 'true'
    
    req = BrailleTranslationRequest(
        text=text,
        standard=standard,
        reverse=reverse,
        include_metadata=True
    )
    
    response = translator.translate(req)
    
    if response.success:
        print(f"Original: {response.original_text}")
        print(f"Result: {response.result}")
        print(f"Standard: {response.standard_used}")
        print(f"Characters: {response.character_count}")
        print(f"Braille cells: {response.braille_cell_count}")
        if response.metadata:
            print(f"Method: {response.metadata.get('translation_method', 'unknown')}")
    else:
        print(f"Error: {response.error}")

if __name__ == '__main__':
    if len(sys.argv) > 1 and sys.argv[1] != '--server':
        main()
    else:
        print("Starting Braille Translation API server...")
        print(f"PyBraille available: {PYBRAILLE_AVAILABLE}")
        print("Access the API at: http://localhost:5000")
        print("Health check: http://localhost:5000/health")
        print("Demo: http://localhost:5000/api/braille/demo")
        app.run(debug=True, host='0.0.0.0', port=5000)
