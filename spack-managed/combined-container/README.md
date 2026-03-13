# Combined Scientific Stack Containers

A **reproducible container environment** for glaciology and geophysical modeling workflows including:

* **Firedrake**
* **Icepack**
* **ICESEE**
* **ISSM**

These containers provide:

* precompiled **MPI / PETSc toolchains**
* preconfigured **runtime environments**
* **no Spack activation required at runtime**

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
      activate-firedrake / with-firedrake
      activate-icepack   / with-icepack
      activate-icesee    / with-icesee
      activate-issm      / with-issm
                     │
                     ▼
┌─────────────────────────────────────────────┐
│                MPI / PETSc                  │
│                                             │
│  OpenMPI 5.x + PETSc 3.24 → Firedrake      │
│  OpenMPI 5.x + PETSc 3.24 → Icepack        │
│  OpenMPI 5.x + HDF5 MPI   → ICESEE         │
│                                             │
│  MPICH 4.x  + PETSc 3.22 → ISSM            │
└─────────────────────────────────────────────┘
                     │
                     ▼
                 Spack Toolchain
```

---

# Python Environments

Each project uses its own isolated virtual environment.

| Project   | Virtual Environment   |
| --------- | --------------------- |
| Firedrake | `/opt/venv-firedrake` |
| Icepack   | `/opt/venv-icepack`   |
| ICESEE    | `/opt/venv-icesee`    |

This separation prevents dependency conflicts while still allowing tools to interact.

Icepack is installed on top of Firedrake but runs in its **own venv**.

---

# Repository Layout

```
combined-container
├── Dockerfile.matlab-runtime
├── Dockerfile.nomatlab-runtime
├── README.md
├── icesee-spack
│   └── repo.yaml
├── issm-env.def
├── issm-env-external-matlab.def
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
| `Dockerfile.matlab-runtime`   | Included | Local workstation / cloud |
| `Dockerfile.nomatlab-runtime` | External | HPC clusters              |

---

# Docker Containers

## 1. MATLAB Runtime Container

This container **includes MATLAB**.

### Base Image

```
mathworks/matlab:r2024b
```

### Build

```
docker build -f Dockerfile.matlab-runtime \
-t bkyanjo/combined-lean:v1.0 .
```

---

# Example Docker Usage

## Firedrake

```
docker run -it bkyanjo/combined-lean:v1.0 \
activate-firedrake python -c "import firedrake"
```

---

## Icepack

```
docker run -it bkyanjo/combined-lean:v1.0 \
activate-icepack python -c "import icepack"
```

---

## ICESEE

```
docker run -it bkyanjo/combined-lean:v1.0 \
activate-icesee python -c "import ICESEE"
```

---

## ISSM

```
docker run -it \
-e MLM_LICENSE_FILE=1711@matlablic.ecs.gatech.edu \
bkyanjo/combined-lean:v1.0 \
activate-issm matlab -batch "issmversion"
```

---

# External MATLAB Container

This container **does not include MATLAB**.

MATLAB must be supplied by the host system.

### Base Image

```
ubuntu:24.04
```

---

## Build

```
docker build -f Dockerfile.nomatlab-runtime \
-t bkyanjo/combined-lean-external-matlab:v1.0 .
```

---

# Run with Host MATLAB

Example host MATLAB installation

```
/apps/MATLAB/R2024b
```

Run container:

```
docker run -it \
-e MATLABROOT=/opt/matlab/R2024b \
-e MLM_LICENSE_FILE=1711@matlablic.ecs.gatech.edu \
-v /apps/MATLAB/R2024b:/opt/matlab/R2024b \
bkyanjo/combined-lean-external-matlab:v1.0 \
activate-issm-external-matlab matlab -batch "issmversion"
```

---

# Apptainer / Singularity

Two Apptainer definition files mirror the Docker images.

| Definition File                | MATLAB   | Usage          |
| ------------------------------ | -------- | -------------- |
| `issm-env.def`                 | Included | MATLAB runtime |
| `issm-env-external-matlab.def` | External | HPC clusters   |

---

# Build Apptainer Containers

## MATLAB Runtime

```
apptainer build combined-env.sif issm-env.def
```

---

## External MATLAB

```
apptainer build combined-env-external-matlab.sif \
issm-env-external-matlab.def
```

---

# Running with Apptainer

## Firedrake

```
apptainer exec combined-env.sif \
with-firedrake python -c "import firedrake"
```

---

## Icepack

```
apptainer exec combined-env.sif \
with-icepack python -c "import icepack"
```

---

## ICESEE

```
apptainer exec combined-env.sif \
with-icesee python -c "import ICESEE"
```

---

## ISSM

```
apptainer exec combined-env.sif \
with-issm matlab -batch "issmversion"
```

---

# Running ISSM with External MATLAB

Example cluster MATLAB installation

```
/apps/MATLAB/R2024b
```

Run:

```
apptainer exec \
--bind /apps/MATLAB/R2024b:/opt/matlab/R2024b \
--env MATLABROOT=/opt/matlab/R2024b \
combined-env-external-matlab.sif \
with-issm matlab -batch "issmversion"
```

---

# Persistent Cache

The container automatically configures persistent caches.

Preferred location

```
/scratch/$USER/combined_cache
```

Fallback

```
/tmp/$USER/combined_cache
```

Created directories

```
pyop2
tsfc
xdg
```

These improve performance for

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

These wrappers automatically configure

* MPI
* PETSc
* library paths
* Python environments
* persistent caches

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

MATLAB licensing is configured through

```
MLM_LICENSE_FILE
```

Example

```
export MLM_LICENSE_FILE=1711@matlablic.ecs.gatech.edu
```

---

# Maintainer

Brian Kyanjo
Georgia Institute of Technology

