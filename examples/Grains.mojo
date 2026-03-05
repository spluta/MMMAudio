from mmm_audio import *

# THE SYNTH

comptime num_output_chans = 2
comptime num_simd_chans = next_power_of_two(num_output_chans)

struct Grains(Movable, Copyable):
    var world: World
    var buffer: SIMDBuffer[2]
    
    var tgrains: TGrains[10] # set the number of simultaneous grains by setting the max_grains parameter here
    var tgrains2: TGrains[10] 
    var impulse: Phasor[1]  
    var start_frame: Float64
     
    fn __init__(out self, world: World):
        self.world = world  

        # buffer uses numpy to load a buffer into an N channel array
        self.buffer = SIMDBuffer[2].load("resources/Shiverer.wav")

        self.tgrains = TGrains[10](self.world)  
        self.tgrains2 = TGrains[10](self.world)
        self.impulse = Phasor[1](self.world)


        self.start_frame = 0.0 

    @always_inline
    fn next(mut self) -> SIMD[DType.float64, num_simd_chans]:

        imp_freq = linlin(self.world[].mouse_y, 0.0, 1.0, 1.0, 20.0)
        var impulse = self.impulse.next_bool(imp_freq, 0, True)  # Get the next impulse sample

        start_frame = Int(linlin(self.world[].mouse_x, 0.0, 1.0, 0.0, Float64(self.buffer.num_frames) - 1.0))

        # if there are 2 (or fewer) output channels, pan the stereo buffer out to 2 channels by panning the stereo playback with pan2
        # if there are more than 2 output channels, pan each of the 2 channels separately and randomly pan each grain channel to a different speaker
        @parameter
        if num_output_chans == 2:
            out = self.tgrains.next[2](self.buffer, 1, impulse, start_frame, 0.4, 0, random_float64(-1.0, 1.0), 1.0)

            return SIMD[DType.float64, num_simd_chans](out[0], out[1]) # because pan2 outputs a SIMD vector size 2, and we require a SIMD vector of size num_simd_chans, you have to manually make the SIMD vector in this case (the compiler does not agree that num_simd_chans == 2, even though it does)
        else:
            # pan each channel separately to num_output_chans speakers
            out0 = self.tgrains.next_pan_az[num_simd_chans=num_simd_chans](self.buffer, 1, impulse, start_frame, 0.4, 0, random_float64(-1.0, 1.0), 1.0, num_output_chans)
            out1 = self.tgrains2.next_pan_az[num_simd_chans=num_simd_chans](self.buffer, 1, impulse, start_frame, 0.4, 1, random_float64(-1.0, 1.0), 1.0, num_output_chans)

            return out0 + out1