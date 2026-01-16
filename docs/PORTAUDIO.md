## macOS (Apple Silicon) — PyAudio / PortAudio troubleshooting

Symptom:

ImportError: dlopen(.../_portaudio...so): symbol not found in flat namespace '_PaMacCore_SetupChannelMap'

Cause:

A PyAudio C extension that wasn't built or linked against the Homebrew `portaudio` library can leave macOS-specific symbols (such as `_PaMacCore_SetupChannelMap`) undefined. This happens when a prebuilt wheel or a local build picks up a different libportaudio (or no libportaudio) at build time.

Fix (run in a macOS arm64 shell with your virtualenv activated):

```bash
# 1) ensure Homebrew portaudio is installed
brew update
brew reinstall portaudio
# optionally: brew reinstall --build-from-source portaudio

# 2) rebuild PyAudio in the venv so it links to Homebrew portaudio
export PA_PREFIX="$(brew --prefix portaudio)"
export PKG_CONFIG_PATH="$PA_PREFIX/lib/pkgconfig:$PKG_CONFIG_PATH"
export CFLAGS="-I$PA_PREFIX/include $CFLAGS"
export CPPFLAGS="-I$PA_PREFIX/include $CPPFLAGS"
export LDFLAGS="-L$PA_PREFIX/lib $LDFLAGS"
export ARCHFLAGS="-arch arm64"

python -m pip uninstall -y PyAudio pyaudio
python -m pip install --no-binary :all: PyAudio
```

Sanity checks:

- If `otool -L` on the `_portaudio*.so` does not reference `/opt/homebrew/.../libportaudio`, the extension was not linked correctly.
- If multiple `libportaudio` copies exist (Homebrew `/opt/homebrew`, `/usr/local`, or MacPorts `/opt/local`), prefer Homebrew on Apple Silicon to avoid mixed-arch or SDK mismatches.

Add the `scripts/install_portaudio.sh` script to automate these steps.
