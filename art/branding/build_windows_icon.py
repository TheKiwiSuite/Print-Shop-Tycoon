"""Convert the owner-supplied transparent Windows icon without redesigning it."""
from pathlib import Path
import shutil
from PIL import Image

root = Path(__file__).resolve().parents[2]
source = root / "art/branding/Print-Shop-Tycoon-Windows-Icon-1024.png"
# Preserve the exact supplied PNG, including its transparent layout.
shutil.copy2(source, root / "source/assets/game-icon.png")
icon = Image.open(source).convert("RGBA")
icon.save(root / "icon/PrintShopTycoon-LogoOnly.ico", sizes=[(16,16),(24,24),(32,32),(48,48),(64,64),(128,128),(256,256)])
icon.resize((256,256), Image.Resampling.LANCZOS).save(root / "art/branding/windows-icon-preview.png")
print("Converted the supplied transparent icon; no background or border added.")
