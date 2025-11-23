### MMMAudio(MMMAudioMeans Mojo) Audio 

MMMAudio is a python environment for sound synthesis which uses Mojo for real-time audio processing.

This is relatively efficient. I was able to get over 1000 sin oscilators going in one instance, with no hickups or distortion. For comparison, SuperCollider can get 5000. Part of this might be my implementation, where I am processing each Synth one sample at a time, rather than in blocks like SC does.

What was encouraging is that writing dsp code in Mojo is incredibly straight-forward and the feedback loop of being able to quickly compile the entire project in a few seconds to test is lightyears better than making externals is SC/max/pd. I think this has a lot of potential.

## Getting Started

[See the Getting Started guide](doc_generation/static_docs/getting-started.md).

A link to the online documentation is found here: [https://spluta.github.io/MMMAudio/](https://spluta.github.io/MMMAudio/)

See "Documentation Generation" on how to build this locally.

## Program structure

MMMAudio is a python Class that is the interface from Python to the Mojo audio graph. The User should only have to interact with this module and should never have to edit this file. To get started, from mmm_src.MMMAudio import MMMAudio, like in the examples, and then interact with it.

MMMAudio currently runs one audio graph at a time. The audio graph is composed of Synths and the Synths are composed of UGens.

The only distinction between a Graph and a Synth is that a Graph contains a next function with no arguments other than self:
```
fn next(mut self: FeedbackDelays) -> List[Float64]:
```
This defines it as a struct that can act as a Graph. Currently there can only be one Graph, but that will change in future versions.
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

At the current time, the struct that represents the Graph has to have the same name as the file that it is in, so the struct/Graph FeedbackDelays has to be in the file FeedbackDelays.mojo. This file only needs to be in Mojo package, but otherwise can be anywhere. You tell the compiler where this file is when you declare the MMMAudio python class, as such:

mmm_audio = MMMAudio(128, num_input_channels=12, num_output_channels=2, in_device=in_device, out_device=out_device, graph_name="Record", package_name="examples")

This means that we are running the "Record" graph from the Record.mojo file in the examples folder. 

There is a user_files directory/Mojo package where users can make their own graphs. You can also make your own directory for this. Just make sure the __init__.mojo file is in the directory (it can be empty), otherwise Mojo will not be able to find the files.

## Running Examples

For more information on running examples see [Examples Index](doc_generation/static_docs/examples/index.md).
``.

## Documentation Generation

For information on the documentation generation see [Documentation Generation](doc_generation/static_docs/contributing/documentation.md).

## Credits

Created by Sam Pluta and Ted Moore.

This repository includes a recording of "Shiverer" by Eric Wubbels as the default sample. This was performed by Eric Wubbels and Erin Lesser and recorded by Jeff Snyder.