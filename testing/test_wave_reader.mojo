from python import PythonObject
from python import Python
from testing import assert_almost_equal

from mmm_audio.sound_file import *
from mmm_audio import *


from python import Python

fn main() raises:
    # files = ["resources/small_wavetable8.wav"]
    
    # this requires a list of files to test against
    files = ["user_files/wave_file/Shivererf32.wav", "user_files/wave_file/Shivererf64.wav", "user_files/wave_file/ShivererI16.wav", "user_files/wave_file/ShivererI24.wav", "user_files/wave_file/ShivererI32.wav", "user_files/wave_file/ShivererU8.wav"]
    
    for file in files:
        
        try:
            # Quick one-liner to read audio
            var scipy = Python.import_module("scipy")
            var np = Python.import_module("numpy")
            var result = scipy.io.wavfile.read(file)
            var sample_rate = result[0]
            var data = result[1]
            print("Data type:", data.dtype)
            if data.dtype == np.int16 or data.dtype == np.int32 or data.dtype == np.uint8:
                data = data.astype(np.float64)/np.iinfo(result[1].dtype).max
            else:
                data = data.astype(np.float64)
            
            print("Sample rate:", sample_rate)
            print("Shape:", data.shape)

            header = read_wav_header(file)
            print_wav_info(header)
            wav = read_wav_SIMDs[2](file, header)
            print(len(wav), len(data))
            try:
                for i in range(header.num_samples):
                    assert_almost_equal(wav[i][0], py_to_float64(data[i][0]), String(i))
                    assert_almost_equal(wav[i][1], py_to_float64(data[i][1]), String(i))
            except err:
                print("What happened: ", err)

            print("WAV file read successfully and data matches NumPy array.")
            # write_wav_file("user_files/wave_file/test_output3.wav", wav, header.sample_rate)
            
        except err:
            print("Error reading WAV file: ", err)
        
