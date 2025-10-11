from mmm_src.MMMWorld import MMMWorld
from mmm_utils.functions import *
from mmm_src.MMMTraits import *
from mmm_dsp.Osc import Osc
from mmm_dsp.Env import *
from collections import Dict
from mmm_utils.Messengers import Messenger

struct ChowningFM(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld] # pointer to the MMMWorld
    var m: Messenger
    var c_osc: Osc  # Carrier oscillator
    var m_osc: Osc  # Modulator oscillator
    var index_env: Env
    var index_env_params: EnvParams
    var amp_env: Env
    var amp_env_params: EnvParams

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.m = Messenger(world_ptr)
        self.c_osc = Osc(world_ptr)
        self.m_osc = Osc(world_ptr)
        self.index_env = Env(world_ptr)
        self.index_env_params = EnvParams()
        self.amp_env = Env(world_ptr)
        self.amp_env_params = EnvParams()


    fn __repr__(self) -> String:
        return String("ChowningFM")

    @always_inline
    fn update_envs(mut self):
        index_vals = self.m.get_list("index_vals")
        # self.world_ptr.print(index_vals, "index_vals")
        if len(index_vals) > 0:
            self.index_env_params.values = index_vals
        index_times = self.m.get_list("index_times")
        if len(index_times) > 0:
            self.index_env_params.times = index_times
        index_curves = self.m.get_list("index_curves")
        if len(index_curves) > 0:
            self.index_env_params.curves = index_curves
        
        amp_vals = self.m.get_list("amp_vals")
        if len(amp_vals) > 0:
            self.amp_env_params.values = amp_vals
        amp_times = self.m.get_list("amp_times")
        if len(amp_times) > 0:
            self.amp_env_params.times = amp_times
        amp_curves = self.m.get_list("amp_curves")
        if len(amp_curves) > 0:
            self.amp_env_params.curves = amp_curves

    @always_inline
    fn next(mut self) -> SIMD[DType.float64, 2]:
        cfreq = self.m.get_val("c_freq", 100)
        mfreq = self.m.get_val("m_freq", 20)
        vol = self.m.get_val("vol", -12)
        trig = self.m.triggered("trigger")
        self.update_envs()

        index = self.index_env.next(self.index_env_params, trig)
        msig = self.m_osc.next(mfreq) * mfreq * index        
        csig = self.c_osc.next(cfreq + msig)
        csig *= self.amp_env.next(self.amp_env_params, trig)
        csig *= dbamp(vol)

        return SIMD[DType.float64, 2](csig, csig)