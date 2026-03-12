#!/usr/bin/env bash
set -euo pipefail

log(){ echo "[build_icepack] $*"; }
die(){ echo "[build_icepack][ERROR] $*" >&2; exit 1; }

ICEPACK_REPO="${ICEPACK_REPO:-https://github.com/icepack/icepack.git}"
ICEPACK_BRANCH="${ICEPACK_BRANCH:-master}"
ICEPACK_PREFIX="${ICEPACK_PREFIX:-/opt/icepack}"
ICEPACK_VENV="${ICEPACK_VENV:-/opt/venv-icepack}"

[[ -x /opt/venv-firedrake/bin/python ]] || die "Missing /opt/venv-firedrake"

if [[ -f /opt/runtime-env/firedrake-env.sh ]]; then
  # shellcheck disable=SC1091
  source /opt/runtime-env/firedrake-env.sh
  unset PETSC_ARCH || true
fi

clone_default_branch() {
  log "Requested branch '${ICEPACK_BRANCH}' not found; cloning repository default branch instead"
  rm -rf "${ICEPACK_PREFIX}"
  git clone --depth=1 "${ICEPACK_REPO}" "${ICEPACK_PREFIX}"
}

if [[ ! -d "${ICEPACK_PREFIX}/.git" ]]; then
  log "Cloning Icepack from ${ICEPACK_REPO} (branch=${ICEPACK_BRANCH})"
  if git ls-remote --exit-code --heads "${ICEPACK_REPO}" "${ICEPACK_BRANCH}" >/dev/null 2>&1; then
    git clone --branch "${ICEPACK_BRANCH}" --depth=1 "${ICEPACK_REPO}" "${ICEPACK_PREFIX}"
  else
    clone_default_branch
  fi
else
  log "Refreshing existing Icepack checkout"
  if git ls-remote --exit-code --heads "${ICEPACK_REPO}" "${ICEPACK_BRANCH}" >/dev/null 2>&1; then
    git -C "${ICEPACK_PREFIX}" fetch --depth=1 origin "${ICEPACK_BRANCH}"
    git -C "${ICEPACK_PREFIX}" checkout "${ICEPACK_BRANCH}"
    git -C "${ICEPACK_PREFIX}" reset --hard "origin/${ICEPACK_BRANCH}"
  else
    log "Branch '${ICEPACK_BRANCH}' not found upstream; keeping existing checkout on repo default branch"
  fi
fi

if [[ ! -d "${ICEPACK_VENV}" ]]; then
  log "Creating Icepack overlay venv from Firedrake Python..."
  /opt/venv-firedrake/bin/python -m venv --system-site-packages "${ICEPACK_VENV}"
fi

# shellcheck disable=SC1091
source "${ICEPACK_VENV}/bin/activate"

FIREDRAKE_SITE_PKGS="/opt/venv-firedrake/lib/python3.12/site-packages"
ICEPACK_SITE_PKGS="$(python -c 'import site; print(site.getsitepackages()[0])')"

[[ -d "${FIREDRAKE_SITE_PKGS}" ]] || die "Missing Firedrake site-packages at ${FIREDRAKE_SITE_PKGS}"

log "Linking Firedrake site-packages into Icepack overlay venv..."
echo "${FIREDRAKE_SITE_PKGS}" > "${ICEPACK_SITE_PKGS}/firedrake-overlay.pth"
export PYTHONPATH="${FIREDRAKE_SITE_PKGS}:${PYTHONPATH:-}"

python -m pip install --upgrade pip setuptools wheel
python -m pip install "numpy<2" patchelf

log "Installing Icepack deps without disturbing Firedrake core ABI..."
python -m pip install \
  "numpy<2" \
  affine \
  aiohttp \
  aiobotocore \
  bounded-pool-executor \
  cftime \
  geopandas \
  geojson \
  gmsh \
  importlib-resources \
  jmespath \
  matplotlib \
  MeshPy \
  multimethod \
  netCDF4 \
  pandas \
  pillow \
  pooch \
  pqdm \
  pyogrio \
  pyparsing \
  pyproj \
  pyroltrilinos \
  python-cmr \
  rasterio \
  s3fs \
  shapely \
  tenacity \
  tinynetrc \
  tqdm \
  wrapt \
  xarray \
  earthaccess

python -m pip install --no-deps --editable "${ICEPACK_PREFIX}"

log "Sanity checks..."
python -c "import numpy; print('numpy:', numpy.__version__)"
python -c "import firedrake; print('firedrake import OK')"
python -c "import icepack; print('icepack import OK')"

log "Done."