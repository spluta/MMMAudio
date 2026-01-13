from mmm_python.OSCServer import OSCServer

def osc_msg_handler(key, *args):
    print(f"Received OSC message: {key} with arguments: {args}")

# Start server
osc_server = OSCServer("0.0.0.0", 5005, osc_msg_handler)
osc_server.start()
osc_server.stop()

