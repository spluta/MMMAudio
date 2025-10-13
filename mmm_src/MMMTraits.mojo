
from mmm_src.MMMWorld import MMMWorld

trait Graphable:
    fn next(mut self: Self) -> List[Float64]: ...

trait Buffable:
    fn read[N: Int = 1](mut self, start_chan: Int64, phase: Float64, interp: Int64 = 0) -> SIMD[DType.float64, N]: ...
    fn get_num_frames(self) -> Float64: ...
    fn get_duration(self) -> Float64: ...
    fn get_buf_sample_rate(self) -> Float64: ...

# when traits can have parameters, this will hopefully be possible
# trait ListProcessable[N: Int](Copyable, Movable):
#     fn next(mut self, input: SIMD[DType.float64, N], arg: SIMD[DType.float64, N]) -> SIMD[DType.float64, N]:
#         ...

    @staticmethod
    fn process_list[num: Int](mut list_of_self: List[Self], ref in_list: List[Float64], mut out_list: List[Float64], *args: SIMD[DType.float64, N]):
        """Process a list of input samples through a list of processors.

        Parameters:
            num: Total number of values in the list.

        Args:
            list_of_self: (List[Lag]): List of Self.
            in_list: (List[Float64]): List of input samples.
            out_list: (List[Float64]): List of output samples after applying the processing.
            args: VariadicList of arguments.

        """

        alias groups = num // N
        alias remainder = num % N

        vals = SIMD[DType.float64, N](0.0)

        # Apply vectorization
        @parameter
        for i in range(groups):
            @parameter
            for j in range(N):
                vals[j] = in_list[j + (i * N)]
            temp = list_of_self[i].next(
                vals, args[0] #onces args can be unpacked, this is a generic solution for almost all ugens
            )
            @parameter
            for j in range(N):
                out_list[i * N + j] = temp[j]
        @parameter
        if remainder > 0:
            @parameter
            for i in range(remainder):
                vals[i] = in_list[groups * N + i]
            temp = list_of_self[groups].next(vals, args[0])
            @parameter
            for i in range(remainder):
                out_list[groups*N + i] = temp[i]
