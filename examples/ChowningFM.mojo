from mmm_audio import *

struct ChowningFM(Representable, Movable, Copyable):
    var world: World # pointer to the MMMWorld
    var m: Messenger
    var c_osc: Osc[1,1,1]  # Carrier oscillator
    var m_osc: Osc[1]  # Modulator oscillator
    var index_env: Env
    var index_env_params: EnvParams
    var amp_env: Env
    var amp_env_params: EnvParams
    var cfreq: Float64
    var mfreq: Float64
    var vol: Float64

    fn __init__(out self, world: World):
        self.world = world
        self.m = Messenger(self.world)
        self.c_osc = Osc[1,1,1](self.world)
        self.m_osc = Osc[1](self.world)
        self.index_env = Env(self.world)
        self.index_env_params = EnvParams()
        self.amp_env = Env(self.world)
        self.amp_env_params = EnvParams()
        self.cfreq = 200.0
        self.mfreq = 100.0
        self.vol = -12.0

    fn __repr__(self) -> String:
        return String("ChowningFM")

    @always_inline
    fn update_envs(mut self):
        
        self.m.update(self.index_env_params.values,"index_vals")
        self.m.update(self.index_env_params.times,"index_times")
        self.m.update(self.index_env_params.curves,"index_curves")
        self.m.update(self.amp_env_params.values,"amp_vals")
        self.m.update(self.amp_env_params.times,"amp_times")
        self.m.update(self.amp_env_params.curves,"amp_curves")

    @always_inline
    fn next(mut self) -> SIMD[DType.float64, 2]:

        self.m.update(self.cfreq,"c_freq")
        self.m.update(self.mfreq,"m_freq")
        self.m.update(self.vol,"vol")
        trig = self.m.notify_trig("trigger")
        self.update_envs()

        index = self.index_env.next(self.index_env_params, trig)
        msig = self.m_osc.next(self.mfreq) * self.mfreq * index
        csig = self.c_osc.next(self.cfreq + msig)
        csig *= self.amp_env.next(self.amp_env_params, trig)
        csig *= dbamp(self.vol)

        return csig