"""
MMMAudio with Dedicated Process
Runs audio processing in a separate process on its own CPU core
"""
import pyaudio
import numpy as np
import ctypes
from multiprocessing import Process, Value, Event, Queue, Array
from math import ceil
from typing import Optional, Tuple, List
from enum import IntEnum
import mojo.importer

import pyautogui


class AudioCommand(IntEnum):
    STOP_PROCESS = 0
    START_AUDIO = 1
    STOP_AUDIO = 2
    SEND_BOOL = 3
    SEND_FLOAT = 4
    SEND_FLOATS = 5
    SEND_INT = 6
    SEND_INTS = 7
    SEND_TRIG = 8
    SEND_STRING = 9
    SEND_STRINGS = 10
    GET_SAMPLES = 11

class MMMAudio:
    """
    MMMAudio class that runs in its own dedicated process.
    All audio processing happens in a separate process,
    while the main process can send commands and parameter changes.
    """

    def __init__(
        self,
        blocksize: int = 64,
        num_input_channels: int = 2,
        num_output_channels: int = 2,
        in_device: str = "default",
        out_device: str = "default",
        graph_name: str = "FeedbackDelays",
        package_name: str = "examples"
    ):
        """Initialize the MMMAudioProcess class.
        
        Args:
            blocksize: Audio block size.
            num_input_channels: Number of input audio channels.
            num_output_channels: Number of output audio channels.
            in_device: Name of the input audio device.
            out_device: Name of the output audio device.
            graph_name: Name of the Mojo graph to use.
            package_name: Name of the package containing the Mojo graph.
        """
        
        # Store configuration
        self.blocksize = blocksize
        self.num_input_channels = num_input_channels
        self.num_output_channels = num_output_channels
        self.in_device = in_device
        self.out_device = out_device
        self.graph_name = graph_name
        self.package_name = package_name
        
        # Process control
        self.process: Optional[Process] = None
        self.stop_flag = Event()
        self.audio_running = Value(ctypes.c_bool, False)
        self.process_ready = Event()
        
        # Command queue for sending messages to the audio process
        self.command_queue = Queue()
        
        # Response queue for getting data back from audio process
        self.response_queue = Queue()
        
        # Shared values for real-time parameter control
        # Add more as needed for your specific parameters
        self.shared_float_params = {}
        self.shared_int_params = {}
        
        # Sample rate will be set when process initializes
        self.sample_rate = Value(ctypes.c_int, 0)

        self.start_process()
        
    def start_process(self):
        """Start the audio process"""
        if self.process is not None and self.process.is_alive():
            print("[Main] Audio process already running")
            return
        
        self.stop_flag.clear()
        self.process_ready.clear()
        
        self.process = Process(
            target=self._audio_process_main,
            args=(
                self.blocksize,
                self.num_input_channels,
                self.num_output_channels,
                self.in_device,
                self.out_device,
                self.graph_name,
                self.package_name,
                self.stop_flag,
                self.audio_running,
                self.process_ready,
                self.command_queue,
                self.response_queue,
                self.sample_rate
            )
        )
        self.process.start()
        print(f"[Main] Audio process started (PID: {self.process.pid})")
        
        # Wait for process to be ready
        if self.process_ready.wait(timeout=10.0):
            print(f"[Main] Audio process ready, sample rate: {self.sample_rate.value}")
        else:
            print("[Main] Warning: Audio process initialization timeout")
    
    def stop_process(self):
        """Stop the audio process and clean up resources"""
        if self.process is None:
            return
        
        print("[Main] Stopping audio process...")
        self.stop_flag.set()
        
        # Send stop command
        self.command_queue.put((AudioCommand.STOP_PROCESS, None))
        
        self.process.join(timeout=5.0)
        if self.process.is_alive():
            print("[Main] Force terminating audio process")
            self.process.terminate()
            self.process.join(timeout=1.0)
        
        print("[Main] Audio process stopped")
        self.process = None
    
    def start_audio(self):
        """Start audio streaming in the audio process"""
        self.command_queue.put((AudioCommand.START_AUDIO, None))
    
    def stop_audio(self):
        """Stop audio streaming in the audio process"""
        self.command_queue.put((AudioCommand.STOP_AUDIO, None))
    
    def is_running(self) -> bool:
        """Check if audio is currently running"""
        return self.audio_running.value
    
    def is_process_alive(self) -> bool:
        """Check if the audio process is alive"""
        return self.process is not None and self.process.is_alive()
    
    # =========================================================================
    # Message sending methods (same interface as original)
    # =========================================================================
    
    def send_bool(self, key: str, value: bool):
        """Send a bool message to the Mojo audio engine."""
        self.command_queue.put((AudioCommand.SEND_BOOL, (key, value)))
    
    def send_float(self, key: str, value: float):
        """Send a float to the Mojo audio engine."""
        self.command_queue.put((AudioCommand.SEND_FLOAT, (key, value)))
    
    def send_floats(self, key: str, values: List[float]):
        """Send a list of floats to the Mojo audio engine."""
        self.command_queue.put((AudioCommand.SEND_FLOATS, (key, values)))
    
    def send_int(self, key: str, value: int):
        """Send an integer to the Mojo audio engine."""
        self.command_queue.put((AudioCommand.SEND_INT, (key, value)))
    
    def send_ints(self, key: str, values: List[int]):
        """Send a list of integers to the Mojo audio engine."""
        self.command_queue.put((AudioCommand.SEND_INTS, (key, values)))
    
    def send_trig(self, key: str):
        """Send a trigger message to the Mojo audio engine."""
        self.command_queue.put((AudioCommand.SEND_TRIG, (key,)))
    
    def send_string(self, key: str, value: str):
        """Send a string message to the Mojo audio engine."""
        self.command_queue.put((AudioCommand.SEND_STRING, (key, value)))
    
    def send_strings(self, key: str, args: List[str]):
        """Send a list of string messages to the Mojo audio engine."""
        self.command_queue.put((AudioCommand.SEND_STRINGS, (key, args)))
    
    # =========================================================================
    # Methods that need response from audio process
    # =========================================================================
    
    def get_samples(self, samples: int) -> np.ndarray:
        """Get samples from the audio process (blocking call)."""
        self.command_queue.put((AudioCommand.GET_SAMPLES, samples))
        
        # Wait for response
        try:
            response = self.response_queue.get(timeout=30.0)
            if response[0] == "SAMPLES":
                return response[1]
            else:
                print(f"[Main] Unexpected response: {response[0]}")
                return np.zeros((samples, self.num_output_channels))
        except Exception as e:
            print(f"[Main] Error getting samples: {e}")
            return np.zeros((samples, self.num_output_channels))
    
    def plot(self, samples: int, clear: bool = True):
        """Plot samples from the audio process."""
        import matplotlib.pyplot as plt
        
        returned_samples = self.get_samples(samples)
        
        num_channels = returned_samples.shape[1] if len(returned_samples.shape) > 1 else 1
        
        fig, axes = plt.subplots(num_channels, 1, figsize=(10, 3 * num_channels))
        if num_channels == 1:
            axes = [axes]
        
        for ch in range(num_channels):
            ax = axes[ch]
            if num_channels > 1:
                ax.plot(returned_samples[:, ch])
            else:
                ax.plot(returned_samples)
            
            ax.set_ylim(-1, 1)
            ax.set_title(f'Channel {ch}')
            ax.set_xlabel("Samples")
            ax.set_ylabel("Amplitude")
            ax.grid()
        
        plt.tight_layout()
        plt.show(block=False)
        
        return returned_samples
    
    # =========================================================================
    # Static method that runs in the separate process
    # =========================================================================
        
    @staticmethod
    def _audio_process_main(
        blocksize: int,
        num_input_channels: int,
        num_output_channels: int,
        in_device: str,
        out_device: str,
        graph_name: str,
        package_name: str,
        stop_flag: Event,
        audio_running: Value,
        process_ready: Event,
        command_queue: Queue,
        response_queue: Queue,
        sample_rate_value: Value
    ):
        """
        Main function for the audio process.
        """
        import sys
        import os
        import numpy as np
        import pyaudio
        import asyncio
        import threading
        from math import ceil
        import pyautogui
        import queue
        
        pid = os.getpid()
        print(f"[PID {pid}] Audio process starting...")
        sys.stdout.flush()
        
        # =========================================================================
        # Helper function to get device info
        # =========================================================================
        def get_device_info(p_temp, device_name, is_input=True):
            if device_name != "default":
                for i in range(p_temp.get_device_count()):
                    dev_info = p_temp.get_device_info_by_index(i)
                    if device_name in dev_info['name']:
                        return dev_info
                print(f"[PID {pid}] Device '{device_name}' not found, using default")
            
            if is_input:
                return p_temp.get_default_input_device_info()
            else:
                return p_temp.get_default_output_device_info()
        
        # =========================================================================
        # Initialize Mojo bridge
        # =========================================================================
        try:
            from mmm_python.make_solo_graph import make_solo_graph
            import importlib
            
            make_solo_graph(graph_name, package_name)
            MMMAudioBridge = importlib.import_module(f"{graph_name}Bridge")
            
            bridge_file = graph_name + "Bridge" + ".mojo"
            if os.path.exists(bridge_file):
                os.remove(bridge_file)
        except Exception as e:
            print(f"[PID {pid}] Error loading Mojo bridge: {e}")
            sys.stdout.flush()
            return
        
        # =========================================================================
        # Initialize PyAudio and get device info
        # =========================================================================
        p_temp = pyaudio.PyAudio()
        in_device_info = get_device_info(p_temp, in_device, True)
        out_device_info = get_device_info(p_temp, out_device, False)
        p_temp.terminate()
        
        if in_device_info['defaultSampleRate'] != out_device_info['defaultSampleRate']:
            print(f"[PID {pid}] Sample rate mismatch!")
            sys.stdout.flush()
            return
        
        sample_rate = int(in_device_info['defaultSampleRate'])
        sample_rate_value.value = sample_rate
        
        in_device_index = in_device_info['index']
        out_device_index = out_device_info['index']
        
        actual_input_channels = min(num_input_channels, int(in_device_info['maxInputChannels']))
        actual_output_channels = min(num_output_channels, int(out_device_info['maxOutputChannels']))
        
        print(f"[PID {pid}] Sample rate: {sample_rate}, Block size: {blocksize}")
        print(f"[PID {pid}] Input channels: {actual_input_channels}, Output channels: {actual_output_channels}")
        sys.stdout.flush()
        
        # =========================================================================
        # Initialize Mojo audio bridge
        # =========================================================================
        mmm_audio_bridge = MMMAudioBridge.MMMAudioBridge(sample_rate, blocksize)
        mmm_audio_bridge.set_channel_count((actual_input_channels, actual_output_channels))
        
        screen_dims = pyautogui.size()
        mmm_audio_bridge.set_screen_dims(screen_dims)
        
        # =========================================================================
        # Shared state for callback
        # =========================================================================
        audio_active = threading.Event()
        input_queue = queue.Queue(maxsize=32)
        
        # Lock for thread-safe bridge access
        bridge_lock = threading.Lock()
        
        # =========================================================================
        # Audio callbacks
        # =========================================================================
        def input_callback(in_data, frame_count, time_info, status):
            """Called by PyAudio when input data is available"""
            if audio_active.is_set():
                try:
                    input_queue.put_nowait(in_data)
                except queue.Full:
                    pass  # Drop frame if queue is full
            return (None, pyaudio.paContinue)
        
        def output_callback(in_data, frame_count, time_info, status):
            """Called by PyAudio when output data is needed"""
            if not audio_active.is_set():
                # Return silence when not active
                silence = np.zeros(
                    frame_count * actual_output_channels,
                    dtype=np.float32
                )
                return (silence.tobytes(), pyaudio.paContinue)
            
            try:
                # Get input data from queue
                try:
                    input_bytes = input_queue.get_nowait()
                    in_array = np.frombuffer(input_bytes, dtype=np.float32)
                except queue.Empty:
                    in_array = np.zeros(
                        frame_count * actual_input_channels,
                        dtype=np.float32
                    )
                
                
                out_buffer = np.zeros(
                    (frame_count, actual_output_channels),
                    dtype=np.float64
                )
                # Process through Mojo bridge
                with bridge_lock:
                    mmm_audio_bridge.next(in_array, out_buffer)
                
                out_buffer = np.clip(out_buffer, -1.0, 1.0)
                output_bytes = out_buffer.astype(np.float32).tobytes()
                
                return (output_bytes, pyaudio.paContinue)
            
            except Exception as e:
                print(f"[PID {pid}] Output callback error: {e}")
                sys.stdout.flush()
                silence = np.zeros(
                    frame_count * actual_output_channels,
                    dtype=np.float32
                )
                return (silence.tobytes(), pyaudio.paContinue)
        
        # =========================================================================
        # Mouse position tracking
        # =========================================================================
        async def get_mouse_position(delay: float = 0.01):
            while not stop_flag.is_set():
                try:
                    x, y = pyautogui.position()
                    x = x / pyautogui.size().width
                    y = y / pyautogui.size().height
                    with bridge_lock:
                        mmm_audio_bridge.update_mouse_pos([x, y])
                except:
                    pass
                await asyncio.sleep(delay)
        
        mouse_thread = threading.Thread(
            target=asyncio.run,
            args=(get_mouse_position(0.01),),
            daemon=False
        )
        mouse_thread.start()
        
        # =========================================================================
        # Initialize PyAudio with callbacks
        # =========================================================================
        p = pyaudio.PyAudio()
        format_code = pyaudio.paFloat32
        
        input_stream = p.open(
            format=format_code,
            channels=actual_input_channels,
            rate=sample_rate,
            input=True,
            input_device_index=in_device_index,
            frames_per_buffer=blocksize,
            stream_callback=input_callback
        )
        
        output_stream = p.open(
            format=format_code,
            channels=actual_output_channels,
            rate=sample_rate,
            output=True,
            output_device_index=out_device_index,
            frames_per_buffer=blocksize,
            stream_callback=output_callback
        )
        
        # Start streams immediately (they'll output silence until activated)
        input_stream.start_stream()
        output_stream.start_stream()
        
        print(f"[PID {pid}] Streams started")
        sys.stdout.flush()
        
        # =========================================================================
        # Signal ready
        # =========================================================================
        process_ready.set()
        print(f"[PID {pid}] Audio process ready")
        sys.stdout.flush()
        
        # =========================================================================
        # Command processing loop
        # =========================================================================
        def handle_stop_process(args):
            print(f"[PID {pid}] Received stop command")
            sys.stdout.flush()
            return False

        def handle_start_audio(args):
            audio_active.set()
            audio_running.value = True
            print(f"[PID {pid}] Audio activated")
            sys.stdout.flush()
            return True

        def handle_stop_audio(args):
            audio_active.clear()
            audio_running.value = False
            # Clear the input queue
            while not input_queue.empty():
                try:
                    input_queue.get_nowait()
                except:
                    break
            print(f"[PID {pid}] Audio deactivated")
            sys.stdout.flush()
            return True

        def handle_send_bool(args):
            key, value = args
            with bridge_lock:
                mmm_audio_bridge.update_bool_msg([key, value])
            return True

        def handle_send_float(args):
            key, value = args
            with bridge_lock:
                mmm_audio_bridge.update_float_msg([key, value])
            return True

        def handle_send_floats(args):
            key, values = args
            key_vals = [key]
            key_vals.extend(values)
            with bridge_lock:
                mmm_audio_bridge.update_floats_msg(key_vals)
            return True

        def handle_send_int(args):
            key, value = args
            with bridge_lock:
                mmm_audio_bridge.update_int_msg([key, value])
            return True

        def handle_send_ints(args):
            key, values = args
            key_vals = [key]
            key_vals.extend([int(i) for i in values])
            with bridge_lock:
                mmm_audio_bridge.update_ints_msg(key_vals)
            return True

        def handle_send_trig(args):
            key = args[0]
            with bridge_lock:
                mmm_audio_bridge.update_trig_msg([key])
            return True

        def handle_send_string(args):
            key, value = args
            with bridge_lock:
                mmm_audio_bridge.update_string_msg([key, str(value)])
            return True

        def handle_send_strings(args):
            key, values = args
            key_vals = [key]
            key_vals.extend(values)
            with bridge_lock:
                mmm_audio_bridge.update_strings_msg(key_vals)
            return True

        def handle_get_samples(args):
            samples = args
            blocks = ceil(samples / blocksize)
            waveform = np.zeros(
                samples * actual_output_channels,
                dtype=np.float64
            ).reshape(samples, actual_output_channels)

            in_buf = np.zeros(
                (blocksize, actual_input_channels),
                dtype=np.float64
            )
            temp_out = np.zeros(
                (blocksize, actual_output_channels),
                dtype=np.float64
            )

            with bridge_lock:
                for i in range(blocks):
                    mmm_audio_bridge.next(in_buf, temp_out)
                    for j in range(temp_out.shape[0]):
                        if i * blocksize + j < samples:
                            waveform[i * blocksize + j] = temp_out[j]

            response_queue.put(("SAMPLES", waveform))
            return True

        command_handlers = [
            handle_stop_process,
            handle_start_audio,
            handle_stop_audio,
            handle_send_bool,
            handle_send_float,
            handle_send_floats,
            handle_send_int,
            handle_send_ints,
            handle_send_trig,
            handle_send_string,
            handle_send_strings,
            handle_get_samples,
        ]

        while not stop_flag.is_set():
            try:
                try:
                    command, args = command_queue.get(timeout=0.1)
                except:
                    continue

                try:
                    command_index = int(command)
                except (TypeError, ValueError):
                    print(f"[PID {pid}] Unknown command: {command}")
                    sys.stdout.flush()
                    continue

                if command_index < 0 or command_index >= len(command_handlers):
                    print(f"[PID {pid}] Unknown command: {command}")
                    sys.stdout.flush()
                    continue

                should_continue = command_handlers[command_index](args)
                if not should_continue:
                    break
            
            except Exception as e:
                print(f"[PID {pid}] Command error: {e}")
                sys.stdout.flush()
        
        # =========================================================================
        # Cleanup (called when stop command is received or on error)
        # =========================================================================
        print(f"[PID {pid}] Cleaning up...")
        sys.stdout.flush()
        
        audio_active.clear()
        
        input_stream.stop_stream()
        input_stream.close()
        output_stream.stop_stream()
        output_stream.close()
        p.terminate()
        
        print(f"[PID {pid}] Audio process terminated")
        sys.stdout.flush()

def list_audio_devices():
    p_temp = pyaudio.PyAudio()
    p_temp.get_device_count()
    for i in range(p_temp.get_device_count()):
        dev_info = p_temp.get_device_info_by_index(i)
        print(f"Device {i}: {dev_info['name']}")
        print(f"  Input channels: {dev_info['maxInputChannels']}")
        print(f"  Output channels: {dev_info['maxOutputChannels']}")
        print(f"  Default sample rate: {dev_info['defaultSampleRate']} Hz")
        print()
    p_temp.terminate()