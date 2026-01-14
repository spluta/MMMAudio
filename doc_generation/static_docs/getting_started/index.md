# Getting Started with MMMAudio

MMMAudio uses [Mojo's Python interop](https://docs.modular.com/mojo/manual/python/) to compile audio graphs directly in your Python programming environment.

Currently Mojo's compiler is MacOS(Apple Silicon) & Linux(x86) only. Windows users can use WSL2 as described below. 

## 1. Clone the Repository

```
git clone https://github.com/spluta/MMMAudio.git
```

or [grab the latest release](https://github.com/spluta/MMMAudio/releases).

## 2. Setup the Environment

`cd` into the root of the downloaded repository, set up your virtual environment, and install required libraries. this should work with python 3.12 and 3.13.  If you find it does or doesn't work with other versions [let us know](https://github.com/spluta/MMMAudio/issues).

depending on your system set up, you may need to explicitly specify the Python version here, eg: 'python3.13 -m venv venv'

```shell
python -m venv venv 
source venv/bin/activate

pip install numpy scipy librosa pyautogui torch mido python-osc python-rtmidi matplotlib PySide6
```

install modular's max/mojo library
the main branch is tied to Mojo 0.25.6.1 - we will move to 0.26 soon.

```shell
pip install mojo==0.25.6.1
```

### 2a. Setup the Environment on MacOS

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

### 2b. Setup the Environment on Windows/WSL2 with Ubuntu

Here are some hints to get the audio samples running under Windows/WSL2. 
I used the Unbuntu distro, but if you adapt the package manager, it will also work on other distributions.

Use your package manager to install `portaudio` and `hidapi` as system-wide c libraries. On MacOS this is:

```shell
sudo apt update
sudo apt install libportaudio2 portaudio19-dev
sudo apt install libhidapi-hidraw0 libhidapi-dev
sudo apt install pulseaudio
```

Use your package manager to install `ALSA runtime` and `ASLA utilities` as system-wide c libraries. On Ubuntu this is:

```shell
sudo apt install alsa-utils
sudo apt install libasound2-dev
```

Verify the installation. You should see a version number

```shell
aplay --version
pkg-config --modversion alsa
```

To make the Windows audio devices "visible" inside WSL2, please install and configure PulseAudio bridge as follows:

Use youe packagemanger to install `PulseAudio`. On Ubuntu this is:
```shell
sudo apt install pulseaudio alsa-utils
```

Create a sound config rc file in your user home directory with the follwing content:
~/.asoundrc
```shell
pcm.!default {
    type pulse
}
ctl.!default {
    type pulse
}
```

Start pulseaudio and verify that the WSLg PulseAudio server is reachable:
```shell
pulseaudio --start
ls -l /mnt/wslg/PulseServer
```

Check also that PortAudio detects PulseAudio
```shell
pactl info
```

Now run your MMMAudio script WITHOUT running pulseaudio --start and enjoy the sound:
```shell
python3 examples/DefaultGraph.py
```

## 3. Run an Example

The best way to run MMMAudio is in REPL mode in your editor. 

to set up the python REPL correctly in VSCode: with the entire directory loaded into a workspace, go to View->Command Palette->Select Python Interpreter. Make sure to select the version of python that is in your venv directory, not the system-wide version. Then it should just work. 

Before you run the code in a new REPL, make sure to close all terminal instances in the current workspace. This will ensure that a fresh REPL environment is created.

Some examples are designed to run a complete script. These are all marked. In these cases, the script can be run by pressing the "play" button on the top right of VSCode or just running the script `python example.py` from inside your virtual environment.

Go to the [Examples](../examples/index.md) page to run an example!

## 4. Make Your Own Sounds

Similar to how running an example considers the `examples` directory a "module" you can create your own "module" to run your code from. The `.gitignore` file already ignores a directory called "mine", so if you make a directory called `mine` next to the `examples` directory you can put all the `.mojo` and corresponding `.py` files in there you want. Be sure to put an empty `__init__.py` and `__init__.mojo` file in your "mine" directory for it to operate as a "module".

To make a new MMMAudio project, a good approach is to copy and paste a `.mojo` and `.py` file pair from the examples directory to get you started. Them modify them!

!!! Note

    Remember that you'll need to change this line of code in the `.py` file to point to your `.mojo` file and the directory it is in. Also, your main `struct` that should run as the audio graph **needs to have the same name as the `.mojo` file**. Notice this pattern in the examples.

```python
mmm_audio = MMMAudio(128, graph_name="MyMojoFile", package_name="mine")
```