from mmm_audio import *
    
struct PAF[num_chans: Int = 1, interp: Int = Interp.linear, os_index: Int = 0, bell_bWrap: Bool = False](Representable, Movable, Copyable):
    """Phase-Aligned Formant generator using a single phasor to synthesize multiple wavetables . From Miller Puckette's "Theory and Technique of Electronic Music," page 170.

    Parameters:
        num_chans: Number of channels.
        interp: Interpolation method. See [Interp](MMMWorld.md/#struct-interp) struct for options.
        os_index: [Oversampling](Oversampling.md) index (0 = no oversampling, 1 = 2x, 2 = 4x, etc.).
        bell_bWrap: Whether to wrap indices that go out of bounds in the bell wavetable.
    """
    var world: World
    
    var phasor: Phasor[Self.num_chans, Self.os_index]

    var cos1_last_phase: MFloat[Self.num_chans]
    var cos2_last_phase: MFloat[Self.num_chans]
    var sin_last_phase: MFloat[Self.num_chans]
    var bell_last_phase: MFloat[Self.num_chans]
    var buffer: List[Float64]

    var oversampling: Oversampling[Self.num_chans, 2**Self.os_index]

    fn __init__(out self, world: World):
        """
        Args:
            world: Pointer to the MMMWorld instance.
        """
        self.world = world

        self.phasor = Phasor[self.num_chans, Self.os_index](self.world)

        self.cos1_last_phase = MFloat[self.num_chans](0.0)
        self.cos2_last_phase = MFloat[self.num_chans](0.0)
        self.sin_last_phase = MFloat[self.num_chans](0.0)
        self.bell_last_phase = MFloat[self.num_chans](0.0)
        self.buffer = List[Float64]()
        
        self.oversampling = Oversampling[self.num_chans, 2**Self.os_index](world)

        self.init_half_sine()

    fn init_half_sine(mut self):
        for i in range(OscBuffersSize):
            v = sin(3.141592653589793 * Float64(i) / Float64(OscBuffersSize))
            self.buffer.append(v)

    fn __repr__(self) -> String:
        return String("PAF")

    @always_inline
    fn next(
        mut self, 
        fundamental: MFloat[self.num_chans] = MFloat[self.num_chans](100.0), 
        center_freq: MFloat[self.num_chans] = MFloat[self.num_chans](440.0), 
        bandwidth: MFloat[self.num_chans] = MFloat[self.num_chans](1.0)
        ) -> MFloat[self.num_chans]:
        """Generate the next synthesized sample.

        Args:
            fundamental: Fundamental frequency of the phasor.
            center_freq: Center frequency of the formant.
            bandwidth: Bandwidth.
        
        Returns:
            The next sample of the synthesizer output.
        """

        cos1 = MFloat[self.num_chans](0.0)
        cos2 = MFloat[self.num_chans](0.0)
        sin = MFloat[self.num_chans](0.0)
        bell_phase = MFloat[self.num_chans](0.0)
        bell = MFloat[self.num_chans](0.0)
        mod = MFloat[self.num_chans](0.0)
        out = MFloat[self.num_chans](0.0)

        @parameter
        if Self.os_index == 0:
            phasor = self.phasor.next(fundamental)
            
            a = center_freq/fundamental
            b = wrap(a, 0.0,1.0)
            
            cos1_phase = phasor*(a - b)
            cos2_phase = cos1_phase + phasor
            sin_phase = phasor            
            @parameter
            for chan in range(self.num_chans):
                cos1[chan] = SpanInterpolator.read[
                        interp=self.interp, 
                        bWrap=True, 
                        mask=OscBuffersMask
                    ](
                        world=self.world, 
                        data=self.world[].osc_buffers[].buffers[MInt[](4)[chan]], 
                        f_idx=(cos1_phase[chan]*OscBuffersSize), 
                        prev_f_idx=self.cos1_last_phase[chan]*OscBuffersSize
                    )

                cos2[chan] = SpanInterpolator.read[
                    interp=self.interp, 
                    bWrap=True, 
                    mask=OscBuffersMask
                    ](
                        world=self.world, 
                        data=self.world[].osc_buffers[].buffers[MInt[](4)[chan]], 
                        f_idx=cos2_phase[chan]*OscBuffersSize, 
                        prev_f_idx=self.cos2_last_phase[chan]*OscBuffersSize
                    )
            
                sin[chan] = SpanInterpolator.read[
                    interp=self.interp, 
                    bWrap=True, 
                    mask=OscBuffersMask
                    ](
                        world=self.world, 
                        data=self.buffer, 
                        f_idx=sin_phase[chan]*OscBuffersSize, 
                        prev_f_idx=self.sin_last_phase[chan]*OscBuffersSize
                    )
            
                bell_phase = (sin*((bandwidth/fundamental)*0.25))+0.5
                bell[chan] = SpanInterpolator.read[
                    interp=self.interp, 
                    bWrap=self.bell_bWrap, 
                    mask=OscBuffersMask
                    ](
                        world=self.world, 
                        data=self.world[].osc_buffers[].buffers[MInt[](5)[chan]], 
                        f_idx=bell_phase[chan]*OscBuffersSize, 
                        prev_f_idx=self.bell_last_phase[chan]*OscBuffersSize
                    )
            self.cos1_last_phase = cos1_phase
            self.cos2_last_phase = cos2_phase
            self.sin_last_phase = sin_phase
            self.bell_last_phase = bell_phase

            mod = ((cos2 - cos1)*b)+cos1
            out = mod * bell
            return out
        else:
            @parameter
            for _ in range(2**Self.os_index):
                phasor = self.phasor.next(fundamental)
                
                a = center_freq/fundamental
                b = wrap(a, 0.0,1.0)
                
                cos1_phase = phasor*(a - b)
                cos2_phase = cos1_phase + phasor
                sin_phase = phasor                
                for chan in range(self.num_chans):
                    cos1[chan] = SpanInterpolator.read[
                            interp=self.interp, 
                            bWrap=True, 
                            mask=OscBuffersMask
                        ](
                            world=self.world, 
                            data=self.world[].osc_buffers[].buffers[MInt[](4)[chan]], 
                            f_idx=(cos1_phase[chan]*OscBuffersSize), 
                            prev_f_idx=self.cos1_last_phase[chan]*OscBuffersSize
                        )

                    cos2[chan] = SpanInterpolator.read[
                        interp=self.interp, 
                        bWrap=True, 
                        mask=OscBuffersMask
                        ](
                            world=self.world, 
                            data=self.world[].osc_buffers[].buffers[MInt[](4)[chan]], 
                            f_idx=cos2_phase[chan]*OscBuffersSize, 
                            prev_f_idx=self.cos2_last_phase[chan]*OscBuffersSize
                        )
                
                    sin[chan] = SpanInterpolator.read[
                        interp=self.interp, 
                        bWrap=True, 
                        mask=OscBuffersMask
                        ](
                            world=self.world, 
                            data=self.buffer, 
                            f_idx=sin_phase[chan]*OscBuffersSize, 
                            prev_f_idx=self.sin_last_phase[chan]*OscBuffersSize
                        )
                
                    bell_phase[chan] = (sin[chan]*((bandwidth[chan]/fundamental[chan])*0.25))+0.5
                    bell[chan] = SpanInterpolator.read[
                        interp=self.interp, 
                        bWrap=self.bell_bWrap, 
                        mask=OscBuffersMask
                        ](
                            world=self.world, 
                            data=self.world[].osc_buffers[].buffers[MInt[](5)[chan]], 
                            f_idx=bell_phase[chan]*OscBuffersSize, 
                            prev_f_idx=self.bell_last_phase[chan]*OscBuffersSize
                        )
                    mod[chan] = ((cos2[chan] - cos1[chan])*b[chan])+cos1[chan]
                    out[chan] = mod[chan] * bell[chan]
                self.cos1_last_phase = cos1_phase
                self.cos2_last_phase = cos2_phase
                self.sin_last_phase = sin_phase
                self.bell_last_phase = bell_phase                
                self.oversampling.add_sample(out)
            
            return self.oversampling.get_sample()