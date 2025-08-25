
from pythonosc.dispatcher import Dispatcher
from pythonosc.osc_server import AsyncIOOSCUDPServer
import threading
import asyncio

def send_msg(self, key, *args):
        print("send_msg", key, args)

        key_vals = [key]  # Start with the key
        key_vals.extend([float(arg) for arg in args])

        self.mmm_audio_bridge.send_msg(key_vals)

async def start_osc_server(self, port=5000):

    # Create a dispatcher to handle incoming messages
    dispatcher = Dispatcher()

    dispatcher.set_default_handler(send_msg)

    # Server configuration
    ip = "127.0.0.1"  # localhost

    # Create and start the server
    server = AsyncIOOSCUDPServer((ip, port), dispatcher, asyncio.get_event_loop())
    transport, protocol = await server.create_serve_endpoint()

    print(f"OSC Server listening on {ip}:{port}")
    print("Press Ctrl+C to stop the server")

    await asyncio.Future()  # Run forever


asyncio.run(start_osc_server(None, 5005))  # Start the OSC server on port 5005
