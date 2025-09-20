### MMM (MMM Means Mojo) Audio 

MMMAudio is a python environment for sound synthesis which uses Mojo for real-time audio processing.

This is relatively efficient. I was able to get over 1000 sin oscilators going in one instance, with no hickups or distortion. For comparison, SuperCollider can get 5000. Part of this might be my implementation, where I am processing each Synth one sample at a time, rather than in blocks like SC does.

What was encouraging is that writing dsp code in Mojo is incredibly straight-forward and the feedback loop of being able to quickly compile the entire project in a few seconds to test is lightyears better than making externals is SC/max/pd. I think this has a lot of potential.

## Getting Started

See `doc_generation/static_docs/getting-started.md`.

## Program structure

MMMAudio is the interface from Python to the Mojo audio graph. The User should only have to interact with this module and should never have to edit this file. import this module, like in the examples, and then interact with it.

MMM currently runs one audio graph at a time. The audio graph is composed of Synths and the Synths are composed of UGens.

The only distinction between a Graph and a Synth is that a Graph contains a next function with no arguments other than self:
```
fn next(mut self: FeedbackDelays) -> List[Float64]:
```
This defines it as a Graphable struct, thus something that can act as a Graph.
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

For more information on running examples see `doc_generation/static_docs/examples/index.md`.

## Documentation Generation

For information on the documentation generation see `doc_generation/static_docs/contributing/documentation.md`.

## Credits

Created by Sam Pluta.

This repository includes a recording of "Shiverer" by Eric Wubbels as the default sample. This was performed by Eric Wubbels and Erin Lesser and recorded by Jeff Snyder.