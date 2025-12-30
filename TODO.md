## UGens

- Shaper
- Dattoro, GVerb

## Big Ones

- replace pyaudio with Mojo PortAudio bindings
- load and save wav files without numpy/scipy
- Multiple graphs in one MMMAudioinstance
- multiprocessor support

## Outline of TableReading

* struct `Player` can play back anything that implements the `Playable` trait
    * `Player::next()`
    * `Player:: var prev_idx_f`
* The interpolation `fn`s are not owned by anything. They will live in `mmm_utils.functions`. They get called as `fn`s in `Player`
* trait `Playable`
  * `fn __getitem__`
  * `fn at_phase[interp: Int = Interp.none]` for convenience re: windowing, etc.
* struct `Buffer` is for loading sound files and VWTs.
  * `var sample_rate`
* struct `OscBuffer` will hold wavetables 2^14 in size
* `BufferedProcess` will still make it's own windows to ensure they're the perfect size. Other UGens can of course do this as well.