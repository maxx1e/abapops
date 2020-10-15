FROM debian:stable-slim

LABEL maintaiter="Jakub Filak <jakub.filak@sap.com>"

RUN apt-get update && apt-get install -y --no-install-recommends curl jq ca-certificates tar python3 python3-requests python3-pyOpenSSL python3-pip && \
    rm -rf /var/lib/apt/lists/*l

RUN mkdir -p /usr/local/sap/nwrfcsdk
ENV SAPNWRFC_HOME=/usr/local/sap/nwrfcsdk

# RUN echo /usr/local/sap/nwrfcsdk/lib > /etc/ld.so.conf.d/nwrfcsdk.conf
# Not possible to use ldconfig without having the libraries in place as
# ldconfig builds its cache and the cache must be built by root
# and the container runs as sapper and we cannot ensure that ldconfig
# is executed upon container start.
# Hence use LD_LIBRARY_PATH
ENV LD_LIBRARY_PATH=/usr/local/sap/nwrfcsdk/lib

VOLUME /usr/local/sap/nwrfcsdk/lib

RUN pip3 install https://github.com/SAP/PyRFC/releases/download/2.0.1/pyrfc-2.0.1-cp37-cp37m-linux_x86_64.whl

RUN curl -kL https://github.com/jfilak/sapcli/archive/master.tar.gz | tar -C /opt/ -zx

RUN ln -sf /opt/sapcli-master/sap /usr/lib/python3.7/site-packages/ && \
    ln -sf /opt/sapcli-master/bin/sapcli /bin/sapcli

RUN sapcli --help
RUN adduser -c "SAP worker" -m -U sapper
USER sapper

WORKDIR /var/tmp
