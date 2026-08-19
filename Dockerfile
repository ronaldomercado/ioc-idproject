ARG REGISTRY=ghcr.io/epics-containers
ARG RUNTIME=${REGISTRY}/ioc-pmac-runtime:2026.6.1
ARG DEVELOPER=${REGISTRY}/ioc-pmac-developer:2026.6.1


##### build stage ##############################################################
FROM  ${DEVELOPER} AS developer

ARG IOC_VERSION=2026.7.31

# install java-related packages for vdct + flatdb
RUN apt-get update -y && \
    apt-get install -y  openjdk-25-jdk-headless maven && \
    rm -rf /var/lib/apt/lists/*

# build vdct
COPY vdct/patchScript.txt /epics/patchScript.txt
RUN cd /epics && \
    git clone https://github.com/epics-extensions/VisualDCT.git \
    -b v2.8.4 extensions/VisualDCT && \
    cd /epics/extensions/VisualDCT && \
    mvn install && \
    ln -s target/VisualDCT-2.8.4.jar VisualDCT.jar && \
    patch < /epics/patchScript.txt && \
    rm /epics/patchScript.txt

ENV PATH=$PATH:/epics/extensions/VisualDCT

# The devcontainer mounts the project root to /epics/generic-source
# Using the same location here makes devcontainer/runtime differences transparent.
ENV SOURCE_FOLDER=/epics/generic-source
# connect ioc source folder to its know location
RUN ln -s ${SOURCE_FOLDER}/ioc ${IOC}

# get the current versions of pvi and ibek
COPY requirements.txt requirements.txt
RUN uv pip install --upgrade -r requirements.txt

WORKDIR ${SOURCE_FOLDER}/ibek-support

COPY ibek-support/_ansible _ansible
ENV PATH=$PATH:${SOURCE_FOLDER}/ibek-support/_ansible

COPY ibek-support/ether_ip/ ether_ip
RUN ansible.sh ether_ip

COPY ibek-support/idMotion/ idMotion
RUN ansible.sh idMotion

COPY ibek-support/idPLC/ idPLC
RUN ansible.sh idPLC

COPY ibek-support/dlsPLC/ dlsPLC
RUN ansible.sh dlsPLC

# get the ioc source and build it
COPY ioc ${SOURCE_FOLDER}/ioc
RUN ansible.sh ioc

# generate a manifest of installed EPICS modules and python packages
COPY scripts/generate_manifest.py /tmp/generate_manifest.py
RUN python3 /tmp/generate_manifest.py "${IOC_VERSION}"

##### runtime preparation stage ################################################
FROM developer AS runtime_prep

# get the products from the build stage and reduce to runtime assets only
# /python is created by uv and is needed in the runtime target
RUN ibek ioc extract-runtime-assets /assets /python

##### runtime stage ############################################################
FROM ${RUNTIME} AS runtime

# get runtime assets from the preparation stage
COPY --from=runtime_prep /assets /

# install runtime system dependencies, collected from install.sh scripts
RUN ibek support apt-install-runtime-packages

# launch the startup script with stdio-expose to allow console connections
CMD ["bash", "-c", "${IOC}/start.sh"]
