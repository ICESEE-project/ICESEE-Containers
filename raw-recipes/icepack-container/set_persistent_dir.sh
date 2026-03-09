#!/bin/sh

# Check if /scratch/midway3 is available
if [ -d "/scratch/midway3" ]; then
    PERSISTENT_DIR="/tmp/icepack_cache"
else
    PERSISTENT_DIR="/tmp/icepack_cache"
fi

# Create the persistent directories
mkdir -p $PERSISTENT_DIR/pyop2
mkdir -p $PERSISTENT_DIR/tsfc
mkdir -p $PERSISTENT_DIR/xdg

# Export environment variables
export PYOP2_CACHE_DIR=$PERSISTENT_DIR/pyop2
export FIREDRAKE_TSFC_KERNEL_CACHE_DIR=$PERSISTENT_DIR/tsfc
export XDG_CACHE_HOME=$PERSISTENT_DIR/xdg
