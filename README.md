### MMM (MMM Means Mojo) Audio 

MMMAudio is a python environment for sound synthesis which uses Mojo for real-time audio processing.

This is relatively efficient. I was able to get over 1000 sin oscilators going in one instance, with no hickups or distortion. For comparison, SuperCollider can get 5000. Part of this might be my implementation, where I am processing each Synth one sample at a time, rather than in blocks like SC does.

What was encouraging is that writing dsp code in Mojo is incredibly straight-forward and the feedback loop of being able to quickly compile the entire project in a few seconds to test is lightyears better than making externals is SC/max/pd. I think this has a lot of potential.

## Setup:

Python/Mojo interop is still getting smoothed out, so check out the latest instructions here as things will likely change:

https://docs.modular.com/mojo/manual/python/

Here is what works now:

first, clone the repository

in the root of the downloaded repository, set up your virtual environment and install required libraries. this should work with python 3.12 and 3.13
```
python3.13 -m venv venv
source venv/bin/activate

pip install numpy scipy librosa pyautogui torch mido python-osc python-rtmidi
```
install modular's max/mojo library. this is the nightly install, though you may want to go with the stable
```
pip install --pre modular \
  --index-url https://dl.modular.com/public/nightly/python/simple/
```

MMM uses pyAudio (portaudio) for audio input/output and hid for hid control.

use your package manager to install portaudio and hidapi as systemwide c libraries. on mac this is:
```
brew install portaudio
brew install hidapi
```

then install pyaduio and hid in your virtual environment
with your venv activated:
```
pip install hid pyaudio
```

if you have trouble installing/running pyaudio, this may help:
```
https://stackoverflow.com/questions/68251169/unable-to-install-pyaudio-on-m1-mac-portaudio-already-installed/68296168#68296168
```

then this uninstall and reinstall pyaudio (hidapi may be the same)

## REPL mode

the best way to run MMM is in repl mode in your editor. i run this in visual studio code. 

to set up the python repl correctly in VSCode: with the entire directory loaded into a workspace, go to View->Command Palette->Select Python Interpreter. Make sure to select the version of python that is in your venv directory, not the system-wide version. Then it should just work. 

Before you run the code in a new REPL, make sure to close all terminal instances in the current workspace. This will ensure that a fresh REPL environment is created.

## Program structure

MMMAudio is the interface from Python to the Mojo audio graph. The User should only have to interact with this module and should never have to edit this file. import this module, like in the examples, and then interact with it.

MMM currently runs one audio graph at a time. The audio graph is composed of Synths and the Synths are composed of UGens.

All Graphs must conform to the Graphable Trait, which means they have next function that takes no arguments. For example, the FeedbackDelays example has the following struct definition:
```
struct FeedbackDelays(Representable, Movable, Graphable, Copyable):
```
and contains the following function:
```
fn next(mut self: FeedbackDelays) -> List[Float64]:
```
These define it as a Graphable struct, thus something that can act as a Graph.
```
Graph
|
-- Synth
   |
   -- UGen
   -- UGen
   -- UGen
   Synth
   |
   -- UGen
   -- UGen
```

Currently there can only be one Graph, but that will change in future versions.

## Running Examples

There are many examples in the examples folder. Each example uses 3 different files. 

The .py file is the interface between python and mojo. Open a .py example from the examples folder. select a line or lines of code, press shift-enter to run that code.

Each .py file has a corresponding .mojo file. This outlines the audio graph structure and the connections between different synths.

The examples all use just one Synth, but there can be any number of synths in a graph. The 'examples.synths' folder contains the definitions for each synth used in the examples.

All of the UGens are defined in mmm_dsp.

Mojo is a compiled language. any change to the audio graph means the entire graph needs to be recompiled. this takes about 4 seconds on my computer and will happen the first time you run an MMMAudio constructor, like:
```
mmm_audio = MMMAudio(128, graph_name="FeedbackDelays", package_name="examples")
```
It will also run when you change the audio graph, so if you change "FeedbackDelays" to something else, it will recompile.

## Stopping a Program

Just close the python instance in the terminal

This will stop the audio thread and release any resources used by the program.

## Credits

Created by Sam Pluta.

This repository includes a recording of "Shiverer" by Eric Wubbels as the default sample. This was performed by Eric Wubbels and Erin Lesser and recorded by Jeff Snyder.