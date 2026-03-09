FROM ubuntu:24.04

# Install necessary packages
RUN apt-get update \
    && apt-get -y dist-upgrade \
    && DEBIAN_FRONTEND=noninteractive apt-get -y install tzdata \
    && apt-get -y install curl vim docker.io \
                 openssh-client build-essential autoconf automake \
                 cmake gfortran git libopenblas-serial-dev \
                 libtool python3-dev python3-pip python3-tk python3-venv \
                 python3-requests zlib1g-dev libboost-dev sudo gmsh \
                 bison flex ninja-build \
                 libocct-ocaf-dev libocct-data-exchange-dev \
                 swig graphviz \
                 libcurl4-openssl-dev libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# Use a more sane locale
ENV LC_ALL=C.UTF-8

# Change the `ubuntu` user to `firedrake`
# and ensure that we do not run as root on self-hosted systems
RUN usermod -d /opt/firedrake -m ubuntu && \
    usermod -l firedrake ubuntu && \
    groupmod -n firedrake ubuntu && \
    usermod -aG sudo firedrake && \
    echo "firedrake:docker" | chpasswd && \
    echo "firedrake ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    ldconfig

# Fetch PETSc, SLEPc and eigen
RUN git clone https://github.com/firedrakeproject/petsc.git /opt/firedrake/petsc && \
    git clone https://github.com/firedrakeproject/slepc.git /opt/firedrake/slepc

# Build MPICH manually because we don't want PETSc to build it twice
RUN bash -c 'cd /opt/firedrake/petsc; \
    ./configure \
        --COPTFLAGS=-O3 -march=native -mtune=native \
        --CXXOPTFLAGS=-O3 -march=native -mtune=native \
        --FOPTFLAGS=-O3 -march=native -mtune=native \
        --with-c2html=0 \
        --with-debugging=0 \
        --with-fortran-bindings=0 \
        --with-make-np=12 \
        --with-shared-libraries=1 \
        --with-zlib \
        --download-fftw \
        --download-hdf5 \
        --download-hwloc \
        --download-hypre \
        --download-metis \
        --download-mumps \
        --download-mpich \
        --download-mpich-device=ch3:sock \
        --download-netcdf \
        --download-pastix \
        --download-pnetcdf \
        --download-ptscotch \
        --download-scalapack \
        --download-suitesparse \
        --download-superlu_dist \
        PETSC_ARCH=packages; \
        mv packages/include/petscconf.h packages/include/old_petscconf.nope;'

# Build default Firedrake PETSc
RUN bash -c 'export PACKAGES=/opt/firedrake/petsc/packages; \
    cd /opt/firedrake/petsc; \
    ./configure \
        --COPTFLAGS=-O3 -march=native -mtune=native \
        --CXXOPTFLAGS=-O3 -march=native -mtune=native \
        --FOPTFLAGS=-O3 -march=native -mtune=native \
        --with-c2html=0 \
        --with-debugging=0 \
        --with-fortran-bindings=0 \
        --with-make-np=12 \
        --with-shared-libraries=1 \
        --with-bison \
        --with-flex \
        --with-zlib \
        --with-fftw-dir=$PACKAGES \
        --with-hdf5-dir=$PACKAGES \
        --with-hwloc-dir=$PACKAGES \
        --with-hypre-dir=$PACKAGES \
        --with-metis-dir=$PACKAGES \
        --with-mpi-dir=$PACKAGES \
        --with-mumps-dir=$PACKAGES \
        --with-netcdf-dir=$PACKAGES \
        --with-pastix-dir=$PACKAGES \
        --with-pnetcdf-dir=$PACKAGES \
        --with-ptscotch-dir=$PACKAGES \
        --with-scalapack-dir=$PACKAGES \
        --with-suitesparse-dir=$PACKAGES \
        --with-superlu_dist-dir=$PACKAGES \
        PETSC_ARCH=default; \
    make PETSC_DIR=/opt/firedrake/petsc PETSC_ARCH=default all;'

# Build default Firedrake SLEPc
RUN bash -c 'export PETSC_DIR=/opt/firedrake/petsc; \
    export PETSC_ARCH=default; \
    cd /opt/firedrake/slepc; \
    ./configure; \
    make SLEPC_DIR=/opt/firedrake/slepc PETSC_DIR=/opt/firedrake/petsc PETSC_ARCH=default;'

# Additionally build complex PETSc for Firedrake
RUN bash -c 'export PACKAGES=/opt/firedrake/petsc/packages; \
    cd /opt/firedrake/petsc; \
    ./configure \
        --COPTFLAGS=-O3 -march=native -mtune=native \
        --CXXOPTFLAGS=-O3 -march=native -mtune=native \
        --FOPTFLAGS=-O3 -march=native -mtune=native \
        --with-c2html=0 \
        --with-debugging=0 \
        --with-fortran-bindings=0 \
        --with-make-np=12 \
        --with-scalar-type=complex \
        --with-shared-libraries=1 \
        --with-bison \
        --with-flex \
        --with-zlib \
        --with-fftw-dir=$PACKAGES \
        --with-hdf5-dir=$PACKAGES \
        --with-hwloc-dir=$PACKAGES \
        --with-metis-dir=$PACKAGES \
        --with-mpi-dir=$PACKAGES \
        --with-mumps-dir=$PACKAGES \
        --with-netcdf-dir=$PACKAGES \
        --with-pastix-dir=$PACKAGES \
        --with-pnetcdf-dir=$PACKAGES \
        --with-ptscotch-dir=$PACKAGES \
        --with-scalapack-dir=$PACKAGES \
        --with-suitesparse-dir=$PACKAGES \
        --with-superlu_dist-dir=$PACKAGES \
        PETSC_ARCH=complex; \
    make PETSC_DIR=/opt/firedrake/petsc PETSC_ARCH=complex all;'

# Build complex Firedrake SLEPc
RUN bash -c 'export PETSC_DIR=/opt/firedrake/petsc; \
    export PETSC_ARCH=complex; \
    cd /opt/firedrake/slepc; \
    ./configure; \
    make SLEPC_DIR=/opt/firedrake/slepc PETSC_DIR=/opt/firedrake/petsc PETSC_ARCH=complex;'

# Clean up unnecessary files
RUN rm -rf /opt/firedrake/petsc/**/externalpackages \
    && rm -rf /opt/firedrake/petsc/src/docs \
    && rm -f /opt/firedrake/petsc/src/**/tutorials/output/* \
    && rm -f /opt/firedrake/petsc/src/**/tests/output/*

# Set environment variables
ENV PETSC_DIR=/opt/firedrake/petsc \
    SLEPC_DIR=/opt/firedrake/slepc \
    MPICH_DIR=/opt/firedrake/petsc/packages/bin \
    HDF5_DIR=/opt/firedrake/petsc/packages \
    HDF5_MPI=ON \
    OMP_NUM_THREADS=1 \
    OPENBLAS_NUM_THREADS=1 \
    PATH=$PATH:/opt/firedrake

# Fetch and install Firedrake
# RUN curl -O https://raw.githubusercontent.com/firedrakeproject/firedrake/master/scripts/firedrake-install && \
#     bash -c "python3 firedrake-install \
#     --no-package-manager \
#     --disable-ssh \
#     --torch \
#     --honour-petsc-dir \
#     --mpicc=/opt/firedrake/petsc/packages/bin/mpicc \
#     --mpicxx=/opt/firedrake/petsc/packages/bin/mpicxx \
#     --mpif90=/opt/firedrake/petsc/packages/bin/mpif90 \
#     --mpiexec=/opt/firedrake/petsc/packages/bin/mpiexec"