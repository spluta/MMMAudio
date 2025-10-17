from sys import simd_width_of
from mmm_src.MMMTraits import *

alias simd_width = simd_width_of[DType.float64]()

# UGen1 has the shape in_sample, argument
fn next[T: UGen1](mut ugen_list: List[T], ref in_list: List[Float64], mut out_list: List[Float64], args: List[Float64]):

    vals = SIMD[DType.float64, simd_width](0.0)
    args_simd = SIMD[DType.float64, simd_width](0.0)
    N = len(out_list)

    @parameter
    fn closure[width: Int](i: Int):
        @parameter
        for j in range(simd_width):
            vals[j] = in_list[j + i]
            args_simd[j] = args[(j + i)%len(args)]  # wrap around if not enough args

        temp = ugen_list[i // simd_width].next(vals, args_simd)
        @parameter
        for j in range(simd_width):
            idx = i + j
            if idx < N:
                # print(idx, end=" ")
                out_list[idx] = temp[j]
            # print("", end="\n")
    vectorize[closure, simd_width](N)