"""Benjolin-inspired Synthesizer

Based on the SuperCollider implementation by Hyppasus
https://scsynth.org/t/benjolin-inspired-instrument/1074/1

Ported to MMMAudio by Ted Moore, October 2025
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
    var delays: List[Delay[1,3]]
    var latches: List[Latch]
    var filters: List[SVF]
    var filter_outputs: List[Float64]
    var sample_dur: Float64
    var sh: List[Float64]
    var dctraps: List[DCTrap]

    var freq1: Float64
    var freq2: Float64
    var scale: Float64
    var rungler1: Float64
    var rungler2: Float64
    var runglerFiltMul: Float64
    var loop: Float64
    var filterFreq: Float64
    var q: Float64
    var gain: Float64
    var filterType: Float64
    var outSignalL: Float64
    var outSignalR: Float64

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.m = Messenger(self.world_ptr)
        self.feedback = 0.0
        self.rungler = 0.0
        self.tri1 = Osc[interp=2,os_index=1](self.world_ptr)
        self.tri2 = Osc[interp=2,os_index=1](self.world_ptr)
        self.pulse1 = Osc[interp=2,os_index=1](self.world_ptr)
        self.pulse2 = Osc[interp=2,os_index=1](self.world_ptr)
        self.delays = List[Delay[1,3]](capacity=8)
        self.latches = List[Latch](capacity=8)
        self.filters = List[SVF](capacity=9)
        self.filter_outputs = List[Float64](capacity=9)
        self.sample_dur = 1.0 / self.world_ptr[0].sample_rate
        self.sh = List[Float64](capacity=9)
        self.dctraps = List[DCTrap](capacity=2)

        self.freq1 = 40
        self.freq2 = 4
        self.scale = 1
        self.rungler1 = 0.16
        self.rungler2 = 0
        self.loop = 0
        self.filterFreq = 40
        self.runglerFiltMul = 1
        self.q = 0.82
        self.gain = 1
        self.filterType = 0
        self.outSignalL = 1
        self.outSignalR = 3

        self.m.register(self.freq1,"freq1")
        self.m.register(self.freq2,"freq2")
        self.m.register(self.scale,"scale")
        self.m.register(self.rungler1,"rungler1")
        self.m.register(self.rungler2,"rungler2")
        self.m.register(self.runglerFiltMul,"runglerFiltMul")
        self.m.register(self.loop,"loop")
        self.m.register(self.filterFreq,"filterFreq")
        self.m.register(self.q,"q")
        self.m.register(self.gain,"gain")
        self.m.register(self.filterType,"filterType")
        self.m.register(self.outSignalL,"outSignalL")
        self.m.register(self.outSignalR,"outSignalR")

        for _ in range(8):
            self.delays.append(Delay[1,3](self.world_ptr, max_delay_time=0.1))
            self.latches.append(Latch(self.world_ptr))

        for _ in range(9):
            self.filters.append(SVF(self.world_ptr))
            self.filter_outputs.append(0.0)
            self.sh.append(0.0)

        for _ in range(2):
            self.dctraps.append(DCTrap(self.world_ptr))

    fn __repr__(self) -> String:
        return String("Default")

    fn next(mut self) -> SIMD[DType.float64, 2]:

        self.m.update()
        
        tri1 = self.tri1.next((self.rungler*self.rungler1)+self.freq1,osc_type=3)
        tri2 = self.tri2.next((self.rungler*self.rungler2)+self.freq2,osc_type=3)
        pulse1 = self.pulse1.next((self.rungler*self.rungler1)+self.freq1,osc_type=2)
        pulse2 = self.pulse2.next((self.rungler*self.rungler2)+self.freq2,osc_type=2)

        pwm = 1.0 if (tri1 + tri2) > 0.0 else 0.0

        pulse1 = (self.feedback*self.loop) + (pulse1 * ((self.loop * -1) + 1))

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
        self.rungler = midicps(self.rungler * linlin(self.scale,0.0,1.0,0.0,127.0))

        self.filter_outputs[0] = self.filters[0].lpf(pwm * self.gain,(self.rungler*self.runglerFiltMul)+self.filterFreq,self.q)
        self.filter_outputs[1] = self.filters[1].hpf(pwm * self.gain,(self.rungler*self.runglerFiltMul)+self.filterFreq,self.q)
        self.filter_outputs[2] = self.filters[2].bpf(pwm * self.gain,(self.rungler*self.runglerFiltMul)+self.filterFreq,self.q)
        self.filter_outputs[3] = self.filters[3].lpf(pwm * self.gain,(self.rungler*self.runglerFiltMul)+self.filterFreq,self.q)
        self.filter_outputs[4] = self.filters[4].peak(pwm * self.gain,(self.rungler*self.runglerFiltMul)+self.filterFreq,self.q)
        self.filter_outputs[5] = self.filters[5].allpass(pwm * self.gain,(self.rungler*self.runglerFiltMul)+self.filterFreq,self.q)
        self.filter_outputs[6] = self.filters[6].bell(pwm,(self.rungler*self.runglerFiltMul)+self.filterFreq,self.q,ampdb(self.gain))
        self.filter_outputs[7] = self.filters[7].highshelf(pwm,(self.rungler*self.runglerFiltMul)+self.filterFreq,self.q,ampdb(self.gain))
        self.filter_outputs[8] = self.filters[8].lowshelf(pwm,(self.rungler*self.runglerFiltMul)+self.filterFreq,self.q,ampdb(self.gain))
        
        filter_output = select(self.filterType,self.filter_outputs) * dbamp(-12)
        filter_output = sanitize(filter_output)

        output = SIMD[DType.float64, 2](0.0, 0.0)
        output[0] = select(self.outSignalL,[tri1, pulse1, tri2, pulse2, pwm, self.sh[0], filter_output])
        output[1] = select(self.outSignalR,[tri1, pulse1, tri2, pulse2, pwm, self.sh[0], filter_output])

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