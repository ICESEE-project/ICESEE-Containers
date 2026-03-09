# Stage 1: Copy MPICH from firedrake-env
FROM bkyanjo/firedrake-env:latest AS firedrake-env
WORKDIR /opt
# ENV PETSC_ARCH=default

# Stage 2: Install MATLAB and ISSM
FROM mathworks/matlab-deps:R2024b

# Declare build arguments
ENV MATLAB_RELEASE=R2024b
ENV MATLAB_PRODUCT_LIST=MATLAB
ENV MATLAB_INSTALL_LOCATION=/opt/matlab/${MATLAB_RELEASE}
ENV LICENSE_SERVER=1711@matlablic.ecs.gatech.edu

# Copy MPICH files from firedrake-env
COPY --from=firedrake-env /opt/firedrake/petsc/packages /opt/firedrake/petsc/packages
ENV MPICH_DIR=/opt/firedrake/petsc/packages/bin
ENV LD_LIBRARY_PATH=/opt/firedrake/petsc/packages/lib:/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH}

# Debug: Inspect MPICH directory structure
RUN ls -R /opt/firedrake/petsc/packages

# Debug: Test mpifort
RUN /opt/firedrake/petsc/packages/bin/mpifort --version || echo "mpifort not found"

# Install dependencies
RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get install --no-install-recommends --yes \
        wget git bash build-essential gfortran python3-dev libtool cmake autoconf automake \
        curl python3 python3-numpy python3-pip python3-tk python3-venv \
        python3-requests zlib1g-dev libboost-dev gmsh \
        bison flex ninja-build \
        libocct-ocaf-dev libocct-data-exchange-dev \
        swig graphviz \
        libcurl4-openssl-dev libxml2-dev libssl-dev \
        unzip patch ca-certificates libopenblas-serial-dev \
    && apt-get clean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/*

# Create matlab user
RUN adduser --shell /bin/bash --disabled-password --gecos "" matlab \
    && echo "matlab ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/matlab \
    && chmod 0440 /etc/sudoers.d/matlab

# Install MATLAB as matlab user
USER matlab
WORKDIR /home/matlab
RUN wget -q https://www.mathworks.com/mpm/glnxa64/mpm \
    && chmod +x mpm \
    && sudo HOME=${HOME} ./mpm install \
        --release=${MATLAB_RELEASE} \
        --destination=${MATLAB_INSTALL_LOCATION} \
        --products ${MATLAB_PRODUCT_LIST} \
    || (echo "MPM Installation Failure. See below for more information:" && cat /tmp/mathworks_root.log && false) \
    && sudo rm -rf mpm /tmp/mathworks_root.log \
    && sudo ln -s ${MATLAB_INSTALL_LOCATION}/bin/matlab /usr/local/bin/matlab

# Set environment variables
ENV MLM_LICENSE_FILE=$LICENSE_SERVER
ENV PATH="${MATLAB_INSTALL_LOCATION}/bin:${PATH}"
ENV LC_ALL=C.UTF-8

# Create ISSM user and clone ISSM repository
USER root
# RUN usermod -d /opt/ISSM -m ubuntu && \
#     usermod -l ISSM ubuntu && \
#     groupmod -n ISSM ubuntu && \
#     usermod -aG sudo ISSM && \
#     echo "ISSM:docker" | chpasswd && \
#     echo "ISSM ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && ldconfig  && \
#     git clone https://github.com/ISSMteam/ISSM.git /opt/ISSM && \
#     chown -R ISSM:ISSM /opt/ISSM && \
#     usermod -d /opt/ISSM -m ISSM 
RUN git clone https://github.com/ISSMteam/ISSM.git /opt/ISSM

# Switch to ISSM user and configure ISSM
# USER ISSM
WORKDIR /opt/ISSM
ENV ISSM_DIR=/opt/ISSM
RUN ["/bin/bash", "-c", "source $ISSM_DIR/etc/environment.sh"]

# Install external packages
WORKDIR $ISSM_DIR/externalpackages/autotools
RUN ./install-linux.sh

WORKDIR $ISSM_DIR/externalpackages/cmake
RUN ./install.sh 

RUN cd "$ISSM_DIR/externalpackages/petsc" \
    && mkdir -p src \
    && git clone -b v3.22.3 https://gitlab.com/petsc/petsc.git src \
    && cd src \
    && ./configure \
        --prefix="$ISSM_DIR/externalpackages/petsc/install" \
        --PETSC_DIR="$ISSM_DIR/externalpackages/petsc/src" \
        --with-debugging=0 \
        --with-valgrind=0 \
        --with-x=0 \
        --with-ssl=0 \
        --with-pic=1 \
        --download-mpich=1 \
        --download-fblaslapack=1 \
        --download-metis=1 \
        --download-mumps=1 \
        --download-parmetis=1 \
        --download-scalapack=1 \
        --download-zlib=1 \
    && make -j$(nproc) \
    && make install

WORKDIR $ISSM_DIR/externalpackages/triangle
RUN ./install-linux.sh

WORKDIR $ISSM_DIR/externalpackages/m1qn3
RUN ./install-linux.sh

# souce ISSM environment
RUN ["/bin/bash", "-c", "source $ISSM_DIR/etc/environment.sh"]

WORKDIR ${ISSM_DIR}
RUN autoreconf -ivf

# configure and build ISSM
RUN bash -c './configure \
   --prefix=${ISSM_DIR} \
   --with-numthreads=2 \
   --with-matlab-dir="${MATLAB_INSTALL_LOCATION}" \
   --with-fortran-lib="-L/usr/lib/x86_64-linux-gnu -lgfortran" \
   --with-mpi-include="${ISSM_DIR}/externalpackages/petsc/install/include" \
   --with-mpi-libflags="-L${ISSM_DIR}/externalpackages/petsc/install/lib -lmpi -lmpicxx -lmpifort" \
   --with-metis-dir="${ISSM_DIR}/externalpackages/petsc/install" \
   --with-parmetis-dir="${ISSM_DIR}/externalpackages/petsc/install" \
   --with-blas-lapack-dir="${ISSM_DIR}/externalpackages/petsc/install" \
   --with-scalapack-dir="${ISSM_DIR}/externalpackages/petsc/install" \
   --with-mumps-dir="${ISSM_DIR}/externalpackages/petsc/install" \
   --with-petsc-dir="${ISSM_DIR}/externalpackages/petsc/install" \
   --with-triangle-dir="${ISSM_DIR}/externalpackages/triangle/install" \
   --with-m1qn3-dir="${ISSM_DIR}/externalpackages/m1qn3/install"'

RUN bash -c 'make -j4 && make install;'

# Clean up build artifacts
RUN rm -rf /opt/ISSM/externalpackages/petsc/**/externalpackages \
    && rm -rf /opt/ISSM/externalpackages/petsc/src/docs \
    && rm -rf /opt/ISSM/externalpackages/petsc/src/**/tutorials/output/* \
    && rm -rf /opt/ISSM/externalpackages/petsc/src/**/tests/output/* 

# Set environment variables for ISSM
ENV ISSM_DIR=/opt/ISSM \
    PETSC_DIR=${ISSM_DIR}/externalpackages/petsc/install \
    MPICH_DIR=${ISSM_DIR}/externalpackages/petsc/install/bin \