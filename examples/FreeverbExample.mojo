from mmm_audio import *

comptime num_chans = 2

struct FreeverbSynth(Copyable, Movable):
    var world: World 
    var buffer: SIMDBuffer[num_chans]

    var play_buf: Play

    var freeverb: Freeverb[num_chans]
    var m: Messenger

    var room_size: Float64
    var lpf_comb: Float64
    var added_space: Float64
    var mix: Float64

    fn __init__(out self, world: World):
        self.world = world 

        # load the audio buffer 
        self.buffer = SIMDBuffer.load("resources/Shiverer.wav")

        # without printing this, the compiler wants to free the buffer for some reason
        print("Loaded buffer with", self.buffer.num_chans, "channels and", self.buffer.num_frames, "frames.")

        self.play_buf = Play(self.world)
        self.freeverb = Freeverb[num_chans](self.world)

        self.room_size = 0.9
        self.lpf_comb = 1000.0
        self.added_space = 0.5
        self.mix = 0.2

        self.m = Messenger(self.world)

    @always_inline
    fn next(mut self) -> SIMD[DType.float64, 2]:

        self.m.update(self.room_size,"room_size")
        self.m.update(self.lpf_comb,"lpf_comb")
        self.m.update(self.added_space,"added_space")
        self.m.update(self.mix,"mix")

        added_space_simd = SIMD[DType.float64, num_chans](self.added_space, self.added_space * 0.99)
        out = self.play_buf.next[num_chans=num_chans](self.buffer, 1.0, True)
        out = self.freeverb.next(out, self.room_size, self.lpf_comb, added_space_simd) * 0.1 * self.mix + out * (1.0 - self.mix)
        return out


struct FreeverbExample(Representable, Movable, Copyable):
    var world: World

    var freeverb_synth: FreeverbSynth  # Instance of the FreeverbSynth

    fn __init__(out self, world: World):
        self.world = world
        self.freeverb_synth = FreeverbSynth(self.world)

    fn __repr__(self) -> String:
        return String("Freeverb_Graph")

    fn next(mut self) -> SIMD[DType.float64, 2]:
        #return SIMD[DType.float64, 2](0.0)
        return self.freeverb_synth.next()  # Return the combined output sample
