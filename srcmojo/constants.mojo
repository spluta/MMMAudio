# from .srcmojo import *

comptime MFloat[N: Int = 1] = SIMD[DType.float64, N]
comptime MInt[N: Int = 1] = SIMD[DType.int, N]
comptime MBool[N: Int = 1] = SIMD[DType.bool, N]
comptime World = UnsafePointer[mut=True, MMMWorld, MutExternalOrigin]
comptime MessengerPointer = UnsafePointer[mut=True, Messenger, MutExternalOrigin]

comptime two_pi = 2.0 * pi
comptime pi_over2 = 1.5707963267948966