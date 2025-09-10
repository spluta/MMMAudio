from mmm_src.MMMAudio import *
list_audio_devices()

# instantiate and load the graph
mmm_audio = MMMAudio(128, num_input_channels=12, num_output_channels=12, in_device="Fireface UFX+ (24059506)", out_device="Fireface UFX+ (24059506)", graph_name="Record", package_name="examples")
mmm_audio.start_audio() 

mmm_audio.send_msg("print_inputs")  

mmm_audio.stop_audio()
