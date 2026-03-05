
from mmm_audio import *

# there can only be one graph in an MMMAudio instance
# a graph can have as many synths as you want
struct TestEnv(Movable, Copyable):
    var world: World
    var env_params: EnvParams
    var env: Env
    var synth: Osc[]
    var messenger: Messenger
    var impulse: Impulse[]
    var mul: Float64

    fn __init__(out self, world: World):
        self.world = world
        self.env_params = EnvParams([0, 1.0, 0.5, 0.5, 0.0], [1, 1, 0.5, 4], [2], True, 0.1)
        self.env = Env(self.world)
        self.synth = Osc(self.world)
        self.messenger = Messenger(self.world)
        self.impulse = Impulse(self.world)
        self.mul = 0.1

    fn next(mut self) -> SIMD[DType.float64, 2]:
        self.messenger.update(self.mul, "mul")
        trig = self.impulse.next_bool(1.0)
        self.env_params.time_warp = linexp(self.world[].mouse_x, 0.0, 1.0, 0.1, 10.0)
        self.env_params.curves[0] = linlin(self.world[].mouse_y, 0.0, 1.0, 4.0, 4.0)
        # self.env_params.curves[0] = self.messenger.get_val("curve", 1)
        env = self.env.next(self.env_params, trig)  # get the next value of the envelope

        self.world[].print(self.env.rising_bool_detector.state, self.env.is_active, self.env.sweep.phase, self.env.sweep.phase, self.env.trig_point, self.env.last_asr)

        sample = self.synth.next(500)
        return env * sample * self.mul



        