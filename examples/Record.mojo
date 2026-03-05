from mmm_audio import *

import time

struct Record_Synth(Representable, Movable, Copyable):
    var world: World
    var buf_dur: Float64
    var buffer: Recorder[]
    var is_recording: Bool
    var is_playing: Float64
    var playback_speed: Float64
    var trig: Bool
    var write_pos: Int 
    var play_buf: Play
    var note_time: Float64
    var num_frames: Int
    var input_chan: Int
    var messenger: Messenger

    fn __init__(out self, world: World):
        self.world = world
        self.buf_dur = 10.0  # seconds
        self.buffer = Recorder(self.world, Int(self.world[].sample_rate*self.buf_dur), self.world[].sample_rate)
        self.is_recording = False
        self.is_playing = 0.0
        self.trig = False
        self.playback_speed = 1.0
        self.play_buf = Play(self.world)
        self.write_pos = 0
        self.note_time = 0.0
        self.num_frames = 0
        self.input_chan = 0
        self.messenger = Messenger(self.world)

    fn __repr__(self) -> String:
        return String("Record_Synth")

    fn start_recording(mut self):
        self.note_time = time.perf_counter()
        self.write_pos = 0
        self.is_recording = True
        self.is_playing = 0.0
        self.trig = False
        print("Recording started")
    
    fn stop_recording(mut self):
        self.note_time = min(time.perf_counter() - self.note_time, self.buf_dur)
        self.num_frames = Int(self.note_time*self.world[].sample_rate)
        self.note_time = Float64(self.num_frames) / self.world[].sample_rate
        self.is_recording = False
        self.is_playing = 1.0
        self.trig = True
        self.write_pos = 0
        print("Recorded duration:", self.note_time, "seconds")
        print("Recording stopped. Now playing.")

    fn next(mut self) -> SIMD[DType.float64, 1]:
        if self.messenger.notify_update(self.input_chan,"set_input_chan"):
            if self.input_chan < 0 and self.input_chan >= self.world[].num_in_chans:
                print("Input channel out of range, resetting to 0")
                self.input_chan = 0

        notified = self.messenger.notify_update(self.is_recording,"is_recording")
        if notified and self.is_recording:
            self.start_recording()
        elif notified and not self.is_recording:
            self.stop_recording()

        # this code does the actual recording, placing the next sample into the buffer
        # my audio interface has audio in on channel 9, so I use self.world[].sound_in[8]
        if self.is_recording:
            # the sound_in List in the world holds the audio in data for the current sample, so grab it from there.
            self.buffer.write(self.world[].sound_in[self.input_chan], self.write_pos)
            self.write_pos += 1
            if self.write_pos >= Int(self.buffer.buf.num_frames):
                self.is_recording = False
                print("Recording stopped: buffer full")
                self.is_playing = 1.0
                self.trig = True
                self.write_pos = 0

        out = self.play_buf.next(self.buffer.buf, self.playback_speed, True, self.trig, start_frame = 0, num_frames = self.num_frames)

        env = min_env(self.play_buf.get_relative_phase(), self.note_time, 0.01)

        out = out * self.is_playing * env

        return out

struct Record(Representable, Movable, Copyable):
    var world: World

    var synth: Record_Synth

    fn __init__(out self, world: World):
        self.world = world
        self.synth = Record_Synth(self.world)

    fn __repr__(self) -> String:
        return String("Record")

    fn next(mut self) -> SIMD[DType.float64, 2]:
        return self.synth.next()