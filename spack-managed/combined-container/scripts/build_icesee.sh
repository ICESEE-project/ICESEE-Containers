#!/usr/bin/env bash
set -euo pipefail

log(){ echo "[build_icesee] $*"; }
die(){ echo "[build_icesee][ERROR] $*" >&2; exit 1; }

SPACK_SETUP="/opt/spack-src/share/spack/setup-env.sh"
SPACK_ENV="/opt/spack-environment"
ICESEE_REPO_URL="${ICESEE_REPO_URL:-https://github.com/ICESEE-project/ICESEE.git}"
ICESEE_BRANCH="${ICESEE_BRANCH:-main}"
ICESEE_SRC_DIR="/opt/ICESEE"
VENV_DIR="/opt/venv-icesee"
REQ_DIR="/opt/requirements"
GEN_REQ_SCRIPT="/opt/build-scripts/gen_pip_reqs.py"

[[ -f "${SPACK_SETUP}" ]] || die "Missing Spack setup script at ${SPACK_SETUP}"
source "${SPACK_SETUP}"
spack env activate "${SPACK_ENV}"

log "Resolving Spack-installed toolchain..."
MPI_DIR="$(spack location -i openmpi@5.0.10)" || die "openmpi@5.0.10 not found in Spack environment"
HDF5_DIR="$(spack location -i hdf5@1.14.5)" || die "hdf5@1.14.5 not found in Spack environment"
PYTHON_PREFIX="$(spack location -i python@3.12)" || die "python@3.12 not found in Spack environment"
PYTHON_BIN="${PYTHON_PREFIX}/bin/python3"

[[ -x "${PYTHON_BIN}" ]] || die "Python executable not found at ${PYTHON_BIN}"

export MPI_DIR
export HDF5_DIR
export PATH="${VENV_DIR}/bin:${MPI_DIR}/bin:${PATH}"
export LD_LIBRARY_PATH="${MPI_DIR}/lib:${HDF5_DIR}/lib:${LD_LIBRARY_PATH:-}"
export CC="${MPI_DIR}/bin/mpicc"
export CXX="${MPI_DIR}/bin/mpicxx"
export FC="${MPI_DIR}/bin/mpifort"
export MPICC="${MPI_DIR}/bin/mpicc"
export MPICXX="${MPI_DIR}/bin/mpicxx"
export MPIFC="${MPI_DIR}/bin/mpifort"
export HDF5_MPI=ON

# ICESEE imports as 'ICESEE', so /opt must be on PYTHONPATH
export PYTHONPATH="/opt:${PYTHONPATH:-}"

mkdir -p "${REQ_DIR}"

if [[ ! -d "${VENV_DIR}" ]]; then
  log "Creating virtual environment at ${VENV_DIR}..."
  "${PYTHON_BIN}" -m venv --system-site-packages "${VENV_DIR}"
fi

# shellcheck disable=SC1091
source "${VENV_DIR}/bin/activate"

log "Upgrading pip/setuptools/wheel..."
python -m pip install --no-cache-dir --upgrade pip setuptools wheel

if [[ ! -d "${ICESEE_SRC_DIR}/.git" ]]; then
  log "Cloning ICESEE (${ICESEE_BRANCH})..."
  git clone --branch "${ICESEE_BRANCH}" --depth=1 "${ICESEE_REPO_URL}" "${ICESEE_SRC_DIR}"
else
  log "Refreshing ICESEE source..."
  git -C "${ICESEE_SRC_DIR}" remote set-url origin "${ICESEE_REPO_URL}"
  git -C "${ICESEE_SRC_DIR}" fetch --depth=1 origin "${ICESEE_BRANCH}"
  git -C "${ICESEE_SRC_DIR}" checkout "${ICESEE_BRANCH}"
  git -C "${ICESEE_SRC_DIR}" reset --hard "origin/${ICESEE_BRANCH}"
fi

[[ -f "${ICESEE_SRC_DIR}/pyproject.toml" ]] || die "Missing ${ICESEE_SRC_DIR}/pyproject.toml"
[[ -f "${GEN_REQ_SCRIPT}" ]] || die "Missing ${GEN_REQ_SCRIPT}"

log "Generating pip requirements from pyproject.toml..."
python "${GEN_REQ_SCRIPT}" \
  --pyproject "${ICESEE_SRC_DIR}/pyproject.toml" \
  --out "${REQ_DIR}/pip.auto.txt" \
  --extras mpi,viz

log "Installing ICESEE Python dependencies..."
python -m pip install --no-cache-dir -r "${REQ_DIR}/pip.auto.txt"

log "Installing ICESEE in editable mode..."
python -m pip install --no-cache-dir -e "${ICESEE_SRC_DIR}"

log "Sanity checks..."
python -c "import sys; print(sys.executable)"
python -c "import ICESEE; print('ICESEE import OK:', ICESEE.__file__)"

log "Done."