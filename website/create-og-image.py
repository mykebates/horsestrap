#!/usr/bin/env python3
"""
Create OG image for Horsestrap using PIL/Pillow
"""

try:
    from PIL import Image, ImageDraw, ImageFont
    import os
    
    # Create a 1200x630 image with gradient background
    width, height = 1200, 630
    img = Image.new('RGB', (width, height), color='#4a4554')
    draw = ImageDraw.Draw(img)
    
    # Create gradient effect (simple approximation)
    for y in range(height):
        color_value = int(0x4a + (0x3a - 0x4a) * (y / height))
        color = f'#{color_value:02x}{color_value-10:02x}{color_value+20:02x}'
        draw.line([(0, y), (width, y)], fill=color)
    
    # Load and resize mascot
    if os.path.exists('horsestrap-mascot.png'):
        mascot = Image.open('horsestrap-mascot.png')
        mascot = mascot.resize((280, 280), Image.Resampling.LANCZOS)
        
        # Paste mascot on the left side
        img.paste(mascot, (100, 175), mascot if mascot.mode == 'RGBA' else None)
    
    # Add text (basic font, will work on most systems)
    try:
        # Try to use a system font
        title_font = ImageFont.truetype("/System/Library/Fonts/Arial.ttf", 72)
        subtitle_font = ImageFont.truetype("/System/Library/Fonts/Arial.ttf", 28)
        tagline_font = ImageFont.truetype("/System/Library/Fonts/Arial.ttf", 24)
        feature_font = ImageFont.truetype("/System/Library/Fonts/Arial.ttf", 18)
    except:
        # Fallback to default font
        title_font = ImageFont.load_default()
        subtitle_font = ImageFont.load_default()
        tagline_font = ImageFont.load_default()
        feature_font = ImageFont.load_default()
    
    # Add text content
    x_text = 450
    y_start = 180
    
    # Title
    draw.text((x_text, y_start), "HORSESTRAP", fill='#f5f5f0', font=title_font)
    
    # Subtitle
    draw.text((x_text, y_start + 100), "The Anti-Framework Framework", fill='#b8b8c0', font=subtitle_font)
    
    # Tagline
    draw.text((x_text, y_start + 150), "Zero-config deployment for .NET Umbraco CMS", fill='#999999', font=tagline_font)
    draw.text((x_text, y_start + 180), "Fresh Ubuntu to live site in 2 minutes", fill='#999999', font=tagline_font)
    
    # Features
    features_y = y_start + 230
    draw.text((x_text, features_y), "🚀 2-Min Deploy    🖥️ CMS Ready    ⚡ Auto SSL", fill='#f5f5f0', font=feature_font)
    
    # Horse pun
    draw.text((1160, 600), "No horse shit, just results. 🐴", fill='#999999', font=feature_font, anchor='ra')
    
    # Save the image
    img.save('horsestrap-og-image.png', 'PNG', quality=95)
    print("OG image created successfully: horsestrap-og-image.png")
    
except ImportError:
    print("PIL/Pillow not available. Please install with: pip install Pillow")
    print("Falling back to copying mascot as OG image...")
    import shutil
    shutil.copy('horsestrap-mascot.png', 'horsestrap-og-image.png')
    
except Exception as e:
    print(f"Error creating OG image: {e}")
    print("Falling back to copying mascot as OG image...")
    import shutil
    shutil.copy('horsestrap-mascot.png', 'horsestrap-og-image.png')