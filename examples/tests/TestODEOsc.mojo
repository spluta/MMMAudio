from mmm_audio import *

struct TestODEOscillator(Representable, Movable, Copyable):
    """Simple harmonic oscillator using RK4 ODE solver.
    
    Tests that the ODE solver produces a clean sine wave.
    """
    var world: UnsafePointer[MMMWorld]
    var solver: RK4[2, 1]  # 2 dimensions: position, velocity
    var frequency: Float64
    var m: Messenger

    fn __init__(out self, world: UnsafePointer[MMMWorld]):
        self.world = world
        self.solver = RK4[2, 1](world)
        self.frequency = 440.0
        self.m = Messenger(world)
        
        # Set initial conditions
        self.solver.state[0] = 1.0  # position
        self.solver.state[1] = 0.0  # velocity

    fn __repr__(self) -> String:
        return String("TestODEOscillator")

    fn next(mut self) -> SIMD[DType.float64, 2]:
        self.m.update(self.frequency, "frequency")
        
        var omega = 2.0 * 3.14159265359 * self.frequency
        var omega_sq = omega * omega
        
        # Define derivatives for harmonic oscillator
        fn derivatives(state: List[SIMD[DType.float64, 1]]) -> List[SIMD[DType.float64, 1]]:
            var derivs = List[SIMD[DType.float64, 1]]()
            derivs.append(state[1])  # dx/dt = velocity
            derivs.append(-omega_sq * state[0])  # dv/dt = -omega^2 * position
            return derivs
        
        self.solver.step(derivatives)
        
        var output = self.solver.state[0][0]
        return SIMD[DType.float64, 2](output, output) * 0.5