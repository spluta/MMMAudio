from mmm_audio import *

# THE SYNTH

comptime how_many = 16

struct MoogPops(Movable, Copyable):
    var world: LegacyUnsafePointer[MMMWorld]  
    var dusts: Dust[how_many]
    var filts: VAMoogLadder[how_many, 4]
    var m: Messenger
    var t_exp_rand: TExpRand[how_many]
    var t_rand: TRand[how_many]
    var t_rand2: TRand[how_many]


    fn __init__(out self, world: LegacyUnsafePointer[MMMWorld]):
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

        return splay(sig, self.world)
