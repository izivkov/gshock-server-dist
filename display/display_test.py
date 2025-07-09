from luma.core.interface.serial import spi
from luma.lcd.device import st7789
from PIL import Image, ImageDraw

# Init display (adjust DC and RST pins if needed)
serial = spi(port=0, device=0, gpio_DC=24, gpio_RST=25)
device = st7789(serial, width=240, height=240, rotate=0)

# Create blank image and draw something
image = Image.new("RGB", (240, 240), "black")
draw = ImageDraw.Draw(image)
draw.text((30, 100), "Hello LCD!", fill="white")

# Display it
device.display(image)
