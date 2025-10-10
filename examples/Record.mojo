from mmm_src.MMMWorld import MMMWorld
from mmm_utils.Messengers import *
from mmm_utils.functions import *
from mmm_src.MMMTraits import *
from mmm_dsp.Buffer import *
from mmm_dsp.RecordBuf import RecordBuf
from mmm_dsp.PlayBuf import PlayBuf
from mmm_dsp.Env import min_env

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
    var note_time: Float64
    var end_frame: Float64
    var input_chan: Int64
    var messenger: Messenger

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
        self.note_time = 0.0
        self.end_frame = 0.0
        self.input_chan = 0
        self.messenger = Messenger(world_ptr)

    fn __repr__(self) -> String:
        return String("Record_Synth")

    fn start_recording(mut self):
        self.note_time = time.perf_counter()
        self.write_pos = 0
        self.is_recording = 1.0
        self.is_playing = 0.0
        self.trig = 0.0
        print("Recording started")
    
    fn stop_recording(mut self):
        self.note_time = min(time.perf_counter() - self.note_time, self.buf_dur)
        self.end_frame = floor(self.note_time*self.world_ptr[0].sample_rate)
        self.note_time = self.end_frame / self.world_ptr[0].sample_rate
        self.is_recording = 0.0
        self.is_playing = 1.0
        self.trig = 1.0
        self.write_pos = 0
        print(self.note_time, self.end_frame/self.world_ptr[0].sample_rate)
        print("Recorded duration:", self.note_time, "seconds")
        print("Recording stopped. Now playing.")

    fn next(mut self) -> SIMD[DType.float64, 1]:
        
        if self.world_ptr[0].top_of_block:
            input_chan = self.messenger.get_val("set_input_chan", 0)
            if input_chan >= 0 and Int64(input_chan) < self.world_ptr[0].num_in_chans:
                self.input_chan = Int64(input_chan)

            start = self.messenger.triggered("start_recording")
            if start > 0:
                self.start_recording()

            stop = self.messenger.triggered("stop_recording")
            if stop > 0:
                self.stop_recording()

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

struct Record(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]

    var synth: Record_Synth

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.synth = Record_Synth(self.world_ptr)

    fn __repr__(self) -> String:
        return String("Record")

    fn next(mut self) -> SIMD[DType.float64, 2]:
        return self.synth.next()