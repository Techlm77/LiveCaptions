#!/bin/sh
# Builds Live Captions into builddir/ and downloads the speech model.
# Install the system dependencies listed in README.md first.
set -eu
cd "$(dirname "$0")"

model=april-english-dev-01110_en.april
ort_sdk=subprojects/april-asr/lib

if [ ! -f subprojects/april-asr/CMakeLists.txt ]; then
    echo "Fetching the april-asr submodule..."
    git submodule update --init --recursive
fi

# Use a distro ONNX Runtime if there is one, else download the official SDK.
# April links whichever it finds and records the path of a downloaded SDK in
# the program, so no LD_LIBRARY_PATH is needed either way.
if [ -n "${ONNX_ROOT:-}" ]; then
    echo "Using ONNX Runtime from ONNX_ROOT=$ONNX_ROOT"
elif [ -e "$ort_sdk" ]; then
    echo "Using the downloaded ONNX Runtime in $ort_sdk"
elif pkg-config --exists libonnxruntime 2>/dev/null; then
    echo "Using the system ONNX Runtime $(pkg-config --modversion libonnxruntime)"
else
    echo "No system ONNX Runtime found, downloading it..."
    ./subprojects/april-asr/download_onnx_linux_x64.sh
fi

# Configure from scratch so a changed ONNX Runtime choice is never mixed
# with a cached one.
if [ -d builddir ]; then
    meson setup --wipe builddir --buildtype release
else
    meson setup builddir --buildtype release
fi
ninja -C builddir

if [ ! -f "$model" ]; then
    echo "Downloading the speech model (about 320 MB)..."
    curl -fL --retry 3 -o "$model.part" "https://april.sapples.net/$model"
    mv "$model.part" "$model"
fi

echo
echo "Done. Start Live Captions with ./run.sh"
