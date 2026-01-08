"""
The Joystick example shows how to connect a joystick and print its values. Normally you would use these values to control parameters in your MMMAudio synths or effects.

Right now, it only supports Logitech Extreme 3D Pro and Thrustmaster joysticks, but you can modify the `parse_report` method in `mmm_python/hid_devices.py` to support your own joystick by examining its HID report format. If you do so, please consider contributing the code back to the repository!
"""

from mmm_python.hid_devices import Joystick
from os import name
import threading

if True:
    joystick = Joystick("thrustmaster", 0x044f, 0xb10a) # provide the correct vendor_id and product_id for your joystick

    # this function will be called whenever new joystick data is read
    def joystick_function(name, x_axis, y_axis, z_axis, throttle, joystick_button, *buttons):
        print(f"Joystick {name}: X={x_axis:.2f}, Y={y_axis:.2f}, Z={z_axis:.2f}, Throttle={throttle:.2f}, Joy_Button={joystick_button}, Buttons={buttons}")
        if buttons[0] == 1:
            print("Button 0 pressed!")

    if joystick.connect():
        print(f"Connected to {joystick.name}")

        # Start reading joystick data in a separate thread - call the joystick_function whenever new data is read
        joystick_thread = threading.Thread(target=joystick.read_continuous, args=(joystick.name, joystick_function, ), daemon=True)
        joystick_thread.start()
    else:
        print(f"Could not connect to {joystick.name}. Make sure the device is plugged in and drivers are installed.")

# disconnect when done - probably will throw an exception
joystick.disconnect()