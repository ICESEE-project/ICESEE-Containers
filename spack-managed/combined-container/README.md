# Combined Scientific Stack Containers

A reproducible container environment for **glaciology and geophysical modeling** workflows including:

* **Firedrake**
* **Icepack**
* **ICESEE**
* **ISSM**

These containers provide **precompiled MPI/PETSc stacks** and **preconfigured runtime environments** so users can run scientific models **without activating Spack at runtime**.

The containers support both:

* **Docker**
* **Apptainer / Singularity**

---

# Stack Architecture

The container intentionally separates toolchains to maintain compatibility between projects.

```
┌─────────────────────────────────────────────┐
│                USER WORKFLOWS               │
│                                             │
│  Firedrake   Icepack   ICESEE    ISSM       │
└─────────────────────────────────────────────┘
                     │
                     ▼
        Runtime activation wrappers
     (activate-firedrake, with-issm, etc.)
                     │
                     ▼
┌─────────────────────────────────────────────┐
│                MPI / PETSc                  │
│                                             │
│  OpenMPI 5.x  + PETSc 3.24  → Firedrake    │
│  OpenMPI 5.x  + PETSc 3.24  → Icepack      │
│  OpenMPI 5.x  + HDF5 MPI    → ICESEE       │
│                                             │
│  MPICH 4.x   + PETSc 3.22   → ISSM         │
└─────────────────────────────────────────────┘
                     │
                     ▼
              Spack Toolchain
```

---

# Repository Layout

```
issm-container
├── Dockerfile.matlab-runtime
├── Dockerfile.no-matlab-runtime
├── README.md
├── icesee-spack
│   └── repo.yaml
├── combined-env-inbuilt-matlab.def
├── combined-env-external-matlab.def
├── scripts
│   ├── build_firedrake.sh
│   ├── build_icepack.sh
│   ├── build_icesee.sh
│   ├── build_issm.sh
│   ├── write_runtime_envs.sh
│   ├── write_runtime_envs_external_matlab.sh  
│   └── gen_pip_reqs.py
└── spack.yaml
```

---

# Container Variants

Two container variants are provided.

| Variant                       | MATLAB   | Intended Usage            |
| ----------------------------- | -------- | ------------------------- |
| `Dockerfile.matlab-runtime`   | Included | Cloud / local workstation |
| `Dockerfile.no-matlab-runtime` | External | HPC clusters             |

---

# Docker Containers

## 1. MATLAB Runtime Container

This container **includes MATLAB** inside the runtime image.

### Base Image

```
mathworks/matlab:r2024b
```

### Build

```bash
docker build -f Dockerfile.matlab-runtime \
-t bkyanjo/combined-lean:v1.0 .
```

---

### Example Usage

#### Firedrake

```bash
docker run -it bkyanjo/combined-lean:v1.0 \
/usr/local/bin/activate-firedrake python -c "import firedrake"
```

#### Icepack

```bash
docker run -it bkyanjo/combined-lean:v1.0 \
/usr/local/bin/activate-icepack python -c "import icepack"
```

#### ICESEE

```bash
docker run -it bkyanjo/combined-lean:v1.0 \
/usr/local/bin/activate-icesee python -c "import ICESEE"
```

#### ISSM

```bash
docker run -it \
-e MLM_LICENSE_FILE=1711@matlablic.ecs.gatech.edu \
bkyanjo/combined-lean:v1.0 \
/usr/local/bin/activate-issm matlab -batch "issmversion"
```

---

# 2. External MATLAB Container

This container **does not include MATLAB**.

MATLAB must be provided by the **host system or HPC cluster**.

### Base Image

```
ubuntu:24.04
```

---

### Build

```bash
docker build -f Dockerfile.nomatlab-runtime \
-t bkyanjo/combined-lean-external-matlab:v1.0 .
```

---

### Run with Host MATLAB

Example host MATLAB installation:

```
/apps/MATLAB/R2024b
```

Run container:

```bash
docker run -it \
-e MATLABROOT=/opt/matlab/R2024b \
-e MLM_LICENSE_FILE=1711@matlablic.ecs.gatech.edu \
-v /apps/MATLAB/R2024b:/opt/matlab/R2024b \
bkyanjo/combined-lean-external-matlab:v1.0 \
/usr/local/bin/activate-issm-external-matlab matlab -batch "issmversion"
```

---

# Apptainer / Singularity

Two Apptainer definition files mirror the Docker images.

| Definition File                     | MATLAB   | Usage          |
| ------------------------------------| -------- | -------------- |
| `combined-env-inbuilt-matlab.def`   | Included | MATLAB runtime |
| `combined-env-external-matlab.def`  | External | Cluster MATLAB |

---

## Build Container

### MATLAB Runtime

```bash
apptainer build combined-env.sif combined-env-inbuilt-matlab.def
```

### External MATLAB

```bash
apptainer build combined-env-external-matlab.sif \
combined-env-external-matlab.def
```

---

# Running with Apptainer

## Firedrake

```bash
apptainer exec combined-env.sif \
with-firedrake python -c "import firedrake"
```

---

## Icepack

```bash
apptainer exec combined-env.sif \
with-icepack python -c "import icepack"
```

---

## ISSM
```bash
apptainer exec combined-env.sif \
with-issm matlab -r "issmversion"
```
---

## ICESEE
```bash
apptainer exec combined-env.sif \
with-icesee python -c "import ICESEE"
```
### Lauching a coupled ICESEE<->Icepack coupled run
```bash
srun --mpi=pmix -n 8 apptainer exec combined-env-inbuilt-matlab.sif with-icepack \
                      python run_da_icepack.py --Nens=40 
```

### Lauching a coupled ICESEE<->ISSM coupled run
```bash
mkdir -p examples execution # for binding with container directories
srun --mpi=pmix -n 8 apptainer exec -B examples:/opt/ISSM/examples,execution:/opt/ISSM/execution \
                            combined-env-inbuilt-matlab.sif with-issm \
                            python run_da_issm.py --Nens=24 --model_nprocs=1
```
---

# Running ISSM with External MATLAB

Example cluster MATLAB:

```
/apps/MATLAB/R2024b
```

Run:

```bash
apptainer exec \
--bind /apps/MATLAB/R2024b:/opt/matlab/R2024b \
--env MATLABROOT=/opt/matlab/R2024b \
combined-env-external-matlab.sif \
with-issm matlab -batch "issmversion"
```

---

# Persistent Cache

The container automatically configures persistent caches.

Preferred location:

```
/scratch/$USER/combined_cache
```

Fallback:

```
/tmp/$USER/combined_cache
```

Created directories:

```
pyop2
tsfc
xdg
```

These improve performance for:

* Firedrake kernel compilation
* TSFC kernels
* Python runtime caching

---

# Runtime Activation Wrappers

Each toolchain has an activation wrapper.

```
with-firedrake
with-icepack
with-icesee
with-issm
```

These automatically configure:

* MPI
* PETSc
* library paths
* persistent caches

---
# Cluster MPI wireup test

## **A Simple Test**
To verify the compatibility of the container with the SLURM environment, you can test it using a simple [mpi_hello_world.c](./mpi_hello_world.c) code by following these steps:

```bash
# Step 1: Purge existing modules
module purge

# Step 2: Compile the MPI code using mpicc from the container
apptainer exec combined-env-inbuilt-matlab.sif with-icesee mpicc mpi_hello_world.c -o mpi_hello

# Step 3: Load necessary modules (adjust GCC and MPI versions as per your system)
module load gcc/12
module load mvapich2

# Step 4: Run the compiled program with SLURM
srun --mpi=pmix -n 4 apptainer exec combined-env-inbuilt-matlab.sif ./mpi_hello
```

---

#### **Expected Output**
The output should resemble the following:

```
Hello world! Processor atl1-1-03-003-35-1.pace.gatech.edu, Rank 1 of 4, CPU 6, NUMA node 0, Namespace mnt:[4026533358]
Hello world! Processor atl1-1-03-003-35-1.pace.gatech.edu, Rank 2 of 4, CPU 23, NUMA node 1, Namespace mnt:[4026533363]
Hello world! Processor atl1-1-03-003-35-1.pace.gatech.edu, Rank 3 of 4, CPU 13, NUMA node 1, Namespace mnt:[4026533361]
Hello world! Processor atl1-1-03-003-35-1.pace.gatech.edu, Rank 0 of 4, CPU 2, NUMA node 0, Namespace mnt:[4026533364]
```

---

# Recommended Deployment

| Environment             | Recommended Container |
| ----------------------- | --------------------- |
| Laptop / workstation    | MATLAB runtime        |
| Cloud computing         | MATLAB runtime        |
| HPC cluster with MATLAB | External MATLAB       |
| Institutional cluster   | External MATLAB       |

---

# MATLAB Licensing

MATLAB licensing is configured through:

```
MLM_LICENSE_FILE
```

Example:

```bash
export MLM_LICENSE_FILE=1711@matlablic.ecs.gatech.edu
```

---

# Maintainer

Brian Kyanjo 
Georgia Institute of Technology


