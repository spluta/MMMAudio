from mmm_audio import *

# there can only be one graph in an MMMAudio instance
# a graph can have as many synths as you want

# Simple RC low-pass filter using Euler ODE solver

struct TestODEFilter[N: Int = 2](Representable, Movable, Copyable):
    var world: UnsafePointer[MMMWorld]
    var noise: WhiteNoise[N]
    var euler: Euler[1, N]  # 1 state variable: the capacitor voltage (output)

    fn __init__(out self, world: UnsafePointer[MMMWorld]):
        self.world = world
        self.noise = WhiteNoise[N]()
        self.euler = Euler[1, N](world)

    fn __repr__(self) -> String:
        return String("TestODEFilter")

    fn next(mut self) -> SIMD[DType.float64, self.N]:
        var input = self.noise.next()

        # Map mouse X to cutoff frequency: 20Hz to 20kHz
        # Left channel: mouse_x, Right channel: 1 - mouse_x (opposite sweep)
        var freq_left = linexp(self.world[].mouse_x, 0.0, 1.0, 20.0, 20000.0)
        var freq_right = linexp(1.0 - self.world[].mouse_x, 0.0, 1.0, 20.0, 20000.0)
        
        # Convert cutoff frequency to RC time constant: fc = 1 / (2 * pi * RC) => RC = 1 / (2 * pi * fc)
        var rc = SIMD[DType.float64, self.N](
            1.0 / (2.0 * 3.14159265359 * freq_left),
            1.0 / (2.0 * 3.14159265359 * freq_right)
        )

        # dV/dt = (Vin - Vout) / RC
        var vout = self.euler.state[0]
        var deriv = List[SIMD[DType.float64, self.N]]()
        deriv.append((input - vout) / rc)

        self.euler.step(deriv)

        return self.euler.state[0] * 0.5