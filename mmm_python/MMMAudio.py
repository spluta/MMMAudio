import sys, os
import numpy as np
import sounddevice as sd
import asyncio

from pythonosc.dispatcher import Dispatcher
from pythonosc.osc_server import AsyncIOOSCUDPServer
import threading

import mojo.importer

import matplotlib.pyplot as plt

from sympy import arg
import mmm_python.Scheduler as Scheduler

from math import ceil
    
sys.path.insert(0, "mmm_src")

class MMMAudio:

    def get_device_info(self, device_name, is_input=True):
        """Look for the audio device by name, or return default device info if not found.
        
        Args:
            device_name: Name of the desired audio device
            is_input: Boolean indicating if the device is for input (True) or output (False). Default is True.
        """

        print(f"Looking for audio device: {device_name}")
        
        if device_name != "default":
            device_index = None
            devices = sd.query_devices()
            
            for i, dev_info in enumerate(devices):
                print(f"Checking device {i}: {dev_info['name']}")
                if device_name in dev_info['name']:
                    device_index = i
                    print(f"Using audio device: {dev_info['name']}")
                    break
            
            if device_index is not None:
                device_info = sd.query_devices(device_index)
            else:
                print(f"Audio device '{device_name}' not found. Using default device.")
                if is_input:
                    device_info = sd.query_devices(kind='input')
                else:
                    device_info = sd.query_devices(kind='output')
        else:
            if is_input:
                device_info = sd.query_devices(kind='input')
            else:
                device_info = sd.query_devices(kind='output')

        return device_info


    def __init__(self, blocksize=64, num_input_channels=2, num_output_channels=2, in_device="default", out_device="default", graph_name="FeedbackDelays", package_name="examples", latency="default"):
        """Initialize the MMMAudio class.
        
        Args:
            blocksize: Audio block size.
            num_input_channels: Number of input audio channels.
            num_output_channels: Number of output audio channels.
            in_device: Name of the input audio device (will use operating system default if not found).
            out_device: Name of the output audio device (will use operating system default if not found).
            graph_name: Name of the Mojo graph to use.
            package_name: Name of the package containing the Mojo graph. This is the folder in which the .mojo file is located.
        """
        self.device_index = None
        # this makes the graph file that should work
        from mmm_python.make_solo_graph import make_solo_graph
        
        import importlib
        # generate the Mojo graph bridge file
        make_solo_graph(graph_name, package_name)

        # this will import the generated Mojo module
        MMMAudioBridge = importlib.import_module(f"{graph_name}Bridge")
        if os.path.exists(graph_name + "Bridge" + ".mojo"):
            os.remove(graph_name + "Bridge" + ".mojo")

        self.blocksize = blocksize
        self.num_input_channels = num_input_channels
        self.num_output_channels = num_output_channels
        self.counter = 0
        self.joysticks = []

        self.running = False

        self.scheduler = Scheduler.Scheduler()

        in_device_info = self.get_device_info(in_device, True)
        out_device_info = self.get_device_info(out_device, False)

        if in_device_info['default_samplerate'] != out_device_info['default_samplerate']:
            print(f"Warning: Sample rates do not match ({in_device_info['default_samplerate']} vs {out_device_info['default_samplerate']})")
            print("Exiting.")
            return

        self.sample_rate = int(in_device_info['default_samplerate'])
        self.in_device_index = in_device_info['index']
        self.out_device_index = out_device_info['index']
        self.num_input_channels = min(self.num_input_channels, int(in_device_info['max_input_channels']))
        self.num_output_channels = min(self.num_output_channels, int(out_device_info['max_output_channels']))

        self.out_buffer = np.zeros((self.blocksize, self.num_output_channels), dtype=np.float64)

        # Initialize the Mojo module AudioEngine

        self.mmm_audio_bridge = MMMAudioBridge.MMMAudioBridge(self.sample_rate, self.blocksize)
        # Even though MMMAudioBridge can be passed the arguments for channel count, if one tries
        # to access that data on the Mojo side, things get weird, so we're breaking up the process
        # of getting all the parameters over to Mojo into multiple steps. That's why .set_channel_count 
        # is called here.
        self.mmm_audio_bridge.set_channel_count((self.num_input_channels, self.num_output_channels))

        self.mouse_active = True

        import platform
        if platform.system() == 'Linux' and 'microsoft' in platform.release().lower():
            print("The platform is WSL. Mouse position tracking is not supported. Use `mmm_audio.fake_mouse()` to simulate mouse movement.")
        else:
            print("Mac or Linux detected. Initializing mouse position tracking.")
            import pyautogui

            async def _get_mouse_position(delay: float = 0.01):
                while True:
                    if self.mouse_active:
                        x, y = pyautogui.position()
                        x = x / pyautogui.size().width
                        y = y / pyautogui.size().height
                        
                        self.mmm_audio_bridge.update_mouse_pos([ x, y ])

                    await asyncio.sleep(delay)

            screen_dims = pyautogui.size()
            self.mmm_audio_bridge.set_screen_dims(screen_dims)  # Initialize with sample rate and screen size

            # the mouse thread will always be running
            threading.Thread(target=asyncio.run, args=(_get_mouse_position(0.01),)).start()
        
        # self.returned_samples = []
        self.audio_stopper = threading.Event()
        self.returned_samples = []

        lat = 'high'
        if latency == "default":
            lat = sd.default.latency
        else:
            lat = latency

        self.input_stream = sd.InputStream(
            device=self.in_device_index,
            channels=self.num_input_channels,
            samplerate=self.sample_rate,
            blocksize=self.blocksize,
            dtype='float32',
            latency = lat
        )

        self.output_stream = sd.OutputStream(
            device=self.out_device_index,
            channels=self.num_output_channels,
            samplerate=self.sample_rate,
            blocksize=self.blocksize,
            dtype='float32',
            latency = lat
        )

        # Start streams
        self.input_stream.start()
        self.output_stream.start()

    def fake_mouse(self, x_size: float = 300, y_size: float = 300):
        from mmm_python.GUI import Slider2D
        from mmm_python.MMMAudio import MMMAudio
        from PySide6.QtWidgets import QApplication, QWidget, QVBoxLayout, QCheckBox

        app = QApplication([])
        app.quitOnLastWindowClosed = True 

        # Create the main window
        window = QWidget()
        window.setWindowTitle("Fake Mouse Position Controller")
        window.resize(x_size, y_size)

        # Create layout
        layout = QVBoxLayout()

        slider2d = Slider2D(x_size, y_size)

        def on_slider_change(x, y):
            self.mmm_audio_bridge.update_mouse_pos([ x, y ])
        # def slider_mouse_updown(is_down):
        #     self.mmm_audio_bridge.send_bool("mouse_down", is_down)  # set amplitude to 0 when mouse is released

        slider2d.value_changed.connect(on_slider_change)
        # slider2d.mouse_updown.connect(slider_mouse_updown)
        layout.addWidget(slider2d)
        window.setLayout(layout)
        window.show()
        app.exec()

    def get_samples(self, samples):
        """Get a specified number of audio samples from MMMAudio. This should be called when audio is stopped. It will push the audio graph forward `samples` samples.
        
        Args:
            samples: Number of samples to get.

        Returns:
            Numpy array of shape (samples, num_output_channels) containing the audio samples.

        """
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
    
    def get_last_plot(self):
        """Get the last plotted audio samples from MMMAudio.
        
        Returns:
            Numpy array of shape (samples, num_output_channels) containing the last plotted audio samples.

        """
        return self.returned_samples
    
    def plot(self, samples, clear=True):
        """Plot the specified number of audio samples from MMMAudio. This should be called when audio is stopped. It will push the audio graph forward `samples` samples and plot the output. The samples will be stored in `self.returned_samples`.

        Args:
            samples: Number of samples to plot.
            clear: Whether to clear the previous plot before plotting. Default is True.
        """

        self.returned_samples = self.get_samples(samples)
        # if clear:
        #     plt.clf()
        
        # Plot each channel on its own subplot
        num_channels = self.returned_samples.shape[1] if len(self.returned_samples.shape) > 1 else 1
        
        fig, axes = plt.subplots(num_channels, 1, figsize=(10, 3 * num_channels))
        if num_channels == 1:
            axes = [axes]  # Make it iterable for single channel
        
        for ch in range(num_channels):
            ax = axes[ch]
            if num_channels > 1:
                ax.plot(self.returned_samples[:, ch])
            else:
                ax.plot(self.returned_samples)
            
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
            # Read input
            in_data, overflowed = self.input_stream.read(self.blocksize)
            if overflowed:
                print("Input overflow")
            in_data = in_data.flatten().astype(np.float32)

            # Process
            self.mmm_audio_bridge.next(in_data, self.out_buffer)
            self.out_buffer = np.clip(self.out_buffer, -1.0, 1.0)

            # Write output
            underflowed = self.output_stream.write(self.out_buffer.astype(np.float32))
            if underflowed:
                print("Output underflow")

    def start_audio(self):
        """Start or restart the audio processing loop."""
        
        print("Starting audio...")
        if not self.running:
            self.running = True
            print(f"Audio started with sample rate: {self.sample_rate}, block size: {self.blocksize}, input channels: {self.num_input_channels}, output channels: {self.num_output_channels}")
            
            def audio_callback(indata, outdata, frames, time, status):
                if status:
                    print(f"Audio status: {status}")
                
                in_data = indata.flatten().astype(np.float32)
                
                self.mmm_audio_bridge.next(in_data, self.out_buffer)
                self.out_buffer = np.clip(self.out_buffer, -1.0, 1.0)
                
                outdata[:] = self.out_buffer.reshape(outdata.shape)
            
            self.stream = sd.Stream(
                device=(self.in_device_index, self.out_device_index),
                channels=(self.num_input_channels, self.num_output_channels),
                samplerate=self.sample_rate,
                blocksize=self.blocksize,
                dtype='float32',
                callback=audio_callback
            )
            self.stream.start()

    def stop_audio(self):
        """Stop the audio processing loop."""
        if self.running:
            self.running = False
            print("Stopping audio...")
            self.stream.stop()
            self.stream.close()

    def send_bool(self, key: str, value: bool):
        """
        Send a bool message to the Mojo audio engine.
        
        Args:
            key: Key for the message 
            value: Boolean value for the bool
        """

        self.mmm_audio_bridge.update_bool_msg([key, value])

    # def send_bools(self, key: str, args: list):
    #     """
    #     Send a list of booleans to the Mojo audio engine.
        
    #     Args:
    #         key: Key for the message 
    #         args: List of float values
    #     """

    #     key_vals = [key]
    #     key_vals.extend(args)

    #     self.mmm_audio_bridge.update_bools_msg(key_vals)

    def send_float(self, key: str, value: float):
        """
        Send a float to the Mojo audio engine.
        
        Args:
            key: Key for the message 
            value: the float value to send
        """

        self.mmm_audio_bridge.update_float_msg([key, value])

    def send_floats(self, key: str, values: list[float]):
        """
        Send a list of floats to the Mojo audio engine.
        
        Args:
            key: Key for the message 
            values: List of float values
        """

        key_vals = [key]
        key_vals.extend(values)

        self.mmm_audio_bridge.update_floats_msg(key_vals)
        
    def send_int(self, key: str, value: int) -> None:
        """
        Send an integer to the Mojo audio engine.
        
        Args:
            key: Key for the message 
            value: Integer value
        """

        self.mmm_audio_bridge.update_int_msg([key, value])

    def send_ints(self, key: str, values: list[int]):
        """
        Send a list of integers to the Mojo audio engine.
        
        Args:
            key: Key for the message 
            values: List of integer values
        """

        key_vals = [key]
        key_vals.extend([int(i) for i in values])

        self.mmm_audio_bridge.update_ints_msg(key_vals)

    def send_trig(self, key: str):
        """
        Send a trigger message to the Mojo audio engine.
        
        Args:
            key: Key for the message 
        """

        self.mmm_audio_bridge.update_trig_msg([key])
    
    # def send_trigs(self, key: str, args):
    #     """
    #     Send a list of triggers to the Mojo audio engine.
        
    #     This method is a bit usual since triggers are typically single events,
    #     but here we send a list of boolean values representing multiple triggers.
    #     This way, on the Mojo side, there may be a List of events, only some of which
    #     are to be triggered at one time. Sending a list of booleans allows for this.
    #     Note that these will act as `Trig`s on the Mojo side so if one element in the
    #     list is False, it will just stay as False, if it is True, it will trigger and then
    #     go back to False on the next audio sample.
        
    #     Args:
    #         key: Key for the message 
    #         values: List of boolean values
    #     """

    #     key_vals = [key]
    #     key_vals.extend(args)

    #     self.mmm_audio_bridge.update_trigs_msg(key_vals)
        
    def send_string(self, key: str, value: str):
        """
        Send a string message to the Mojo audio engine.

        Args:
            key: Key for the message 
            value: String value for the message
        """

        self.mmm_audio_bridge.update_string_msg([key, str(value)])

    def send_strings(self, key: str, args: list[str]):
        """
        Send a list of string messages to the Mojo audio engine.

        Args:
            key: Key for the message 
            args: list of strings for the message
        """
        key_vals = [key]
        key_vals.extend(args)

        self.mmm_audio_bridge.update_strings_msg(key_vals)
 

def list_audio_devices():
    devices = sd.query_devices()
    
    for i, dev_info in enumerate(devices):
        print(f"Device {i}: {dev_info['name']}")
        print(f"  Input channels: {dev_info['max_input_channels']}")
        print(f"  Output channels: {dev_info['max_output_channels']}")
        print(f"  Default sample rate: {dev_info['default_samplerate']} Hz")
        print()