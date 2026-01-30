from mmm_audio import *

struct FM4(Movable, Copyable):
    var world: LegacyUnsafePointer[MMMWorld]

    var osc0: Osc[1, Interp.sinc, 2]
    var osc1: Osc[1, Interp.sinc, 2]
    var osc2: Osc[1, Interp.sinc, 2]
    var osc3: Osc[1, Interp.sinc, 2]

    var osc0_freq: MFloat[1]
    var osc1_freq: MFloat[1]
    var osc2_freq: MFloat[1]
    var osc3_freq: MFloat[1]

    var osc0_mul: List[MFloat[1]]
    var osc1_mul: List[MFloat[1]]
    var osc2_mul: List[MFloat[1]]
    var osc3_mul: List[MFloat[1]]
    var m: Messenger

    var fb: List[MFloat[1]]

    var osc_frac: List[MFloat[1]]

    fn __init__(out self, world: LegacyUnsafePointer[MMMWorld]):
        self.world = world

        self.osc0 = Osc[1, Interp.sinc, 2](world)
        self.osc1 = Osc[1, Interp.sinc, 2](world)
        self.osc2 = Osc[1, Interp.sinc, 2](world)
        self.osc3 = Osc[1, Interp.sinc, 2](world)
        
        self.osc0_freq = 220.0
        self.osc1_freq = 440.0
        self.osc2_freq = 220.0
        self.osc3_freq = 220.0

        self.osc0_mul = [0.0, 0.0]
        self.osc1_mul = [0.0, 0.0]
        self.osc2_mul = [0.0, 0.0]
        self.osc3_mul = [0.0, 0.0]

        self.m = Messenger(world)
        self.fb = [0.0, 0.0, 0.0, 0.0]
        self.osc_frac = [0.0, 0.0, 0.0, 0.0]

    fn next(mut self) -> MFloat[2]:

        self.m.update(self.osc0_freq, "osc0_freq")
        self.m.update(self.osc1_freq, "osc1_freq")
        self.m.update(self.osc2_freq, "osc2_freq")
        self.m.update(self.osc3_freq, "osc3_freq")

        self.m.update(self.osc0_mul[0], "osc0_mula")
        self.m.update(self.osc0_mul[1], "osc0_mulb")

        self.m.update(self.osc1_mul[0], "osc1_mula")
        self.m.update(self.osc1_mul[1], "osc1_mulb")

        self.m.update(self.osc2_mul[0], "osc2_mula")
        self.m.update(self.osc2_mul[1], "osc2_mulb")

        self.m.update(self.osc3_mul[0], "osc3_mula")
        self.m.update(self.osc3_mul[1], "osc3_mulb")

        self.m.update(self.osc_frac[0], "osc_frac0")
        self.m.update(self.osc_frac[1], "osc_frac1")
        self.m.update(self.osc_frac[2], "osc_frac2")
        self.m.update(self.osc_frac[3], "osc_frac3")

        fm_0 = self.fb[1] * self.osc0_mul[0] + self.fb[2] * self.osc0_mul[1]

        osc0 = self.osc0.next_vwt(self.osc0_freq + fm_0, osc_frac=self.osc_frac[0])
        fm_1 = osc0 * self.osc1_mul[0] + self.fb[3] * self.osc1_mul[1]
        osc1 = self.osc1.next_vwt(self.osc1_freq + fm_1, osc_frac=self.osc_frac[1])
        fm_2 = osc1 * self.osc2_mul[0] + self.fb[3] * self.osc2_mul[1]
        osc2 = self.osc2.next_vwt(self.osc2_freq + fm_2, osc_frac=self.osc_frac[2])
        fm_3 = osc0 * self.osc3_mul[0] + osc1 * self.osc3_mul[1]
        osc3 = self.osc3.next_vwt(self.osc3_freq + fm_3, osc_frac=self.osc_frac[3])

        self.fb = [osc0, osc1, osc2, osc3]

        return MFloat[2](osc0, osc1) *0.2
