from typing import Optional, Callable
import hid
import time
from .hid_parse_defs import *
from . import hid_parse_defs as _hid_parse_defs
import inspect

class Joystick:
    """Connect a Joystick to control parameters. This class supports Logitech Extreme 3D Pro and Thrustmaster joysticks, whose HID reports were parse manually. See the `parse_report` method for the report format for these joysticks. Yours will probably be something like that!
    """
    def __init__(self, name: str, vendor_id=0x046d, product_id=0xc215):
        """Initialize connection with a Joystick.
        
        Args:
            name: Joystick name. Will be used to look up the correct parser function found in `hid_parse_defs.py`.
            vendor_id: Identification number of the vendor.
            product_id: Identification number of the product.
        """
        self.device = None

        self.verbose = False

        self.name = name
        self.vendor_id = vendor_id
        self.product_id = product_id
        self.x_axis = 0
        self.y_axis = 0
        self.z_axis = 0
        self.throttle = 0
        self.joystick_button = 0
        self.buttons = [0] * 16  # 16 buttons

        # auto-discover parser functions in hid_parse_defs.py and map name -> callable(self, data, combined)
        self.joystick_fn_dict = {}
        for name, func in inspect.getmembers(_hid_parse_defs, inspect.isfunction):
            if name.startswith("_") or func.__module__ != _hid_parse_defs.__name__:
                continue
            self.joystick_fn_dict[name] = (lambda data, combined, f=func: f(self, data, combined))

    def connect(self):
        """Connect to the joystick"""
        try:
            self.device = hid.Device(self.vendor_id, self.product_id)
            print(f"Connected to: {self.name}")
            return True
        except Exception as e:
            print(f"Failed to connect: {e}")
            return False
    
    def disconnect(self):
        """Disconnect from the joystick"""
        if self.device:
            self.device.close()
            print("Disconnected")
    
    def parse_report(self, data):
        """Parse the 8-byte HID report from Logitech Extreme 3D Pro or Thrustmaster joystick"""

        if len(data) < 7:
            return None
        
        # this is a 32-bit integer of 1s and 0s pertaining to the joystick state
        combined = int.from_bytes(data, byteorder='little')
        # print(f"Combined data: {combined:032b}")  # Debug print of the combined data
        # print(f"Combined data: {combined>>40:032b}")  # Debug print of the combined data

        if self.name.lower() in self.joystick_fn_dict:
            self.joystick_fn_dict[self.name.lower()](data, combined)
        else:
            print(f"Joystick parsing not implemented for: {self.name}")


    def read_continuous(self, name: str, function: Callable[..., None], duration: Optional[float] = None):
        """Read joystick data continuously.
        
        Args:
            name: Joystick name
            function: Function to call with joystick data
            duration: Duration to read data (in seconds). If None, read indefinitely.
        """
        if not self.device:
            print("Device not connected")
            return
        
        self.name = name
        start_time = time.time()
            
        try:
            while True:
                # Check duration limit
                if duration and (time.time() - start_time) > duration:
                    break
                
                # Read data with timeout
                data = self.device.read(9, 10)

                if data:
                    self.parse_report(data)
                    if self.verbose:
                        print(f"X: {self.x_axis:.2f}, Y: {self.y_axis:.2f}, Z: {self.z_axis:.2f}, Throttle: {self.throttle:.2f}, Joy_Button: {self.joystick_button}, Buttons: {self.buttons}")
                    function(self.name, self.x_axis, self.y_axis, self.z_axis, self.throttle, self.joystick_button, *self.buttons)
                time.sleep(0.001)  # Small delay to prevent overwhelming output
                
        except KeyboardInterrupt:
            print("\nStopped by user")

def list_hid_devices():
    print("Available HID devices:")
    for device_dict in hid.enumerate():
        print(f"Manufacturer: {device_dict.get('manufacturer_string', 'Unknown')}")
        print(f"Product: {device_dict.get('product_string', 'Unknown')}")
        print(f"Vendor ID: 0x{device_dict.get('vendor_id', 0):04x}")
        print(f"Product ID: 0x{device_dict.get('product_id', 0):04x}")
        print(f"Path: {device_dict.get('path', 'Unknown')}")
        print("--------------------")
