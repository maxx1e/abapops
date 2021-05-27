FROM debian:stable-slim

RUN apt-get update && apt-get install -y --no-install-recommends curl jq ca-certificates tar python3 python3-requests python3-openssl python3-pip python3-venv && \
    rm -rf /var/lib/apt/lists/* && \
    python_ver=$(python3 --version)
RUN mkdir -p /usr/local/sap/nwrfcsdk
ENV SAPNWRFC_HOME=/usr/local/sap/nwrfcsdk
ENV SAP_USER_HOME=/home/sapper

# RUN echo /usr/local/sap/nwrfcsdk/lib > /etc/ld.so.conf.d/nwrfcsdk.conf
# Not possible to use ldconfig without having the libraries in place as
# ldconfig builds its cache and the cache must be built by root
# and the container runs as sapper and we cannot ensure that ldconfig
# is executed upon container start.
# Hence use LD_LIBRARY_PATH
ENV LD_LIBRARY_PATH=/usr/local/sap/nwrfcsdk/lib

# Install yq processing tool
RUN curl -LJO https://github.com/mikefarah/yq/releases/download/3.4.1/yq_linux_amd64 && \
    chmod a+rx yq_linux_amd64 && \
    mv yq_linux_amd64 /opt/yq

# Optional Volume for the NW RFC Library
# VOLUME /usr/local/sap/nwrfcsdk/lib
# Instal python pyRFC module
RUN pip3 install https://github.com/SAP/PyRFC/releases/download/2.0.1/pyrfc-2.0.1-cp37-cp37m-linux_x86_64.whl

# Download and isntall sapcli. Activate virtual env for the python.
RUN curl -kL https://github.com/jfilak/sapcli/archive/master.tar.gz | tar -C /opt/ -zx
RUN cd /opt/sapcli-master && \
    python3 -m venv ve && \
    . ve/bin/activate

# Install python dependecies.
RUN cd /opt/sapcli-master && \
    pip3 install -r  requirements.txt

# Provide Symbol links to the py RFC library and create bin label for sapcli old lib link ln -sf /opt/sapcli-master/sap /usr/local/lib/python3.9/dist-packages && \
RUN ln -sf /opt/sapcli-master/sapcli /bin/sapcli && \
    ln -sf /opt/yq /bin/yq

# Smoke Test
RUN  yq -h && \
     sapcli --help

# Handle user permissions uid 1001 as in Azure pipelines
RUN echo "[INFO] Handle users permission." && \
    useradd --home-dir "${SAP_USER_HOME}" --create-home --shell /bin/bash --user-group --uid 1001 --comment 'DevOps SAP tool' --password "$(echo WeLoveSap |openssl passwd -1 -stdin)" sapper && \
    # Allow anybody to write into the user HOME
    chmod a+w "${SAP_USER_HOME}"
# USER sapper

WORKDIR /var/tmp
