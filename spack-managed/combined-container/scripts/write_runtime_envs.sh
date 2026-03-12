#!/usr/bin/env bash
set -euo pipefail

log(){ echo "[write_runtime_envs] $*"; }
die(){ echo "[write_runtime_envs][ERROR] $*" >&2; exit 1; }

SPACK_SETUP="/opt/spack-src/share/spack/setup-env.sh"
SPACK_ENV="/opt/spack-environment"
RUNTIME_ENV_DIR="/opt/runtime-env"
BIN_DIR="/usr/local/bin"

[[ -f "${SPACK_SETUP}" ]] || die "Missing Spack setup script: ${SPACK_SETUP}"
source "${SPACK_SETUP}"
spack env activate "${SPACK_ENV}"

log "Resolving runtime dependency locations from Spack..."

FIREDRAKE_PETSC_DIR="$(spack location -i 'petsc@3.24.0')" || die "petsc@3.24.0 not found"
OPENMPI_DIR="$(spack location -i 'openmpi@5.0.10')" || die "openmpi@5.0.10 not found"
MPICH_DIR="$(spack location -i 'mpich@4.2.3')" || die "mpich@4.2.3 not found"
HDF5_DIR="$(spack location -i 'hdf5@1.14.5')" || die "hdf5@1.14.5 not found"
PYTHON_DIR="$(spack location -i 'python@3.12')" || die "python@3.12 not found"

ISSM_PETSC_DIR="${ISSM_PETSC_DIR:-/opt/ISSM/externalpackages/petsc/src}"
MATLABROOT="${MATLABROOT:-/opt/matlab/R2024b}"
ISSM_DIR="${ISSM_DIR:-/opt/ISSM}"

mkdir -p "${RUNTIME_ENV_DIR}" "${BIN_DIR}"

log "Writing firedrake-env.sh ..."
cat > "${RUNTIME_ENV_DIR}/firedrake-env.sh" <<EOF
export PYTHON_DIR="${PYTHON_DIR}"
export MPI_DIR="${OPENMPI_DIR}"
export PETSC_DIR="${FIREDRAKE_PETSC_DIR}"
export PATH="/opt/venv-firedrake/bin:${PYTHON_DIR}/bin:${OPENMPI_DIR}/bin:\${PATH}"
export LD_LIBRARY_PATH="${OPENMPI_DIR}/lib:${FIREDRAKE_PETSC_DIR}/lib:${PYTHON_DIR}/lib:\${LD_LIBRARY_PATH:-}"
export CC="${OPENMPI_DIR}/bin/mpicc"
export CXX="${OPENMPI_DIR}/bin/mpicxx"
export FC="${OPENMPI_DIR}/bin/mpifort"
export MPICC="${OPENMPI_DIR}/bin/mpicc"
export MPICXX="${OPENMPI_DIR}/bin/mpicxx"
export MPIFC="${OPENMPI_DIR}/bin/mpifort"
export HDF5_MPI=ON
EOF

log "Writing icepack-env.sh ..."
cat > "${RUNTIME_ENV_DIR}/icepack-env.sh" <<EOF
export PYTHON_DIR="${PYTHON_DIR}"
export MPI_DIR="${OPENMPI_DIR}"
export PETSC_DIR="${FIREDRAKE_PETSC_DIR}"
export PATH="/opt/venv-icepack/bin:${PYTHON_DIR}/bin:${OPENMPI_DIR}/bin:\${PATH}"
export LD_LIBRARY_PATH="${OPENMPI_DIR}/lib:${FIREDRAKE_PETSC_DIR}/lib:${PYTHON_DIR}/lib:\${LD_LIBRARY_PATH:-}"
export CC="${OPENMPI_DIR}/bin/mpicc"
export CXX="${OPENMPI_DIR}/bin/mpicxx"
export FC="${OPENMPI_DIR}/bin/mpifort"
export MPICC="${OPENMPI_DIR}/bin/mpicc"
export MPICXX="${OPENMPI_DIR}/bin/mpicxx"
export MPIFC="${OPENMPI_DIR}/bin/mpifort"
export HDF5_MPI=ON
EOF

log "Writing icesee-env.sh ..."
cat > "${RUNTIME_ENV_DIR}/icesee-env.sh" <<EOF
export PYTHON_DIR="${PYTHON_DIR}"
export MPI_DIR="${OPENMPI_DIR}"
export HDF5_DIR="${HDF5_DIR}"
export PATH="/opt/venv-icesee/bin:${OPENMPI_DIR}/bin:\${PATH}"
export LD_LIBRARY_PATH="${OPENMPI_DIR}/lib:${HDF5_DIR}/lib:\${LD_LIBRARY_PATH:-}"
export CC="${OPENMPI_DIR}/bin/mpicc"
export CXX="${OPENMPI_DIR}/bin/mpicxx"
export FC="${OPENMPI_DIR}/bin/mpifort"
export MPICC="${OPENMPI_DIR}/bin/mpicc"
export MPICXX="${OPENMPI_DIR}/bin/mpicxx"
export MPIFC="${OPENMPI_DIR}/bin/mpifort"
export HDF5_MPI=ON
export PYTHONPATH="/opt:\${PYTHONPATH:-}"
EOF

log "Writing issm-env.sh ..."
cat > "${RUNTIME_ENV_DIR}/issm-env.sh" <<EOF
export MPI_DIR="${MPICH_DIR}"
export PETSC_DIR="${ISSM_PETSC_DIR}"
export PYTHON_DIR="${PYTHON_DIR}"
export MATLABROOT="${MATLABROOT}"
export ISSM_DIR="${ISSM_DIR}"
export PATH="${MPICH_DIR}/bin:${ISSM_DIR}/bin:\${PATH}"
export LD_LIBRARY_PATH="${MPICH_DIR}/lib:${ISSM_PETSC_DIR}/lib:\${LD_LIBRARY_PATH:-}"
export HDF5_MPI=ON
export MLM_LICENSE_FILE=1711@matlablic.ecs.gatech.edu
EOF

log "Writing activate-firedrake ..."
cat > "${BIN_DIR}/activate-firedrake" <<'EOF'
#!/usr/bin/env bash
set -e
source /opt/runtime-env/firedrake-env.sh
source /opt/runtime-env/icesee-env.sh
unset PETSC_ARCH
exec "$@"
EOF

log "Writing activate-icepack ..."
cat > "${BIN_DIR}/activate-icepack" <<'EOF'
#!/usr/bin/env bash
set -e
source /opt/runtime-env/icepack-env.sh
source /opt/runtime-env/icesee-env.sh
unset PETSC_ARCH
exec "$@"
EOF

log "Writing activate-icesee ..."
cat > "${BIN_DIR}/activate-icesee" <<'EOF'
#!/usr/bin/env bash
set -e
source /opt/runtime-env/icesee-env.sh
exec "$@"
EOF

log "Writing activate-issm ..."
cat > "${BIN_DIR}/activate-issm" <<'EOF'
#!/usr/bin/env bash
set -e
source /opt/runtime-env/issm-env.sh
export MLM_LICENSE_FILE="${MLM_LICENSE_FILE:-1711@matlablic.ecs.gatech.edu}"
if [ -f /opt/ISSM/etc/environment.sh ]; then
  set +u
  . /opt/ISSM/etc/environment.sh
  set -u
fi
source /opt/runtime-env/icesee-env.sh
exec "$@"
EOF

chmod +x \
  "${BIN_DIR}/activate-firedrake" \
  "${BIN_DIR}/activate-icepack" \
  "${BIN_DIR}/activate-icesee" \
  "${BIN_DIR}/activate-issm"

log "Runtime environment scripts created successfully."