def logi_3dpro(joystick, data, combined):
    joystick.x_axis = (((combined >> 16) & 0xFFFF) - 32768) / 32768.0  # X-axis (16 bits, centered around 0)
    joystick.y_axis = 1.0-(((combined >> 32) & 0xFFFF) - 32768) / 32768.0  # Y-axis (16 bits, centered around 0)
    joystick.z_axis = (((combined >> 48) & 0xFFFF) - 32768) / 32768.0  # Z-axis (16 bits, centered around 0)

    joystick.joystick_button = (combined >> 8) & 0x01
    joystick.throttle = (((combined >> 40) & 0xFFFF)) / 65535.0
    buttons = (combined >> 0) & 0xFF                             # Button states (8-bit)
    for i in range(8):
        joystick.buttons[i] = int(buttons & (1 << i) > 0)

def thrustmaster(joystick, data, combined):
    joystick.x_axis = (((combined >> 24) & 0xFFFF)) / 16383.0  # X-axis (10 bits, centered around 0)
    joystick.y_axis = 1.0-(((combined >> 40) & 0xFFFF)) / 16384.0  # Y-axis (16 bits, centered around 0)
    joystick.z_axis = (((combined >> 56) & 0xFF)/ 255.0)  # Z-axis (8 bits, 0-255)

    joystick.joystick_button = (combined >> 16) & 0x0F
    joystick.throttle = data[8] / 255.0
    buttons0 = data[0]                             # Button states (8-bit)
    buttons1 = data[1]                             # Button states (8-bit)
    for i in range(8):
        joystick.buttons[i] = int(buttons0 & (1 << i) > 0)
    for i in range(8):
        joystick.buttons[i + 8] = int(buttons1 & (1 << i) > 0)