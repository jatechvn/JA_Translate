# lib/modules/ocr_processor.py
# Native Windows OCR trích xuất văn bản từ hình ảnh cho JA Translate

import sys
import json
import os

def ensure_dependencies():
    for mod, pkg in [('winocr', 'winocr'), ('PIL', 'pillow')]:
        try:
            __import__(mod)
        except ImportError:
            import subprocess
            try:
                subprocess.check_call([sys.executable, "-m", "pip", "install", pkg, "--quiet"])
            except Exception:
                pass

def extract_text_from_image(image_path, lang='en'):
    if not os.path.exists(image_path):
        return {'success': False, 'error': f'Image file not found: {image_path}'}
    try:
        ensure_dependencies()
        import winocr
        from PIL import Image

        img = Image.open(image_path)
        # Convert to RGB if palette or mono
        if img.mode not in ('RGB', 'RGBA'):
            img = img.convert('RGBA')

        res = winocr.recognize_pil_sync(img, lang=lang)
        extracted = ''
        if isinstance(res, dict):
            extracted = res.get('text', '')
        elif hasattr(res, 'text'):
            extracted = str(res.text)
        else:
            extracted = str(res)

        return {'success': True, 'text': extracted.strip()}
    except Exception as e:
        return {'success': False, 'error': str(e)}

if __name__ == '__main__':
    # Parse CLI argument
    if len(sys.argv) < 2:
        print(json.dumps({'success': False, 'error': 'No image path provided'}, ensure_ascii=False))
        sys.exit(1)

    path = sys.argv[1]
    lang_arg = sys.argv[2] if len(sys.argv) > 2 else 'en'
    result = extract_text_from_image(path, lang=lang_arg)
    print(json.dumps(result, ensure_ascii=False))
