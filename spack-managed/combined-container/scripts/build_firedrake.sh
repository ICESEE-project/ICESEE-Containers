#!/usr/bin/env bash
set -euo pipefail

source /opt/spack-src/share/spack/setup-env.sh
spack env activate /opt/spack-environment

PYTHON="$(spack location -i python)/bin/python3"
MPI_DIR="$(spack location -i openmpi)"
PETSC_DIR="$(spack location -i 'petsc@3.24.0 ^openmpi@5.0.6')"

export PATH="${MPI_DIR}/bin:${PATH}"
export LD_LIBRARY_PATH="${MPI_DIR}/lib:${PETSC_DIR}/lib:${LD_LIBRARY_PATH:-}"
export CC="${MPI_DIR}/bin/mpicc"
export CXX="${MPI_DIR}/bin/mpicxx"
export FC="${MPI_DIR}/bin/mpifort"
export MPICC="${MPI_DIR}/bin/mpicc"
export MPICXX="${MPI_DIR}/bin/mpicxx"
export MPIFC="${MPI_DIR}/bin/mpifort"
export PETSC_DIR="${PETSC_DIR}"
export HDF5_MPI=ON
unset PETSC_ARCH

"${PYTHON}" -m venv --system-site-packages /opt/venv-firedrake
source /opt/venv-firedrake/bin/activate

python -m pip install --upgrade pip
printf "setuptools<81\nnumpy<2\npetsc4py==3.24.0\n" > /tmp/constraints.txt
export PIP_CONSTRAINT=/tmp/constraints.txt

python -m pip install "firedrake[check]"