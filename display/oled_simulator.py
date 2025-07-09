from luma.core.interface.serial import i2c
from luma.oled.device import ssd1306
from PIL import Image, ImageDraw, ImageFont
from datetime import datetime

def generate_battery_icon(percent: int, width=20, height=10) -> Image.Image:
    """Generates a battery icon as a 1-bit monochrome image."""
    icon = Image.new("1", (width + 3, height), color=0)
    draw = ImageDraw.Draw(icon)
    draw.rectangle([0, 0, width - 1, height - 1], outline=1, fill=0)
    terminal_width = 3
    terminal_height = height // 2
    draw.rectangle([width, (height - terminal_height) // 2,
                    width + terminal_width, (height + terminal_height) // 2], fill=1)
    fill_width = int((width - 2) * max(0, min(percent, 100)) / 100)
    if fill_width > 0:
        draw.rectangle([1, 1, 1 + fill_width - 1, height - 2], fill=1)
    return icon

# Common function to draw OLED status
def draw_oled_status(draw, image, width, height, font_large, font_small,
                     watch_name, battery, temperature, last_sync, alarm, reminder, auto_sync,
                     margin=8, box_padding=8):
    # Header (centered horizontally, margin from top)
    bbox = draw.textbbox((0, 0), watch_name, font=font_large)
    w, h = bbox[2] - bbox[0], bbox[3] - bbox[1]
    draw.text(((width - w) // 2, margin), watch_name, font=font_large, fill=255)

    # Battery level
    battery_level = int(str(battery).strip('%')) if isinstance(battery, str) else int(battery)
    battery_icon = generate_battery_icon(battery_level)
    icon_x = width - battery_icon.width - margin
    icon_y = margin
    image.paste(battery_icon, (icon_x, icon_y))

    # Temperature below battery icon
    temp_str = f"{temperature}°C"
    bbox_temp = draw.textbbox((0, 0), temp_str, font=font_small)
    temp_w = bbox_temp[2] - bbox_temp[0]
    temp_h = bbox_temp[3] - bbox_temp[1]
    temp_x = width - temp_w - margin
    temp_y = icon_y + battery_icon.height + 2
    draw.text((temp_x, temp_y), temp_str, font=font_small, fill=255)

    # Draw rectangle around battery icon and temperature with padding
    rect_left = min(icon_x, temp_x) - box_padding
    rect_top = icon_y - box_padding
    rect_right = width - margin + box_padding - 1
    rect_bottom = temp_y + temp_h + box_padding
    draw.rectangle(
        [rect_left, rect_top, rect_right, rect_bottom],
        outline=255,
        width=1
    )

    # Info text with top margin
    y = h + margin * 2 + 12 + 10
    if isinstance(last_sync, datetime):
        delta = datetime.now() - last_sync
        hours = delta.seconds // 3600
        minutes = (delta.seconds % 3600) // 60
        last_sync_str = f"{hours:02}:{minutes:02} since sync"
    else:
        last_sync_str = str(last_sync).strip() if last_sync else ""

    info = [
        ("Last Sync:", last_sync_str),
        ("Next Alarm:", alarm),
        ("Rem:", reminder),
        ("Auto Sync:", auto_sync)
    ]

    for label, value in info:
        str_value = str(value).strip() if value is not None else ""
        draw.text((margin, y), label, font=font_small, fill=255)
        bbox_val = draw.textbbox((0, 0), str_value, font=font_small)
        val_w = bbox_val[2] - bbox_val[0]
        draw.text((width - val_w - margin, y), str_value, font=font_small, fill=255)
        y += bbox_val[3] - bbox_val[1] + margin

    # Draw a small watch icon at the bottom right in blue and yellow (for preview) or monochrome (for real OLED)
    icon_size = 24
    watch_x = width - icon_size - margin
    watch_y = height - icon_size - margin

    # For monochrome, draw a simple watch icon
    watch_icon = Image.new("1", (icon_size, icon_size), 0)
    icon_draw = ImageDraw.Draw(watch_icon)
    icon_draw.ellipse([2, 2, icon_size - 3, icon_size - 3], outline=255, fill=255)
    icon_draw.ellipse([6, 6, icon_size - 7, icon_size - 7], outline=0, fill=0)
    center = icon_size // 2
    icon_draw.line([center, center, center, center - 6], fill=0, width=2)
    icon_draw.line([center, center, center + 5, center], fill=0, width=2)
    image.paste(watch_icon, (watch_x, watch_y))
    
class MockOLEDDisplay:
    def __init__(self, width=240, height=240, output_file="oled_preview.png"):
        self.width = width
        self.height = height
        self.output_file = output_file
        self.image = Image.new("1", (self.width, self.height), color=0)
        self.draw = ImageDraw.Draw(self.image)

        # Load fonts
        self.font_large = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 18)
        self.font_small = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 12)

    def show_status(self, watch_name, battery, temperature, last_sync, alarm, reminder, auto_sync):
        MARGIN = 8  # margin in pixels around all edges
        BOX_PADDING = 8  # extra padding inside the battery/temperature box

        # Clear screen
        self.draw.rectangle((0, 0, self.width, self.height), fill=0)

        # Use the shared drawing function
        draw_oled_status(
            self.draw, self.image, self.width, self.height,
            self.font_large, self.font_small,
            watch_name, battery, temperature, last_sync, alarm, reminder, auto_sync,
            margin=MARGIN, box_padding=BOX_PADDING
        )

        # Save image
        self.image.save(self.output_file)
        print(f"🖼 OLED preview saved as '{self.output_file}'")

class RealOLEDDisplay:
    def __init__(self, width=128, height=64, i2c_port=1, i2c_address=0x3C):
        self.width = width
        self.height = height
        serial = i2c(port=i2c_port, address=i2c_address)
        self.device = ssd1306(serial, width=self.width, height=self.height)
        self.font_large = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 18)
        self.font_small = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 12)

    def show_status(self, watch_name, battery, temperature, last_sync, alarm, reminder, auto_sync):
        MARGIN = 8  # margin in pixels around all edges
        BOX_PADDING = 8  # extra padding inside the battery/temperature box

        # Create a new image for each update
        image = Image.new("1", (self.width, self.height), color=0)
        draw = ImageDraw.Draw(image)

        # Use the shared drawing function
        draw_oled_status(
            draw, image, self.width, self.height,
            self.font_large, self.font_small,
            watch_name, battery, temperature, last_sync, alarm, reminder, auto_sync,
            margin=MARGIN, box_padding=BOX_PADDING
        )

        # Display on the real OLED
        self.device.display(image)