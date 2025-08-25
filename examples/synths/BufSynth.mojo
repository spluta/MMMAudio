from mmm_dsp.Buffer import *
from mmm_dsp.Filters import VAMoogLadder
from mmm_dsp.Osc import *
from mmm_utils.functions import linexp
from random import random_float64
from memory import UnsafePointer
from mmm_src.MMMWorld import MMMWorld
from mmm_dsp.PlayBuf import *
from mmm_dsp.OscBuffers import OscBuffers

struct BufSynth(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld] 
    var buffer: InterleavedBuffer

    var num_chans: Int64

    var playBuf: PlayBuf
    var playback_speed: Float64
    
    var moog: List[VAMoogLadder]
    var lpf_freq: Float64
    var lpf_freq_lag: Lag

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr 

        # load the audio buffer 
        self.buffer = InterleavedBuffer(self.world_ptr, "resources/Shiverer.wav")
        self.num_chans = self.buffer.num_chans  

        self.playback_speed = 1.0

        self.playBuf = PlayBuf(self.world_ptr, self.num_chans)  

        self.moog = List[VAMoogLadder]()
        for _ in range(self.num_chans):
            self.moog.append(VAMoogLadder(self.world_ptr)) 
        self.lpf_freq = 20000.0 
        self.lpf_freq_lag = Lag(world_ptr)

    fn next(mut self) -> List[Float64]:
        out = self.playBuf.next(self.buffer, self.playback_speed, True)
        
        freq = self.lpf_freq_lag.next(self.lpf_freq, 0.1)
        for i in range(self.num_chans):
            out[i] = self.moog[i].next(out[i], freq, 1.0)
        return out

    fn __repr__(self) -> String:
        return String("BufSynth")