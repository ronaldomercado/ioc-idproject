#!/bin/bash

# A launcher for the epics container 
thisdir=$(realpath $(dirname ${0}))

volumes="
-v=${thisdir}/..:/workspace
-v /home/tempuser/dev/ts02k-motion:/epics/ts02k-motion
"
opts="
--net host
--security-opt=label=type:container_runtime_t
"
podman run -dit ${volumes} ${opts} --name=ts16k-ioc1 localhost/ioc-idproject:latest 
