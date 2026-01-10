This trait requires that two functions be implemented (see below for more details).

* `fn next_frame()`: This function gets passed a list of magnitudes
and a list of phases that are the result of an FFT. The user should manipulate 
these values in place so that once this function is done the values in those 
lists are what the user wants to be used for the IFFT conversion back into 
amplitude samples. Because the FFT only happens every `hop_size` samples (and
uses the most recent `window_size` samples), this function only gets called every
`hop_size` samples. `hop_size` is set as a parameter in the `FFTProcessor`
struct that the user's struct is passed to.
* `fn get_messages()`: Because `.next_frame()` only runs every `hop_size`
samples and a `Messenger` can only check for new messages from Python at the top 
of every audio block, it's not guaranteed that these will line up, so this struct
could very well miss incoming messages! To remedy this, put all your message getting
code in this get_messages() function. It will get called by FFTProcessor (whose 
`.next()` function does get called every sample) to make sure that any messages
intended for this struct get updated.

## Outline of Spectral Processing:

1. The user creates a custom struct that implements the FFTProcessable trait. The
required functions for that are `.next_frame()` and `.get_messages()`. 
`.next_frame()` is passed a `List[Float64]` of magnitudes and a
`List[Float64]` of phases. The user can manipulate this data however they want and 
then needs to replace the values in those lists with what they want to be used for
the IFFT.
2. The user passes their struct (in 1) as a Parameter to the `FFTProcess` struct. 
You can see where the parameters such as `window_size`, `hop_size`, and window types 
are expressed.
3. In the user synth's `.next()` function (running one sample at a time) they pass in
every sample to the `FFTProcess`'s `.next()` function which:
    * has a `BufferedProcess` to store samples and pass them on 
    to `FFTProcessor` when appropriate
    * when `FFTProcessor` receives a window of amplitude samples, it performs an
    `FFT` getting the mags and phases which are then passed on to the user's 
    struct that implements `FFTProcessable`. The mags and phases are modified in place
    and then this whole pipeline basically hands the data all the way back out to the user's
    synth struct where `FFTProcess`'s `.next()` function returns the next appropriate
    sample (after buffering -> FFT -> processing -> IFFT -> output buffering) to get out 
    to the speakers (or whatever).