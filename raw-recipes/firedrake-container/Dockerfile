FROM bkyanjo/firedrake-env:latest
WORKDIR /opt/firedrake
ENV PETSC_ARCH=default

#ENV PETSC_DIR=/opt/firedrake/petsc/default

# Now install Firedrake.
RUN curl -O https://raw.githubusercontent.com/firedrakeproject/firedrake/master/scripts/firedrake-install
RUN bash -c "python3 firedrake-install \
    --no-package-manager \
    --disable-ssh \
    --torch \
    --honour-petsc-dir \
    --mpicc=$MPICH_DIR/mpicc \
    --mpicxx=$MPICH_DIR/mpicxx \
    --mpif90=$MPICH_DIR/mpif90 \
    --mpiexec=$MPICH_DIR/mpiexec \
    --mpihome=$MPICH_DIR"
