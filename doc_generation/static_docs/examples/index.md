# Examples

There are many examples in the examples folder. Each example uses 2 different files. 

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