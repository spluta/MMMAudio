# MMMAudio Roadmap

## 1. Move to 26.1 or Mojo 1.0

This year Mojo should have a 1.0 release, probably some time in the summer. MMMAudio is currently stuck on Mojo 25.6 because of the changes made to UnsafePointer, which is the principle struct of MMMWorld. We could use LegacyUnsafePointer without changing anything else, but who wants to type that all over the place? So a big goal is to move to the new UnsafPointer, then move toward Mojo 1.0 compliance.

## 2. Test Suite

With our move to Mojo 1.0, we need to develop a comprehensive test suite to make sure MMMAudio code is safe. 

## 3. Multi-MMMAudio

You can already run multiple instances of MMMAudio. Just run them in different Terminal instances or run one in your code editor and one in the Terminal. 

However, with Python 3.14 and beyond, we should be able to run multiple audio engines within the same Python instance, and control them with the same Python control environment. So Python schedulers, like OSCServer and Scheduler could send messages to different audio engines, giving us true parallel audio, just as SuperCollider does it.


## 4. GPU-based dsp

Mojo is designed for GPU and it works on Apple Silicon GPUs. This should allow us to integrate GPU-based dsp, like FFTs, into the codebase.

## 5. Faster Compile Time

Compile time is a bit slow right now. Part of this is that the Mojo compiler doesn't seem to parallelize compilation in Python, and we imagine this will change. We also need to look at this on our end to see if things can be optimized.

## 6. Mojo-side I/O Bindings

Right now, the audio loop is happening on the Python side of MMMAudio, using PyAudio (Python bindings for PortAudio). We need to move this to the Mojo side, and make Mojo bindings for PortAudio, RTAudio, or libsoundio. 

## 7. Mojo -> Python Messaging

Currently we have a robust messaging system to send messages from Python to Mojo, but not the other way around. We need to implement this.