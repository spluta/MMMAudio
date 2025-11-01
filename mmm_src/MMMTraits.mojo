trait Messagable(Copyable, Movable):
    fn register_messages(mut self):
        pass

# from mmm_src.MMMWorld import MMMWorld
# from sys import simd_width_of
# from algorithm import vectorize

# trait Graphable:
#     fn next(mut self: Self) -> List[Float64]: ...

# # trait Buffable:
# #     fn read[N: Int = 1](mut self, start_chan: Int64, phase: Float64, interp: Int64 = 0) -> SIMD[DType.float64, N]: ...
# #     fn get_num_frames(self) -> Float64: ...
# #     fn get_duration(self) -> Float64: ...
# #     fn get_buf_sample_rate(self) -> Float64: ...

# # trait MutableIndexable(Sized, Copyable, Movable, SizedRaising):
# #     fn __getitem__[I: Indexer, //](ref self, idx: I) -> ref [self] Float64: ...
# #     fn __setitem__(mut self, index: Int, value: Float64): ...

# # trait UGen1(Copyable, Movable):
# #     fn next(mut self, arg0: SIMD[DType.float64, simd_width_of[DType.float64]()], arg1: SIMD[DType.float64, simd_width_of[DType.float64]()]) -> SIMD[DType.float64, simd_width_of[DType.float64]()]: ...

# # # when traits can have parameters, this will hopefully be possible
# # trait ListProcessable(Copyable, Movable):
# #     pass
# #     # fn next(mut self, ref in_list: List[Float64], mut out_list: List[Float64], args: List[Float64]): ...

# # trait Indexable(Sized, Copyable, Movable):
# #     fn __getitem__[I: Indexer, //](ref self, idx: I) -> ref [self] T: ...

# # trait IndexReadable:
# #     fn len(self) -> Int:
# #         return len(self)
# #     fn getitem(mut self, i: Int) -> Float64:
# #         return self[i]
