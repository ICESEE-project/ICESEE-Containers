# ISSM Container

This directory provides two ISSM container variants:

- **MATLAB runtime image**: includes MATLAB in the final runtime image
- **No-MATLAB runtime image**: builds ISSM with MATLAB in the builder stage, but the final runtime image is a lightweight Ubuntu image that expects MATLAB to be provided by the host or cluster

It also provides matching Apptainer definition recipes for cluster use.