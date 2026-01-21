from mmm_audio import *

# THE SYNTH


# The synth here, called StereoBeatingSines, is not yet the "graph" that MMMAudio will 
# call upon to make sound with. StereoBeatingSines is a struct that
# defines some DSP behavior that can be called upon by 
# the ManyOscillators graph below.

struct StereoBeatingSines(Representable, Movable, Copyable):
    var world: LegacyUnsafePointer[MMMWorld] # pointer to the MMMWorld
    var osc1: Osc[interp=Interp.linear] # first oscillator
    var osc2: Osc[interp=Interp.linear] # second oscillator
    var osc_freqs: SIMD[DType.float64, 2] # frequencies for the two oscillators
    var pan2_osc: Osc # LFO for panning
    var pan2_freq: Float64 # frequency for the panning LFO
    var vol_osc: Osc # LFO for volume
    var vol_osc_freq: Float64 # frequency for the volume LFO

    fn __init__(out self, world: LegacyUnsafePointer[MMMWorld], center_freq: Float64):
        self.world = world

        # create two oscillators. The [2] here is *kind of* like an array
        # with two elements, but the more accurate way to look at it is a
        # SIMD operation with a width of 2. For more info on MMMAudio's SIMD 
        # support, see: https://spluta.github.io/MMMAudio/api/ 
        # Just FYI, it's not 2 because this is a stereo synth, it's 2 to
        # create some nice beating patterns. The output is stereo because later
        # the pan2 function positions the summed oscillators in the stereo field

        self.osc1 = Osc[interp=Interp.linear](self.world)
        self.osc2 = Osc[interp=Interp.linear](self.world)
        
        self.pan2_osc = Osc(self.world)
        self.pan2_freq = random_float64(0.03, 0.1)

        self.vol_osc = Osc(self.world)
        self.vol_osc_freq = random_float64(0.05, 0.2)
        self.osc_freqs = SIMD[DType.float64, 2](
            center_freq + random_float64(1.0, 5.0),
            center_freq - random_float64(1.0, 5.0)
        )

    fn __repr__(self) -> String:
        return String("StereoBeatingSines")

    @always_inline
    fn next(mut self) -> SIMD[DType.float64, 2]:
        # calling .next on both oscillators gets both of their next samples
        temp = self.osc1.next(self.osc_freqs[0]) + self.osc2.next(self.osc_freqs[1])

        # modulate the volume with a slow LFO
        
        temp = temp * (self.vol_osc.next(self.vol_osc_freq) * 0.5 + 0.5)

        pan2_loc = self.pan2_osc.next(self.pan2_freq)  # Get pan position

        return pan2(temp, pan2_loc)  # Pan the temp signal

# THE GRAPH
# This graph is what MMMAudio will call upon to make sound with (because
# it is the struct that has the same name as this).

struct ManyOscillators(Copyable, Movable):
    var world: LegacyUnsafePointer[MMMWorld]
    var synths: List[StereoBeatingSines]  # Instances of the StereoBeatingSines synth
    var messenger: Messenger
    var num_pairs: Int64

    fn __init__(out self, world: LegacyUnsafePointer[MMMWorld]):
        self.world = world

        # initialize the list of synths
        self.synths = List[StereoBeatingSines]()

        self.messenger = Messenger(self.world)
        self.num_pairs = 10

        # add 10 pairs to the list
        for _ in range(self.num_pairs):
            self.synths.append(StereoBeatingSines(self.world, random_exp_float64(100.0, 1000.0)))

    @always_inline
    fn next(mut self) -> SIMD[DType.float64, 2]:

        if self.messenger.notify_update(self.num_pairs,"num_pairs"):
            if len(self.synths) != Int(self.num_pairs):
                if self.num_pairs > len(self.synths):
                    # add more
                    for _ in range(self.num_pairs - len(self.synths)):
                        self.synths.append(StereoBeatingSines(self.world, random_exp_float64(100.0, 1000.0)))
                else:
                    # remove some
                    for _ in range(len(self.synths) - self.num_pairs):
                        _ = self.synths.pop()

        # sum all the stereo outs from the N synths
        sum = SIMD[DType.float64, 2](0.0, 0.0)
        for i in range(len(self.synths)):
            sum += self.synths[i].next()

        return sum * (0.5 / Float64(self.num_pairs))  # scale the output down