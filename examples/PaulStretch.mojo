from mmm_audio import *

comptime window_size = 2048
comptime hop_size = window_size // 4

struct PaulStretchWindow[window_size: Int](FFTProcessable):
    comptime bins = (Self.window_size // 2) + 1
    var world: World
    var m: Messenger
    var rtpghi_mix: Float64
    var rtpghiL: RTPGHI
    var rtpghiR: RTPGHI
    var l_mags: List[Float64]
    var r_mags: List[Float64]
    var l_phases: List[Float64]
    var r_phases: List[Float64]

    def __init__(out self, world: World):
        self.world = world
        self.m = Messenger(self.world)

        self.rtpghi_mix = 0.0
        self.rtpghiL = RTPGHI(Self.window_size, hop_size)
        self.rtpghiR = RTPGHI(Self.window_size, hop_size)
        self.l_mags = List[Float64](length=Self.bins, fill=0.0)
        self.r_mags = List[Float64](length=Self.bins, fill=0.0)
        self.l_phases = List[Float64](length=Self.bins, fill=0.0)
        self.r_phases = List[Float64](length=Self.bins, fill=0.0)

    def get_messages(mut self):
        self.m.update(self.rtpghi_mix, "rtpghi_mix")

    def next_stereo_frame(
        mut self, 
        mut mags: List[MFloat[2]], 
        mut phases: List[MFloat[2]]
    ) -> None:
        if self.rtpghi_mix > 0.0:
            # Extract mono channels from stereo input
            for i in range(Self.bins):
                self.l_mags[i] = mags[i][0]
                self.r_mags[i] = mags[i][1]

            # Process through RTPGHI
            # On return, l_mags/r_mags contain the delayed magnitudes
            # and l_phases/r_phases contain the matching reconstructed phases
            self.rtpghiL.process_frame(self.l_mags, self.l_phases)
            self.rtpghiR.process_frame(self.r_mags, self.r_phases)

            # Write back synchronized magnitudes and phases
            for i in range(Self.bins):
                mags[i][0] = self.l_mags[i]
                mags[i][1] = self.r_mags[i]
                phases[i][0] = self.l_phases[i]
                phases[i][1] = self.r_phases[i]

        if self.rtpghi_mix < 1.0:
            for ref p in phases:
                offset = MFloat[2](
                    random_float64(0.0, Math.tau),
                    random_float64(0.0, Math.tau)
                )
                p = (p + (offset * (1.0 - self.rtpghi_mix))) % Math.tau

struct PaulStretch(Movable, Copyable):
    var world: World
    var buffer: SIMDBuffer[2]
    var saw: LFSaw[1]
    var paul_stretch: FFTProcess[PaulStretchWindow[window_size],ifft=True,input_window_shape=WindowType.hann,output_window_shape=WindowType.hann]
    var m: Messenger
    var dur_mult: Float64

    def __init__(out self, world: World):
        self.world = world
        self.buffer = SIMDBuffer.load("resources/Shiverer.wav")
        self.saw = LFSaw(self.world)

        self.paul_stretch = FFTProcess[
                PaulStretchWindow[window_size],
                ifft=True,
                input_window_shape=WindowType.hann,
                output_window_shape=WindowType.hann
            ](self.world,process=PaulStretchWindow[window_size](self.world),window_size=window_size,hop_size=hop_size)

        self.m = Messenger(self.world)
        self.dur_mult = 40.0

    def next(mut self) -> SIMD[DType.float64,2]:
        self.m.update(self.dur_mult,"dur_mult")
        speed = 1.0/self.buffer.duration * (1.0/self.dur_mult)
        phase = self.saw.next(speed)*0.5 + 0.5
        o = self.paul_stretch.next_from_stereo_buffer(self.buffer, phase)
        return o

