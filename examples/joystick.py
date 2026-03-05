"""
The Joystick example shows how to connect a joystick or other hid device and print its values. Normally you would use these values to control parameters in your MMMAudio synths or effects.

Right now, it only supports Logitech Extreme 3D Pro and Thrustmaster joysticks, but you can modify the `parse_report` method in `mmm_python/hid_devices.py` to support your own joystick by examining its HID report format. If you do so, please consider contributing the code back to the repository!
"""

import threading
from os import name

from mmm_python.hid_devices import Joystick

if True:
    joystick = Joystick(
        "thrustmaster", 0x044F, 0xB10A
    )  # provide the correct vendor_id and product_id for your joystick

    # this function will be called whenever new joystick data is read
    def joystick_function(
        name, x_axis, y_axis, z_axis, throttle, joystick_button, *buttons
    ):
        print(
            f"Joystick {name}: X={x_axis:.2f}, Y={y_axis:.2f}, Z={z_axis:.2f}, Throttle={throttle:.2f}, Joy_Button={joystick_button}, Buttons={buttons}"
        )
        if buttons[0] == 1:
            # example action when button 0 is pressed - replace with your own action, like turning on a synth 
            print("Button 0 pressed!")

    if joystick.connect():
        print(f"Connected to {joystick.name}")

        # Start reading joystick data in a separate thread - call the joystick_function whenever new data is read
        joystick_thread = threading.Thread(
            target=joystick.read_continuous,
            args=(
                joystick.name,
                joystick_function,
            ),
            daemon=False,
        )
        joystick_thread.start()
    else:
        print(
            f"Could not connect to {joystick.name}. Make sure the device is plugged in and drivers are installed."
        )

# disconnect when done - probably will throw an exception
joystick.disconnect()



# adding your own joystick/HID support ------------------------|

# find your device

import hid

print("Connected HID Devices:")
for device_dict in hid.enumerate(0x0, 0x0):
    print(f"  Device Found:")
    for key, value in device_dict.items():
        print(f"    {key}: {value}")
    print("\n")

# To add support for your own joystick, you will need to parse its HID report manually. Below is an example of how to do this by adding a custom parser function for a Thrustmaster joystick.
if True:
    import threading
    from os import name

    from mmm_python.hid_devices import Joystick

    joystick = Joystick(
        "my_joystick", 1103, 45322
    )  # this is the vendor_id and product_id for a Thrustmaster joystick, but we are going to make our own parser

    # my custom parser for the joystick
    def custom_parser(joystick, data, combined):

        print(bin(combined)) # the hid data comes in as a readable binary string

        joystick.x_axis = (
            (combined >> 24) & 0xFFFF
        ) / 16383.0  # X-axis (10 bits, centered around 0)
        joystick.y_axis = (
            1.0 - ((combined >> 40) & 0xFFFF) / 16384.0
        )  # Y-axis (16 bits, centered around 0)
        joystick.z_axis = ((combined >> 56) & 0xFF) / 255.0  # Z-axis (8 bits, 0-255)

        joystick.joystick_button = (combined >> 16) & 0x0F
        joystick.throttle = data[8] / 255.0

        # the buttons of the thrustmaster are the first 16 bits
        buttons0 = data[0]
        buttons1 = data[1]
        for i in range(8):
            joystick.buttons[i] = int(buttons0 & (1 << i) > 0)
        for i in range(8):
            joystick.buttons[i + 8] = int(buttons1 & (1 << i) > 0)

    joystick.joystick_fn_dict["my_joystick"] = lambda data, combined: custom_parser(
        joystick, data, combined
    )

    # this function will be called whenever new joystick data is read
    def joystick_function(
        name, x_axis, y_axis, z_axis, throttle, joystick_button, *buttons
    ):
        print(
            f"Joystick {name}: X={x_axis:.2f}, Y={y_axis:.2f}, Z={z_axis:.2f}, Throttle={throttle:.2f}, Joy_Button={joystick_button}, Buttons={buttons}"
        )
        if buttons[0] == 1:
            print("Button 0 pressed!")

    if joystick.connect():
        print(f"Connected to {joystick.name}")
        # Start reading joystick data in a separate thread - call the joystick_function whenever new data is read
        joystick_thread = threading.Thread(
            target=joystick.read_continuous,
            args=(
                joystick.name,
                joystick_function,
            ),
            daemon=False,
        )
        joystick_thread.start()
    else:
        print(
            f"Could not connect to {joystick.name}. Make sure the device is plugged in and drivers are installed."
        )
