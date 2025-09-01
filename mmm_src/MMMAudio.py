import sys
import time
import numpy as np
from scipy.io import wavfile
import pyaudio
import asyncio

from pythonosc.dispatcher import Dispatcher
from pythonosc.osc_server import AsyncIOOSCUDPServer
import threading

from mmm_src.hid_devices import Joystick

import mojo.importer
import os

import pyautogui
import mmm_src.Scheduler as Scheduler

from math import ceil
    
sys.path.insert(0, "mmm_src")


class MMMAudio:
    

    def __init__(self, blocksize=64, channels=2, audio_device="default", graph_name="FeedbackDelays", package_name="examples"):
        self.device_index = None
        # this makes the graph file that should work
        from mmm_src.make_solo_graph import make_solo_graph
        make_solo_graph(graph_name, package_name)

        import MMMAudioBridge

        self.blocksize = blocksize
        self.channels = channels
        self.counter = 0
        self.joysticks = []

        self.running = False

        self.scheduler = Scheduler.Scheduler()

        # Get default system sample rate from PyAudio
        p_temp = pyaudio.PyAudio()
        if audio_device != "default":
            device_index = None
            for i in range(p_temp.get_device_count()):
                dev_info = p_temp.get_device_info_by_index(i)
                if audio_device in dev_info['name']:
                    device_index = i
                    self.audio_device_index = device_index
                    print(f"Using audio device: {dev_info['name']}")
                    break
            if device_index is not None:
                device_info = p_temp.get_device_info_by_index(device_index)
                self.sample_rate = int(device_info['defaultSampleRate'])
                print(f"Sample rate for {audio_device}: {self.sample_rate}")
            else:
                print(f"Audio device '{audio_device}' not found. Using default device.")
                device_info = p_temp.get_default_output_device_info()
                self.sample_rate = int(device_info['defaultSampleRate'])
        
        print(f"Default sample rate: {self.sample_rate}")
        p_temp.terminate()
        
        self.wire_buffer = np.zeros((self.blocksize, self.channels), dtype=np.float64)
        print(self.wire_buffer.shape)
        
        # Initialize the Mojo module AudioEngine

        # if active_graphs == None:
        #     active_graphs = (0, )
        # if isinstance(active_graphs, int):
        #     active_graphs = (active_graphs,)  # this has to be one of the dumbest features of any programming language
        # print("active_graphs:", active_graphs)
        self.mmm_audio_bridge = MMMAudioBridge.MMMAudioBridge(self.sample_rate, self.blocksize, self.channels)
        # self.mmm_audio_bridge.set_active_graphs(active_graphs)

        # Get screen size
        screen_dims = pyautogui.size()
        self.mmm_audio_bridge.set_screen_dims(screen_dims)  # Initialize with sample rate and screen size

        self.p = None
        self.stream = None
        self.data_index = 0

        # the mouse thread will always be running
        threading.Thread(target=asyncio.run, args=(self.get_mouse_position(0.01),)).start()

    async def get_mouse_position(self, delay: float = 0.01):
        while True:
            x, y = pyautogui.position()
            self.mmm_audio_bridge.send_msg(["mouse_x", x])
            self.mmm_audio_bridge.send_msg(["mouse_y", y])
            await asyncio.sleep(delay)

    def callback(self, in_data, frame_count, time_info, status):
        
        current_time = time.time()
        
        # Pass wire_buffer to the Mojo audio engine. Mojo modifies the wire_buffer in place
        self.mmm_audio_bridge.next(self.wire_buffer)

        # if self.counter % 100 == 0:
        #     duration = time.time() - current_time
        #     print(duration / (self.blocksize/self.sample_rate))
        # self.counter += 1

        self.wire_buffer = np.clip(self.wire_buffer, -1.0, 1.0)
        # Convert to bytes
        chunk = self.wire_buffer.astype(np.float32).tobytes()

        # Return empty data when we've reached the end
        if len(chunk) == 0:
            return (chunk, pyaudio.paComplete)
        
        return (chunk, pyaudio.paContinue)
    
    def increment(self, samples):
        blocks = ceil(samples / self.blocksize)
        for i in range(blocks):
            self.mmm_audio_bridge.next(self.wire_buffer)

    def plot(self, samples):
        blocks = ceil(samples / self.blocksize)
        # Create empty array to store the waveform data
        waveform = np.zeros(samples*self.channels, dtype=np.float64)
        for i in range(blocks):
            self.mmm_audio_bridge.next(self.wire_buffer)
            waveform[i*self.blocksize:(i+1)*self.blocksize] = self.wire_buffer[:, 0]
        return waveform
    
    def start_audio(self):
        # Instantiate PyAudio
        if not self.running:
            self.running = True
            self.p = pyaudio.PyAudio()
            format_code = pyaudio.paFloat32
            
            # Open stream using callback
            self.stream = self.p.open(
                format=format_code,
                channels=self.channels,
                rate=self.sample_rate,
                input_device_index=self.audio_device_index,
                output_device_index=self.audio_device_index,
                input=True,
                output=True,
                frames_per_buffer=self.blocksize,
                stream_callback=self.callback
            )

        else:
            print("Audio is already running.")
    
    def stop_audio(self):
        if self.running:
            self.running = False
            if self.stream:
                self.stream.close()
            if self.p:
                self.p.terminate()
        else:
            print("Audio is not running.")

    def send_msg(self, key, *args):
        """
        Send a message to the Mojo audio engine.
        
        Args:
            key: Key for the message 
            *args: Additional arguments for the message
        """

        key_vals = [key]  # Start with the key
        key_vals.extend([float(arg) for arg in args])

        self.mmm_audio_bridge.send_msg(key_vals)

    def send_text_msg(self, key, *args):
        """
        Send a message to the Mojo audio engine.
        
        Args:
            key: Key for the message 
            *args: Additional arguments for the message
        """

        key_vals = [key]  # Start with the key
        key_vals.extend([str(arg) for arg in args])

        self.mmm_audio_bridge.send_text_msg(key_vals)

    def send_midi(self, msg):
        # encodes the midi message into a key val pair, where the key includes type/channel/etc in one string
        key = str(msg.type) + "/" + str(msg.channel)
        if hasattr(msg, "note"):
            key = key + "/" + str(msg.note)
        if hasattr(msg, "control"):
            key = key + "/" + str(msg.control)
        if hasattr(msg, "value"):
            self.mmm_audio_bridge.send_midi((key, msg.value))

        if hasattr(msg, "pitch"):
            self.mmm_audio_bridge.send_midi((key, msg.pitch))
        if hasattr(msg, "velocity"):
            self.mmm_audio_bridge.send_midi((key, msg.velocity))


    def add_hid_device(self, name, vendor_id, product_id):
        """
        Add a HID device to the MMMAudio instance.

        Args:
            name: Name of the HID device
            vendor_id: Vendor ID of the HID device
            product_id: Product ID of the HID device
        """
        joystick = Joystick(name, vendor_id, product_id)
        
        if joystick.connect():
            print(f"Connected to {name}")
            # Start reading joystick data in a separate thread
            joystick_thread = threading.Thread(target=joystick.read_continuous, args=(name, self.mmm_audio_bridge, ), daemon=True)
            joystick_thread.start()
            self.joysticks.append(joystick)
        else:
            print(f"Could not connect to {name}. Make sure the device is plugged in and drivers are installed.")

    async def start_osc_server(self, port=5000):

        # Create a dispatcher to handle incoming messages
        dispatcher = Dispatcher()

        dispatcher.set_default_handler(self.send_msg)

        # Server configuration
        ip = "127.0.0.1"  # localhost

        # Create and start the server
        server = AsyncIOOSCUDPServer((ip, port), dispatcher, asyncio.get_event_loop())
        transport, protocol = await server.create_serve_endpoint()

        print(f"OSC Server listening on {ip}:{port}")
        print("Press Ctrl+C to stop the server")

        await asyncio.Future()  # Run forever

        # with this commented out, the OSC server survives ctl-c 

        # try:
        #     # Keep the server running
        #     await asyncio.Future()  # Run forever
        # except KeyboardInterrupt:
        #     print("\nShutting down server...")
        # finally:
        #     transport.close()    

def list_audio_devices():
    p_temp = pyaudio.PyAudio()
    p_temp.get_device_count()
    # List all available audio devices
    for i in range(p_temp.get_device_count()):
        dev_info = p_temp.get_device_info_by_index(i)
        print(f"Device {i}: {dev_info['name']}")
        print(f"  Input channels: {dev_info['maxInputChannels']}")
        print(f"  Output channels: {dev_info['maxOutputChannels']}")
        print(f"  Default sample rate: {dev_info['defaultSampleRate']} Hz")
        print()
    p_temp.terminate()
