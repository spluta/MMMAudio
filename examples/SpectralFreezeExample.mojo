from mmm_src.MMMWorld import *
from mmm_utils.Messengers import Messenger
from mmm_dsp.PlayBuf import PlayBuf
from mmm_utils.functions import select
from mmm_dsp.FFTProcess import *
from mmm_utils.Windows import WindowTypes
from mmm_dsp.FFT import FFT
from mmm_dsp.Env import ASREnv
from random import random_float64

alias two_pi = 2.0 * pi

struct SpectralFreezeWindow[window_size: Int](FFTProcessable):
    var world_ptr: UnsafePointer[MMMWorld]
    var m: Messenger
    var bin: Int64
    var freeze_gate: Bool
    var stored_phases: List[SIMD[DType.float64, 2]]
    var stored_mags: List[SIMD[DType.float64, 2]]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], namespace: Optional[String] = None):
        self.world_ptr = world_ptr
        self.bin = (window_size // 2) + 1
        self.m = Messenger(world_ptr, namespace)
        self.freeze_gate = False
        self.stored_phases = [SIMD[DType.float64, 2](0.0) for _ in range(window_size)]
        self.stored_mags = [SIMD[DType.float64, 2](0.0) for _ in range(window_size)]

    fn get_messages(mut self) -> None:
        self.m.update(self.freeze_gate, "freeze_gate")

    # the stereo fft process has to be formatted this way
    fn next_frame[num_chans: Int = 2](mut self, mut mags: List[SIMD[DType.float64, num_chans]], mut phases: List[SIMD[DType.float64, num_chans]]) -> None:

        # the current implementation requires you to explicitly address both channels of mags and phases

        if not self.freeze_gate:
            for i, m in enumerate(mags):
                self.stored_mags[i][0] = m[0]
                self.stored_mags[i][1] = m[1]
        else:
            for i, m in enumerate(self.stored_mags):
                mags[i][0] = m[0]
                mags[i][1] = m[1]
        for ref p in phases:
            p = SIMD[DType.float64, num_chans](random_float64(0.0, 2.0 * 3.141592653589793), random_float64(0.0, 2.0 * 3.141592653589793))
            

struct SpectralFreeze[window_size: Int](Movable, Copyable):
    """
     Spectral Freeze

    """

    alias hop_size = window_size // 4
    var world_ptr: UnsafePointer[MMMWorld]
    var freeze: FFTProcess[SpectralFreezeWindow[window_size],window_size,Self.hop_size,WindowTypes.hann,WindowTypes.hann]
    var m: Messenger
    var freeze_gate: Bool
    var asr: ASREnv

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], namespace: Optional[String] = None):
        self.world_ptr = world_ptr
        self.freeze = FFTProcess[
                SpectralFreezeWindow[window_size],
                window_size,
                self.hop_size,
                WindowTypes.hann,
                WindowTypes.hann
            ](self.world_ptr,process=SpectralFreezeWindow[window_size](self.world_ptr, namespace))
        self.m = Messenger(world_ptr, namespace)
        self.freeze_gate = False
        self.asr = ASREnv(world_ptr)

    fn next(mut self, sample: SIMD[DType.float64, 2]) -> SIMD[DType.float64, 2]:
        self.m.update(self.freeze_gate, "freeze_gate")
        env = self.asr.next(0.01, 1.0, 0.01, self.freeze_gate, 1.0)
        freeze = self.freeze.next[2](sample)
        return select(env, [sample, freeze])

# this really should have a window size of 8192 or more, but the numpy FFT seems to barf on this
alias window_size = 2048

struct SpectralFreezeExample(Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var buffer: Buffer
    var play_buf: PlayBuf   
    var spectral_freeze: SpectralFreeze[window_size]
    var m: Messenger
    var stereo_switch: Bool

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], namespace: Optional[String] = None):
        self.world_ptr = world_ptr
        self.buffer = Buffer("resources/Shiverer.wav")
        self.play_buf = PlayBuf(world_ptr) 
        self.spectral_freeze = SpectralFreeze[window_size](world_ptr)
        self.m = Messenger(world_ptr)
        self.stereo_switch: Bool = False

    fn next(mut self) -> SIMD[DType.float64,2]:
        self.m.update(self.stereo_switch,"stereo_switch")

        out = self.play_buf.next[2](self.buffer, 0, 1)

        out = self.spectral_freeze.next(out)

        return out

