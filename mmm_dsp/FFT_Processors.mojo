from mmm_src.MMMWorld import *
from mmm_dsp.FFTProcess import *
from mmm_utils.Messengers import Messenger
from mmm_utils.Windows import WindowTypes
from mmm_utils.functions import select
from mmm_dsp.FFT import FFT
from mmm_dsp.Env import ASREnv
from random import random_float64

alias two_pi = 2.0 * pi

struct SpectralFreezeWindow[window_size: Int](FFTStereoProcessable):
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

    fn next_frame(mut self, mut mags: List[SIMD[DType.float64, 2]], mut phases: List[SIMD[DType.float64, 2]]) -> None:
        if not self.freeze_gate:
            # self.stored_phases = phases.copy()
            self.stored_mags = mags.copy()
        else:
            mags = self.stored_mags.copy()
        for i in range(window_size):
            phases[i] += SIMD[DType.float64, 2](random_float64(0, two_pi), random_float64(0, two_pi))
            

struct SpectralFreeze[window_size: Int](Movable, Copyable):
    alias hop_size = window_size // 4
    var world_ptr: UnsafePointer[MMMWorld]
    var freeze: FFTStereoProcess[SpectralFreezeWindow[window_size],window_size,Self.hop_size,WindowTypes.hann,WindowTypes.hann]
    var m: Messenger
    var freeze_gate: Bool
    var asr: ASREnv

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], namespace: Optional[String] = None):
        self.world_ptr = world_ptr
        self.freeze = FFTStereoProcess[
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
        freeze = self.freeze.next(sample)
        return select(env, [sample, freeze])