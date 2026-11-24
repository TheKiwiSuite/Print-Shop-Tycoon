CHARACTER COLOUR LAYERS (2026-11-20)

The approved owner sheet (source/assets/owner-walk.png) is unchanged. The script
build_character_layers.py splits it into five tintable grayscale layers - skin,
hair, cap, shirt and overalls - using colour and position masks. Small blobs such
as eyes and brows are excluded. The game draws the original sheet, then the
layers tinted per character (scripts/character_look.gd). Sam is drawn without
layers, so he looks exactly as before.

layers/character-*.png  copied unchanged to source/assets/characters
layers/preview.png      six sample looks (front and back)
layers/layers.json      mask pixel counts and shading reference values

Rebuild (CPU only, a few seconds):
  blender -b --factory-startup --python build_character_layers.py -- --sheet <owner-walk.png> --out <new folder>
