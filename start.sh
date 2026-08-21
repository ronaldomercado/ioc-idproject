#!/bin/bash

# A launcher for the epics container 
thisdir=$(realpath $(dirname ${0}))

volumes="
-v=${thisdir}/..:/workspace
"

opts="
--net host
--security-opt=label=type:container_runtime_t
"
podman run -dit ${volumes} ${opts} --name=ts16k-ioc1 ghcr.io/ronaldomercado/ioc-idproject-developer:0.3
#podman run -dit ${volumes} ${opts} --name=ts16k-ioc1 localhost/k16ws
