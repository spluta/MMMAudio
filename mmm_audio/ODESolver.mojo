from .MMMWorld_Module import *
from math import *

struct Euler[num_dims: Int, num_chans: Int = 1](Copyable, Movable):
    """Simple Euler method ODE solver.

    Parameters:
        num_dims: Number of dimensions (state variables), e.g. 2 for position and velocity.
        num_chans: Number of SIMD channels.
    """

    var state: List[SIMD[DType.float64, num_chans]]
    var dt: Float64
    var world: UnsafePointer[MMMWorld]

    fn __init__(out self, world: UnsafePointer[MMMWorld]):
        """Initialize the Euler struct."""
        self.world = world
        self.dt = 1.0 / world[].sample_rate
        self.state = List[SIMD[DType.float64, num_chans]]()
        for _ in range(num_dims):
            self.state.append(SIMD[DType.float64, num_chans](0.0))
        
    fn step(mut self, derivatives: List[SIMD[DType.float64, num_chans]]):
        """Perform a single Euler integration step.

        Args:
            derivatives: List of derivatives for each state variable.
        """
        for i in range(num_dims):
            self.state[i] = self.state[i] + derivatives[i] * self.dt

struct RK2[num_dims: Int, num_chans: Int = 1](Copyable, Movable):
    """Runge-Kutta 2nd order ODE solver.

    Parameters:
        num_dims: Number of dimensions (state variables), e.g. 2 for position and velocity.
        num_chans: Number of SIMD channels.
    """

    var state: List[SIMD[DType.float64, num_chans]]
    var dt: Float64
    var world: UnsafePointer[MMMWorld]

    fn __init__(out self, world: UnsafePointer[MMMWorld]):
        """Initialize the RK2 struct."""
        self.world = world
        self.state = List[SIMD[DType.float64, num_chans]]()
        self.dt = 1.0 / world[].sample_rate
        for _ in range(num_dims):
            self.state.append(SIMD[DType.float64, num_chans](0.0))

    fn step(mut self, fn_deriv: fn(List[SIMD[DType.float64, num_chans]]) -> List[SIMD[DType.float64, num_chans]]):
        """Perform a single RK2 integration step.

        Args:
            fn_deriv: Function that computes derivatives given the current state.
        """
        var k1 = fn_deriv(self.state)
        var temp_state = List[SIMD[DType.float64, num_chans]]()
        for i in range(num_dims):
            temp_state.append(self.state[i] + k1[i] * (self.dt / 2.0))
        
        var k2 = fn_deriv(temp_state)
        
        for i in range(num_dims):
            self.state[i] = self.state[i] + k2[i] * self.dt

struct RK4[num_dims: Int, num_chans: Int = 1](Copyable, Movable):
    """Runge-Kutta 4th order ODE solver.
    Parameters:
        num_dims: Number of dimensions (state variables), e.g. 2 for position and velocity.
        num_chans: Number of SIMD channels.
    """
    var state: List[SIMD[DType.float64, num_chans]]
    var dt: Float64
    var world: UnsafePointer[MMMWorld]

    fn __init__(out self, world: UnsafePointer[MMMWorld]):
        """Initialize the RK4 struct."""
        self.world = world
        self.dt = 1.0 / world[].sample_rate
        self.state = List[SIMD[DType.float64, num_chans]]()
        for _ in range(num_dims):
            self.state.append(SIMD[DType.float64, num_chans](0.0))

    fn step(mut self, fn_deriv: fn(List[SIMD[DType.float64, num_chans]]) -> List[SIMD[DType.float64, num_chans]]):
        """Perform a single RK4 integration step.
        Args:
            fn_deriv: Function that computes derivatives given the current state.
        """
        var k1 = fn_deriv(self.state)
        var temp_state = List[SIMD[DType.float64, num_chans]]()
        for i in range(num_dims):
            temp_state.append(self.state[i] + k1[i] * (self.dt / 2.0))
        
        var k2 = fn_deriv(temp_state)
        temp_state.clear()
        for i in range(num_dims):
            temp_state.append(self.state[i] + k2[i] * (self.dt / 2.0))
            
        var k3 = fn_deriv(temp_state)
        temp_state.clear()
        for i in range(num_dims):
            temp_state.append(self.state[i] + k3[i] * self.dt)
        
        var k4 = fn_deriv(temp_state)
        for i in range(num_dims):
            self.state[i] = self.state[i] + (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i]) * (self.dt / 6.0)