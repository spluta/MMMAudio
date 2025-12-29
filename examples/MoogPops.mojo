from mmm_src.MMMWorld import MMMWorld
from mmm_utils.functions import *
from mmm_src.MMMTraits import *

from mmm_dsp.Osc import Dust
from mmm_dsp.Pan import splay
from mmm_dsp.Filters import VAMoogLadder
from random import random_float64
from mmm_utils.Messenger import Messenger
from mmm_dsp.Noise import TExpRand, TRand

# THE SYNTH

alias how_many = 16

struct MoogPops(Movable, Copyable):
    var world: UnsafePointer[MMMWorld]  
    var dusts: Dust[how_many]
    var filts: VAMoogLadder[how_many, 4]
    var m: Messenger
    var t_exp_rand: TExpRand[how_many]
    var t_rand: TRand[how_many]
    var t_rand2: TRand[how_many]


    fn __init__(out self, world: UnsafePointer[MMMWorld]):
        self.world = world
        self.dusts = Dust[how_many](world)
        self.filts = VAMoogLadder[how_many, 4](world)
        self.m = Messenger(world)
        self.t_exp_rand = TExpRand[how_many]()
        self.t_rand = TRand[how_many]()
        self.t_rand2 = TRand[how_many]()

    fn next(mut self) -> SIMD[DType.float64, 2]:
        
        dusts = self.dusts.next_bool(0.25, 4.0)
        freqs = self.t_exp_rand.next(8000.0, 18000.0, dusts)
        qs = self.t_rand.next(0.5, 1.04, dusts)
        sig = self.filts.next(dusts.cast[DType.float64]() * self.t_rand2.next(0.2, 1.0, dusts), freqs, qs) 

        return splay(sig*2, self.world)
