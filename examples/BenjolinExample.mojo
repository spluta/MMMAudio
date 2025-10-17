"""

@misc{benjolinsc,
  url={https://scsynth.org/t/benjolin-inspired-instrument/1074/1},
  title={Benjolin inspired instrument},
  author={Hyppasus},
  journal={SuperCollider Forum}
}

"""

from mmm_src.MMMWorld import MMMWorld
from mmm_utils.Messengers import *
from mmm_utils.functions import *
from mmm_src.MMMTraits import *
from mmm_dsp.Delays import Delay
from math import tanh
from mmm_dsp.Distortion import Latch
from mmm_utils.functions import linlin, midicps
from mmm_dsp.Osc import Osc
from mmm_dsp.Filters import *
from mmm_utils.Print import Print

struct Benjolin(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]  
    var m: Messenger
    var feedback: Float64
    var rungler: Float64
    var tri1: Osc[interp=2,os_index=1]
    var tri2: Osc[interp=2,os_index=1]
    var pulse1: Osc[interp=2,os_index=1]
    var pulse2: Osc[interp=2,os_index=1]
    var delays: List[Delay[1,3,True]]
    var latches: List[Latch]
    var filters: List[SVF]
    var filter_outputs: List[Float64]
    var sample_dur: Float64
    var sh: List[Float64]
    var dctraps: List[DCTrap]
    var printers: List[Print]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.m = Messenger(self.world_ptr)
        self.feedback = 0.0
        self.rungler = 0.0
        self.tri1 = Osc[interp=2,os_index=1](self.world_ptr)
        self.tri2 = Osc[interp=2,os_index=1](self.world_ptr)
        self.pulse1 = Osc[interp=2,os_index=1](self.world_ptr)
        self.pulse2 = Osc[interp=2,os_index=1](self.world_ptr)
        self.delays = List[Delay[1,3,True]](capacity=8)
        self.latches = List[Latch](capacity=8)
        self.filters = List[SVF](capacity=9)
        self.filter_outputs = List[Float64](capacity=9)
        self.sample_dur = 1.0 / self.world_ptr[0].sample_rate
        self.sh = List[Float64](capacity=9)
        self.dctraps = List[DCTrap](capacity=2)
        self.printers = List[Print](capacity=13)

        print("len dels",len(self.delays))

        for i in range(8):
            self.delays[i] = Delay[1,3,True](self.world_ptr, max_delay_time=0.1)

        for i in range(8):
            self.latches[i] = Latch(self.world_ptr)

        for i in range(9):
            self.filters[i] = SVF(self.world_ptr)

        for i in range(9):
            self.sh[i] = 0

        for i in range(2):
            self.dctraps[i] = DCTrap(self.world_ptr)

        # for i in range(len(self.printers)):
        #     self.printers[i] = Print(self.world_ptr)

    fn __repr__(self) -> String:
        return String("Default")

    fn next(mut self) -> SIMD[DType.float64, 2]:
        freq1 = self.m.get_val("freq1", 40.0)
        freq2 = self.m.get_val("freq2", 4.0)
        scale = self.m.get_val("scale", 1.0)
        rungler1 = self.m.get_val("rungler1", 0.16)
        rungler2 = self.m.get_val("rungler2", 0.0)
        runglerFiltMul = self.m.get_val("runglerFiltMul", 9.0)
        loop = self.m.get_val("loop", 0.0)
        filterFreq = self.m.get_val("filterFreq", 40.0)
        q = self.m.get_val("q", 0.82)
        gain = self.m.get_val("gain", 1.0)
        filterType = self.m.get_val("filterType", 0.0)
        outSignalL = self.m.get_val("outSignalL", 1.0)
        outSignalR = self.m.get_val("outSignalR", 3.0)

        tri1 = self.tri1.next((self.rungler*rungler1)+freq1,osc_type=3)
        tri2 = self.tri2.next((self.rungler*rungler2)+freq2,osc_type=3)
        pulse1 = self.pulse1.next((self.rungler*rungler1)+freq1,osc_type=2)
        pulse2 = self.pulse2.next((self.rungler*rungler2)+freq2,osc_type=2)

        pwm = 1.0 if (tri1 + tri2) > 0.0 else 0.0
        
        pulse1 = (self.feedback*loop) + (pulse1 * ((loop * -1) + 1))

        self.sh[0] = 1.0 if pulse1 > 0.5 else 0.0
        # pretty sure this makes no sense, but it matches the original code...:
        self.sh[0] = 1.0 if (1.0 > self.sh[0]) == (1.0 < self.sh[0]) else 0.0
        self.sh[0] = (self.sh[0] * -1) + 1

        self.sh[1] = self.delays[0].next(self.latches[0].next(self.sh[0],pulse2 > 0),self.sample_dur)
        self.sh[2] = self.delays[1].next(self.latches[1].next(self.sh[1],pulse2 > 0),self.sample_dur * 2)
        self.sh[3] = self.delays[2].next(self.latches[2].next(self.sh[2],pulse2 > 0),self.sample_dur * 3)
        self.sh[4] = self.delays[3].next(self.latches[3].next(self.sh[3],pulse2 > 0),self.sample_dur * 4)
        self.sh[5] = self.delays[4].next(self.latches[4].next(self.sh[4],pulse2 > 0),self.sample_dur * 5)
        self.sh[6] = self.delays[5].next(self.latches[5].next(self.sh[5],pulse2 > 0),self.sample_dur * 6)
        self.sh[7] = self.delays[6].next(self.latches[6].next(self.sh[6],pulse2 > 0),self.sample_dur * 7)
        self.sh[8] = self.delays[7].next(self.latches[7].next(self.sh[7],pulse2 > 0),self.sample_dur * 8)

        self.rungler = ((self.sh[0]/(2**8)))+(self.sh[1]/(2**7))+(self.sh[2]/(2**6))+(self.sh[3]/(2**5))+(self.sh[4]/(2**4))+(self.sh[5]/(2**3))+(self.sh[6]/(2**2))+(self.sh[7]/(2**1))

        self.feedback = self.rungler
        self.rungler = midicps(self.rungler * linlin(scale,0.0,1.0,0.0,127.0))

        self.filter_outputs[0] = self.filters[0].lpf(pwm * gain,(self.rungler*runglerFiltMul)+filterFreq,q)
        self.filter_outputs[1] = self.filters[1].hpf(pwm * gain,(self.rungler*runglerFiltMul)+filterFreq,q)
        self.filter_outputs[2] = self.filters[2].bpf(pwm * gain,(self.rungler*runglerFiltMul)+filterFreq,q)
        self.filter_outputs[3] = self.filters[3].lpf(pwm * gain,(self.rungler*runglerFiltMul)+filterFreq,q)
        self.filter_outputs[4] = self.filters[4].peak(pwm * gain,(self.rungler*runglerFiltMul)+filterFreq,q)
        self.filter_outputs[5] = self.filters[5].allpass(pwm * gain,(self.rungler*runglerFiltMul)+filterFreq,q)
        self.filter_outputs[6] = self.filters[6].bell(pwm,(self.rungler*runglerFiltMul)+filterFreq,q,ampdb(gain))
        self.filter_outputs[7] = self.filters[7].highshelf(pwm,(self.rungler*runglerFiltMul)+filterFreq,q,ampdb(gain))
        self.filter_outputs[8] = self.filters[8].lowshelf(pwm,(self.rungler*runglerFiltMul)+filterFreq,q,ampdb(gain))

        
        filter_output = select(filterType,self.filter_outputs) * dbamp(-12)
        filter_output = sanitize(filter_output)

        self.world_ptr[0].print(filter_output,"filter output: ")

        output = SIMD[DType.float64, 2](0.0, 0.0)
        output[0] = select(outSignalL,[tri1, pulse1, tri2, pulse2, pwm, self.sh[0], filter_output])
        output[1] = select(outSignalR,[tri1, pulse1, tri2, pulse2, pwm, self.sh[0], filter_output])

        for i in range(len(self.dctraps)):
            output[i] = self.dctraps[i].next(output[i])
            output[i] = tanh(output[i])

        return output

struct BenjolinExample(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var benjolin: Benjolin

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.benjolin = Benjolin(self.world_ptr)

    fn __repr__(self) -> String:
        return String("Benjolin_Example")

    fn next(mut self) -> SIMD[DType.float64, 2]:

        return self.benjolin.next()  # Get the next sample from the Benjolin