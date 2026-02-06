struct HilbertWindow[window_size: Int](FFTProcessable):
    var m: Messenger
    comptime pi_over2 = 1.5707963267948966

    fn __init__(out self, world: World):
        self.m = Messenger(world)

    fn get_messages(mut self) -> None:
        pass

    fn next_frame(mut self, mut mags: List[MFloat[1]], mut phases: List[MFloat[1]]) -> None:
        for ref p in phases:
            p -= Self.pi_over2
        mags[0] = MFloat[1](0.0)
        mags[Self.window_size // 2] = MFloat[1](0.0)

# User's Synth
struct Hilbert[window_size: Int, hop_size: Int, window_type: Int = WindowType.sine](Movable, Copyable):
    var world: World
    var hilbert: FFTProcess[HilbertWindow[Self.window_size],Self.window_size,Self.hop_size,Self.window_type,Self.window_type]
    var delay: Delay[1, Interp.none]
    var delay_time: MFloat[]

    fn __init__(out self, world: World):
        self.world = world
        self.delay_time = Float64(self.window_size)/self.world[].sample_rate

        self.delay = Delay[1, Interp.none](self.world, self.delay_time+1.0/self.world[].sample_rate)

        self.hilbert = FFTProcess[
                HilbertWindow[Self.window_size],
                Self.window_size,
                Self.hop_size,
                Self.window_type,
                Self.window_type
            ](self.world,process=HilbertWindow[Self.window_size](self.world))

    fn next(mut self, input: MFloat[1]) -> Tuple[Float64, Float64]:
        o = self.hilbert.next(input)
        delayed: Float64 = self.delay.next(input, self.delay_time)
        return Tuple(delayed, o)

