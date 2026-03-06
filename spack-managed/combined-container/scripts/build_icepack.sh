#!/usr/bin/env bash
set -euo pipefail

source /opt/venv-firedrake/bin/activate

python -m pip install --upgrade pip
python -m pip install patchelf

if [[ ! -d /opt/icepack/.git ]]; then
  git clone --depth=1 https://github.com/icepack/icepack.git /opt/icepack
fi

python -m pip install --editable /opt/icepack
python -m pip install gmsh ipykernel