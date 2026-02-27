from mmm_audio import *

struct MessengerRoundTripTest(Movable, Copyable):
    var world: World
    var m: Messenger
    var float_val: Float64
    var floats_val: List[Float64]
    var int_val: Int
    var ints_val: List[Int]
    var bool_val: Bool
    var str: String
    var strs: List[String]

    var stream_float_val: Float64
    var stream_floats_val: List[Float64]
    var stream_int_val: Int
    var stream_ints_val: List[Int]
    var stream_bool_val: Bool
    var stream_str_val: String
    var stream_strs_val: List[String]

    fn __init__(out self, world: World):
        self.world = world
        self.m = Messenger(self.world)
        self.float_val = 0.0
        self.floats_val = List[Float64]()
        self.int_val = 0
        self.ints_val = List[Int]()
        self.bool_val = False
        self.str = ""
        self.strs = List[String]()

        self.stream_float_val = 42.42
        self.stream_floats_val = [1.1, 2.2, 3.3]
        self.stream_int_val = 1825
        self.stream_ints_val = [1776,2026]
        self.stream_bool_val = True
        self.stream_str_val = "kenobi"
        self.stream_strs_val = ["luke", "leia", "han"]

    fn next(mut self) -> SIMD[DType.float64, 2]:
        
        if self.m.notify_update(self.float_val,"float"):
            self.m.reply_once("float_return", self.float_val + 1.0)
        
        if self.m.notify_update(self.floats_val,"floats"):
            self.m.reply_once("floats_return", [x + 1.0 for x in self.floats_val])

        if self.m.notify_update(self.int_val,"int"):
            self.m.reply_once("int_return", self.int_val + 1)
        
        if self.m.notify_update(self.ints_val,"ints"):
            self.m.reply_once("ints_return", [x + 1 for x in self.ints_val])
        
        if self.m.notify_update(self.bool_val,"bool"):
            self.m.reply_once("bool_return", not self.bool_val)
        
        if self.m.notify_trig("trig"):
            self.m.reply_once("trig_return")
        
        if self.m.notify_update(self.str,"str"):
            self.m.reply_once("str_return", self.str + "_return")
        
        if self.m.notify_update(self.strs,"strs"):
            self.m.reply_once("strs_return", [s + "_return" for s in self.strs])

        self.m.reply_stream("stream_float", self.stream_float_val)
        self.m.reply_stream("stream_floats", self.stream_floats_val)
        self.m.reply_stream("stream_int", self.stream_int_val)
        self.m.reply_stream("stream_ints", self.stream_ints_val)
        self.m.reply_stream("stream_bool", self.stream_bool_val)
        self.m.reply_stream("stream_str", self.stream_str_val)
        self.m.reply_stream("stream_strs", self.stream_strs_val)
        
        return SIMD[DType.float64, 2](0.0, 0.0)