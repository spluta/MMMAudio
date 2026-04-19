from mmm_audio import *

struct TestTopNFreqs(Movable, Copyable):
    var world: World
    var analyzer: FFTProcess[TopNFreqs,ifft=False,input_window_shape=WindowType.hann]
    var sines: List[Osc[]]
    var m: Messenger
    var freqs: List[MFloat[]]
    var out_sines: List[Osc[]]
    var out_pairs: List[Tuple[Float64, Float64]]
    var changed: List[Changed[Int]]

    fn __init__(out self, world: World):
        self.world = world
        p = TopNFreqs(world[].sample_rate, 1024, num_peaks=3, sort_by_freq=True, thresh=-30.0)
        self.analyzer = FFTProcess[TopNFreqs,ifft=False,input_window_shape=WindowType.hann](self.world,p^, window_size=1024, hop_size=512)
        self.sines = [Osc(self.world) for _ in range(3)]
        self.m = Messenger(self.world)
        self.freqs = [440.0 for _ in range(3)]
        self.out_sines = [Osc(self.world) for _ in range(3)]
        self.out_pairs = [(0.0, 0.0) for _ in range(3)]
        self.changed = [Changed[Int](0) for _ in range(3)]

    fn next(mut self) -> MFloat[2]:
        self.m.update(self.freqs, "freqs")
        s = 0.0
        for i in range(len(self.sines)):
             s += self.sines[i].next(self.freqs[i])
        _ = self.analyzer.next(s)

        out_pairs = self.analyzer.buffered_process.process.process.get_features_ptr()  # Get a pointer to the freq, amp pairs

        for i in range(3):
            self.world[].print("hearing ", out_pairs[][i][0], "Hz with amplitude", out_pairs[][i][1], n_blocks = 20, end = " ")
        self.world[].print("")

        o = splay(
            [self.out_sines[i].next(out_pairs[][i][0]) * out_pairs[][i][1] for i in range(3)],
            self.world
        )

        return o * 0.1

