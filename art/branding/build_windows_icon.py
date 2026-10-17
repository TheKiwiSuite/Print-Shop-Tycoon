"""Package the approved wide logo as a full-size square Windows icon."""
from pathlib import Path
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parents[2]
logo = Image.open(root / "art/branding/Transparent Print Shop Tycoon Logo.png").convert("RGBA")
logo = logo.crop(logo.getbbox())
# The square badge fills normal Windows icon bounds without stretching the logo.
icon = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
draw = ImageDraw.Draw(icon)
draw.rounded_rectangle((16, 16, 1007, 1007), radius=170, fill="#09234b", outline="#0876ed", width=24)
draw.rounded_rectangle((46, 46, 977, 977), radius=144, outline="#4bc9ff", width=5)
logo.thumbnail((980, 880), Image.Resampling.LANCZOS)
icon.alpha_composite(logo, ((1024-logo.width)//2, (1024-logo.height)//2))
icon = icon.resize((512, 512), Image.Resampling.LANCZOS)
icon.save(root / "source/assets/game-icon.png")
icon.save(root / "icon/PrintShopTycoon-Square.ico", sizes=[(16,16),(24,24),(32,32),(48,48),(64,64),(128,128),(256,256)])
icon.resize((256, 256), Image.Resampling.LANCZOS).save(root / "art/branding/windows-icon-preview.png")
print("Square badge bounds:", icon.getbbox())
