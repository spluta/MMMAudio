from mmm_audio import *

struct DattorroReverbExample(Movable, Copyable):
        var world: World
        var m: Messenger
        var reverb: DattorroReverb[Interp.none] #the original uses Interp.none on the non-modulated delay lines
        var in_chan: Int

        fn __init__(out self, world: World):
                self.world = world
                self.m = Messenger(world)
                self.reverb = DattorroReverb[Interp.none](world)
                self.in_chan = 0

        fn next(mut self) -> MFloat[2]:
                self.m.update(self.in_chan, "in_chan")
                input = MFloat[2](self.world[].sound_in[0])

                self.m.update(self.reverb.pre_delay_time, "pre_delay_time")
                self.m.update(self.reverb.decay, "decay")
                self.m.update(self.reverb.bandwidth, "bandwidth")
                self.m.update(self.reverb.damping, "damping")
                self.m.update(self.reverb.decay_diffusion1, "decay_diffusion1")
                self.m.update(self.reverb.decay_diffusion2, "decay_diffusion2")
                self.m.update(self.reverb.input_diffusion[0], "input_diffusion1")
                self.m.update(self.reverb.input_diffusion[1], "input_diffusion2")

                return self.reverb.next(input)