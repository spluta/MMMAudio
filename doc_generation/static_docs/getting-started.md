# Getting Started with MMMAudio

[Mojo's Python interop](https://docs.modular.com/mojo/manual/python/) is still getting smoothed out so things will likely change.

Here is what works now. The instructions are aimed at and have been tested on MacOS (currently Mojo's compiler is MacOS & Linux only).

## 1. Clone the Repository

```
git clone https://github.com/spluta/MMMAudio.git
```

## 2. Setup the Environment

`cd` into the root of the downloaded repository, set up your virtual environment, and install required libraries. this should work with python 3.12 and 3.13.  If you find it does or doesn't work with other versions [let us know](https://github.com/spluta/MMMAudio/issues).

depending on your system set up, you may need to explicitly specify the Python version here, eg: 'python3.13 -m venv venv'

```shell
python -m venv venv 
source venv/bin/activate

pip install numpy scipy librosa pyautogui torch mido python-osc python-rtmidi matplotlib PySide6
```

install modular's max/mojo library

```shell
pip install mojo
```

Use your package manager to install `portaudio` and `hidapi` as system-wide c libraries. On MacOS this is:

```shell
brew install portaudio
brew install hidapi
```

MMMAudio uses `pyAudio` (`portaudio`) for audio input/output and `hid` for HID control.

Then install `pyaduio` and `hid` in your virtual environment with your `venv` activated:

```shell
pip install hid pyaudio
```

if you have trouble installing/running `pyaudio`, try this:
1. [do this](https://stackoverflow.com/questions/68251169/unable-to-install-pyaudio-on-m1-mac-portaudio-already-installed/68296168#68296168)
2. Then this uninstall and reinstall `pyaudio` (`hidapi` may be the same).

## 3. Run an Example

The best way to run MMMAudio is in REPL mode in your editor. 

to set up the python REPL correctly in VSCode: with the entire directory loaded into a workspace, go to View->Command Palette->Select Python Interpreter. Make sure to select the version of python that is in your venv directory, not the system-wide version. Then it should just work. 

Before you run the code in a new REPL, make sure to close all terminal instances in the current workspace. This will ensure that a fresh REPL environment is created.

Go to the [Examples](examples/index.md) page to run an example!

## 4. Windows!!!

MMMAudio can run in Windows inside of WSL. The user first needs to install WSL if it has not be installed already.

### Solution — PulseAudio bridge (recommended)

This makes real Windows audio devices visible inside WSL2.
PyAudio & PortAudio will then work normally.

Install PulseAudio on Ubuntu
sudo apt install pulseaudio alsa-utils

Create ~/.asoundrc:

pcm.!default {
    type pulse
}
ctl.!default {
    type pulse
}
Start pulseaudio:
pulseaudio --start

I got a small error trying to startup pulseaudio manually: (it is unecessary)

to verify that the device can be found

Verify the WSLg PulseAudio server is reachable
ls -l /mnt/wslg/PulseServer

Check that PortAudio detects PulseAudio
pactl info

Now run your MMMAudio script WITHOUT running pulseaudio --start:
python3 examples/DefaultGraph.py

enjoy the sound :-) 

