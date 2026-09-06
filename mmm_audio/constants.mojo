from mmm_audio.MMMWorld_Module import MMMWorld
from mmm_audio.Messenger_Module import Messenger
from std.math import pi

comptime MFloat[N: SIMDLength = 1] = SIMD[DType.float64, N]
comptime MInt[N: SIMDLength = 1] = SIMD[DType.int, N]
comptime MBool[N: SIMDLength = 1] = SIMD[DType.bool, N]
comptime World = Pointer[mut=True, MMMWorld, MutUntrackedOrigin]
comptime MessengerPointer = Pointer[mut=True, Messenger, MutUntrackedOrigin]

comptime two_pi = 2.0 * pi
comptime pi_over2 = 1.5707963267948966