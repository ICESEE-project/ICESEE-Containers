#!/usr/bin/env bash
set -euo pipefail

source /opt/venv-firedrake/bin/activate

mkdir -p /opt/requirements

if [[ ! -d /opt/ICESEE/.git ]]; then
  git clone --depth=1 https://github.com/ICESEE-project/ICESEE.git /opt/ICESEE
fi

python /opt/build-scripts/gen_pip_reqs.py \
  --pyproject /opt/ICESEE/pyproject.toml \
  --out /opt/requirements/pip.auto.txt \
  --extras mpi,viz

python -m pip install --no-cache-dir -r /opt/requirements/pip.auto.txt
python -m pip install --no-cache-dir -e /opt/ICESEE