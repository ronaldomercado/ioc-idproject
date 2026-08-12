volumes="
-v /home/tempuser/dev:/workspace
-v /home/tempuser/dev/ts02k-motion:/epics/ts02k-motion
"
opts="
--net host
--security-opt=label=type:container_runtime_t
"
podman run -dit ${volumes} localhost/ec_test:latest 
