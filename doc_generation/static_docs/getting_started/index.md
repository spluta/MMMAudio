# Getting Started with MMMAudio

MMMAudio uses [Mojo's Python interop](https://docs.modular.com/mojo/manual/python/) to compile audio graphs directly in your Python programming environment.

Currently Mojo's compiler is MacOS(Apple Silicon) & Linux(x86) only. Windows users can use WSL2 as described below. 

Please see the [MMMAudio YouTube Playlist](https://www.youtube.com/playlist?list=PLeOjmNO6F-TQ6p9pEYT3zt1dEfFaUWezr) to view the available video tutorials about MMMAudio!

## 1. Clone the Repository

```
git clone https://github.com/spluta/MMMAudio.git
```

or [grab the latest release](https://github.com/spluta/MMMAudio/releases).

## 2. Setup the Python Virtual Environment (On Windows, follow the instructions under 2b. first, then come back here to get Python correctly configured)

`cd` into the root of the downloaded repository, set up your virtual environment, and install required libraries. this should work with python 3.12 and 3.13.  If you find it does or doesn't work with other versions [let us know](https://github.com/spluta/MMMAudio/issues).

depending on your system set up, you may need to explicitly specify the Python version here, eg: 'python3.13 -m venv venv'

```shell
python -m venv venv 
source venv/bin/activate

pip install numpy scipy librosa pyautogui torch mido python-osc python-rtmidi matplotlib PySide6
```

install modular's max/mojo library
the main branch is tied to Mojo 0.25.7.

```shell
pip install mojo==0.25.7
```

### 2a. Further Setup of the Environment on MacOS (Apple Silicon Only - Mojo Does not and will not work on Intel Macs)

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

First, you need to install WSL2. Follow online guides to get this installed. This involves and install and a restart of your computer.

Use your package manager to install `portaudio` and `hidapi` as system-wide c libraries. On Ubuntu this is:

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

When running an example, the Mojo compiler considers the `examples` directory a "module". This is important because when you make your own directory of files and projects, that directory also needs to be a module. 

For your directory to be considered a "module" by the mojo compiler, in addition to your `.mojo` and `.py` files, there also needs to be an empty `__init__.mojo` file in that directory. (See how the examples folder has this file and it is empty. It is there because it needs to be!)

The `.gitignore` file already ignores two directories, one called "mine" and one called "user_files", so if you make a directory called `mine` or `user_files` next to the `examples` directory, you can put all the `.mojo` and corresponding `.py` files in there you want (plus the `__init__.mojo` file) and git will never accidentally overwrite these directories.

To make a new MMMAudio project, a good approach is to copy and paste a `.mojo` and `.py` file pair from the examples directory to get you started. Then modify them!

!!! Note

    When running a MMMAudio program in your `.py` file, the `MMMAudio(128, etc)` 
    line has important information that must be correct for compilation 
    (notice this pattern in the examples):
    
    1) The `graph_name` corresponds to:  
       - The name of the `.mojo` file to search for the audio graph  
       - AND the name of the struct within that file serving as the main audio graph  
       
       In the example below, the file "MyMojoFile.mojo" contains struct `MyMojoFile`. 
       This struct must have a `.next` function with no input arguments that outputs 
       a `SIMD[DType.float64, N]` vector of any size (typically N=2) or just a Float64.

    2) The `package_name` corresponds to the folder containing your files:  
       - Files in `MMMAudio/mine` use `package_name="mine"`  
       - Files in `MMMAudio/user_files` use `package_name="user_files"`  
       - Your folder must be inside the MMMAudio directory and must contain the `__init__.mojo` file as explained above  


```python
mmm_audio = MMMAudio(128, graph_name="MyMojoFile", package_name="mine")
```

This is how all the examples look, so just look at those for "inspiration."