FROM bkyanjo/issm:latest 

# install ICESEE
# WORKDIR /opt/ICESEE
RUN git clone https://github.com/ICESEE-project/ICESEE.git /opt/ICESEE

# Create and activate a Python virtual environment
WORKDIR /opt/ICESEE
RUN python3 -m venv /opt/icesee-venv && \
    . /opt/icesee-venv/bin/activate && \
    pip install --no-cache-dir --upgrade pip   && \
    pip install --no-cache-dir numpy scipy>=1.15.1 jupyter>=1.1.1 matplotlib>=3.10.0 \
        pandas>=2.2.3 bigmpi4py==1.2.4 jax==0.5.3 jaxlib==0.5.3 jaxopt==0.8.3 \
        jaxtyping==0.3.0 ray Cython dask psutil==6.1.1 tqdm==4.67.1 pyyaml nose gstools

# Remove build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends     gawk bison && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV HDF5_MPI="ON"
ENV CC=${ISSM_DIR}/externalpackages/petsc/install/bin/mpicc
ENV MPICC=${ISSM_DIR}/externalpackages/petsc/install/bin/mpicc
RUN pip install --no-cache-dir mpi4py==4.0.1
# # install pkg-config
# RUN apt-get update && \
#     apt-get install -y --no-install-recommends pkg-config libhdf5-openmpi-dev  && \
#     apt-get clean && \
#     rm -rf /var/lib/apt/lists/*
# RUN pip install --no-cache-dir --no-binary=h5py h5py


# Set environment variables for ICESEE
ENV ICESEE=/opt/ICESEE \
    PYTHONPATH=/opt/ICESEE:$PYTHONPATH \
    PATH=/opt/icesee-venv/bin:$PATH

RUN ["/bin/bash", "-c", "source $ISSM_DIR/etc/environment.sh"]

# Download and extract glibc 2.38
WORKDIR /tmp
RUN wget -c https://ftp.gnu.org/gnu/glibc/glibc-2.38.tar.gz \
    && tar -zxvf glibc-2.38.tar.gz \
    && rm glibc-2.38.tar.gz

# Build and install glibc 2.38 in /opt/glibc-2.38, unsetting LD_LIBRARY_PATH
RUN mkdir /tmp/glibc-build \
    && cd /tmp/glibc-build \
    && unset LD_LIBRARY_PATH \
    && /tmp/glibc-2.38/configure --prefix=/opt/glibc-2.38 \
    && make -j$(nproc) \
    && make install \
    && rm -rf /tmp/glibc-*

# Set LD_LIBRARY_PATH for applications to use glibc 2.38 and MATLAB runtime
ENV LD_LIBRARY_PATH=/opt/glibc-2.38/lib:/usr/local/MATLAB/MATLAB_Runtime/R2024b/runtime/glnxa64:/usr/local/MATLAB/MATLAB_Runtime/R2024b/bin/glnxa64:/usr/local/MATLAB/MATLAB_Runtime/R2024b/sys/os/glnxa64:$LD_LIBRARY_PATH

# set ISSM_DIR environment variable
ENV ISSM_DIR=/opt/ISSM \
    PATH=/opt/firedrake/petsc/packages/bin:$PATH \
    LD_LIBRARY_PATH=/opt/firedrake/petsc/packages/lib:$LD_LIBRARY_PATH