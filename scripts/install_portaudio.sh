#!/usr/bin/env bash
set -euo pipefail

echo "Install/repair PortAudio and rebuild PyAudio in the active venv (Apple Silicon)"

echo "1) Update Homebrew and reinstall portaudio"
brew update
brew reinstall portaudio
# Optionally build from source if you suspect bottle issues:
# brew reinstall --build-from-source portaudio

echo "\n2) Set environment so pip builds PyAudio linked to Homebrew portaudio"
PA_PREFIX="$(brew --prefix portaudio)"
export PKG_CONFIG_PATH="$PA_PREFIX/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
export CFLAGS="-I$PA_PREFIX/include ${CFLAGS:-}"
export CPPFLAGS="-I$PA_PREFIX/include ${CPPFLAGS:-}"
export LDFLAGS="-L$PA_PREFIX/lib ${LDFLAGS:-}"
export ARCHFLAGS="-arch arm64"

echo "PA_PREFIX=$PA_PREFIX"
pkg-config --cflags --libs portaudio-2.0 || true

echo "\n3) Rebuild PyAudio inside the activated virtualenv"
python -m pip uninstall -y PyAudio pyaudio || true
python -m pip install --no-binary :all: PyAudio

echo "\nDone. Verify by running: python -c \"import pyaudio; p=pyaudio.PyAudio(); print(p.get_host_api_count()); p.terminate()\""
