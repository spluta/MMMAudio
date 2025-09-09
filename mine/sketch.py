import pyaudio
import time
import threading
import multiprocessing
import numpy as np

def simple_audio_passthrough():
    # Audio configuration
    CHUNK = 1024        # Buffer size
    FORMAT = pyaudio.paFloat32  # 16-bit audio
    CHANNELS = 1        # Mono
    RATE = 44100        # Sample rate

    # Initialize PyAudio
    p = pyaudio.PyAudio()

    # Open input stream
    input_stream = p.open(format=FORMAT,
                         channels=2,
                         rate=RATE,
                         input=True,
                         frames_per_buffer=CHUNK)

    # Open output stream
    output_stream = p.open(format=FORMAT,
                          channels=2,
                          rate=RATE,
                          output=True,
                          frames_per_buffer=CHUNK)

    print("Starting audio passthrough... Press Ctrl+C to stop")

    def doit():
        max = 0.0
        while True:
            # Read audio data from input
            data = input_stream.read(CHUNK)

            # Convert the mono input to stereo by interleaving with zeros
            # Since the input is in int16 format, we need to interleave properly
            in_data = np.frombuffer(data, dtype=np.float32)
            print(in_data.shape)
            # Interleave in_data (left channel) and mono_zeros (right channel)
            stereo_data = in_data   # Left channel
            print(stereo_data[:10])
            
            for sample in stereo_data:
                if sample > max:
                    max = sample
            print("Max amplitude:", max)
            # Right channel is already zeros
            data = stereo_data.tobytes()
            
            # Write audio data to output
            output_stream.write(data)

    # # threading.Thread(target=doit).start()
    multiprocessing.Process(target=doit).start()

# if __name__ == "__main__":
#     simple_audio_passthrough()
#     multiprocessing.Process(target=doit).start()

    