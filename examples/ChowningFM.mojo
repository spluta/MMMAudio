from mmm_src.MMMWorld import MMMWorld
from mmm_utils.functions import *
from mmm_src.MMMTraits import *
from mmm_dsp.Osc import Osc
from mmm_dsp.Env import *
from collections import Dict

struct ChowningFM(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld] # pointer to the MMMWorld
    var c_osc: Osc
    var m_osc: Osc
    var parameters: Dict[String, Float64]
    var amp_env: Env
    var amp_env_params: EnvParams
    var index_env: Env
    var index_env_params: EnvParams

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr

        self.c_osc = Osc(world_ptr)
        self.m_osc = Osc(world_ptr)
        self.parameters = Dict[String, Float64]()
        self.parameters["c_freq"] = 440.0
        self.parameters["m_freq"] = 220.0
        self.parameters["vol"] = -12.0
        self.parameters["trig"] = 0.0
        self.amp_env = Env(world_ptr)
        self.index_env = Env(world_ptr)
        self.index_env_params = EnvParams(
            values=List[Float64](10.0, 2.0, 0.0),
            times=List[Float64](1.8, 0.7),
            curves=List[Float64](1.0, 1.0),
        )
        self.amp_env_params = EnvParams(
            values=List[Float64](0.0, 1.0, 0.2, 0.0),
            times=List[Float64](0.03,1.8, 0.7),
            curves=List[Float64](1.0, 1.0, 1.0),
        )

    fn __repr__(self) -> String:
        return String("ChowningFM")

    fn get_msgs(mut self):
        for item in self.parameters.items():
            msg = self.world_ptr[0].get_msg(item.key)
            if msg:
                self.parameters[item.key] = msg.value()[0]

        vals = self.world_ptr[0].get_msg("amp_env_levels")
        if vals and len(vals.value()) > 1:
            self.amp_env_params.values = vals.value()

        vals = self.world_ptr[0].get_msg("amp_env_times")
        if vals and len(vals.value()) > 1:
            self.amp_env_params.times = vals.value()

        vals = self.world_ptr[0].get_msg("amp_env_curves")
        if vals and len(vals.value()) > 1:
            self.amp_env_params.curves = vals.value()

        vals = self.world_ptr[0].get_msg("index_env_levels")
        if vals and len(vals.value()) > 1:
            self.index_env_params.values = vals.value()

        vals = self.world_ptr[0].get_msg("index_env_times")
        if vals and len(vals.value()) > 1:
            self.index_env_params.times = vals.value()

        vals = self.world_ptr[0].get_msg("index_env_curves")
        if vals and len(vals.value()) > 1:
            self.index_env_params.curves = vals.value()

    @always_inline
    fn next(mut self) -> SIMD[DType.float64, 2]:
        self.get_msgs()

        msig = self.m_osc.next(self.parameters.get("m_freq",220)) 
        msig *= self.parameters.get("m_freq",220)
        index = self.index_env.next(self.index_env_params, self.parameters.get("trig",0.0))
        self.world_ptr[0].print(index,"index",freq=50)
        msig *= index

        csig = self.c_osc.next(self.parameters.get("c_freq",440) + msig)
        csig *= self.amp_env.next(self.amp_env_params, self.parameters.get("trig",0.0))
        csig *= dbamp(self.parameters.get("vol",-12.0))

        return SIMD[DType.float64, 2](csig, csig)