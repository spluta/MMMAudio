struct HilbertWindow[window_size: Int](ComplexFFTProcessable):
    var m: Messenger
    comptime pi_over2 = 1.5707963267948966

    fn __init__(out self, world: World):
        self.m = Messenger(world)

    fn get_messages(mut self) -> None:
        pass

    fn next_frame(mut self, mut complex: List[ComplexSIMD[DType.float64, 1]]) -> None:
        complex[0] *= ComplexSIMD[DType.float64, 1](0.0, 0.0)
        complex[self.window_size] *= ComplexSIMD[DType.float64, 1](0.0, 0.0)
        
        @parameter
        for i in range(1, Self.window_size):
            complex[i] *= ComplexSIMD[DType.float64, 1](0.0, -1.0)

struct Hilbert[window_size: Int, hop_size: Int, window_type: Int = WindowType.sine](Movable, Copyable):
    var world: World
    var hilbert: ComplexFFTProcess[HilbertWindow[Self.window_size],Self.window_size,Self.hop_size,Self.window_type,Self.window_type]
    var delay: Delay[1, Interp.none]
    var delay_time: MFloat[]

    fn __init__(out self, world: World):
        self.world = world
        self.delay_time = Float64(self.window_size)/self.world[].sample_rate

        self.delay = Delay[1, Interp.none](self.world, Int64(self.window_size))

        self.hilbert = ComplexFFTProcess[
                HilbertWindow[Self.window_size],
                Self.window_size,
                Self.hop_size,
                Self.window_type,
                Self.window_type
            ](self.world,process=HilbertWindow[Self.window_size](self.world))

    fn next(mut self, input: MFloat[1]) -> Tuple[Float64, Float64]:
        o = self.hilbert.next(input)
        delayed: Float64 = self.delay.next(input, Int64(self.window_size))
        return Tuple(delayed, o)

