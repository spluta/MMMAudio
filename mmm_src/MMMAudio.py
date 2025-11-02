import sys
import numpy as np
import pyaudio
import asyncio

from pythonosc.dispatcher import Dispatcher
from pythonosc.osc_server import AsyncIOOSCUDPServer
import threading

import mojo.importer

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

        # Get screen size
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
            x = x / pyautogui.size().width
            y = y / pyautogui.size().height
            
            self.mmm_audio_bridge.update_mouse_pos([ x, y ])

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
        
        # Plot each channel on its own subplot
        num_channels = a.shape[1] if len(a.shape) > 1 else 1
        
        fig, axes = plt.subplots(num_channels, 1, figsize=(10, 3 * num_channels))
        if num_channels == 1:
            axes = [axes]  # Make it iterable for single channel
        
        for ch in range(num_channels):
            ax = axes[ch]
            if num_channels > 1:
                ax.plot(a[:, ch])
            else:
                ax.plot(a)
            
            ax.set_ylim(-1, 1)
            ax.set_title(f'Channel {ch}')
            ax.set_xlabel("Samples")
            ax.set_ylabel("Amplitude")
            ax.grid()
        
        plt.tight_layout()
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

    def send_float(self, key: str, value: float):
        """
        Send a message to the Mojo audio engine.
        
        Args:
            key: Key for the message 
            *args: Additional arguments for the message
        """

        self.mmm_audio_bridge.update_float_msg([key, value])
        
    def send_gate(self, key: str, value: bool):
        """
        Send a gate message to the Mojo audio engine.
        
        Args:
            key: Key for the message 
            value: Boolean value for the gate
        """

        self.mmm_audio_bridge.update_gate_msg([key, value])

    def send_trig(self, key: str):
        """
        Send a trigger message to the Mojo audio engine.
        
        Args:
            key: Key for the message 
        """

        self.mmm_audio_bridge.update_trig_msg([key])
        
    def send_list(self, key: str, values: list[float]):
        """
        Send a list message to the Mojo audio engine.
        
        Args:
            key: Key for the message 
            values: List of float values
        """

        key_vals = [key]  # Start with the key
        key_vals.extend([str(v) for v in values])

        self.mmm_audio_bridge.update_list_msg(key_vals)

    def send_text(self, key, arg: str | list[str]):
        """
        Send a message to the Mojo audio engine.
        
        Args:
            key: Key for the message 
            *args: Additional arguments for the message
        """

        key_vals = [key]  # Start with the key
        key_vals.extend(arg if isinstance(arg, list) else [arg])

        self.mmm_audio_bridge.update_text_msg(key_vals)
        
    def send_int(self, key: str, value: int) -> None:
        """
        Send an integer message to the Mojo audio engine.
        
        Args:
            key: Key for the message 
            value: Integer value
        """

        self.mmm_audio_bridge.update_int_msg([key, value])

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
