# =========================
# Stage 1: build everything
# =========================
FROM ubuntu:24.04 AS builder

LABEL org.opencontainers.image.authors="Brian Kyanjo <briankyanjo@u.boisestate.edu>" \
      org.opencontainers.image.title="Spack Firedrake base (builder)" \
      org.opencontainers.image.description="Builder stage for Spack-managed Python, MPI, PETSc, and Firedrake"

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
    m4 \
    make \
    ninja-build \
    pkg-config \
    python3 \
    python3-venv \
    python3-pip \
    unzip \
    wget \
    zip \
    perl \
    tar \
    xz-utils \
    bzip2 \
    patch \
    cmake \
    flex \
    bison \
    libssl-dev \
    libffi-dev \
    libhwloc-dev \
    libnuma-dev \
    openssh-client \
    locales \
 && rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

WORKDIR /opt
RUN git clone --depth=1 https://github.com/spack/spack.git /opt/spack-src

ENV SPACK_ROOT=/opt/spack-src
ENV PATH=/opt/spack-src/bin:$PATH

# Copy repo metadata and environment
WORKDIR /opt
COPY icesee-spack /opt/icesee-spack
COPY spack.yaml /opt/spack-environment/spack.yaml

# Build the Spack environment
WORKDIR /opt/spack-environment
RUN . /opt/spack-src/share/spack/setup-env.sh && \
    spack env activate . && \
    spack repo add /opt/icesee-spack || true && \
    spack concretize -f && \
    spack install -j"$(nproc)"

# Ensure pip tooling is present in Spack Python
RUN . /opt/spack-src/share/spack/setup-env.sh && \
    spack env activate /opt/spack-environment && \
    PYTHON="$(spack location -i python)/bin/python3" && \
    "$PYTHON" -m ensurepip --upgrade || true && \
    "$PYTHON" -m pip install --upgrade pip setuptools wheel

# Install Firedrake in a venv layered on top of the Spack Python stack
WORKDIR /opt
RUN . /opt/spack-src/share/spack/setup-env.sh && \
    spack env activate /opt/spack-environment && \
    PYTHON="$(spack location -i python)/bin/python3" && \
    MPI_DIR="$(spack location -i openmpi)" && \
    PETSC_DIR="$(spack location -i petsc)" && \
    export PATH="${MPI_DIR}/bin:${PATH}" && \
    export LD_LIBRARY_PATH="${MPI_DIR}/lib:${PETSC_DIR}/lib:${LD_LIBRARY_PATH:-}" && \
    export CC="${MPI_DIR}/bin/mpicc" && \
    export CXX="${MPI_DIR}/bin/mpicxx" && \
    export FC="${MPI_DIR}/bin/mpifort" && \
    export MPICC="${MPI_DIR}/bin/mpicc" && \
    export MPICXX="${MPI_DIR}/bin/mpicxx" && \
    export MPIFC="${MPI_DIR}/bin/mpifort" && \
    export PETSC_DIR="${PETSC_DIR}" && \
    unset PETSC_ARCH && \
    export HDF5_MPI=ON && \
    "$PYTHON" -m venv --system-site-packages /opt/venv-firedrake && \
    source /opt/venv-firedrake/bin/activate && \
    python -m pip install --upgrade pip && \
    printf "setuptools<81\nnumpy<2\npetsc4py==3.24.0\n" > /tmp/constraints.txt && \
    export PIP_CONSTRAINT=/tmp/constraints.txt && \
    python -m pip install "firedrake[check]"

# Runtime helper script
RUN cat > /usr/local/bin/activate-spack-firedrake.sh <<'EOF'
#!/bin/bash
set -e
source /opt/spack-src/share/spack/setup-env.sh
spack env activate /opt/spack-environment
export MPI_DIR="$(spack location -i openmpi)"
export PETSC_DIR="$(spack location -i petsc)"
export PATH="/opt/venv-firedrake/bin:${MPI_DIR}/bin:${PATH}"
export LD_LIBRARY_PATH="${MPI_DIR}/lib:${PETSC_DIR}/lib:${LD_LIBRARY_PATH:-}"
export CC="${MPI_DIR}/bin/mpicc"
export CXX="${MPI_DIR}/bin/mpicxx"
export FC="${MPI_DIR}/bin/mpifort"
export MPICC="${MPI_DIR}/bin/mpicc"
export MPICXX="${MPI_DIR}/bin/mpicxx"
export MPIFC="${MPI_DIR}/bin/mpifort"
export HDF5_MPI=ON
unset PETSC_ARCH
exec "$@"
EOF

RUN chmod +x /usr/local/bin/activate-spack-firedrake.sh

# Optional strip pass to shrink copied runtime payload
RUN set -euo pipefail; \
    for ROOT in /opt/spack /opt/venv-firedrake; do \
      [ -d "$ROOT" ] || continue; \
      find -L "$ROOT" -type f -exec readlink -f '{}' \; | sort -u | \
        xargs -r file -i | \
        awk -F: '/charset=binary/ && /x-executable|x-sharedlib/ {print $1}' | \
        xargs -r strip --strip-unneeded 2>/dev/null || true; \
    done


# =========================
# Stage 2: runtime image
# =========================
FROM ubuntu:24.04 AS runtime

LABEL org.opencontainers.image.authors="Brian Kyanjo <briankyanjo@u.boisestate.edu>" \
      org.opencontainers.image.title="Spack Firedrake base" \
      org.opencontainers.image.description="Runtime image with Spack-managed Python, MPI, PETSc, and Firedrake"

SHELL ["/bin/bash", "-lc"]
ENV DEBIAN_FRONTEND=noninteractive

# Only runtime packages here
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    file \
    gfortran \
    libffi-dev \
    libhwloc-dev \
    libnuma-dev \
    libssl-dev \
    locales \
    openssh-client \
    perl \
    python3 \
    python3-venv \
    xz-utils \
    zlib1g \
 && rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Copy only what is needed at runtime
COPY --from=builder /opt/spack-src /opt/spack-src
COPY --from=builder /opt/spack /opt/spack
COPY --from=builder /opt/spack-environment /opt/spack-environment
COPY --from=builder /opt/venv-firedrake /opt/venv-firedrake
COPY --from=builder /opt/icesee-spack /opt/icesee-spack
COPY --from=builder /usr/local/bin/activate-spack-firedrake.sh /usr/local/bin/activate-spack-firedrake.sh

ENV SPACK_ROOT=/opt/spack-src
ENV PATH=/opt/spack-src/bin:$PATH
ENV OMP_NUM_THREADS=1
ENV OPENBLAS_NUM_THREADS=1
ENV HDF5_MPI=ON

RUN chmod +x /usr/local/bin/activate-spack-firedrake.sh

ENTRYPOINT ["/usr/local/bin/activate-spack-firedrake.sh"]
CMD ["/bin/bash"]