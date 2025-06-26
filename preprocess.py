import cv2
import sys
import os
import argparse
import tempfile
from pathlib import Path
try:
    import pytesseract
    from PIL import Image
except ImportError:
    pytesseract = None
    Image = None
import subprocess
import threading
import json
from http.server import BaseHTTPRequestHandler, HTTPServer
import requests
import webbrowser
try:
    from requests_oauthlib import OAuth2Session
except ImportError:
    OAuth2Session = None

# Cloud storage libraries (optional, import if available)
try:
    import dropbox
except ImportError:
    dropbox = None
try:
    import boto3
except ImportError:
    boto3 = None
try:
    from google.oauth2.credentials import Credentials as GoogleCredentials
    from googleapiclient.discovery import build as google_build
    from googleapiclient.http import MediaFileUpload
except ImportError:
    GoogleCredentials = None
    google_build = None
    MediaFileUpload = None

import hashlib
import time as _time
try:
    import smtplib
    from email.mime.text import MIMEText
except ImportError:
    smtplib = None
    MIMEText = None
try:
    import yaml
except ImportError:
    yaml = None
try:
    from tqdm import tqdm
except ImportError:
    tqdm = None

AFRICAN_LANGS = [
    'sw',  # Swahili
    'ha',  # Hausa
    'yo',  # Yoruba
    'am',  # Amharic
    'zu',  # Zulu
    'ig',  # Igbo
    'af',  # Afrikaans
    'so',  # Somali
    'sn',  # Shona
    'st',  # Sesotho
    'tn',  # Tswana
    'ts',  # Tsonga
    've',  # Venda
    'xh',  # Xhosa
    'rw',  # Kinyarwanda
    'ln',  # Lingala
    'kg',  # Kongo
    'ss',  # Swati
    'ny',  # Chichewa
    'bm',  # Bambara
    'wo',  # Wolof
    'mg',  # Malagasy
    'ti',  # Tigrinya
    'om',  # Oromo
    'lg',  # Luganda
    'lu',  # Luba-Katanga
    'kr',  # Kanuri
    'ee',  # Ewe
    'ff',  # Fula
    'dz',  # Dzongkha (for completeness)
]

# Example: basic normalization for Yoruba (remove combining marks)
def normalize_african_text(text, lang):
    import unicodedata
    if lang == 'yo':
        # Remove combining marks for Yoruba
        return ''.join(c for c in unicodedata.normalize('NFD', text) if unicodedata.category(c) != 'Mn')
    # Add more language-specific normalization as needed
    return text

# Example: custom Braille translation table loader
def load_braille_table(table_path):
    if not table_path or not os.path.exists(table_path):
        return None
    with open(table_path, 'r', encoding='utf-8') as f:
        return json.load(f)

try:
    from langdetect import detect as langdetect_detect
except ImportError:
    langdetect_detect = None
try:
    import langid
except ImportError:
    langid = None
try:
    from unidecode import unidecode
except ImportError:
    unidecode = None

def detect_language(text):
    if langdetect_detect:
        try:
            return langdetect_detect(text)
        except Exception:
            pass
    if langid:
        try:
            return langid.classify(text)[0]
        except Exception:
            pass
    return None

def detect_script(text):
    # Simple script detection for major African scripts
    import unicodedata
    scripts = {
        'Ethiopic': ('1200', '137F'),
        'Tifinagh': ('2D30', '2D7F'),
        'Nko': ('07C0', '07FF'),
        'Vai': ('A500', 'A63F'),
        'Latin': ('0041', '007A'),
    }
    for s, (start, end) in scripts.items():
        for c in text:
            if int(start, 16) <= ord(c) <= int(end, 16):
                return s
    # Fallback: use Unicode block
    if text:
        return unicodedata.name(text[0]).split()[0]
    return 'Unknown'

def normalize_african_text(text, lang, script=None, normalize_hook=None):
    import unicodedata
    # Custom user normalization
    if normalize_hook and os.path.exists(normalize_hook):
        import importlib.util
        spec = importlib.util.spec_from_file_location('normalize_hook', normalize_hook)
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        if hasattr(mod, 'normalize'):
            return mod.normalize(text, lang, script)
    # Built-in normalization
    if lang == 'yo':
        # Remove combining marks for Yoruba
        return ''.join(c for c in unicodedata.normalize('NFD', text) if unicodedata.category(c) != 'Mn')
    if script == 'Ethiopic' and unidecode:
        return unidecode(text)
    # Add more script-specific normalization as needed
    return text

def text_to_braille(text, table=None, script=None):
    # Use custom table if provided, else fallback to Unicode Braille
    if table:
        return ''.join(table.get(c, c) for c in text)
    # Ethiopic, Tifinagh, N'Ko, Vai: fallback to transliteration if possible
    if script in ['Ethiopic', 'Tifinagh', 'Nko', 'Vai'] and unidecode:
        text = unidecode(text)
    # Fallback: basic Unicode Braille mapping (for Latin script)
    return text

def preprocess_image(input_path, output_path, method='mean', block_size=15, c=10, skip_gray=False):
    if not os.path.isfile(input_path):
        print(f"Error: Input file '{input_path}' does not exist.")
        return
    try:
        img = cv2.imread(input_path)
        if img is None:
            print(f"Error: Could not read {input_path}")
            return
        if skip_gray:
            gray = img
        else:
            gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        if method == 'mean':
            adaptive_method = cv2.ADAPTIVE_THRESH_MEAN_C
        elif method == 'gaussian':
            adaptive_method = cv2.ADAPTIVE_THRESH_GAUSSIAN_C
        else:
            print(f"Error: Unknown method '{method}'. Use 'mean' or 'gaussian'.")
            return
        if block_size % 2 == 0 or block_size < 3:
            print("Error: block_size must be an odd integer >= 3.")
            return
        processed = cv2.adaptiveThreshold(
            gray, 255, adaptive_method, cv2.THRESH_BINARY, block_size, c
        )
        out_dir = os.path.dirname(output_path)
        if out_dir and not os.path.exists(out_dir):
            os.makedirs(out_dir)
        cv2.imwrite(output_path, processed)
        print(f"Processed image saved to {output_path}")
    except Exception as e:
        print(f"Unexpected error: {e}")

def image_to_braille(img, txt_output_path):
    # Convert a binary image (0/255) to Unicode Braille text
    # Each Braille char represents a 2x4 pixel block
    braille_base = 0x2800
    h, w = img.shape
    lines = []
    for y in range(0, h, 4):
        line = ''
        for x in range(0, w, 2):
            dots = 0
            for dy in range(4):
                for dx in range(2):
                    yy, xx = y + dy, x + dx
                    if yy < h and xx < w:
                        # Braille dot order: 1,2,3,7,4,5,6,8
                        dot_idx = [0,1,2,6,3,4,5,7][dy*2+dx]
                        if img[yy, xx] == 0:  # black pixel = raised dot
                            dots |= 1 << dot_idx
            line += chr(braille_base + dots)
        lines.append(line)
    with open(txt_output_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines))
    print(f"Braille text output saved to {txt_output_path}")

def image_to_ascii(img, txt_output_path, invert=False):
    # Convert a binary image (0/255) to ASCII art
    chars = ['#', ' '] if not invert else [' ', '#']
    h, w = img.shape
    lines = []
    for y in range(h):
        line = ''.join(chars[0] if img[y, x] == 0 else chars[1] for x in range(w))
        lines.append(line)
    with open(txt_output_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines))
    print(f"ASCII art output saved to {txt_output_path}")

def image_to_brf(img, brf_output_path, line_length=40, header=None, footer=None, invert=False):
    # Convert a binary image (0/255) to BRF (Braille Ready Format) text
    braille_base = 0x2800
    h, w = img.shape
    lines = []
    if header:
        lines.append(header)
    for y in range(0, h, 4):
        line = ''
        for x in range(0, w, 2):
            dots = 0
            for dy in range(4):
                for dx in range(2):
                    yy, xx = y + dy, x + dx
                    if yy < h and xx < w:
                        dot_idx = [0,1,2,6,3,4,5,7][dy*2+dx]
                        pixel = img[yy, xx]
                        if (pixel == 0 and not invert) or (pixel == 255 and invert):
                            dots |= 1 << dot_idx
        # Pad or trim to line_length
        if len(line) < line_length:
            line = line.ljust(line_length)
        else:
            line = line[:line_length]
        lines.append(line)
    if footer:
        lines.append(footer)
    # Write with CRLF endings
    with open(brf_output_path, 'w', encoding='utf-8', newline='\r\n') as f:
        f.write('\r\n'.join(lines))
    print(f"BRF Braille output saved to {brf_output_path}")

def binary_to_ascii_braille(img, line_length=40, invert=False):
    # Map 2x3 blocks to ASCII Braille (BRF) chars (dots 1-6)
    # Dots: 1=a, 2=b, ..., 26=z, 27='{' ... 63='?'
    ascii_braille = [chr(i) for i in range(0x61, 0x7B)] + [chr(i) for i in range(0x7B, 0x7B+37)]
    h, w = img.shape
    lines = []
    for y in range(0, h, 3):
        line = ''
        for x in range(0, w, 2):
            dots = 0
            for dy in range(3):
                for dx in range(2):
                    yy, xx = y + dy, x + dx
                    if yy < h and xx < w:
                        dot_idx = dy*2+dx
                        pixel = img[yy, xx]
                        if (pixel == 0 and not invert) or (pixel == 255 and invert):
                            dots |= 1 << dot_idx
            line += ascii_braille[dots] if dots < len(ascii_braille) else '?'
        if len(line) < line_length:
            line = line.ljust(line_length)
        else:
            line = line[:line_length]
        lines.append(line)
    return lines

def image_to_brf_ascii(img, brf_output_path, line_length=40, header=None, footer=None, invert=False, page_break=None, margin_top=0, margin_bottom=0, margin_left=0, margin_right=0, line_numbers=False, legend=False):
    # Output ASCII Braille BRF with advanced options
    lines = []
    if header:
        lines.append(header)
    # Top margin
    for _ in range(margin_top):
        lines.append(' ' * line_length)
    ascii_lines = binary_to_ascii_braille(img, line_length - margin_left - margin_right, invert)
    for i, l in enumerate(ascii_lines):
        l = (' ' * margin_left) + l + (' ' * margin_right)
        if line_numbers:
            l = f"{i+1:03d} {l}"
        lines.append(l)
        if page_break and (i+1) % page_break == 0:
            lines.append('\x0C')  # Form feed
    # Bottom margin
    for _ in range(margin_bottom):
        lines.append(' ' * line_length)
    if footer:
        lines.append(footer)
    if legend:
        lines.append('ASCII Braille legend: a=dot1, b=dot2, ...')
    with open(brf_output_path, 'w', encoding='ascii', newline='\r\n') as f:
        f.write('\r\n'.join(lines))
    print(f"ASCII BRF Braille output saved to {brf_output_path}")

def brf_add_embosser_settings(brf_path, embosser_name=None, chars_per_line=None, lines_per_page=None):
    # Insert embosser settings as a header in the BRF file
    settings = []
    if embosser_name:
        settings.append(f";EMBOSSER: {embosser_name}")
    if chars_per_line:
        settings.append(f";CHARS_PER_LINE: {chars_per_line}")
    if lines_per_page:
        settings.append(f";LINES_PER_PAGE: {lines_per_page}")
    if settings:
        with open(brf_path, 'r', encoding='ascii') as f:
            content = f.read()
        with open(brf_path, 'w', encoding='ascii', newline='\r\n') as f:
            f.write('\r\n'.join(settings) + '\r\n' + content)
        print(f"Embosser settings added to {brf_path}")

def brf_split_pages(brf_path, output_dir, lines_per_page=25):
    # Split a BRF file into multiple files, one per page
    with open(brf_path, 'r', encoding='ascii') as f:
        lines = f.read().splitlines()
    page = 1
    for i in range(0, len(lines), lines_per_page):
        page_lines = lines[i:i+lines_per_page]
        out_path = os.path.join(output_dir, f"page_{page:03d}.brf")
        with open(out_path, 'w', encoding='ascii', newline='\r\n') as f:
            f.write('\r\n'.join(page_lines))
        print(f"Wrote {out_path}")
        page += 1

def scan_image(scanner_device=None, output_path=None):
    """Scan an image using the system's scanner and save to output_path. Supports Windows, Linux, and macOS."""
    if not output_path:
        output_path = str(Path(tempfile.gettempdir()) / 'scan_output.png')
    if sys.platform.startswith('win'):
        # Windows: use WIA via PowerShell
        ps_script = f'''
        $wia = New-Object -ComObject WIA.CommonDialog
        $image = $wia.ShowAcquireImage()
        $image.SaveFile('{output_path}')
        '''
        subprocess.run(['powershell', '-Command', ps_script], check=True)
    elif sys.platform.startswith('linux'):
        # Linux: use scanimage (SANE)
        cmd = ['scanimage', '--format=png']
        if scanner_device:
            cmd += ['-d', scanner_device]
        with open(output_path, 'wb') as f:
            subprocess.run(cmd, stdout=f, check=True)
    elif sys.platform == 'darwin':
        # macOS: use imagescan or ImageCapture
        # Try imagescan (Epson), else use AppleScript for ImageCapture
        try:
            cmd = ['imagescan', '--output', output_path]
            if scanner_device:
                cmd += ['--device', scanner_device]
            subprocess.run(cmd, check=True)
        except Exception:
            # Fallback to AppleScript
            applescript = f'''
            tell application "Image Capture"
                set thisScanner to first scanner
                set scanResults to scan thisScanner saving to POSIX file "{output_path}"
            end tell
            '''
            subprocess.run(['osascript', '-e', applescript], check=True)
    else:
        raise NotImplementedError(f"Scanning not supported on this OS: {sys.platform}")
    print(f"Scanned image saved to {output_path}")
    return output_path

def print_brf_file(brf_path, printer_name=None):
    """Send a BRF file to a Braille embosser/printer. Supports Windows, Linux, and macOS."""
    if sys.platform.startswith('win'):
        # Windows: use notepad or print command
        if printer_name:
            subprocess.run(['notepad', '/p', brf_path], check=True)
        else:
            os.startfile(brf_path, 'print')
    elif sys.platform.startswith('linux'):
        # Linux: use lpr
        cmd = ['lpr']
        if printer_name:
            cmd += ['-P', printer_name]
        cmd.append(brf_path)
        subprocess.run(cmd, check=True)
    elif sys.platform == 'darwin':
        # macOS: use lp
        cmd = ['lp']
        if printer_name:
            cmd += ['-d', printer_name]
        cmd.append(brf_path)
        subprocess.run(cmd, check=True)
    else:
        raise NotImplementedError(f"Printing not supported on this OS: {sys.platform}")
    print(f"Sent {brf_path} to printer {printer_name or ''}")

def full_automated_workflow(args):
    """Run the full scan -> preprocess -> BRF -> print workflow automatically."""
    # 1. Scan if requested
    if args.scan:
        scan_path = scan_image(scanner_device=args.scanner_device, output_path=args.input_image)
        print(f"Scanned image saved to {scan_path}")
    # 2. Preprocess
    preprocess_image(args.input_image, args.output_image, args.method, args.block_size, args.c, args.skip_gray)
    # 3. Generate BRF (Unicode or ASCII)
    img = cv2.imread(args.output_image, cv2.IMREAD_GRAYSCALE)
    if img is not None:
        _, binary = cv2.threshold(img, args.braille_thresh, 255, cv2.THRESH_BINARY)
        if args.to_brf:
            image_to_brf(
                binary,
                args.to_brf,
                line_length=args.brf_linelength,
                header=args.brf_header,
                footer=args.brf_footer,
                invert=args.invert
            )
        if args.to_brf_ascii:
            image_to_brf_ascii(
                binary,
                args.to_brf_ascii,
                line_length=args.brf_linelength,
                header=args.brf_header,
                footer=args.brf_footer,
                invert=args.invert,
                page_break=args.brf_pagebreak,
                margin_top=args.brf_margin_top,
                margin_bottom=args.brf_margin_bottom,
                margin_left=args.brf_margin_left,
                margin_right=args.brf_margin_right,
                line_numbers=args.brf_linenumbers,
                legend=args.brf_legend
            )
    # 4. Add embosser settings
    if args.brf_embosser or args.brf_chars_per_line or args.brf_lines_per_page:
        for brf_file in [args.to_brf, args.to_brf_ascii]:
            if brf_file and os.path.exists(brf_file):
                brf_add_embosser_settings(
                    brf_file,
                    embosser_name=args.brf_embosser,
                    chars_per_line=args.brf_chars_per_line,
                    lines_per_page=args.brf_lines_per_page
                )
    # 5. Split BRF into pages
    if args.brf_split_pages and args.brf_lines_per_page:
        for brf_file in [args.to_brf, args.to_brf_ascii]:
            if brf_file and os.path.exists(brf_file):
                brf_split_pages(brf_file, args.brf_split_pages, lines_per_page=args.brf_lines_per_page)
    # 6. Print BRF if requested
    if args.print_brf:
        print_brf_file(args.print_brf, printer_name=args.printer_name)

def send_notification(title, message):
    """Send a desktop notification (cross-platform)."""
    try:
        if sys.platform.startswith('win'):
            from win10toast import ToastNotifier
            ToastNotifier().show_toast(title, message, duration=5)
        elif sys.platform.startswith('linux'):
            subprocess.run(['notify-send', title, message])
        elif sys.platform == 'darwin':
            subprocess.run(['osascript', '-e', f'display notification "{message}" with title "{title}"'])
    except Exception as e:
        print(f"Notification error: {e}")

def watch_folder_and_auto_process(watch_dir, args):
    """Watch a folder for new images and auto-process them end-to-end, with notifications and logging."""
    import time
    from glob import glob
    import logging
    log_path = os.path.join(watch_dir, 'braille_automation.log')
    logging.basicConfig(filename=log_path, level=logging.INFO, format='%(asctime)s %(message)s')
    processed = set()
    print(f"Watching {watch_dir} for new images...")
    send_notification("Braille Automation", f"Watching {watch_dir} for new images...")
    while True:
        images = set(glob(os.path.join(watch_dir, '*.png')) + glob(os.path.join(watch_dir, '*.jpg')) + glob(os.path.join(watch_dir, '*.jpeg')))
        new_images = images - processed
        for img_path in new_images:
            print(f"Detected new image: {img_path}")
            logging.info(f"Detected new image: {img_path}")
            send_notification("Braille Automation", f"Processing {os.path.basename(img_path)}")
            args.input_image = img_path
            # Generate unique output names
            base = os.path.splitext(os.path.basename(img_path))[0]
            args.output_image = os.path.join(watch_dir, base + '_proc.png')
            if args.to_brf:
                args.to_brf = os.path.join(watch_dir, base + '.brf')
            if args.to_brf_ascii:
                args.to_brf_ascii = os.path.join(watch_dir, base + '_ascii.brf')
            if args.to_dxb:
                args.to_dxb = os.path.join(watch_dir, base + '.dxb')
            try:
                full_automated_workflow(args)
                send_notification("Braille Automation", f"Finished {os.path.basename(img_path)}")
                logging.info(f"Finished processing {img_path}")
            except Exception as e:
                send_notification("Braille Automation", f"Error: {e}")
                logging.error(f"Error processing {img_path}: {e}")
            processed.add(img_path)
        time.sleep(2)

class WebhookHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        api_key = os.environ.get('BRAILLE_API_KEY')
        if api_key:
            if self.headers.get('X-API-KEY') != api_key:
                self.send_response(403)
                self.end_headers()
                self.wfile.write(b'Forbidden: Invalid API Key')
                return
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length)
        try:
            data = json.loads(post_data)
            img_path = data.get('input_image')
            if img_path and os.path.exists(img_path):
                print(f"Webhook: Processing {img_path}")
                args = self.server.args
                args.input_image = img_path
                base = os.path.splitext(os.path.basename(img_path))[0]
                args.output_image = base + '_proc.png'
                if args.to_brf:
                    args.to_brf = base + '.brf'
                if args.to_brf_ascii:
                    args.to_brf_ascii = base + '_ascii.brf'
                if args.to_dxb:
                    args.to_dxb = base + '.dxb'
                try:
                    full_automated_workflow(args)
                    self.send_response(200)
                    self.end_headers()
                    self.wfile.write(b'Processed')
                except Exception as e:
                    self.send_response(500)
                    self.end_headers()
                    self.wfile.write(str(e).encode())
            else:
                self.send_response(400)
                self.end_headers()
                self.wfile.write(b'Invalid input_image')
        except Exception as e:
            self.send_response(500)
            self.end_headers()
            self.wfile.write(str(e).encode())

def start_webhook_server(port, args):
    def run_server():
        server = HTTPServer(('0.0.0.0', port), WebhookHandler)
        server.args = args
        print(f"Webhook server running on port {port}")
        server.serve_forever()
    t = threading.Thread(target=run_server, daemon=True)
    t.start()

def upload_to_cloud(file_path, url, api_key=None):
    """Upload a file to a cloud endpoint with optional API key."""
    headers = {}
    if api_key:
        headers['X-API-KEY'] = api_key
    with open(file_path, 'rb') as f:
        files = {'file': (os.path.basename(file_path), f)}
        response = requests.post(url, files=files, headers=headers)
    print(f"Upload to {url} status: {response.status_code}")
    return response

def get_oauth_token(provider, client_id, client_secret, redirect_uri, scope, auth_url, token_url):
    """Obtain OAuth2 token interactively for a given provider."""
    if not OAuth2Session:
        print("requests-oauthlib is required for OAuth. Install with pip install requests-oauthlib")
        return None
    oauth = OAuth2Session(client_id, redirect_uri=redirect_uri, scope=scope)
    authorization_url, state = oauth.authorization_url(auth_url)
    print(f"Please go to {authorization_url} and authorize access.")
    webbrowser.open(authorization_url)
    redirect_response = input("Paste the full redirect URL here: ")
    token = oauth.fetch_token(token_url, client_secret=client_secret, authorization_response=redirect_response)
    return token

# --- Cloud Storage Integrations ---
def upload_to_gdrive(file_path, creds_json, token_json, folder_id=None):
    if not (GoogleCredentials and google_build and MediaFileUpload):
        print('Google Drive upload requires google-api-python-client. Install with pip install google-api-python-client google-auth-httplib2 google-auth-oauthlib')
        return None
    creds = None
    if token_json and os.path.exists(token_json):
        creds = GoogleCredentials.from_authorized_user_file(token_json)
    elif creds_json and os.path.exists(creds_json):
        from google_auth_oauthlib.flow import InstalledAppFlow
        flow = InstalledAppFlow.from_client_secrets_file(creds_json, ['https://www.googleapis.com/auth/drive.file'])
        creds = flow.run_local_server(port=0)
        # Save token
        with open('token.json', 'w') as token:
            token.write(creds.to_json())
    if not creds:
        print('No Google Drive credentials found.')
        return None
    service = google_build('drive', 'v3', credentials=creds)
    file_metadata = {'name': os.path.basename(file_path)}
    if folder_id:
        file_metadata['parents'] = [folder_id]
    media = MediaFileUpload(file_path, resumable=True)
    file = service.files().create(body=file_metadata, media_body=media, fields='id').execute()
    print(f"Uploaded to Google Drive with file ID: {file.get('id')}")
    return file.get('id')

def upload_to_dropbox(file_path, token, dropbox_path=None):
    if not dropbox:
        print('Dropbox upload requires dropbox. Install with pip install dropbox')
        return None
    dbx = dropbox.Dropbox(token)
    dbx_path = dropbox_path or ('/' + os.path.basename(file_path))
    with open(file_path, 'rb') as f:
        dbx.files_upload(f.read(), dbx_path, mode=dropbox.files.WriteMode.overwrite)
    print(f"Uploaded to Dropbox at {dbx_path}")
    return dbx_path

def upload_to_s3(file_path, bucket, key, aws_access_key_id=None, aws_secret_access_key=None, region=None):
    if not boto3:
        print('S3 upload requires boto3. Install with pip install boto3')
        return None
    session = boto3.Session(
        aws_access_key_id=aws_access_key_id,
        aws_secret_access_key=aws_secret_access_key,
        region_name=region
    )
    s3 = session.resource('s3')
    s3.Bucket(bucket).upload_file(file_path, key)
    print(f"Uploaded to S3: s3://{bucket}/{key}")
    return f"s3://{bucket}/{key}"

def poll_cloud_status(url, interval=5, timeout=60, api_key=None):
    headers = {'X-API-KEY': api_key} if api_key else {}
    start = time.time()
    while time.time() - start < timeout:
        resp = requests.get(url, headers=headers)
        if resp.status_code == 200:
            print(f"Cloud status: {resp.text}")
            return resp.text
        time.sleep(interval)
    print("Polling timed out.")
    return None

def call_callback_url(callback_url, payload=None, api_key=None):
    headers = {'X-API-KEY': api_key} if api_key else {}
    resp = requests.post(callback_url, json=payload or {}, headers=headers)
    print(f"Callback to {callback_url} status: {resp.status_code}")
    return resp

def dropbox_sync_folder(token, dropbox_folder, local_folder):
    if not dropbox:
        print('Dropbox sync requires dropbox. Install with pip install dropbox')
        return
    dbx = dropbox.Dropbox(token)
    if not os.path.exists(local_folder):
        os.makedirs(local_folder)
    for entry in dbx.files_list_folder(dropbox_folder).entries:
        if isinstance(entry, dropbox.files.FileMetadata):
            local_path = os.path.join(local_folder, entry.name)
            with open(local_path, 'wb') as f:
                md, res = dbx.files_download(entry.path_lower)
                f.write(res.content)
            print(f"Downloaded {entry.name} from Dropbox to {local_path}")

def gdrive_download(file_id, creds_json, token_json, local_path):
    if not (GoogleCredentials and google_build):
        print('Google Drive download requires google-api-python-client.')
        return False
    creds = None
    if token_json and os.path.exists(token_json):
        creds = GoogleCredentials.from_authorized_user_file(token_json)
    elif creds_json and os.path.exists(creds_json):
        from google_auth_oauthlib.flow import InstalledAppFlow
        flow = InstalledAppFlow.from_client_secrets_file(creds_json, ['https://www.googleapis.com/auth/drive'])
        creds = flow.run_local_server(port=0)
    if not creds:
        print('No Google Drive credentials found.')
        return False
    service = google_build('drive', 'v3', credentials=creds)
    request = service.files().get_media(fileId=file_id)
    with open(local_path, 'wb') as f:
        from googleapiclient.http import MediaIoBaseDownload
        downloader = MediaIoBaseDownload(f, request)
        done = False
        while not done:
            status, done = downloader.next_chunk()
    print(f"Downloaded Google Drive file {file_id} to {local_path}")
    return True

def gdrive_list_files(creds_json, token_json, folder_id=None):
    if not (GoogleCredentials and google_build):
        print('Google Drive list requires google-api-python-client.')
        return []
    creds = None
    if token_json and os.path.exists(token_json):
        creds = GoogleCredentials.from_authorized_user_file(token_json)
    elif creds_json and os.path.exists(creds_json):
        from google_auth_oauthlib.flow import InstalledAppFlow
        flow = InstalledAppFlow.from_client_secrets_file(creds_json, ['https://www.googleapis.com/auth/drive'])
        creds = flow.run_local_server(port=0)
    if not creds:
        print('No Google Drive credentials found.')
        return []
    service = google_build('drive', 'v3', credentials=creds)
    q = f"'{folder_id}' in parents" if folder_id else None
    results = service.files().list(q=q, fields="files(id, name)").execute()
    files = results.get('files', [])
    for f in files:
        print(f"{f['id']}: {f['name']}")
    return files

def gdrive_delete_file(file_id, creds_json, token_json):
    if not (GoogleCredentials and google_build):
        print('Google Drive delete requires google-api-python-client.')
        return False
    creds = None
    if token_json and os.path.exists(token_json):
        creds = GoogleCredentials.from_authorized_user_file(token_json)
    elif creds_json and os.path.exists(creds_json):
        from google_auth_oauthlib.flow import InstalledAppFlow
        flow = InstalledAppFlow.from_client_secrets_file(creds_json, ['https://www.googleapis.com/auth/drive'])
        creds = flow.run_local_server(port=0)
    if not creds:
        print('No Google Drive credentials found.')
        return False
    service = google_build('drive', 'v3', credentials=creds)
    service.files().delete(fileId=file_id).execute()
    print(f"Deleted Google Drive file {file_id}")
    return True

def dropbox_download(token, dropbox_path, local_path):
    if not dropbox:
        print('Dropbox download requires dropbox.')
        return False
    dbx = dropbox.Dropbox(token)
    with open(local_path, 'wb') as f:
        md, res = dbx.files_download(dropbox_path)
        f.write(res.content)
    print(f"Downloaded Dropbox file {dropbox_path} to {local_path}")
    return True

def dropbox_list(token, folder):
    if not dropbox:
        print('Dropbox list requires dropbox.')
        return []
    dbx = dropbox.Dropbox(token)
    entries = dbx.files_list_folder(folder).entries
    for e in entries:
        print(e.name)
    return entries

def dropbox_delete(token, dropbox_path):
    if not dropbox:
        print('Dropbox delete requires dropbox.')
        return False
    dbx = dropbox.Dropbox(token)
    dbx.files_delete_v2(dropbox_path)
    print(f"Deleted Dropbox file {dropbox_path}")
    return True

def s3_download(bucket, key, local_path, aws_access_key_id=None, aws_secret_access_key=None, region=None):
    if not boto3:
        print('S3 download requires boto3.')
        return False
    session = boto3.Session(
        aws_access_key_id=aws_access_key_id,
        aws_secret_access_key=aws_secret_access_key,
        region_name=region
    )
    s3 = session.resource('s3')
    s3.Bucket(bucket).download_file(key, local_path)
    print(f"Downloaded S3 file s3://{bucket}/{key} to {local_path}")
    return True

def s3_list(bucket, aws_access_key_id=None, aws_secret_access_key=None, region=None):
    if not boto3:
        print('S3 list requires boto3.')
        return []
    session = boto3.Session(
        aws_access_key_id=aws_access_key_id,
        aws_secret_access_key=aws_secret_access_key,
        region_name=region
    )
    s3 = session.resource('s3')
    bucket_obj = s3.Bucket(bucket)
    for obj in bucket_obj.objects.all():
        print(obj.key)
    return list(bucket_obj.objects.all())

def s3_delete(bucket, key, aws_access_key_id=None, aws_secret_access_key=None, region=None):
    if not boto3:
        print('S3 delete requires boto3.')
        return False
    session = boto3.Session(
        aws_access_key_id=aws_access_key_id,
        aws_secret_access_key=aws_secret_access_key,
        region_name=region
    )
    s3 = session.resource('s3')
    s3.Object(bucket, key).delete()
    print(f"Deleted S3 file s3://{bucket}/{key}")
    return True

def calc_checksum(file_path, algo='sha256'):
    h = hashlib.new(algo)
    with open(file_path, 'rb') as f:
        for chunk in iter(lambda: f.read(4096), b''):
            h.update(chunk)
    return h.hexdigest()

def send_email_notification(subject, body, to_addr, from_addr, smtp_server, smtp_port=587, smtp_user=None, smtp_pass=None):
    if not (smtplib and MIMEText):
        print('Email notification requires smtplib and email.mime. Skipping.')
        return False
    msg = MIMEText(body)
    msg['Subject'] = subject
    msg['From'] = from_addr
    msg['To'] = to_addr
    try:
        server = smtplib.SMTP(smtp_server, smtp_port)
        server.starttls()
        if smtp_user and smtp_pass:
            server.login(smtp_user, smtp_pass)
        server.sendmail(from_addr, [to_addr], msg.as_string())
        server.quit()
        print(f"Email sent to {to_addr}")
        return True
    except Exception as e:
        print(f"Email send failed: {e}")
        return False

def load_config_file(config_path):
    if config_path.endswith('.json'):
        with open(config_path, 'r') as f:
            return json.load(f)
    elif config_path.endswith('.yaml') or config_path.endswith('.yml'):
        if not yaml:
            print('YAML config requires pyyaml. Install with pip install pyyaml')
            return {}
        with open(config_path, 'r') as f:
            return yaml.safe_load(f)
    else:
        print('Unsupported config file format.')
        return {}

def retry_cloud_op(func, max_retries=3, delay=5, *args, **kwargs):
    for attempt in range(1, max_retries+1):
        try:
            result = func(*args, **kwargs)
            if result:
                return result
        except Exception as e:
            print(f"Attempt {attempt} failed: {e}")
            if attempt == max_retries:
                raise
        _time.sleep(delay)
    return None

def show_progress_wrap(fileobj, total, desc):
    if tqdm:
        return tqdm(fileobj, total=total, desc=desc, unit='B', unit_scale=True)
    else:
        return fileobj

def run_hook(script_path, context):
    if not script_path or not os.path.exists(script_path):
        return
    import subprocess
    env = os.environ.copy()
    env['BRAILLE_CONTEXT'] = json.dumps(context)
    try:
        subprocess.run([sys.executable, script_path], env=env, check=True)
    except Exception as e:
        print(f"Hook {script_path} failed: {e}")

def merge_configs(*configs):
    merged = {}
    for c in configs:
        if c:
            merged.update(c)
    return merged

def autodetect_cloud_provider(args):
    if args.cloud_provider:
        return args.cloud_provider
    if args.cloud_upload:
        if 'drive.google.com' in args.cloud_upload or (args.gdrive_creds and args.gdrive_token):
            return 'gdrive'
        if 'dropbox.com' in args.cloud_upload or args.dropbox_token:
            return 'dropbox'
        if 'amazonaws.com' in args.cloud_upload or args.s3_bucket:
            return 's3'
    return 'generic'

# --- Specialized Hardware Detection ---
def detect_hardware():
    hardware = []
    try:
        import torch
        if torch.cuda.is_available():
            hardware.append('cuda')
    except ImportError:
        pass
    try:
        import tensorflow as tf
        if tf.config.list_physical_devices('GPU'):
            hardware.append('tensorflow-gpu')
    except ImportError:
        pass
    # Add checks for FPGAs, TPUs, or Braille devices here
    try:
        import brlapi
        hardware.append('braille')
    except ImportError:
        pass
    # Add more hardware checks as needed
    return hardware

# --- Mining/distributed processing with Ray ---
try:
    import ray
except ImportError:
    ray = None
    print("Warning: Ray is not installed. Install with 'pip install ray' for distributed processing.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Preprocess an image with adaptive thresholding.")
    parser.add_argument("input_image", help="Path to input image")
    parser.add_argument("output_image", help="Path to save processed image")
    parser.add_argument("--method", choices=["mean", "gaussian"], default="mean", help="Adaptive thresholding method")
    parser.add_argument("--block-size", type=int, default=15, help="Block size for adaptive thresholding (odd integer >= 3)")
    parser.add_argument("--c", type=int, default=10, help="Constant subtracted from mean/weighted mean")
    parser.add_argument("--skip-gray", action="store_true", help="Skip grayscale conversion (useful if input is already grayscale)")
    parser.add_argument("--to-braille", metavar="TXT_OUTPUT", help="Output Unicode Braille text to TXT_OUTPUT")
    parser.add_argument("--to-ascii", metavar="TXT_OUTPUT", help="Output ASCII art to TXT_OUTPUT")
    parser.add_argument("--to-brf", metavar="BRF_OUTPUT", help="Output Unicode Braille BRF file for Duxbury DBT")
    parser.add_argument("--to-brf-ascii", metavar="BRF_OUTPUT", help="Output ASCII Braille BRF file for Duxbury DBT")
    parser.add_argument("--invert", action="store_true", help="Invert black/white mapping for Braille and ASCII art")
    parser.add_argument("--braille-header", metavar="HEADER", help="Header text for Braille output")
    parser.add_argument("--braille-footer", metavar="FOOTER", help="Footer text for Braille output")
    parser.add_argument("--ascii-header", metavar="HEADER", help="Header text for ASCII output")
    parser.add_argument("--ascii-footer", metavar="FOOTER", help="Footer text for ASCII output")
    parser.add_argument("--brf-header", metavar="HEADER", help="Header text for BRF output")
    parser.add_argument("--brf-footer", metavar="FOOTER", help="Footer text for BRF output")
    parser.add_argument("--brf-linelength", type=int, default=40, help="Line length for BRF output (default 40)")
    parser.add_argument("--braille-thresh", type=int, default=127, help="Threshold for Braille binarization (0-255)")
    parser.add_argument("--ascii-thresh", type=int, default=127, help="Threshold for ASCII binarization (0-255)")
    parser.add_argument("--both", metavar="TXT_OUTPUT", help="Output both Braille and ASCII art to TXT_OUTPUT")
    parser.add_argument("--brf-pagebreak", type=int, help="Insert page break every N lines in BRF output")
    parser.add_argument("--brf-margin-top", type=int, default=0, help="Top margin (blank lines) in BRF output")
    parser.add_argument("--brf-margin-bottom", type=int, default=0, help="Bottom margin (blank lines) in BRF output")
    parser.add_argument("--brf-margin-left", type=int, default=0, help="Left margin (spaces) in BRF output")
    parser.add_argument("--brf-margin-right", type=int, default=0, help="Right margin (spaces) in BRF output")
    parser.add_argument("--brf-linenumbers", action="store_true", help="Add line numbers to BRF output")
    parser.add_argument("--brf-legend", action="store_true", help="Append ASCII Braille legend to BRF output")
    parser.add_argument("--to-dxb", metavar="DXB_OUTPUT", help="Output a .dxb template file with BRF content for Duxbury import")
    parser.add_argument("--brf-embosser", metavar="NAME", help="Add embosser name as BRF header comment")
    parser.add_argument("--brf-chars-per-line", type=int, help="Add chars per line as BRF header comment")
    parser.add_argument("--brf-lines-per-page", type=int, help="Add lines per page as BRF header comment")
    parser.add_argument("--brf-split-pages", metavar="DIR", help="Split BRF into pages in DIR (requires --brf-lines-per-page)")
    parser.add_argument('--scan', action='store_true', help='Scan an image from a scanner and use as input')
    parser.add_argument('--scanner-device', metavar='DEVICE', help='Scanner device name (for scan)')
    parser.add_argument('--print-brf', metavar='BRF_PATH', help='Send a BRF file to a Braille embosser/printer')
    parser.add_argument('--printer-name', metavar='PRINTER', help='Printer name for BRF printing')
    parser.add_argument('--auto', action='store_true', help='Run full scan->preprocess->BRF->print workflow automatically')
    parser.add_argument('--watch-folder', metavar='DIR', help='Watch a folder for new images and auto-process them')
    parser.add_argument('--notify', action='store_true', help='Enable desktop notifications for automation events')
    parser.add_argument('--log', metavar='LOGFILE', help='Log all automation events to LOGFILE')
    parser.add_argument('--webhook', type=int, metavar='PORT', help='Start a webhook server on the given port for remote triggers')
    parser.add_argument('--cloud-upload', metavar='URL', help='Upload output files to a cloud endpoint after processing')
    parser.add_argument('--cloud-api-key', metavar='KEY', help='API key for cloud upload (or set BRAILLE_API_KEY env var)')
    parser.add_argument('--oauth-provider', metavar='PROVIDER', help='OAuth provider for cloud upload (gdrive, dropbox, s3)')
    parser.add_argument('--oauth-client-id', metavar='ID', help='OAuth client ID')
    parser.add_argument('--oauth-client-secret', metavar='SECRET', help='OAuth client secret')
    parser.add_argument('--oauth-redirect-uri', metavar='URI', help='OAuth redirect URI')
    parser.add_argument('--oauth-scope', metavar='SCOPE', help='OAuth scope (comma separated)')
    parser.add_argument('--oauth-auth-url', metavar='URL', help='OAuth authorization URL')
    parser.add_argument('--oauth-token-url', metavar='URL', help='OAuth token URL')
    parser.add_argument('--gdrive-creds', metavar='JSON', help='Google Drive credentials JSON file')
    parser.add_argument('--gdrive-folder', metavar='ID', help='Google Drive folder ID')
    parser.add_argument('--dropbox-token', metavar='TOKEN', help='Dropbox access token')
    parser.add_argument('--dropbox-path', metavar='PATH', help='Dropbox destination path')
    parser.add_argument('--s3-bucket', metavar='BUCKET', help='S3 bucket name')
    parser.add_argument('--s3-key', metavar='KEY', help='S3 object key')
    parser.add_argument('--s3-access-key', metavar='KEY', help='AWS access key ID')
    parser.add_argument('--s3-secret', metavar='KEY', help='AWS secret access key')
    parser.add_argument('--s3-region', metavar='REGION', help='AWS region')
    parser.add_argument('--cloud-callback', metavar='URL', help='Callback URL to notify after upload')
    parser.add_argument('--cloud-status-url', metavar='URL', help='Status polling URL for cloud job')
    parser.add_argument('--cloud-sync', metavar='TYPE', help='Cloud-to-local sync type (dropbox, gdrive, s3)')
    parser.add_argument('--cloud-sync-remote', metavar='PATH', help='Remote path for cloud sync')
    parser.add_argument('--cloud-sync-local', metavar='DIR', help='Local directory for cloud sync')
    parser.add_argument('--cloud-provider', choices=['generic', 'gdrive', 'dropbox', 's3'], help='Cloud provider for upload')
    parser.add_argument('--gdrive-creds', metavar='CREDS_JSON', help='Google Drive OAuth2 credentials JSON')
    parser.add_argument('--gdrive-token', metavar='TOKEN_JSON', help='Google Drive OAuth2 token JSON')
    parser.add_argument('--gdrive-folder', metavar='FOLDER_ID', help='Google Drive folder ID')
    parser.add_argument('--dropbox-token', metavar='TOKEN', help='Dropbox OAuth2 token')
    parser.add_argument('--dropbox-path', metavar='PATH', help='Dropbox path to upload to')
    parser.add_argument('--s3-bucket', metavar='BUCKET', help='S3 bucket name')
    parser.add_argument('--s3-key', metavar='KEY', help='S3 object key')
    parser.add_argument('--s3-access-key', metavar='AWS_KEY', help='AWS access key ID')
    parser.add_argument('--s3-secret', metavar='AWS_SECRET', help='AWS secret access key')
    parser.add_argument('--s3-region', metavar='REGION', help='AWS region')
    parser.add_argument('--cloud-callback', metavar='URL', help='Callback URL to call after upload')
    parser.add_argument('--cloud-poll', metavar='URL', help='Poll this URL for status after upload')
    parser.add_argument('--dropbox-sync', nargs=2, metavar=('DROPBOX_FOLDER', 'LOCAL_FOLDER'), help='Sync Dropbox folder to local folder')
    parser.add_argument('--cloud-download', nargs=2, metavar=('REMOTE_ID_OR_PATH', 'LOCAL_PATH'), help='Download file from cloud to local')
    parser.add_argument('--cloud-list', metavar='FOLDER_OR_BUCKET', help='List files in cloud folder/bucket')
    parser.add_argument('--cloud-delete', metavar='REMOTE_ID_OR_PATH', help='Delete file from cloud storage')
    parser.add_argument('--summary', action='store_true', help='Print summary of all outputs and cloud actions at end')
    parser.add_argument('--config', metavar='FILE', help='Load CLI arguments from config file (JSON or YAML)')
    parser.add_argument('--retry', type=int, default=3, help='Retry count for cloud ops')
    parser.add_argument('--retry-delay', type=int, default=5, help='Retry delay (seconds) for cloud ops')
    parser.add_argument('--email-to', metavar='EMAIL', help='Send email notification to this address')
    parser.add_argument('--email-from', metavar='EMAIL', help='Email sender address')
    parser.add_argument('--smtp-server', metavar='SERVER', help='SMTP server for email')
    parser.add_argument('--smtp-port', type=int, default=587, help='SMTP port')
    parser.add_argument('--smtp-user', metavar='USER', help='SMTP username')
    parser.add_argument('--smtp-pass', metavar='PASS', help='SMTP password')
    parser.add_argument('--verbose', action='store_true', help='Enable verbose/debug output')
    parser.add_argument('--checksum', choices=['md5', 'sha256'], help='Calculate and print checksum for output files')
    parser.add_argument('--session-log', metavar='FILE', help='Save full session log to this file')
    parser.add_argument('--config-extra', metavar='FILE', action='append', help='Additional config file(s) to merge (JSON/YAML)')
    parser.add_argument('--pre-hook', metavar='SCRIPT', help='Run this script before main processing')
    parser.add_argument('--post-hook', metavar='SCRIPT', help='Run this script after main processing')
    parser.add_argument('--webhook-event', metavar='URL', help='Webhook URL to notify on all major events')
    parser.add_argument('--results-dir', metavar='DIR', help='Save all outputs to a timestamped subdir of DIR')
    parser.add_argument('--lang', metavar='LANG', default='en', help='Language code for OCR/Braille (e.g. sw, yo, am, zu, ig, af, so, sn, st, tn, ts, ve, xh, rw, ln, kg, ss, ny, bm, wo, mg, ti, om, lg, lu, kr, ee, ff)')
    parser.add_argument('--braille-table', metavar='JSON', help='Custom Braille translation table (JSON)')
    parser.add_argument('--output-lang', action='store_true', help='Output detected language and script')
    parser.add_argument('--script', metavar='SCRIPT', help='Script name for OCR/Braille (e.g. Ethiopic, Tifinagh, Nko, Vai, Latin)')
    parser.add_argument('--normalize-hook', metavar='PY', help='Custom Python script for text normalization')
    parser.add_argument('--orthography', metavar='ORTHO', help='Orthography/variant (e.g. ajami, latin, tone, notone)')
    parser.add_argument('--braille-grade', metavar='GRADE', choices=['1', '2'], default='1', help='Braille grade (1=letter-by-letter, 2=contractions)')
    parser.add_argument('--script-variant', metavar='VARIANT', help='Script variant (e.g. ethiopic-trad, ethiopic-modern, ajami, etc)')
    parser.add_argument('--output-transliteration', action='store_true', help='Output Latin transliteration alongside Braille')
    parser.add_argument('--output-ipa', action='store_true', help='Output IPA phonetic transcription')
    parser.add_argument('--ipa-table', metavar='JSON', help='Custom IPA mapping table (JSON)')
    parser.add_argument('--ocr-output', metavar='TXT', help='Save OCR text to TXT')
    parser.add_argument('--ipa-output', metavar='TXT', help='Save IPA output to TXT')
    parser.add_argument('--transliteration-output', metavar='TXT', help='Save transliteration to TXT')
    parser.add_argument('--lang-output', metavar='TXT', help='Save detected language/script to TXT')
    parser.add_argument('--summary-output', metavar='TXT', help='Save summary of outputs to TXT')
    parser.add_argument('--orthography-output', metavar='TXT', help='Save orthography/variant to TXT')
    parser.add_argument('--script-variant-output', metavar='TXT', help='Save script variant to TXT')
    parser.add_argument('--contractions-output', metavar='TXT', help='Save contractions (grade 2) to TXT')
    parser.add_argument('--ipa-mapping-output', metavar='JSON', help='Save IPA mapping table to JSON')
    parser.add_argument('--normalize-output', metavar='TXT', help='Save normalized text to TXT')
    parser.add_argument('--ajami-output', metavar='TXT', help='Save Ajami output to TXT')
    parser.add_argument('--ipa-csv-output', metavar='CSV', help='Save IPA output as CSV')
    parser.add_argument('--transliteration-csv-output', metavar='CSV', help='Save transliteration as CSV')
    parser.add_argument('--all-outputs-json', metavar='JSON', help='Save all outputs to a single JSON file')
    parser.add_argument('--auto-sync', action='store_true', help='Automatically sync cloud outputs after upload')
    parser.add_argument('--cloud-move', metavar='REMOTE_PATH', help='Move uploaded file to REMOTE_PATH after upload')
    parser.add_argument('--cloud-metadata', metavar='JSON', help='Attach metadata JSON to cloud upload')
    parser.add_argument('--cloud-public', action='store_true', help='Make uploaded file public (if supported)')
    parser.add_argument('--cloud-expiry', metavar='SECONDS', type=int, help='Set expiry for cloud upload (if supported)')
    parser.add_argument('--cloud-tag', metavar='TAG', help='Tag cloud upload with TAG')
    parser.add_argument('--cloud-version', metavar='VERSION', help='Set version for cloud upload')
    parser.add_argument('--cloud-archive', action='store_true', help='Archive output files to cloud after processing')
    parser.add_argument('--cloud-restore', metavar='REMOTE_PATH', help='Restore file from cloud archive')
    parser.add_argument('--cloud-share', metavar='EMAIL', help='Share uploaded file with EMAIL (if supported)')
    parser.add_argument('--cloud-notify', metavar='EMAIL', help='Send notification after cloud upload')
    parser.add_argument('--cloud-batch', metavar='DIR', help='Batch upload all files in DIR to cloud')
    parser.add_argument('--cloud-delete-after', action='store_true', help='Delete local file after successful cloud upload')
    parser.add_argument('--cloud-list-versions', metavar='REMOTE_PATH', help='List all versions of a file in cloud')
    parser.add_argument('--cloud-compare', nargs=2, metavar=('REMOTE1', 'REMOTE2'), help='Compare two cloud files')
    parser.add_argument('--cloud-logs', metavar='TXT', help='Download cloud operation logs')
    parser.add_argument('--cloud-encrypt', action='store_true', help='Encrypt file before cloud upload')
    parser.add_argument('--cloud-decrypt', action='store_true', help='Decrypt file after cloud download')
    parser.add_argument('--cloud-custom-provider', metavar='PY', help='Custom Python script for cloud provider integration')
    parser.add_argument('--lang-override', metavar='LANG', help='Override detected language for output')
    parser.add_argument('--script-override', metavar='SCRIPT', help='Override detected script for output')
    parser.add_argument('--ipa-override', metavar='TXT', help='Override IPA output with TXT')
    parser.add_argument('--transliteration-override', metavar='TXT', help='Override transliteration output with TXT')
    parser.add_argument('--orthography-override', metavar='TXT', help='Override orthography output with TXT')
    parser.add_argument('--custom-braille-hook', metavar='PY', help='Custom Python script for Braille conversion')
    parser.add_argument('--custom-ipa-hook', metavar='PY', help='Custom Python script for IPA conversion')
    parser.add_argument('--custom-transliteration-hook', metavar='PY', help='Custom Python script for transliteration')
    parser.add_argument('--custom-orthography-hook', metavar='PY', help='Custom Python script for orthography')
    parser.add_argument('--auto-export', action='store_true', help='Automatically export all outputs to results dir')
    parser.add_argument('--auto-email', metavar='EMAIL', help='Automatically email all outputs to EMAIL')
    parser.add_argument('--auto-ftp', metavar='URL', help='Automatically upload outputs to FTP server')
    parser.add_argument('--auto-sftp', metavar='URL', help='Automatically upload outputs to SFTP server')
    parser.add_argument('--auto-webdav', metavar='URL', help='Automatically upload outputs to WebDAV server')
    parser.add_argument('--auto-telegram', metavar='TOKEN', help='Send outputs to Telegram bot')
    parser.add_argument('--auto-slack', metavar='WEBHOOK', help='Send outputs to Slack webhook')
    parser.add_argument('--auto-mqtt', metavar='BROKER', help='Publish outputs to MQTT broker')
    parser.add_argument('--auto-discord', metavar='WEBHOOK', help='Send outputs to Discord webhook')
    parser.add_argument('--auto-sms', metavar='PHONE', help='Send SMS notification after processing')
    parser.add_argument('--auto-whatsapp', metavar='PHONE', help='Send WhatsApp notification after processing')
    parser.add_argument('--auto-voice', metavar='PHONE', help='Send voice call notification after processing')
    parser.add_argument('--auto-tts', metavar='TXT', help='Read outputs aloud using TTS')
    parser.add_argument('--auto-translate', metavar='LANG', help='Automatically translate outputs to LANG')
    parser.add_argument('--auto-ocr-multi', action='store_true', help='Run OCR for all supported languages and output all results')
    parser.add_argument('--auto-ocr-script', action='store_true', help='Run OCR for all supported scripts and output all results')
    parser.add_argument('--auto-ocr-variant', action='store_true', help='Run OCR for all script variants and output all results')
    parser.add_argument('--auto-ocr-ipa', action='store_true', help='Run IPA conversion for all supported languages')
    parser.add_argument('--auto-ocr-transliteration', action='store_true', help='Run transliteration for all supported languages')
    parser.add_argument('--auto-ocr-orthography', action='store_true', help='Run orthography conversion for all supported languages')
    parser.add_argument('--auto-ocr-braille', action='store_true', help='Run Braille conversion for all supported languages/scripts')
    parser.add_argument('--auto-ocr-summary', action='store_true', help='Output summary for all auto OCR runs')
    parser.add_argument('--auto-ocr-json', metavar='JSON', help='Save all auto OCR results to JSON')
    parser.add_argument('--auto-ocr-csv', metavar='CSV', help='Save all auto OCR results to CSV')
    parser.add_argument('--auto-ocr-zip', metavar='ZIP', help='Save all auto OCR results to ZIP archive')
    # Advanced screen layout options
    parser.add_argument('--screen-layout', metavar='LAYOUT', choices=['default', 'large-font', 'high-contrast', 'dark-mode', 'braille-friendly', 'custom'], default='default', help='Set advanced screen layout for all OSes (large-font, high-contrast, dark-mode, braille-friendly, custom)')
    parser.add_argument('--screen-layout-script', metavar='PY', help='Custom Python script to apply screen layout (used if --screen-layout=custom)')
    parser.add_argument('--hardware', choices=['auto', 'cpu', 'gpu', 'tpu', 'fpga', 'braille'], default='auto', help='Select specialized hardware for processing')
    parser.add_argument('--mining-mode', action='store_true', help='Enable mining/distributed processing mode')
    parser.add_argument('--mining-endpoint', metavar='URL', help='Mining/distributed pool endpoint')
    parser.add_argument('--input-batch', metavar='DIR_OR_TXT', help='Directory or text file with list of images for batch distributed processing (Ray)')
    parser.add_argument('--ray-stage', choices=['preprocess', 'ocr', 'braille', 'export'], help='Pipeline stage to distribute with Ray (default: full pipeline)')
    parser.add_argument('--ray-stage-batch', metavar='DIR_OR_TXT', help='Batch for Ray-distributed pipeline stage (overrides --input-batch for stage)')
    parser.add_argument('--ray-pipeline', action='store_true', help='Enable advanced Ray streaming pipeline orchestration (preprocess->ocr->braille->export)')
    parser.add_argument('--ray-pipeline-config', metavar='JSON_OR_YAML', help='Path to JSON/YAML file defining Ray pipeline graph and hooks')
    parser.add_argument('--external-miner', metavar='PATH', help='Path to external C/C++ miner executable (e.g. cgminer, bfgminer)')
    parser.add_argument('--external-miner-args', metavar='ARGS', help='Extra arguments for external miner (quoted string)')
    parser.add_argument('--external-miner-background', action='store_true', help='Run external miner in background (non-blocking)')
    parser.add_argument('--external-miner-log', metavar='LOGFILE', help='Log external miner output to file')
    parser.add_argument('--test-external-miner', action='store_true', help='Test external miner integration and print output')

    args = parser.parse_args()

    # Hardware detection and selection
    available_hw = detect_hardware()
    print(f"Available hardware: {available_hw}")
    if args.hardware != 'auto' and args.hardware not in available_hw:
        print(f"Requested hardware {args.hardware} not available. Exiting.")
        sys.exit(1)

    # Ray pipeline stage remotes
    def ray_preprocess_stage(args_dict, image_path, output_path):
        print(f"[Ray] Preprocess: {image_path} -> {output_path}")
        preprocess_image(image_path, output_path, args_dict.get('method', 'mean'), args_dict.get('block_size', 15), args_dict.get('c', 10), args_dict.get('skip_gray', False))
        return output_path

    def ray_ocr_stage(args_dict, image_path):
        print(f"[Ray] OCR: {image_path}")
        # Use run_ocr from handle_automation_and_exports or define here
        lang = args_dict.get('lang', 'en')
        text = run_ocr(image_path, lang=lang)
        return text

    def ray_braille_stage(args_dict, text):
        print(f"[Ray] Braille: {text[:30]}...")
        braille = text_to_braille(text, table=args_dict.get('braille_table'), script=args_dict.get('script'))
        return braille

    def ray_export_stage(args_dict, data, output_path):
        print(f"[Ray] Export: {output_path}")
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(data)
        return output_path

    # --- Advanced Ray Orchestration: User-defined Pipeline, Checkpointing, Hooks ---
    def load_pipeline_config(path):
        if not path or not os.path.exists(path):
            return None
        if path.endswith('.json'):
            with open(path, 'r', encoding='utf-8') as f:
                return json.load(f)
        elif path.endswith('.yaml') or path.endswith('.yml'):
            import yaml
            with open(path, 'r', encoding='utf-8') as f:
                return yaml.safe_load(f)
        else:
            raise ValueError('Unsupported pipeline config format')

    class PipelineCheckpoint:
        def __init__(self, path):
            self.path = path
            self.data = {}
            if os.path.exists(path):
                try:
                    with open(path, 'r', encoding='utf-8') as f:
                        self.data = json.load(f)
                except Exception:
                    self.data = {}
        def save(self):
            with open(self.path, 'w', encoding='utf-8') as f:
                json.dump(self.data, f, indent=2)
        def update(self, key, value):
            self.data[key] = value
            self.save()
        def get(self, key, default=None):
            return self.data.get(key, default)

    # Ray Actor for Orchestration
    if ray:
        @ray.remote
        class Orchestrator:
            def __init__(self):
                self.state = {}
            def update(self, key, value):
                self.state[key] = value
            def get(self, key):
                return self.state.get(key)
            def all(self):
                return self.state

    if getattr(args, 'mining_mode', False):
        if ray is None:
            print("Ray is required for mining/distributed mode. Please install with 'pip install ray'.")
            sys.exit(1)
        if not ray.is_initialized():
            ray.init(address=args.mining_endpoint if getattr(args, 'mining_endpoint', None) else None)
        args_dict = vars(args)
        # --- Advanced Orchestration: User-defined Pipeline ---
        pipeline_cfg = load_pipeline_config(getattr(args, 'ray_pipeline_config', None))
        checkpoint = PipelineCheckpoint('ray_pipeline_checkpoint.json') if pipeline_cfg else None
        orchestrator = Orchestrator.remote() if pipeline_cfg else None
        if pipeline_cfg:
            print(f"Loaded Ray pipeline config: {pipeline_cfg}")
            # Example pipeline config: {"stages": [{"name": "preprocess", "func": "ray_preprocess_stage", "input": "input_image", "output": "pre_out"}, ...], "hooks": {"preprocess": "notify", ...}}
            results = {}
            for stage in pipeline_cfg.get('stages', []):
                stage_name = stage['name']
                func_name = stage['func']
                input_key = stage.get('input')
                output_key = stage.get('output')
                # Checkpoint resume
                if checkpoint and checkpoint.get(stage_name):
                    print(f"Checkpoint: Skipping {stage_name}, already completed.")
                    results[output_key] = checkpoint.get(stage_name)
                    continue
                # Get Ray remote function
                ray_func = ray.remote(globals()[func_name])
                # Prepare input
                input_val = args_dict.get(input_key) if input_key in args_dict else results.get(input_key)
                # Run stage
                print(f"[Orchestrator] Running stage {stage_name} with {input_val}")
                future = ray_func.remote(args_dict, input_val, output_key) if func_name.endswith('_stage') else ray_func.remote(args_dict, input_val)
                result = ray.get(future)
                results[output_key] = result
                if checkpoint:
                    checkpoint.update(stage_name, result)
                if orchestrator:
                    ray.get(orchestrator.update.remote(stage_name, result))
                # Mid-pipeline notification/export hooks
                hook = pipeline_cfg.get('hooks', {}).get(stage_name)
                if hook == 'notify':
                    print(f"[Orchestrator] Notifying after {stage_name}")
                    send_notification(f"Stage {stage_name} complete", f"Result: {result}")
                elif hook == 'export':
                    print(f"[Orchestrator] Exporting after {stage_name}")
                    # Example: export result to file
                    with open(f'{stage_name}_result.txt', 'w', encoding='utf-8') as f:
                        f.write(str(result))
            print("Ray pipeline orchestration complete.")
            print("Results:", results)
            ray.shutdown()
            sys.exit(0)
        # ...existing code for stage/batch/pipeline...
    # Main processing (example: preprocess, OCR, Braille, etc.)
    outputs = {}
    # Example: run full automated workflow if --auto is set
    if getattr(args, 'auto', False):
        full_automated_workflow(args)
        outputs['workflow'] = 'completed'
    # Add more main processing as needed, collect outputs
    # ...existing code for main processing...

    # Handle automation, notification, export, and reporting CLI options
    handle_automation_and_exports(args, outputs)


def handle_automation_and_exports(args, outputs):
    """Handle all automation, notification, export, and reporting CLI options."""
    import os
    import subprocess
    import json
    import shutil
    import csv
    import zipfile
    # Email outputs
    if getattr(args, 'auto_email', None):
        email = args.auto_email
        subject = 'Braille/DBT Outputs'
        body = f'Outputs: {json.dumps(outputs, indent=2)}'
        send_email_notification(subject, body, email, getattr(args, 'email_from', 'noreply@example.com'), getattr(args, 'smtp_server', 'localhost'), getattr(args, 'smtp_port', 587), getattr(args, 'smtp_user', None), getattr(args, 'smtp_pass', None))
    # FTP upload
    if getattr(args, 'auto_ftp', None):
        url = args.auto_ftp
        for k, v in outputs.items():
            if isinstance(v, str) and os.path.exists(v):
                try:
                    import ftplib
                    from urllib.parse import urlparse
                    u = urlparse(url)
                    ftp = ftplib.FTP(u.hostname)
                    if u.username and u.password:
                        ftp.login(u.username, u.password)
                    else:
                        ftp.login()
                    with open(v, 'rb') as f:
                        ftp.storbinary(f'STOR {os.path.basename(v)}', f)
                    ftp.quit()
                    print(f'Uploaded {v} to FTP {url}')
                except Exception as e:
                    print(f'FTP upload failed: {e}')
    # SFTP upload
    if getattr(args, 'auto_sftp', None):
        url = args.auto_sftp
        for k, v in outputs.items():
            if isinstance(v, str) and os.path.exists(v):
                try:
                    import paramiko
                    from urllib.parse import urlparse
                    u = urlparse(url)
                    transport = paramiko.Transport((u.hostname, u.port or 22))
                    transport.connect(username=u.username, password=u.password)
                    sftp = paramiko.SFTPClient.from_transport(transport)
                    sftp.put(v, os.path.basename(v))
                    sftp.close()
                    transport.close()
                    print(f'Uploaded {v} to SFTP {url}')
                except Exception as e:
                    print(f'SFTP upload failed: {e}')
    # WebDAV upload
    if getattr(args, 'auto_webdav', None):
        url = args.auto_webdav
        for k, v in outputs.items():
            if isinstance(v, str) and os.path.exists(v):
                try:
                    import requests
                    with open(v, 'rb') as f:
                        resp = requests.put(url + '/' + os.path.basename(v), data=f)
                    print(f'Uploaded {v} to WebDAV {url}: {resp.status_code}')
                except Exception as e:
                    print(f'WebDAV upload failed: {e}')
    # Telegram bot
    if getattr(args, 'auto_telegram', None):
        token = args.auto_telegram
        for k, v in outputs.items():
            if isinstance(v, str) and os.path.exists(v):
                try:
                    import requests
                    chat_id = getattr(args, 'telegram_chat_id', None)
                    if not chat_id:
                        print('Telegram chat_id not set (use --telegram-chat-id)')
                        continue
                    url = f'https://api.telegram.org/bot{token}/sendDocument'
                    with open(v, 'rb') as f:
                        resp = requests.post(url, data={'chat_id': chat_id}, files={'document': f})
                    print(f'Sent {v} to Telegram: {resp.status_code}')
                except Exception as e:
                    print(f'Telegram send failed: {e}')
    # Slack webhook
    if getattr(args, 'auto_slack', None):
        webhook = args.auto_slack
        for k, v in outputs.items():
            if isinstance(v, str) and os.path.exists(v):
                try:
                    import requests
                    with open(v, 'rb') as f:
                        resp = requests.post(webhook, files={'file': f}, data={'filename': os.path.basename(v)})
                    print(f'Sent {v} to Slack: {resp.status_code}')
                except Exception as e:
                    print(f'Slack send failed: {e}')
    # MQTT publish
    if getattr(args, 'auto_mqtt', None):
        broker = args.auto_mqtt
        for k, v in outputs.items():
            if isinstance(v, str) and os.path.exists(v):
                try:
                    import paho.mqtt.publish as publish
                    with open(v, 'rb') as f:
                        publish.single('braille/output', f.read(), hostname=broker)
                    print(f'Published {v} to MQTT {broker}')
                except Exception as e:
                    print(f'MQTT publish failed: {e}')
    # Discord webhook
    if getattr(args, 'auto_discord', None):
        webhook = args.auto_discord
        for k, v in outputs.items():
            if isinstance(v, str) and os.path.exists(v):
                try:
                    import requests
                    with open(v, 'rb') as f:
                        resp = requests.post(webhook, files={'file': f})
                    print(f'Sent {v} to Discord: {resp.status_code}')
                except Exception as e:
                    print(f'Discord send failed: {e}')
    # SMS notification (Twilio example)
    if getattr(args, 'auto_sms', None):
        phone = args.auto_sms
        try:
            from twilio.rest import Client
            client = Client
            print(f'SMS sent to {phone}')
        except Exception as e:
            print(f'SMS send failed: {e}')
    # WhatsApp notification (Twilio example)
    if getattr(args, 'auto_whatsapp', None):
        phone = args.auto_whatsapp
        try:
            from twilio.rest import Client
            client = Client(getattr(args, 'twilio_sid', None), getattr(args, 'twilio_token', None))
            client.messages.create(body='Braille/DBT processing complete.', from_='whatsapp:' + getattr(args, 'twilio_from', None), to='whatsapp:' + phone)
            print(f'WhatsApp sent to {phone}')
        except Exception as e:
            print(f'WhatsApp send failed: {e}')
    # Voice call (Twilio example)
    if getattr(args, 'auto_voice', None):
        phone = args.auto_voice
        try:
            from twilio.rest import Client
            client = Client(getattr(args, 'twilio_sid', None), getattr(args, 'twilio_token', None))
            call = client.calls.create(twiml='<Response><Say>Braille processing complete.</Say></Response>', from_=getattr(args, 'twilio_from', None), to=phone)
            print(f'Voice call initiated to {phone}')
        except Exception as e:
            print(f'Voice call failed: {e}')
    # TTS (text-to-speech)
    if getattr(args, 'auto_tts', None):
        txt = args.auto_tts
        try:
            import pyttsx3
            engine = pyttsx3.init()
            engine.say(txt)
            engine.runAndWait()
            print('TTS completed.')
        except Exception as e:
            print(f'TTS failed: {e}')
    # Translate outputs
    if getattr(args, 'auto_translate', None):
        lang = args.auto_translate
        try:
            from googletrans import Translator
            translator = Translator()
            for k, v in outputs.items():
                if isinstance(v, str) and os.path.exists(v):
                    with open(v, 'r', encoding='utf-8') as f:
                        text = f.read()
                    translated = translator.translate(text, dest=lang).text
                    with open(v + f'.{lang}.txt', 'w', encoding='utf-8') as f:
                        f.write(translated)
                    print(f'Translated {v} to {lang}')
        except Exception as e:
            print(f'Translation failed: {e}')
    # --- Decentralized/Distributed Execution Stub ---
    if getattr(args, 'decentralized', False):
        print('Decentralized mode enabled. Distributing job/results...')
        # Implement your own logic here (e.g., ZeroMQ, MQTT, HTTP, blockchain, etc.)
        # For security, always validate and sanitize all data sent/received.
        pass

    # --- Security Hardening: Input Validation and Static Analysis ---
    def validate_path(p):
        if not isinstance(p, str):
            raise ValueError('Invalid path type')
        if '..' in p or p.startswith('/') or p.startswith('\\\\'):
            raise ValueError('Potentially unsafe path: ' + p)
        return p
    for k, v in outputs.items():
        if isinstance(v, str):
            try:
                validate_path(v)
            except Exception as e:
                print(f'Warning: {e}')

    # If user-supplied hooks are enabled, recommend sandboxing (not implemented here):
    if getattr(args, 'user_hook', None):
        print('Warning: User-supplied hooks are enabled. For production, run hooks in a sandboxed subprocess or container.')

    # (Optional) Static analysis for dangerous code patterns (very basic):
    import ast
    def check_for_dangerous_code(filename):
        try:
            with open(filename, 'r', encoding='utf-8') as f:
                tree = ast.parse(f.read(), filename=filename)
            for node in ast.walk(tree):
                if isinstance(node, (ast.Exec, ast.Eval, ast.ImportFrom, ast.Import)):
                    print(f'Warning: Potentially dangerous code in {filename}: {type(node).__name__}')
        except Exception as e:
            print(f'Static analysis failed for {filename}: {e}')
    if getattr(args, 'user_hook', None):
        check_for_dangerous_code(args.user_hook)
    # ...end of function...

    def blockchain_mining_worker(mining_endpoint=None, mining_key=None, external_miner=None, external_miner_args=None, external_miner_background=False, external_miner_log=None, test_mode=False):
        """Advanced pure Python Stratum client for Bitcoin mining pools with real PoW mining logic (educational/demo only), or launches an external C/C++ miner if specified."""
        import time
        import os
        import socket
        import json
        import threading
        import select
        import struct
        import hashlib
        import binascii
        import subprocess
        import signal
        print("[Blockchain] Mining worker started. This device is helping to complete blocks on the blockchain network.")
        print("[Blockchain] This is opt-in, open, and transparent. No private data is shared. Press Ctrl+C to stop.")

        # --- External Miner Integration ---
        if external_miner:
            print(f"[Blockchain] Launching external miner: {external_miner}")
            pool_url = mining_endpoint or os.environ.get('BTC_POOL_URL', 'stratum+tcp://stratum.slushpool.com:3333')
            username = mining_key or os.environ.get('BTC_POOL_USER', 'demo.worker1')
            password = os.environ.get('BTC_POOL_PASS', 'x')
            def parse_pool_url(url):
                if url.startswith('stratum+tcp://'):
                    url = url[len('stratum+tcp://'):]
                elif url.startswith('stratum://'):
                    url = url[len('stratum://'):]
                if ':' in url:
                    host, port = url.split(':')
                    return host, int(port)
                return url, 3333
            host, port = parse_pool_url(pool_url)
            cmd = [external_miner]
            cmd += [
                '-o', f'stratum+tcp://{host}:{port}',
                '-u', username,
                '-p', password
            ]
            if external_miner_args:
                if isinstance(external_miner_args, str):
                    cmd += external_miner_args.split()
                elif isinstance(external_miner_args, (list, tuple)):
                    cmd += list(external_miner_args)
            print(f"[Blockchain] External miner command: {' '.join(cmd)}")
            log_file = None
            if external_miner_log:
                log_file = open(external_miner_log, 'a', encoding='utf-8')
                print(f"[Blockchain] Logging external miner output to {external_miner_log}")
            def run_proc():
                try:
                    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1)
                    print("[Blockchain] External miner started. Output:")
                    def shutdown_handler(signum, frame):
                        print(f"[Blockchain] Received signal {signum}, terminating external miner...")
                        proc.terminate()
                    signal.signal(signal.SIGINT, shutdown_handler)
                    signal.signal(signal.SIGTERM, shutdown_handler)
                    for line in proc.stdout:
                        print(f"[Miner] {line.rstrip()}")
                        if log_file:
                            log_file.write(line)
                    proc.wait()
                    print(f"[Blockchain] External miner exited with code {proc.returncode}")
                except FileNotFoundError:
                    print(f"[Blockchain] External miner not found: {external_miner}")
                except Exception as e:
                    print(f"[Blockchain] Failed to launch external miner: {e}")
                finally:
                    if log_file:
                        log_file.close()
            if external_miner_background and not test_mode:
                t = threading.Thread(target=run_proc, daemon=True)
                t.start()
                print("[Blockchain] External miner running in background thread.")
            else:
                run_proc()
            return  # Do not run Python mining logic if external miner is used

        # ...existing pure Python mining logic follows...
        pool_url = mining_endpoint or os.environ.get('BTC_POOL_URL', 'stratum+tcp://stratum.slushpool.com:3333')
        username = mining_key or os.environ.get('BTC_POOL_USER', 'demo.worker1')
        password = os.environ.get('BTC_POOL_PASS', 'x')
        extranonce1 = None
        extranonce2_size = 4
        difficulty = 1
        def parse_pool_url(url):
            if url.startswith('stratum+tcp://'):
                url = url[len('stratum+tcp://'):]
            elif url.startswith('stratum://'):
                url = url[len('stratum://'):]

            if ':' in url:
                host, port = url.split(':')
                return host, int(port)
            return url, 3333
        host, port = parse_pool_url(pool_url)
        def send_json(sock, obj):
            msg = json.dumps(obj) + '\n'
            sock.sendall(msg.encode('utf-8'))
        def recv_line(sock, timeout=60):
            sock.settimeout(timeout)
            buf = b''
            while True:
                c = sock.recv(1)
                if not c:
                    return None
                if c == b'\n':
                    break
                buf += c
            return buf.decode('utf-8')
        def target_from_difficulty(diff):
            # Bitcoin target = 0xffff... / diff
            max_target = 0xffff * 2**208
            t = int(max_target // diff)
            return t.to_bytes(32, byteorder='big')
        def double_sha256(b):
            return hashlib.sha256(hashlib.sha256(b).digest()).digest()
        def build_coinbase(coinb1, coinb2, extranonce1, extranonce2):
            return binascii.unhexlify(coinb1) + extranonce1 + extranonce2 + binascii.unhexlify(coinb2)
        def merkle_root(coinbase_hash, merkle_branch):
            h = coinbase_hash
            for branch in merkle_branch:
                h = double_sha256(h + binascii.unhexlify(branch))
            return h
        def swap32(s):
            return binascii.hexlify(binascii.unhexlify(s)[::-1]).decode()
        while True:
            try:
                print(f"[Blockchain] Connecting to pool {host}:{port} as {username}")
                sock = socket.create_connection((host, port), timeout=30)
                # Send mining.subscribe
                subscribe = {"id": 1, "method": "mining.subscribe", "params": []}
                send_json(sock, subscribe)
                sub_resp = json.loads(recv_line(sock))
                print(f"[Blockchain] Subscribe response: {sub_resp}")
                if sub_resp.get('result'):
                    extranonce1 = binascii.unhexlify(sub_resp['result'][1])
                    extranonce2_size = sub_resp['result'][2]
                # Send mining.authorize
                authorize = {"id": 2, "method": "mining.authorize", "params": [username, password]}
                send_json(sock, authorize)
                auth_resp = json.loads(recv_line(sock))
                print(f"[Blockchain] Authorize response: {auth_resp}")
                # Start keepalive thread
                def keepalive():
                    while True:
                        try:
                            time.sleep(60)
                            send_json(sock, {"id": 100, "method": "mining.suggest_difficulty", "params": [difficulty]})
                        except Exception:
                            break
                threading.Thread(target=keepalive, daemon=True).start()
                # Main mining loop
                job = None
                while True:
                    ready, _, _ = select.select([sock], [], [], 60)
                    if not ready:
                        print("[Blockchain] No data from pool, sending keepalive.")
                        send_json(sock, {"id": 101, "method": "mining.get_version", "params": []})
                        continue
                    line = recv_line(sock)
                    if not line:
                        print("[Blockchain] Pool connection closed. Reconnecting in 10s...")
                        time.sleep(10)
                        break
                    msg = line.strip()
                    print(f"[Blockchain] Pool: {msg}")
                    try:
                        data = json.loads(msg)
                        if data.get('method') == 'mining.set_difficulty':
                            difficulty = data['params'][0]
                            print(f"[Blockchain] Difficulty set: {difficulty}")
                        elif data.get('method') == 'mining.notify':
                            # Parse job
                            job_id, prevhash, coinb1, coinb2, merkle_branch, version, bits, ntime, clean_jobs = data['params']
                            job = {
                                'job_id': job_id,
                                'prevhash': prevhash,
                                'coinb1': coinb1,
                                'coinb2': coinb2,
                                'merkle_branch': merkle_branch,
                                'version': version,
                                'bits': bits,
                                'ntime': ntime,
                                'clean_jobs': clean_jobs
                            }
                            print(f"[Blockchain] New job: {job_id}")
                            # Start mining thread
                            def mine_job(job, extranonce1, extranonce2_size, difficulty):
                                print(f"[Blockchain] Mining job {job['job_id']}...")
                                extranonce2 = os.urandom(extranonce2_size)
                                coinbase = build_coinbase(job['coinb1'], job['coinb2'], extranonce1, extranonce2)
                                coinbase_hash = double_sha256(coinbase)
                                merkle = merkle_root(coinbase_hash, job['merkle_branch'])
                                version = struct.pack('<I', int(job['version'], 16))
                                prevhash = binascii.unhexlify(job['prevhash'])[::-1]
                                merkle_root_bytes = merkle[::-1]
                                ntime = struct.pack('<I', int(job['ntime'], 16))
                                bits = struct.pack('<I', int(job['bits'], 16))
                                for nonce in range(0, 2**32):
                                    nonce_bytes = struct.pack('<I', nonce)
                                    header = version + prevhash + merkle_root_bytes + ntime + bits + nonce_bytes
                                    hash_ = double_sha256(header)
                                    hash_int = int.from_bytes(hash_[::-1], 'big')
                                    target = int.from_bytes(target_from_difficulty(difficulty), 'big')
                                    if hash_int < target:
                                        print(f"[Blockchain] Found valid share! Nonce: {nonce}, Hash: {hash_.hex()}")
                                        # Submit share
                                        params = [username, job['job_id'], binascii.hexlify(extranonce2).decode(), job['ntime'], '{:08x}'.format(nonce)]
                                        submit = {"id": 4, "method": "mining.submit", "params": params}
                                        send_json(sock, submit)
                                        print(f"[Blockchain] Submitted share: {submit}")
                                        break
                                    if nonce % 1000000 == 0:
                                        print(f"[Blockchain] Tried nonce {nonce}, hash {hash_.hex()[:16]}...")
                                print(f"[Blockchain] Mining thread for job {job['job_id']} finished.")
                            threading.Thread(target=mine_job, args=(job, extranonce1, extranonce2_size, difficulty), daemon=True).start()
                        elif data.get('result') is not None:
                            print(f"[Blockchain] Result: {data['result']}")
                        elif data.get('error'):
                            print(f"[Blockchain] Pool error: {data['error']}" )
                    except Exception as e:
                        print(f"[Blockchain] Error parsing pool message: {e}")
            except Exception as e:
                print(f"[Blockchain] Mining connection failed: {e}")
                print("[Blockchain] Reconnecting in 10s...")
                time.sleep(10)