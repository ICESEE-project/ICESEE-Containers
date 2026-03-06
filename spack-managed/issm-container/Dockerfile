FROM mathworks/matlab:r2024b

LABEL org.opencontainers.image.authors="Brian Kyanjo <briankyanjo@u.boisestate.edu>" \
      org.opencontainers.image.title="Spack ISSM base" \
      org.opencontainers.image.description="MATLAB + Spack-managed MPICH/PETSc toolchain for ISSM"

SHELL ["/bin/bash", "-lc"]
ENV DEBIAN_FRONTEND=noninteractive

# System packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    binutils \
    ca-certificates \
    curl \
    file \
    gfortran \
    git \
    make \
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

# Install Spack
WORKDIR /opt
RUN git clone --depth=1 https://github.com/spack/spack.git /opt/spack-src

ENV SPACK_ROOT=/opt/spack-src
ENV PATH=/opt/spack-src/bin:$PATH

# Copy Spack environment and helper script
COPY spack.yaml /opt/spack-environment/spack.yaml
COPY scripts/build_issm_spack.sh /opt/build_issm_spack.sh

RUN chmod +x /opt/build_issm_spack.sh

# Install Spack toolchain
WORKDIR /opt/spack-environment
RUN . /opt/spack-src/share/spack/setup-env.sh && \
    spack env activate . && \
    spack concretize -f && \
    spack install -j"$(nproc)"

# Ensure pip tooling exists in Spack Python
RUN . /opt/spack-src/share/spack/setup-env.sh && \
    spack env activate /opt/spack-environment && \
    PYTHON="$(spack location -i python)/bin/python3" && \
    "$PYTHON" -m ensurepip --upgrade || true && \
    "$PYTHON" -m pip install --upgrade pip setuptools wheel

# Build ISSM using the Spack-managed MPICH/PETSc stack
RUN /opt/build_issm_spack.sh

# Helper entrypoint
RUN cat > /usr/local/bin/activate-spack-issm.sh <<'EOF'
#!/bin/bash
set -e
source /opt/spack-src/share/spack/setup-env.sh
spack env activate /opt/spack-environment

export MPI_DIR="$(spack location -i mpich)"
export PETSC_DIR="$(spack location -i petsc)"
export PATH="${MPI_DIR}/bin:/opt/ISSM/bin:${PATH}"
export LD_LIBRARY_PATH="${MPI_DIR}/lib:${PETSC_DIR}/lib:${LD_LIBRARY_PATH:-}"
export HDF5_MPI=ON
export ISSM_DIR=/opt/ISSM

if [ -f /opt/ISSM/etc/environment.sh ]; then
    set +u
    . /opt/ISSM/etc/environment.sh
    set -u
fi

exec "$@"
EOF

RUN chmod +x /usr/local/bin/activate-spack-issm.sh

ENTRYPOINT ["/usr/local/bin/activate-spack-issm.sh"]
CMD ["/bin/bash"]