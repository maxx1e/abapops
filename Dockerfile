FROM debian:stable-slim

LABEL maintaiter="Jakub Filak <jakub.filak@sap.com>"

RUN apt-get update && apt-get install -y --no-install-recommends curl jq ca-certificates tar python3 python3-requests python3-openssl python3-pip && \
    rm -rf /var/lib/apt/lists/*

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

# Optional Volume for the NW RFC Library
VOLUME /usr/local/sap/nwrfcsdk/lib
# Instal python pyRFC module
RUN pip3 install https://github.com/SAP/PyRFC/releases/download/2.0.1/pyrfc-2.0.1-cp37-cp37m-linux_x86_64.whl
# Download sapcli
RUN curl -kL https://github.com/jfilak/sapcli/archive/master.tar.gz | tar -C /opt/ -zx
# Provide Symbol links to the py RFC library and create bin label for sapcli
RUN ln -sf /opt/sapcli-master/sap /usr/local/lib/python3.7/dist-packages/ && \
    ln -sf /opt/sapcli-master/bin/sapcli /bin/sapcli
# Smoke Test
RUN sapcli --help
# Handle user permissions uid 1001 as in Azure pipelines
RUN echo "[INFO] Handle users permission." && \
    useradd --home-dir "${SAP_USER_HOME}" --create-home --shell /bin/bash --user-group --uid 1001 --comment 'DevOps SAP tool' --password "$(echo WeLoveSap |openssl passwd -1 -stdin)" sapper && \
    # Allow anybody to write into the user HOME
    chmod a+w "${SAP_USER_HOME}"
# Copy certs chain. Can be commented, and than volume attached to this path
COPY /certs "${SAP_USER_HOME}"
USER sapper

WORKDIR /var/tmp
