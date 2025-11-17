from mmm_src.MMMAudio import MMMAudio
from mmm_src.Patterns import Pseq

mmm_audio = MMMAudio(256, graph_name="SpectralFreezeExample", package_name="examples")
mmm_audio.start_audio()

# make a sequence that toggles the freeze gate on and off
seq = Pseq([True, False])

mmm_audio.send_bool("freeze_gate", seq.next())

mmm_audio.stop_audio()