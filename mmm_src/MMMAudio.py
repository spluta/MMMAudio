import sys
import time
import numpy as np
from scipy.io import wavfile
import pyaudio
import asyncio

from pythonosc.dispatcher import Dispatcher
from pythonosc.osc_server import AsyncIOOSCUDPServer
import threading
import multiprocessing

from mmm_src.hid_devices import Joystick

import mojo.importer
import os

import matplotlib.pyplot as plt

import pyautogui
import mmm_src.Scheduler as Scheduler

from math import ceil
    
sys.path.insert(0, "mmm_src")

class MMMAudio:
    
    def get_device_info(self, p_temp, device_name, is_input=True):

        print(f"Looking for audio device: {device_name}")
        
        if device_name != "default":
            device_index = None
            for i in range(p_temp.get_device_count()):
                dev_info = p_temp.get_device_info_by_index(i)
                print(f"Checking device {i}: {dev_info['name']}")
                if device_name in dev_info['name']:
                    device_index = i
                    print(f"Using audio device: {dev_info['name']}")
                    break
            if device_index is not None:
                device_info = p_temp.get_device_info_by_index(device_index)
                
            else:
                print(f"Audio device '{device_name}' not found. Using default device.")
                device_info = p_temp.get_default_output_device_info()
        else:
            if is_input:
                device_info = p_temp.get_default_input_device_info()
            else:
                device_info = p_temp.get_default_output_device_info()

        return device_info


    def __init__(self, blocksize=64, num_input_channels=2, num_output_channels=2, in_device="default", out_device="default", graph_name="FeedbackDelays", package_name="examples"):
        self.device_index = None
        # this makes the graph file that should work
        from mmm_src.make_solo_graph import make_solo_graph
        make_solo_graph(graph_name, package_name)

        import MMMAudioBridge

        self.blocksize = blocksize
        self.num_input_channels = num_input_channels
        self.num_output_channels = num_output_channels
        self.counter = 0
        self.joysticks = []

        self.running = False

        self.scheduler = Scheduler.Scheduler()

        p_temp = pyaudio.PyAudio()
        in_device_info = self.get_device_info(p_temp, in_device, True)
        out_device_info = self.get_device_info(p_temp, out_device, False)
        p_temp.terminate()


        if in_device_info['defaultSampleRate'] != out_device_info['defaultSampleRate']:
            print(f"Warning: Sample rates do not match ({in_device_info['defaultSampleRate']} vs {out_device_info['defaultSampleRate']})")
            print("Exiting.")
            return
        
        self.sample_rate = int(in_device_info['defaultSampleRate'])
        self.in_device_index = in_device_info['index']
        self.out_device_index = out_device_info['index']
        self.num_input_channels = min(self.num_input_channels, int(in_device_info['maxInputChannels']))
        self.num_output_channels = min(self.num_output_channels, int(out_device_info['maxOutputChannels']))

        self.out_buffer = np.zeros((self.blocksize, self.num_output_channels), dtype=np.float64)

        # Initialize the Mojo module AudioEngine

        self.mmm_audio_bridge = MMMAudioBridge.MMMAudioBridge(self.sample_rate, self.blocksize)
        self.mmm_audio_bridge.set_channel_count((self.num_input_channels, self.num_output_channels))

        # # Get screen size
        screen_dims = pyautogui.size()
        self.mmm_audio_bridge.set_screen_dims(screen_dims)  # Initialize with sample rate and screen size

        # the mouse thread will always be running
        threading.Thread(target=asyncio.run, args=(self.get_mouse_position(0.01),)).start()

        self.p = pyaudio.PyAudio()
        format_code = pyaudio.paFloat32

        self.audio_stopper = threading.Event()

        self.input_stream = self.p.open(format=format_code,
            channels= self.num_input_channels,
            rate=self.sample_rate,
            input=True,
            input_device_index=self.in_device_index,
            frames_per_buffer=self.blocksize)

        self.output_stream = self.p.open(format=format_code,
            channels= self.num_output_channels,
            rate=self.sample_rate,
            output=True,
            output_device_index=self.out_device_index,
            frames_per_buffer=self.blocksize)


    async def get_mouse_position(self, delay: float = 0.01):
        while True:
            x, y = pyautogui.position()
            self.mmm_audio_bridge.send_msg(["mouse_x", x])
            self.mmm_audio_bridge.send_msg(["mouse_y", y])
            
            await asyncio.sleep(delay)

    def get_samples(self, samples):
        blocks = ceil(samples / self.blocksize)
        # Create empty array to store the waveform data
        waveform = np.zeros(samples*self.num_output_channels, dtype=np.float64).reshape(samples, self.num_output_channels)
        in_buf = np.zeros((self.blocksize, self.num_input_channels), dtype=np.float64)

        for i in range(blocks):
            self.mmm_audio_bridge.next(in_buf, self.out_buffer)
            for j in range(self.out_buffer.shape[0]):
                if i*self.blocksize + j < samples:
                    waveform[i*self.blocksize + j] = self.out_buffer[j]

        return waveform
    
    def plot(self, samples, clear=True):
        a = self.get_samples(samples)
        if clear:
            plt.clf()
        plt.title("MMMAudio Output")
        plt.xlabel("Samples")
        plt.ylabel("Amplitude")
        plt.grid()
        plt.plot(np.array(a))
        plt.show(block=False)
    
    def audio_loop(self):
        max = 0.0
        while not self.audio_stopper.is_set():
            data = self.input_stream.read(self.blocksize, exception_on_overflow=False)
            in_data = np.frombuffer(data, dtype=np.float32)
            # in_data = in_data.flatten()

            self.mmm_audio_bridge.next(in_data, self.out_buffer)
            self.out_buffer = np.clip(self.out_buffer, -1.0, 1.0)
            chunk = self.out_buffer.astype(np.float32).tobytes()
            self.output_stream.write(chunk)

    def start_audio(self):
        # Instantiate PyAudio
        print("Starting audio...")
        if not self.running:
            self.running = True
            self.audio_stopper.clear()
            print("Audio started with sample rate:", self.sample_rate, "block size:", self.blocksize, "input channels:", self.num_input_channels, "output channels:", self.num_output_channels)
            self.audio_thread = threading.Thread(target=self.audio_loop)
            self.audio_thread.start()
    
    def stop_audio(self):
        if self.running:
            self.running = False
            print("Stopping audio...")
            self.audio_stopper.set()

    def send_msg(self, key, *args):
        """
        Send a message to the Mojo audio engine.
        
        Args:
            key: Key for the message 
            *args: Additional arguments for the message
        """

        key_vals = [key]  # Start with the key
        # if it gets a list as the first argument, unpack it
        if len(args) == 1 and isinstance(args[0], list):
            args = args[0]
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

    # # currently doesn't handle sysex or other complex midi messages
    # def send_midi(self, msg):
    #     # encodes the midi message into a key val pair, where the key includes type/channel/etc in one string
    #     # send a midi clock message to keep things in sync
    #     if hasattr(msg, "note"):
    #         self.mmm_audio_bridge.send_midi((str(msg.type), msg.channel, msg.note, msg.velocity))
    #     if hasattr(msg, "control"):
    #         self.mmm_audio_bridge.send_midi(("cc", msg.channel, msg.control, msg.value))
    #     if hasattr(msg, "pitch"):
    #         self.mmm_audio_bridge.send_midi(("bend", msg.channel, msg.pitch))


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

    async def start_osc_server(self, ip = "127.0.0.1", port=5000):

        # Create a dispatcher to handle incoming messages
        dispatcher = Dispatcher()
        dispatcher.set_default_handler(self.send_msg)

        # Create and start the server
        server = AsyncIOOSCUDPServer((ip, port), dispatcher, asyncio.get_event_loop())
        transport, protocol = await server.create_serve_endpoint()

        print(f"OSC Server listening on {ip}:{port}")
        print("Press Ctrl+C to stop the server")

        await asyncio.Future()  # Run forever
 

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
