from random import random
import sys
from math import sqrt
from time import perf_counter_ns

fn rmsfloat[windowsize: Int = 1024]() -> Float64:
    window: List[Float64] = List[Float64](length=windowsize,fill=0.0)

    @parameter
    for i in range(windowsize):
        window[i] = random.random_float64() * 2.0 - 1.0
    
    sum: Float64 = 0.0

    @parameter
    for i in range(windowsize):
        sum += window[i] * window[i]
    rms: Float64 = sqrt(sum / Float64(windowsize))
    # print("RMS Float64: " , rms)
    return rms

fn rmssimd[windowsize: Int = 1024]() -> Float64:
    
    comptime simdwidth: Int = sys.simd_width_of[Float64]()

    # print("SIMD width: ", simdwidth)

    window = LegacyUnsafePointer[Scalar[DType.float64]].alloc(windowsize)

    for i in range(windowsize):
        window[i] = random.random_float64() * 2.0 - 1.0
    
    sum = 0.0
    for i in range(0, windowsize, simdwidth):
        v = window.load[width=simdwidth](offset=i)
        sum += (v * v).reduce_add() 

    rms: Float64 = sqrt(sum / Float64(windowsize))

    return rms

fn main():

    n: Int = 1000

    start_time = perf_counter_ns()
    # floats
    rms: Float64 = 0.0
    for _ in range(n):
        rms = rmsfloat()
    end_time = perf_counter_ns()
    
    print("RMS Float64: ", rms)
    print("Time taken for rmsfloat: ", end_time - start_time)

    # simd floats
    start_time = perf_counter_ns()
    for _ in range(n):
        rms = rmssimd()
    end_time = perf_counter_ns()

    print("RMS SIMD Float64: ", rms)
    print("Time taken for rmssimd: ", end_time - start_time)
    