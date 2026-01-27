# Getting MMMAudio working with Windows/WSL

Install WSL - You may want to follow current LLM instructions, but this worked for me:

Inside the PowerShell:
```shell
wsl --install
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

you may need to do this separately:
Go to the Windows Store and get Ubuntu 22.04.5 LTS


in the PowerShell (not wsl) run:
```shell
wsl --version
```
which should give you an output like this:
```shell
WSL version: 2.6.3.0
Kernel version: 6.6.87.2-1
WSLg version: 1.0.71
MSRDC version: 1.2.6353
Direct3D version: 1.611.1-81528511
DXCore version: 10.0.26100.1-240331-1435.ge-release
Windows version: 10.0.26200.7623
```
and then:
```shell
wsl --list --verbose
```
which should give you something like this:
```shell
  NAME            STATE           VERSION
* Ubuntu-22.04    Running         2
```



Open Visual Studio Code and Install and Enable the WSL extension (in Extensions)

Go to Command Palette - Connect to wsl

Install the Mojo and Python extensions for WSL

open a new terminal in VSCode

this should open a wsl terminal

`cd ~/`

now we are in the user directory

clone the MMMAudio program

```shell
git clone https://github.com/spluta/MMMAudio.git
cd MMMAudio
```

check out the sounddevice branch (wsl doesn't like pyaudio):
```shell
git checkout --track origin/sounddevice
```
if you type:
```shell
git branch
```
the sounddevice branch should be selected

```shell
cd ~/
```

create the alsa config file and open it in vscode for editing:
```shell
code ~/.asoundrc
```
enter this text into the .asoundrc:
```
pcm.!default {
    type pulse
    hint.description "PulseAudio Sound Server"
}

ctl.!default {
    type pulse
}

pcm.pulse {
    type pulse
}

ctl.pulse {
    type pulse
}
```

create and edit the pulseaudio config file:
```shell
code ~/.config/pulse/daemon.conf
```
add this to the file and save it:
```
default-fragments = 5
default-fragment-size-msec = 2
nice-level = -20
high-priority = yes
```

install python3.13 (you can use 3.13 and above):
```shell
sudo apt update
sudo apt install build-essential

sudo apt install software-properties-common
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt install python3.13
sudo apt install pulseaudio-utils
```

I had to run this for pip to be installed:
```shell
sudo apt update && sudo apt install python3.13-venv
```

Now make and activate the virtual environment:
```shell
python3.13 -m venv venv

source venv/bin/activate
```
install the dependencies:
```shell
pip install numpy scipy librosa pyautogui torch mido python-osc matplotlib PySide6 hid sounddevice mojo==0.25.6.1
```

In VSCode:
View->Command Palette-> Select Python Interpreter
select the python inside your virtual environment

Open one of the examples and run it!

Some notes:
 - Mouse does not work. Use `mmm_audio.fake_mouse()` to fake the mouse with a GUI.
 - There is currently no MIDI working on windows/wsl. rt-midi doesn't build. Maybe someone can figure this out?
 - Open Sound Control works, but you have to send OSC messages to the ip address of wsl, which can be accessed this way:
```shell
hostname -I
```

### Now go back to the [Getting Started](index.md) Guide and look at 3. and 4.