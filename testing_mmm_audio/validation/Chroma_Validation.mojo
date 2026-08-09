from mmm_audio import *

comptime fftsize: Int = 1024
comptime hopsize: Int = 512
comptime n_chroma: Int = 12

# struct ChromaTestSuite(FFTProcessable):
# 	var chroma: Chroma
# 	var data: List[List[Float64]]

# 	def __init__(out self, w: World):
# 		self.chroma = Chroma[](w[].sample_rate, fftsize, n_chroma=n_chroma)
# 		self.data = List[List[Float64]]()

# 	def next_frame(mut self, mut mags: List[Float64], mut phases: List[Float64]):
# 		self.chroma.next_frame(mags, phases)
# 		self.data.append(self.chroma.chroma.copy())

def main() raises:
	buf = Buffer.load("resources/Shiverer.wav")

	results = Chroma.buf_analysis(buf, chan=0, start_frame=0, num_frames=None, n_chroma=n_chroma, tuning=0.0, norm=inf[DType.float64](), power=2.0, ctroct=5.0, octwidth=2.0, base_c=True, fft_size=fftsize, hop_size=hopsize, padding=Padding.half_window)

	with open("testing_mmm_audio/validation/mojo_results/chroma_mojo_results.csv", "w") as f:
		f.write("windowsize," + String(fftsize) + "\n")
		f.write("hopsize," + String(hopsize) + "\n")
		f.write("n_chroma," + String(n_chroma) + "\n")
		f.write("Chroma\n")
		for i, frame in enumerate(results):
			if i > 0:
				f.write("\n")
			for j, value in enumerate(frame):
				if j > 0:
					f.write(",")
				f.write(String(value))
