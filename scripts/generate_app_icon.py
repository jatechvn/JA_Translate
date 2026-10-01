import os
from PIL import Image
import numpy as np

def generate_icons():
    logo_path = 'assets/logo.png'
    if not os.path.exists(logo_path):
        print(f"Error: {logo_path} not found.")
        return

    im = Image.open(logo_path)
    data = np.array(im)
    # Filter out stray pixels with low alpha
    data[:, :, 3][data[:, :, 3] <= 2] = 0
    im_clean = Image.fromarray(data)

    bbox = im_clean.getbbox()
    cropped = im_clean.crop(bbox)
    w, h = cropped.size

    # Square canvas with 10% padding
    max_dim = max(w, h)
    canvas_size = int(max_dim * 1.12)
    square_im = Image.new('RGBA', (canvas_size, canvas_size), (0, 0, 0, 0))
    offset = ((canvas_size - w) // 2, (canvas_size - h) // 2)
    square_im.paste(cropped, offset)

    # Generate square png (512x512)
    square_png = square_im.resize((512, 512), Image.Resampling.LANCZOS)
    square_png.save('assets/app_icon.png')

    # Generate multi-res ico for Windows
    icon_sizes = [(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
    target_ico_1 = 'windows/runner/resources/app_icon.ico'
    target_ico_2 = 'assets/app_icon.ico'

    os.makedirs(os.path.dirname(target_ico_1), exist_ok=True)
    square_im.save(target_ico_1, format='ICO', sizes=icon_sizes)
    square_im.save(target_ico_2, format='ICO', sizes=icon_sizes)

    print('Generated icon successfully!')
    print(f'Target 1: {target_ico_1} ({os.path.getsize(target_ico_1)} bytes)')
    print(f'Target 2: {target_ico_2} ({os.path.getsize(target_ico_2)} bytes)')
    print(f'Square PNG: assets/app_icon.png ({os.path.getsize("assets/app_icon.png")} bytes)')

if __name__ == '__main__':
    generate_icons()
