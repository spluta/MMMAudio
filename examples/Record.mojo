from mmm_src.MMMWorld import MMMWorld
from mmm_utils.functions import *
from mmm_src.MMMTraits import *
from mmm_dsp.Buffer import *
from mmm_dsp.RecordBuf import RecordBuf
from mmm_dsp.PlayBuf import PlayBuf
from mmm_dsp.Env import min_env
from mmm_dsp.Filters import Lag

import time
from math import floor

from mmm_dsp.Osc import Osc

struct Record_Synth(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var buf_dur: Float64
    var buffer: Buffer
    var is_recording: Float64
    var is_playing: Float64
    var playback_speed: Float64
    var trig: Float64
    var write_pos: Int64 
    var record_buf: RecordBuf
    var play_buf: PlayBuf
    var note_ons: List[List[Int64]]
    var note_offs: List[List[Int64]]
    var note_time: Float64
    var lag: Lag
    var end_frame: Float64
    var input_chan: Int64

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.buf_dur = 10.0  # seconds
        self.buffer = Buffer(1, Int64(self.world_ptr[0].sample_rate*self.buf_dur), self.world_ptr[0].sample_rate)
        self.is_recording = 0.0
        self.is_playing = 0.0
        self.trig = 0.0
        self.playback_speed = 1.0
        self.record_buf = RecordBuf(world_ptr)
        self.play_buf = PlayBuf(world_ptr)
        self.write_pos = 0
        self.note_ons = List[List[Int64]]()
        self.note_offs = List[List[Int64]]()
        self.note_time = 0.0
        self.end_frame = 0.0
        self.lag = Lag(world_ptr)
        self.input_chan = 0 

    fn __repr__(self) -> String:
        return String("Record_Synth")

    fn next(mut self) -> SIMD[DType.float64, 1]:
        self.get_msgs()

        for note_on in self.note_ons:
            print(note_on[0], note_on[1], note_on[2], end = "\n")
            if note_on[1] == 48:  
                self.note_time = time.perf_counter()
                self.write_pos = 0
                self.is_recording = 1.0
                self.is_playing = 0.0
                self.trig = 0.0
                print("Recording started")
        self.note_ons.clear()

        for note_off in self.note_offs:
            if note_off[1] == 48:  # C4 to stop recording
                self.note_time = min(time.perf_counter() - self.note_time, self.buf_dur)
                self.end_frame = floor(self.note_time*self.world_ptr[0].sample_rate)
                print(self.note_time, self.end_frame/self.world_ptr[0].sample_rate)
                self.note_time = self.end_frame / self.world_ptr[0].sample_rate
                print("Recorded duration:", self.note_time, "seconds")
                self.is_recording = 0.0
                print("Recording stopped. Now playing.")
                self.is_playing = 1.0
                self.trig = 1.0
                self.write_pos = 0
                
        self.note_offs.clear()

        # this code does the actual recording, placing the next sample into the buffer
        # my audio interface has audio in on channel 9, so I use self.world_ptr[0].sound_in[8]
        if self.is_recording:
            # the sound_in List in the world_ptr holds the audio in data for the current sample, so grab it from there.
            self.buffer.write(self.world_ptr[0].sound_in[self.input_chan], self.write_pos)
            self.write_pos += 1
            if self.write_pos >= Int(self.buffer.num_frames):
                self.is_recording = 0.0
                print("Recording stopped: buffer full")
                self.is_playing = 1.0
                self.trig = 1.0
                self.write_pos = 0

        out = self.play_buf.next(self.buffer, 0, self.playback_speed, True, self.trig, start_frame = 0, end_frame = self.end_frame)

        out = out * self.is_playing * min_env(self.play_buf.get_win_phase(), self.note_time, 0.01)

        return out

    fn get_msgs(mut self: Self):
        # Get messages from the world
        msg = self.world_ptr[0].get_msg("print_inputs")
        if msg:
            for i in range(self.world_ptr[0].num_in_chans):
                print("input[", i, "] =", self.world_ptr[0].sound_in[i])
        msg = self.world_ptr[0].get_msg("start_recording")
        if msg:
            self.write_pos = 0
            self.is_recording = 1.0
            self.is_playing = 0.0
            self.trig = 0.0
        msg = self.world_ptr[0].get_msg("set_input_chan")
        if msg:
            chan = Int64(msg.value()[0])
            if chan >= 0 and chan < self.world_ptr[0].num_in_chans:
                self.input_chan = chan
                print("Setting input channel to", chan)
        note_ons = self.world_ptr[0].get_midi("note_on",-1, -1)  # Get all note on messages
        if note_ons:
            self.note_ons = note_ons.value().copy()
        note_offs = self.world_ptr[0].get_midi("note_off",-1, -1)  # Get all note off messages
        if note_offs:
            self.note_offs = note_offs.value().copy()

# there can only be one graph in an MMMAudio instance
# a graph can have as many synths as you want
struct Record(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]

    var synth: Record_Synth

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.synth = Record_Synth(self.world_ptr)

    fn __repr__(self) -> String:
        return String("Record")

    fn next(mut self) -> SIMD[DType.float64, 2]:
        sample = self.synth.next()
        # print("sample:", sample)
        return sample