#!/usr/bin/env bash
set -euo pipefail

log(){ echo "[build_issm] $*"; }
die(){ echo "[build_issm][ERROR] $*" >&2; exit 1; }

source /opt/spack-src/share/spack/setup-env.sh
spack env activate /opt/spack-environment

export ISSM_PREFIX=/opt/ISSM
export ISSM_DIR=/opt/ISSM
export ISSM_REPO="${ISSM_REPO:-https://github.com/ISSMteam/ISSM.git}"
export ISSM_BRANCH="${ISSM_BRANCH:-main}"
export ISSM_NUMTHREADS="${ISSM_NUMTHREADS:-2}"
export MAKE_JOBS="${MAKE_JOBS:-$(nproc)}"

MATLABROOT="${MATLABROOT:-/opt/matlab/R2024b}"
[[ -d "${MATLABROOT}" ]] || die "MATLABROOT not found: ${MATLABROOT}"

MPI_DIR="$(spack location -i mpich)"
PETSC_DIR="$(spack location -i 'petsc@3.22.3 ^mpich@4.2.3')"

export PATH="${MPI_DIR}/bin:${PATH}"
export LD_LIBRARY_PATH="${MPI_DIR}/lib:${PETSC_DIR}/lib:${LD_LIBRARY_PATH:-}"
export CC="${MPI_DIR}/bin/mpicc"
export CXX="${MPI_DIR}/bin/mpicxx"
export FC="${MPI_DIR}/bin/mpifort"
export MPICC="${MPI_DIR}/bin/mpicc"
export MPICXX="${MPI_DIR}/bin/mpicxx"
export MPIFC="${MPI_DIR}/bin/mpifort"
export HDF5_MPI=ON

GFORTRAN_LIBDIR="$(dirname "$(gfortran -print-file-name=libgfortran.so)")"
FORTRAN_LIBFLAGS="-L${GFORTRAN_LIBDIR} -lgfortran"

if [[ ! -d "${ISSM_PREFIX}/.git" ]]; then
  git clone --branch "${ISSM_BRANCH}" --depth 1 "${ISSM_REPO}" "${ISSM_PREFIX}"
fi

cd "${ISSM_PREFIX}"

cd externalpackages/autotools
./install-linux.sh
export PATH="${ISSM_PREFIX}/externalpackages/autotools/install/bin:${PATH}"

cd "${ISSM_PREFIX}/externalpackages/triangle"
./install-linux.sh

cd "${ISSM_PREFIX}/externalpackages/m1qn3"
./install-linux.sh

TRIANGLE_DIR="${ISSM_PREFIX}/externalpackages/triangle/install"
M1QN3_DIR="${ISSM_PREFIX}/externalpackages/m1qn3/install"

cd "${ISSM_PREFIX}"
autoreconf -ivf

./configure \
  --prefix="${ISSM_PREFIX}" \
  --with-matlab-dir="${MATLABROOT}" \
  --with-fortran-lib="${FORTRAN_LIBFLAGS}" \
  --with-mpi-include="${MPI_DIR}/include" \
  --with-mpi-libflags="-L${MPI_DIR}/lib -lmpi -lmpicxx -lmpifort" \
  --with-triangle-dir="${TRIANGLE_DIR}" \
  --with-petsc-dir="${PETSC_DIR}" \
  --with-metis-dir="${PETSC_DIR}" \
  --with-parmetis-dir="${PETSC_DIR}" \
  --with-blas-lapack-dir="${PETSC_DIR}" \
  --with-scalapack-dir="${PETSC_DIR}" \
  --with-mumps-dir="${PETSC_DIR}" \
  --with-m1qn3-dir="${M1QN3_DIR}" \
  --with-numthreads="${ISSM_NUMTHREADS}"

make -j"${MAKE_JOBS}"
make install