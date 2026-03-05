from mmm_audio import *

comptime two_pi = 2.0 * pi

struct SpectralFreezeWindow[window_size: Int](FFTProcessable):
    var world: World
    var m: Messenger
    var bin: Int
    var freeze_gate: Bool
    var stored_phases: List[SIMD[DType.float64, 2]]
    var stored_mags: List[SIMD[DType.float64, 2]]

    fn __init__(out self, world: World, namespace: Optional[String] = None):
        self.world = world
        self.bin = (Self.window_size // 2) + 1
        self.m = Messenger(world, namespace)
        self.freeze_gate = False
        self.stored_phases = [SIMD[DType.float64, 2](0.0) for _ in range(Self.window_size)]
        self.stored_mags = [SIMD[DType.float64, 2](0.0) for _ in range(Self.window_size)]
    fn get_messages(mut self) -> None:
        self.m.update(self.freeze_gate, "freeze_gate")

    fn next_stereo_frame(mut self, mut mags: List[SIMD[DType.float64, 2]], mut phases: List[SIMD[DType.float64, 2]]) -> None:
        if not self.freeze_gate:
            # self.stored_phases = phases.copy()
            self.stored_mags = mags.copy()
        else:
            mags = self.stored_mags.copy()
        for i in range(Self.window_size):
            phases[i] += SIMD[DType.float64, 2](random_float64(0, two_pi), random_float64(0, two_pi))
            

struct SpectralFreeze[window_size: Int](Movable, Copyable):
    """
     Spectral Freeze.
    """

    comptime hop_size = Self.window_size // 4
    var world: World
    var freeze: FFTProcess[SpectralFreezeWindow[Self.window_size],Self.window_size,Self.hop_size,WindowType.hann,WindowType.hann]
    var m: Messenger
    var freeze_gate: Bool
    var asr: ASREnv

    fn __init__(out self, world: World, namespace: Optional[String] = None):
        self.world = world
        self.freeze = FFTProcess[
                SpectralFreezeWindow[Self.window_size],
                Self.window_size,
                Self.hop_size,
                WindowType.hann,
                WindowType.hann
            ](self.world,process=SpectralFreezeWindow[Self.window_size](self.world, namespace))
        self.m = Messenger(self.world, namespace)
        self.freeze_gate = False
        self.asr = ASREnv(self.world)

    fn next(mut self, sample: SIMD[DType.float64, 2]) -> SIMD[DType.float64, 2]:
        self.m.update(self.freeze_gate, "freeze_gate")
        env = self.asr.next(0.01, 1.0, 0.01, self.freeze_gate, 1.0)
        freeze = self.freeze.next_stereo(sample)
        return select(env, [sample, freeze]) * 0.3

# this really should have a window size of 8192 or more, but the numpy FFT seems to barf on this
comptime window_size = 2048

struct SpectralFreezeExample(Movable, Copyable):
    var world: World
    var buffer: Buffer
    var play_buf: Play   
    var spectral_freeze: SpectralFreeze[window_size]
    var m: Messenger
    var stereo_switch: Bool

    fn __init__(out self, world: World, namespace: Optional[String] = None):
        self.world = world
        self.buffer = Buffer.load("resources/Shiverer.wav")
        self.play_buf = Play(self.world) 
        self.spectral_freeze = SpectralFreeze[window_size](self.world)
        self.m = Messenger(self.world)
        self.stereo_switch: Bool = False

    fn next(mut self) -> SIMD[DType.float64,2]:
        self.m.update(self.stereo_switch,"stereo_switch")

        out = self.play_buf.next[2](self.buffer,1)

        out = self.spectral_freeze.next(out)

        return out

