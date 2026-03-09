FROM bkyanjo/firedrake-vanilla:latest
WORKDIR /opt/firedrake

RUN apt -y update && sudo apt -y install patchelf
RUN chown -R 1000:1000 /opt/firedrake && chmod -R 755 /opt/firedrake
# Copy the shell script into the Docker image
COPY set_persistent_dir.sh /opt/firedrake/set_persistent_dir.sh

# Make the shell script executable
RUN chmod +x /opt/firedrake/set_persistent_dir.sh

# Run the shell script to set up persistent directories and environment variables
RUN /opt/firedrake/set_persistent_dir.sh

# Activate the virtual environment and install Icepack packages
RUN . firedrake/bin/activate && \
    pip install git+https://github.com/icepack/Trilinos.git && \
    pip install git+https://github.com/icepack/pyrol.git && \
    pip install git+https://github.com/icepack/icepack.git

# Create the persistent directories
RUN mkdir -p /tmp/icepack_cache/pyop2 && \
    mkdir -p /tmp/icepack_cache/tsfc && \
    mkdir -p /tmp/icepack_cache/xdg

# Set environment variables
ENV PERSISTENT_DIR=/tmp/icepack_cache/
ENV PYOP2_CACHE_DIR=${PERSISTENT_DIR}/pyop2
ENV FIREDRAKE_TSFC_KERNEL_CACHE_DIR=${PERSISTENT_DIR}/tsfc
ENV XDG_CACHE_HOME=${PERSISTENT_DIR}/xdg


    
