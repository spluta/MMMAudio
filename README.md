### MMMAudio(MMMAudioMeans Mojo) Audio 

MMMAudio is a Mojo/Python environment for sound synthesis which uses Mojo for real-time audio processing and Python as a scripting control language.

MMMAudio is a highly efficient synthesis system that uses parallelized SIMD operations for maximum efficiency on CPUs. I was able to get over 6000 sine oscilators going in one instance on my M2 Mac, with no hickups or distortion. 

Writing dsp code in Mojo is straight-forward and the feedback loop of being able to quickly compile the entire project in a few seconds to test is faster than making externals in SC/max/pd. 

## Getting Started

[See the Getting Started guide](https://spluta.github.io/MMMAudio/getting_started/).

A link to the online documentation is found here: [https://spluta.github.io/MMMAudio/](https://spluta.github.io/MMMAudio/)

See "Documentation Generation" on how to build this locally.

## Program structure

MMMAudio takes advantage of Mojo/Python interoperation compiled directly within a Python project. MMMAudio uses Mojo for all audio processing and Python as the scripting language that controls the audio engine. We take advantage of being part of the Python ecosystem, using Python libraries like numpy, scipy, pyaudio, mido, hid, and pythonosc to facilitate interaction with the audio engine.

MMMAudio currently runs one audio graph at a time. The audio graph is composed of Synths and the Synths are composed of UGens.

A basic program structure may look like this:
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

At the current time, the struct that represents the Graph has to have the same name as the file that it is in, so the struct/Graph FeedbackDelays has to be in the file FeedbackDelays.mojo. This file needs to be in a Mojo package, but otherwise can be anywhere. You tell the compiler where this file is when you declare the MMMAudio python class, as such:

mmm_audio = MMMAudio(128, num_input_channels=12, num_output_channels=2, in_device=in_device, out_device=out_device, graph_name="Record", package_name="examples")

This means that we are running the "Record" graph from the Record.mojo file in the examples folder. 

There is a user_files directory/Mojo package where users can make their own graphs. You can also make your own directory for this. Just make sure the __init__.mojo file is in the directory (it can be empty), otherwise Mojo will not be able to find the files.

## Running Examples

For more information on running examples see [Examples Index](https://spluta.github.io/MMMAudio/examples/).
``.

## VS Code + pixi: run Python line-by-line with Shift+Enter

If you want to use [pixi](https://pixi.prefix.dev/latest/) as the environment manager and be able to press `Shift+Enter` in a `.py` file to execute the current line/selection in REPL mode, use these settings:

- In workspace `.vscode/settings.json`:
   - `python.defaultInterpreterPath`: `${workspaceFolder}/.pixi/envs/default/bin/python`
   - `python.terminal.activateEnvironment`: `false`
   - `python.REPL.sendToNativeREPL`: `false`
- In VS Code keybindings, map `shift+enter` to `python.execSelectionInTerminal` for Python editors.

## User Directory

An ideal place to put your own projects is a directory called user_files in the root of MMMAudio project. Git will not track this directory. 

This directory will need an empty __init__.mojo file in it, so that the mojo compiler can see it as a package.

Then loading MMMAudio in your project's python file, use the following syntax:

mmm_audio = MMMAudio(128, graph_name="MyProject", package_name="user_files")

MMMAudio will look in the 'user_file's' directory for the necessary files to execute your script.

## Roadmap

See the [Roadmap](https://spluta.github.io/MMMAudio/contributing/Roadmap) to see where MMMAudio is headed next.

## Documentation Generation

For information on the documentation generation see [Documentation Generation](https://spluta.github.io/MMMAudio/contributing/documentation/).

## Credits

Created by Sam Pluta and Ted Moore.

This repository includes a recording of "Shiverer" by Eric Wubbels as the default sample. This was performed by Eric Wubbels and Erin Lesser and recorded by Jeff Snyder.
