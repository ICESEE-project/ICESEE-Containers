# =========================
# Stage 1: builder
# =========================
FROM mathworks/matlab:r2024b AS builder

LABEL org.opencontainers.image.authors="Brian Kyanjo <briankyanjo@u.boisestate.edu>" \
      org.opencontainers.image.title="Combined scientific stack builder" \
      org.opencontainers.image.description="Builder for Firedrake, Icepack, ICESEE, and ISSM with Spack-managed MPI/PETSc stacks"

SHELL ["/bin/bash", "-lc"]
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    binutils \
    ca-certificates \
    curl \
    file \
    gfortran \
    git \
    gnupg \
    lsb-release \
    make \
    m4 \
    ninja-build \
    pkg-config \
    perl \
    python3 \
    python3-pip \
    python3-venv \
    bzip2 \
    xz-utils \
    unzip \
    wget \
    zip \
    patch \
    cmake \
    flex \
    bison \
    libssl-dev \
    libffi-dev \
    libhwloc-dev \
    libnuma-dev \
    libblas-dev \
    liblapack-dev \
    zlib1g-dev \
    locales \
 && rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

WORKDIR /opt
RUN git clone --depth=1 https://github.com/spack/spack.git /opt/spack-src

ENV SPACK_ROOT=/opt/spack-src
ENV PATH=/opt/spack-src/bin:$PATH

COPY spack.yaml /opt/spack-environment/spack.yaml
COPY icesee-spack /opt/icesee-spack
COPY scripts /opt/build-scripts

RUN chmod +x /opt/build-scripts/*.sh

WORKDIR /opt/spack-environment
RUN . /opt/spack-src/share/spack/setup-env.sh && \
    spack env activate . && \
    spack concretize -f && \
    spack install -j"$(nproc)"

RUN . /opt/spack-src/share/spack/setup-env.sh && \
    spack env activate /opt/spack-environment && \
    PYTHON="$(spack location -i python)/bin/python3" && \
    "$PYTHON" -m ensurepip --upgrade || true && \
    "$PYTHON" -m pip install --upgrade pip setuptools wheel

RUN /opt/build-scripts/build_firedrake.sh
RUN /opt/build-scripts/build_icepack.sh
RUN /opt/build-scripts/build_icesee.sh
RUN /opt/build-scripts/build_issm.sh

RUN cat > /usr/local/bin/activate-firedrake <<'EOF'
#!/bin/bash
set -e
source /opt/spack-src/share/spack/setup-env.sh
spack env activate /opt/spack-environment
MPI_DIR="$(spack location -i openmpi)"
PETSC_DIR="$(spack location -i 'petsc@3.24.0 ^openmpi@5.0.6')"
export PATH="/opt/venv-firedrake/bin:${MPI_DIR}/bin:${PATH}"
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
exec "$@"
EOF

RUN cat > /usr/local/bin/activate-icepack <<'EOF'
#!/bin/bash
exec /usr/local/bin/activate-firedrake "$@"
EOF

RUN cat > /usr/local/bin/activate-icesee <<'EOF'
#!/bin/bash
set -e
source /opt/spack-src/share/spack/setup-env.sh
spack env activate /opt/spack-environment
MPI_DIR="$(spack location -i openmpi)"
PETSC_DIR="$(spack location -i 'petsc@3.24.0 ^openmpi@5.0.6')"
export PATH="/opt/venv-firedrake/bin:${MPI_DIR}/bin:${PATH}"
export LD_LIBRARY_PATH="${MPI_DIR}/lib:${PETSC_DIR}/lib:${LD_LIBRARY_PATH:-}"
export CC="${MPI_DIR}/bin/mpicc"
export CXX="${MPI_DIR}/bin/mpicxx"
export FC="${MPI_DIR}/bin/mpifort"
export MPICC="${MPI_DIR}/bin/mpicc"
export MPICXX="${MPI_DIR}/bin/mpicxx"
export MPIFC="${MPI_DIR}/bin/mpifort"
export PETSC_DIR="${PETSC_DIR}"
export HDF5_MPI=ON
export PYTHONPATH="/opt/ICESEE:${PYTHONPATH:-}"
unset PETSC_ARCH
exec "$@"
EOF

RUN cat > /usr/local/bin/activate-issm <<'EOF'
#!/bin/bash
set -e
source /opt/spack-src/share/spack/setup-env.sh
spack env activate /opt/spack-environment
MPI_DIR="$(spack location -i mpich)"
PETSC_DIR="$(spack location -i 'petsc@3.22.3 ^mpich@4.2.3')"
export PATH="${MPI_DIR}/bin:/opt/ISSM/bin:${PATH}"
export LD_LIBRARY_PATH="${MPI_DIR}/lib:${PETSC_DIR}/lib:${LD_LIBRARY_PATH:-}"
export ISSM_DIR=/opt/ISSM
export HDF5_MPI=ON
export MLM_LICENSE_FILE="${MLM_LICENSE_FILE:-1711@matlablic.ecs.gatech.edu}"
if [ -f /opt/ISSM/etc/environment.sh ]; then
  set +u
  . /opt/ISSM/etc/environment.sh
  set -u
fi
exec "$@"
EOF

RUN chmod +x /usr/local/bin/activate-firedrake \
              /usr/local/bin/activate-icepack \
              /usr/local/bin/activate-icesee \
              /usr/local/bin/activate-issm

RUN set -euo pipefail; \
    for ROOT in /opt/spack /opt/venv-firedrake /opt/ISSM; do \
      [ -d "$ROOT" ] || continue; \
      find -L "$ROOT" -type f -exec readlink -f '{}' \; | sort -u | \
        xargs -r file -i | \
        awk -F: '/charset=binary/ && /x-executable|x-sharedlib/ {print $1}' | \
        xargs -r strip --strip-unneeded 2>/dev/null || true; \
    done

# =========================
# Stage 2: runtime
# =========================
FROM mathworks/matlab:r2024b AS runtime

SHELL ["/bin/bash", "-lc"]
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    file \
    gfortran \
    git \
    libffi-dev \
    libhwloc-dev \
    libnuma-dev \
    libssl-dev \
    libblas-dev \
    liblapack-dev \
    perl \
    python3 \
    python3-venv \
    locales \
    xz-utils \
    zlib1g \
 && rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

COPY --from=builder /opt/spack-src /opt/spack-src
COPY --from=builder /opt/spack /opt/spack
COPY --from=builder /opt/spack-environment /opt/spack-environment
COPY --from=builder /opt/venv-firedrake /opt/venv-firedrake
COPY --from=builder /opt/ICESEE /opt/ICESEE
COPY --from=builder /opt/icepack /opt/icepack
COPY --from=builder /opt/ISSM /opt/ISSM
COPY --from=builder /usr/local/bin/activate-firedrake /usr/local/bin/activate-firedrake
COPY --from=builder /usr/local/bin/activate-icepack /usr/local/bin/activate-icepack
COPY --from=builder /usr/local/bin/activate-icesee /usr/local/bin/activate-icesee
COPY --from=builder /usr/local/bin/activate-issm /usr/local/bin/activate-issm

ENV SPACK_ROOT=/opt/spack-src
ENV PATH=/opt/spack-src/bin:$PATH
ENV OMP_NUM_THREADS=1
ENV OPENBLAS_NUM_THREADS=1
ENV HDF5_MPI=ON

ENTRYPOINT ["/bin/bash"]