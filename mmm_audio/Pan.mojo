from math import sqrt, floor, cos, pi, sin
from bit import next_power_of_two
from sys import simd_width_of
from mmm_audio import *

@always_inline
fn pan2(samples: Float64, pan: Float64) -> SIMD[DType.float64, 2]:
    """
    Simple constant power panning function.

    Args:
        samples: Float64 - Mono input sample.
        pan: Float64 - Pan value from -1.0 (left) to 1.0 (right).

    Returns:
        Stereo output as SIMD[DType.float64, 2].
    """

    var pan2 = clip(pan, -1.0, 1.0)  # Ensure pan is set and clipped before processing
    var gains = SIMD[DType.float64, 2](-pan2, pan2)

    samples_out = samples * sqrt((1 + gains) * 0.5)
    return samples_out  # Return stereo output as List

@always_inline
fn pan_stereo(samples: SIMD[DType.float64, 2], pan: Float64) -> SIMD[DType.float64, 2]:
    """
    Simple constant power panning function for stereo samples.

    Args:
        samples: SIMD[DType.float64, 2] - Stereo input sample.
        pan: Float64 - Pan value from -1.0 (left) to 1.0 (right).

    Returns:
        Stereo output as SIMD[DType.float64, 2].
    """
    var pan2 = clip(pan, -1.0, 1.0)  # Ensure pan is set and clipped before processing
    var gains = SIMD[DType.float64, 2](-pan2, pan2)

    samples_out = samples * sqrt((1 + gains) * 0.5)
    return samples_out  # Return stereo output as List

@always_inline
fn splay[num_simd: Int](input: List[SIMD[DType.float64, num_simd]], world: World) -> SIMD[DType.float64, 2]:
    """
    Splay multiple input channels into stereo output.

    There are multiple versions of splay to handle different input types. It can take a list of SIMD vectors or a single 1 or many channel SIMD vector. In the case of a list of SIMD vectors, each channel within the vector is treated separately and panned individually.

    Args:
        input: List of input samples from multiple channels.
        world: Pointer to MMMWorld containing the pan_window.

    Returns:
        Stereo output as SIMD[DType.float64, 2].
    """
    num_input_channels = len(input) * num_simd
    out = SIMD[DType.float64, 2](0.0)

    for i in range(num_input_channels):
        if num_input_channels == 1:
            out = input[0][0] * SIMD[DType.float64, 2](0.7071, 0.7071)
        else:
            pan = Float64(i) / Float64(num_input_channels - 1)

            index0 = i // num_simd
            index1 = i % num_simd
            
            pan_mul = SpanInterpolator.read[
                        interp=Interp.none,
                        bWrap=False,
                        mask=255
                    ](
                        world = world,
                        data=world[].windows[].pan2,
                        f_idx=pan * 255.0
                    )
            out += input[index0][index1] * pan_mul
    return out

@always_inline
fn splay[num_input_channels: Int](input: SIMD[DType.float64, num_input_channels], world: World) -> SIMD[DType.float64, 2]:
    """
    Splay multiple input channels into stereo output.

    There are multiple versions of splay to handle different input types. It can take a list of SIMD vectors or a single 1 or many channel SIMD vector. In the case of a list of SIMD vectors, each channel within the vector is treated separately and panned individually.

    Args:
        input: List of input samples from multiple channels. List of Float64 or List of SIMD vectors.
        world: Pointer to MMMWorld containing the pan_window.
    
    Returns:
        Stereo output as SIMD[DType.float64, 2].
    """
    out = SIMD[DType.float64, 2](0.0)

    for i in range(num_input_channels):
        if num_input_channels == 1:
            out = input[0] * SIMD[DType.float64, 2](0.7071, 0.7071)
        else:
            pan = Float64(i) / Float64(num_input_channels - 1)

            pan_mul = SpanInterpolator.read[
                        interp=Interp.none,
                        bWrap=False,
                        mask=255
                    ](
                        world = world,
                        data=world[].windows[].pan2,
                        f_idx=pan * 255.0
                    )
            out += input[i] * pan_mul
    return out

@always_inline
fn pan_az[simd_out_size: Int = 2](sample: Float64, pan: Float64, num_speakers: Int, width: Float64 = 2.0, orientation: Float64 = 0.5) -> SIMD[DType.float64, simd_out_size]:
    """
    Pan a mono sample to N speakers arranged in a circle around the listener using azimuth panning.

    Parameters:
        simd_out_size: Number of output channels (speakers). Must be a power of two that is at least as large as num_speakers.

    Args:
        sample: Mono input sample.
        pan: Pan position from 0.0 to 1.0.
        num_speakers: Number of speakers to pan to.
        width: Width of the speaker array (default is 2.0).
        orientation: Orientation offset of the speaker array (default is 0.5).

    Returns:
        SIMD[DType.float64, simd_out_size]: The panned output sample for each speaker.
    """

    var rwidth = 1.0 / width
    var frange = Float64(num_speakers) * rwidth
    var rrange = 1.0 / frange

    var aligned_pos_fac = 0.5 * Float64(num_speakers)
    var aligned_pos_const = width * 0.5 + orientation
    var constant = pan * 2.0 * aligned_pos_fac + aligned_pos_const

    out = SIMD[DType.float64, simd_out_size](0.0)

    comptime simd_width: Int = simd_width_of[DType.float64]() * 2

    @parameter
    fn process_speakers[simd_width: Int](i: Int) unified {mut}:
        # Create index vector
        var indices = SIMD[DType.float64, simd_width]()
        for j in range(simd_width):
            indices[j] = i + j
        
        # Compute chan_pos
        var pos = (constant - indices) * rwidth
        pos = (pos - frange * floor(rrange * pos)) * pi
        
        # Compute chan_amp with conditional
        var mask: SIMD[DType.bool, simd_width] = pos.lt(pi)
        sig = mask.select(sin(pos), SIMD[DType.float64, simd_width](0.0)) * sample
        for j in range(simd_width):
            out[Int(i + j)] = sig[j]

    vectorize[simd_width](Int(num_speakers), process_speakers)

    return out

comptime pi_over_2 = pi / 2.0

struct SplayN[num_channels: Int = 2, pan_points: Int = 128](Movable, Copyable):
    """
    SplayN - Splays multiple input channels into N output channels. Different from `splay` which only outputs stereo, SplayN can output to any number of channels.
    
    Parameters:
        num_channels: Number of output channels to splay to.
        pan_points: Number of discrete pan points to use for panning calculations. Default is 128.
    """
    var output: List[Float64]  # Output list for stereo output
    var world: World
    var mul_list: List[SIMD[DType.float64, Self.num_channels]]

    fn __init__(out self, world: World):
        """
        Initialize the SplayN instance.

        Args:
            world: Pointer to the MMMWorld instance.
        """
        self.output = [0.0, 0.0]  # Initialize output list for stereo output
        self.world = world

        js = SIMD[DType.float64, self.num_channels](0.0, 1.0)
        @parameter
        if self.num_channels > 2:
            for j in range(self.num_channels):
                js[j] = Float64(j)

        self.mul_list = [SIMD[DType.float64, self.num_channels](0.0) for _ in range(self.pan_points)]
        for i in range(self.pan_points):
            pan = Float64(i) * Float64(self.num_channels - 1) / Float64(self.pan_points - 1)

            d = abs(pan - js)
            @parameter
            if self.num_channels > 2:
                for j in range(self.num_channels):
                    if d[j] < 1.0:
                        d[j] = d[j]
                    else:
                        d[j] = 1.0
            
            for j in range(self.num_channels):
                self.mul_list[i][j] = cos(d[j] * pi_over_2)

    @always_inline
    fn next[num_simd: Int](mut self, input: List[SIMD[DType.float64, num_simd]]) -> SIMD[DType.float64, self.num_channels]:
        """Evenly distributes multiple input channels to num_channels of output channels.

        Args:
            input: List of input samples from multiple channels.

        Returns:
            SIMD[DType.float64, self.num_channels]: The panned output sample for each output channel.
        """
        out = SIMD[DType.float64, self.num_channels](0.0)

        in_len = len(input) * num_simd
        if in_len == 0:
            return out
        elif in_len == 1:
            out = input[0][0] * self.mul_list[0]
            return out
        for i in range(in_len):
            index0 = i // num_simd
            index1 = i % num_simd

            out += input[index0][index1] * self.mul_list[Int(Float64(i) / Float64(in_len - 1) * Float64(self.pan_points - 1))]
            
        return out