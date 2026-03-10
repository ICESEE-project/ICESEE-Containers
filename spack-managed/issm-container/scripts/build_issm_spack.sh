#!/usr/bin/env bash
set -euo pipefail

log(){ echo "[build_issm] $*"; }
die(){ echo "[build_issm][ERROR] $*" >&2; exit 1; }

source /opt/spack-src/share/spack/setup-env.sh
spack env activate /opt/spack-environment

# Define the paths for METIS, ParMETIS, BLAS, LAPACK, ScaLAPACK, MUMPS
METIS_DIR="$(spack location -i metis@5.1.0)"
PARMETIS_DIR="$(spack location -i parmetis@4.0.3)"
BLAS_DIR="$(spack location -i openblas)"
LAPACK_DIR="$(spack location -i openblas)"  # Assuming LAPACK is bundled with OpenBLAS
SCALAPACK_DIR="$(spack location -i scalapack)"
MUMPS_DIR="$(spack location -i mumps)"

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
export LD_LIBRARY_PATH="${MPI_DIR}/lib:${PETSC_DIR}/lib:${METIS_DIR}/lib:${PARMETIS_DIR}/lib:${BLAS_DIR}/lib:${LAPACK_DIR}/lib:${SCALAPACK_DIR}/lib:${MUMPS_DIR}/lib:${LD_LIBRARY_PATH:-}"
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
  log "Cloning ISSM repository..."
  git clone --branch "${ISSM_BRANCH}" --depth 1 "${ISSM_REPO}" "${ISSM_PREFIX}"
else
  log "ISSM repository already present, updating..."
  git -C "${ISSM_PREFIX}" fetch --depth 1 origin "${ISSM_BRANCH}" || true
  git -C "${ISSM_PREFIX}" checkout "${ISSM_BRANCH}" || true
  git -C "${ISSM_PREFIX}" pull || true
fi

cd "${ISSM_PREFIX}"

log "Installing external dependencies..."

# Install Autotools, Triangle, and M1QN3
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

log "Configuring ISSM with Spack-managed dependencies..."

# Configure ISSM with MPI, PETSc, and other dependencies
./configure \
  --prefix="${ISSM_PREFIX}" \
  --with-matlab-dir="${MATLABROOT}" \
  --with-fortran-lib="${FORTRAN_LIBFLAGS}" \
  --with-mpi-include="${MPI_DIR}/include" \
  --with-mpi-libflags="-L${MPI_DIR}/lib -lmpi -lmpicxx -lmpifort" \
  --with-metis-dir="${METIS_DIR}" \
  --with-parmetis-dir="${PARMETIS_DIR}" \
  --with-blas-lapack-dir="${BLAS_DIR}" \
  --with-scalapack-dir="${SCALAPACK_DIR}" \
  --with-mumps-dir="${MUMPS_DIR}" \
  --with-petsc-dir="${PETSC_DIR}" \
  --with-triangle-dir="${TRIANGLE_DIR}" \
  --with-m1qn3-dir="${M1QN3_DIR}" \
  --with-numthreads="${ISSM_NUMTHREADS}"

log "Building ISSM..."
make -j"${MAKE_JOBS}"

log "Installing ISSM..."
make install

log "Checking install..."
test -f "${ISSM_PREFIX}/etc/environment.sh" || die "ISSM environment.sh missing after install"

log "Done. ISSM installed in ${ISSM_PREFIX}"