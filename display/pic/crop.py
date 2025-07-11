from PIL import Image

img = Image.open("gw_b5600_orig.png")
cropped = img.crop((0, 24, 240, 264))  # left, top, right, bottom
cropped.save("gw_b5600.png")
