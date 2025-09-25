# Getting Started with MMMAudio

Python/Mojo interop is still getting smoothed out, so check out the latest instructions here as things will likely change:

https://docs.modular.com/mojo/manual/python/

Here is what works now:

First, clone the repository

in the root of the downloaded repository, set up your virtual environment and install required libraries. this should work with python 3.12 and 3.13
```
python3.13 -m venv venv
source venv/bin/activate

pip install numpy scipy librosa pyautogui torch mido python-osc python-rtmidi
```
install modular's max/mojo library
```
pip install mojo
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
