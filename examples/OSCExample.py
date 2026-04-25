"""
The OSCServer class provides a simple interface for receiving and sending OSC messages.

In this example, we create an OSC server that listens for incoming messages on port 5005. A port must always be specified and only one OSCServer can listen on a given port at a time. 

If the in_ip parameter is set to "0.0.0.0", the server will pass messages received from any IP address. If it is set to a specific IP address, the server will only pass messages from that address.

The callback function osc_msg_handler is called on incoming messages that pass the IP filter. It takes three parameters: client_address, key, and *args. 
    client_address is a tuple of (ip, port) for the sender of the message. 
    key is the OSC address pattern of the message. 
    *args are the arguments sent with the message.
"""
# this version gets messages from any IP address
if True:
    from mmm_python.OSCServer import OSCServer

    def osc_msg_handler(client_address, key, *args):
        print(f"From: {client_address} | key: {key} | Args: {args}")

    os = OSCServer("0.0.0.0", 5005, osc_msg_handler)
    os.start()

# this version only gets messages from the specified IP address
if True:
    from mmm_python.OSCServer import OSCServer

    def osc_msg_handler(client_address, key, *args):
        print(f"From: {client_address} | key: {key} | Args: {args}")

    os = OSCServer("169.254.252.246", 5005, osc_msg_handler)
    os.start()