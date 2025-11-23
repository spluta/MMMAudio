# Examples

There are many examples in the examples folder. Each example uses 2 different files. 

The `.py` file is the interface between Python and Mojo. Open a `.py` example from the examples folder. If you're using VSCode or another editor that allows REPL mode, select a line or lines of code, press shift-enter to run that code. 

> Unless otherwise specified, the examples are intended to be run in REPL mode by executing one line at a time. A few of the examples are intended to be run by pressing the green "play" button in VS Code (or a similar button in your editor of choice) to execute the whole file at once. If this is the case the example file will explicitly state to do it this way instead of REPL mode. (Before you execute your first line of python code, which opens a REPL in the terminal, make sure all terminals in VSCode are closed. If one is open, VSCode may try to run the code in the current terminal, which can fail. If all terminals are closed, it will always make a fresh REPL in a fresh Terminal.)

Each `.py` file has a corresponding `.mojo` file with a similar name (Python files are snake case, Mojo files are Camel case). The Mojo file outlines the audio graph structure and the connections between different synths.

All of the UGens are defined in mmm_dsp.

Mojo is a compiled language. any change to the audio graph means the entire graph needs to be recompiled. this takes about 4 seconds on my computer and will happen the first time you run an MMMAudio constructor, like:

```python
mmm_audio = MMMAudio(128, graph_name="FeedbackDelays", package_name="examples")
```

It will also run when you change the audio graph, so if you change "FeedbackDelays" to something else, it will recompile.

> Note that in the example Mojo file the name of the file and the name of the main struct needs to be the same! For example, when trying to run the "FeedbackDelays" example (as above), that Python script looks for a struct named "FeedbackDelays" in the file `FeedbackDelays.mojo`. If you edit the examples or make your own script, be sure to keep this coordination aligned. (In the future this requirement may change for the better.)

## Stopping a Program

To stop a running MMMAudio program, close the python instance in the terminal. This will stop the audio thread and release any resources used by the program.