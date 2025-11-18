from display.lib import LCD_1inch3
from display.display import Display
from PIL import Image, ImageDraw
import RPi.GPIO as GPIO

class WaveshareDisplay(Display):
    def __init__(self, width=240, height=240, dc=24, rst=25, bl=18, spi_speed_hz=40000000):
        self.width = width
        self.height = height

        self.disp = LCD_1inch3.LCD_1inch3()
        self.disp.Init()
        self.disp.clear() 
        self.disp.bl_DutyCycle(10)

        self.image = Image.new("RGB", (self.width, self.height), color=0)
        self.draw = ImageDraw.Draw(self.image)

        # New code
        GPIO.setmode(GPIO.BCM)

        BL = 18
        GPIO.setup(BL, GPIO.OUT)
        self.pwm = GPIO.PWM(BL, 1000)  # 1 kHz
        self.pwm.start(100)

    def show_status(self, watch_name, battery, temperature, last_sync, alarm, reminder, auto_sync):
        super().show_status(watch_name, battery, temperature, last_sync, alarm, reminder, auto_sync)

        self.disp.ShowImage(self.image)
 
    def set_brightness(self, percent):
        percent = max(0, min(100, percent))
        self.pwm.ChangeDutyCycle(percent)
