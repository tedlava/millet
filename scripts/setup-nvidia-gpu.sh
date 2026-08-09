#!/usr/bin/env bash
# Run after `pipx install millet-pipeline[gui,parakeet]` on an NVIDIA host
# to add CUDA-accelerated Parakeet support. onnxruntime-gpu is deliberately
# NOT a declared dependency (see pyproject.toml comment) since its correct
# version is tied to your CUDA toolkit — 1.27+ requires CUDA 13, this repo's
# torch pin (cu128) needs onnxruntime-gpu<1.27.

set -euo pipefail
pipx runpip millet-pipeline uninstall onnxruntime -y
pipx runpip millet-pipeline install "onnxruntime-gpu<1.27"
echo "Done. Verify with: millet check"
