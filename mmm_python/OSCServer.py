import threading
import asyncio
from pythonosc.dispatcher import Dispatcher
from pythonosc.osc_server import AsyncIOOSCUDPServer

class OSCServer:
    """A threaded OSC server using python-osc library. With a given message handler function, will call that function on incoming messages."""

    def __init__(self, ip="0.0.0.0", port=5005, osc_msg_handler=None):
        """Initialize the OSC server with IP, port, and message handler.
        
        Args:
            ip (str): IP address to bind the server to. If "0.0.0.0", listens on all interfaces. This is the default.
            port (int): Port number to listen on.
            osc_msg_handler (function): Function to handle incoming OSC messages.
        """

        self.ip = ip
        self.port = port
        self.thread = None
        self.stop_flag = threading.Event()  # Use threading.Event instead
        self.transport = None
        self.osc_msg_handler = osc_msg_handler if osc_msg_handler else self.default_handler
        self.dispatcher = Dispatcher()

    def default_handler(self, address, *args):
        print(f"Default Function: Received OSC message: {address} with arguments: {args}")

    def set_osc_msg_handler(self, handler):
        """Set a custom OSC message handler.
        
        Args:
            handler (function): Function to handle incoming OSC messages.
        """
        self.osc_msg_handler = handler
        self.dispatcher.set_default_handler(self.osc_msg_handler)

    def start(self):
        """Start the OSC server in a separate thread"""
        if self.thread and self.thread.is_alive():
            print("Server is already running")
            return
            
        self.stop_flag.clear()
        self.thread = threading.Thread(target=self._run_server, daemon=False)
        self.thread.start()
        print("OSC Server thread started")
    
    def stop(self):
        """Stop the OSC server gracefully"""
        if not self.thread or not self.thread.is_alive():
            print("Server is not running")
            return
            
        print("Stopping OSC server...")
        self.stop_flag.set()  # Simple flag set - no coroutines needed
        
        # Wait for the thread to finish
        self.thread.join(timeout=5.0)
        
        if self.thread.is_alive():
            print("Warning: Thread did not stop gracefully")
        else:
            print("OSC Server stopped successfully")
    
    def _run_server(self):
        """Run the server in its own event loop"""
        asyncio.run(self._start_osc_server())
    
    async def _start_osc_server(self):
        self.dispatcher.set_default_handler(self.osc_msg_handler)
        
        server = AsyncIOOSCUDPServer((self.ip, self.port), self.dispatcher, asyncio.get_event_loop())
        self.transport, protocol = await server.create_serve_endpoint()
        
        print(f"OSC Server listening on {self.ip}:{self.port}")
        
        try:
            # Check stop flag periodically instead of using asyncio.Event
            while not self.stop_flag.is_set():
                await asyncio.sleep(0.1)  # Check every 100ms
        except asyncio.CancelledError:
            pass
        finally:
            print("Closing OSC server transport...")
            if self.transport:
                self.transport.close()

