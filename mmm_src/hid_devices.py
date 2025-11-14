from typing import Optional, Callable
import hid
import time

class Joystick:
    """Connect a Joystick to control parameters.
    """
    def __init__(self, name: str, vendor_id=0x046d, product_id=0xc215):
        """Initialize connection with a Joystick.
        
        Args:
            name: Joystick name.
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

        if self.name=="logi_3Dpro":
            self.x_axis = (((combined >> 0) & 0x3FF)) / 1023.0  # X-axis (10 bits, centered around 0)
            self.y_axis = 1.0-(((combined >> 10) & 0x3FF)) / 1023.0  # Y-axis (10 bits, centered around 0)
            self.z_axis = (((combined >> 24) & 0xFF)/ 255.0)  # Z-axis (8 bits, 0-255)

            self.joystick_button = (combined >> 20) & 0x0F  # Joystick button state (4 bits)
            self.throttle = data[5] / 255.0
            buttons0 = data[4]                             # Button states (8-bit)
            buttons1 = data[6]                             # Button states (8-bit)
            for i in range(8):
                self.buttons[i] = int(buttons0 & (1 << i) > 0)
            for i in range(4):
                self.buttons[i + 8] = int(buttons1 & (1 << i) > 0)
                
        elif self.name=="thrustmaster":
            self.x_axis = (((combined >> 24) & 0xFFFF)) / 16383.0  # X-axis (10 bits, centered around 0)
            self.y_axis = 1.0-(((combined >> 40) & 0xFFFF)) / 16384.0  # Y-axis (16 bits, centered around 0)
            self.z_axis = (((combined >> 56) & 0xFF)/ 255.0)  # Z-axis (8 bits, 0-255)

            self.joystick_button = (combined >> 16) & 0x0F
            self.throttle = data[8] / 255.0
            buttons0 = data[0]                             # Button states (8-bit)
            buttons1 = data[1]                             # Button states (8-bit)
            for i in range(8):
                self.buttons[i] = int(buttons0 & (1 << i) > 0)
            for i in range(8):
                self.buttons[i + 8] = int(buttons1 & (1 << i) > 0)


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