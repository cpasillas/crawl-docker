FROM python:2

ENV LC_ALL C.UTF-8

# Installing crawl deps
RUN apt-get update && \
    apt-get -y install apt-utils \
                       build-essential \
                       libncursesw5-dev \
                       bison \
                       flex \
                       liblua5.1-0-dev \
                       libsqlite3-dev \
                       libz-dev \
                       pkg-config \
                       libsdl2-image-dev \
                       libsdl2-mixer-dev \
                       libsdl2-dev \
                       libfreetype6-dev \
                       libpng-dev \
                       ttf-dejavu-core && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Installing utility programs
RUN apt-get update
RUN apt-get install -y vim
RUN apt-get install -y less

# Installing tornado webserver
RUN pip install tornado==3.2.2

# Setting directory path variables
ENV ROOTDIR /root
ENV CRAWL_OUT_DIR ${ROOTDIR}/crawlout
ENV CRAWL_ROOT_DIR ${ROOTDIR}/crawl
ENV CRAWL_SRC_DIR ${CRAWL_ROOT_DIR}/crawl-ref/source
ENV CRAWL_BUILD_SCRIPT ${ROOTDIR}/build_crawl.sh

ENV DOCKERDATADIR /data
ENV SAVEDIR ${DOCKERDATADIR}/saves

RUN mkdir ${DOCKERDATADIR}

ADD build_crawl.sh ${CRAWL_BUILD_SCRIPT}
RUN chmod 777 ${CRAWL_BUILD_SCRIPT}


# Movable line to dirty docker cache.
ARG CACHE_DATE=2017-01-20


# Cloning cpasillas fork for Crawl special versions
WORKDIR ${ROOTDIR}
RUN git clone https://github.com/cpasillas/crawl.git

# Building turkey
WORKDIR ${CRAWL_ROOT_DIR}
RUN ${CRAWL_BUILD_SCRIPT} turkey-0.20 ${CRAWL_OUT_DIR}/turkey-0.20 ${SAVEDIR}/turkey-0.20

ENV SERVER_DIR ${CRAWL_OUT_DIR}/webserver
# "Copying over turkey's webserver to ${SERVER_DIR}"
WORKDIR ${CRAWL_SRC_DIR}
RUN cp -R webserver ${SERVER_DIR}

# Deleting source for special Crawl versions at ${CRAWL_ROOT_DIR}/*
RUN rm -rf ${CRAWL_ROOT_DIR}/*

# Cloning crawl config.py base for webserver
WORKDIR ${ROOTDIR}
RUN git clone https://github.com/cpasillas/crawl-web-config.git

ENV WEB_CONFIG ${SERVER_DIR}/config.py
# Copying personal config into crawl source dir for running web server
RUN cp /root/crawl-web-config/config.py ${WEB_CONFIG}
# String replacing important directories in config.py:
# "{{root_data_dir}} -> ${DOCKERDATADIR}"
# "{{root_binary_dir}} -> ${CRAWL_OUT_DIR}"
# "{{root_webserver_dir}} -> ${SERVER_DIR}"
# "{{util_dir}} -> ${SERVER_DIR}"
RUN sed -i "s:{{root_data_dir}}:${DOCKERDATADIR}:" ${WEB_CONFIG}
RUN sed -i "s:{{root_binary_dir}}:${CRAWL_OUT_DIR}:" ${WEB_CONFIG}
RUN sed -i "s:{{root_webserver_dir}}:${SERVER_DIR}:" ${WEB_CONFIG}
RUN sed -i "s:{{util_dir}}:${SERVER_DIR}:" ${WEB_CONFIG}

# "Copying custom start script to webserver dir (specified as util_dir above)"
ENV WEB_INIT_SCRIPT ${SERVER_DIR}/webtiles-init-player.sh
RUN cp /root/crawl-web-config/webtiles-init-player.sh ${WEB_INIT_SCRIPT}
RUN chmod 755 ${WEB_INIT_SCRIPT}
# "String replacing important directory in webtile-init-player.sh"
# "{{data_root}} -> ${DOCKERDATADIR}"
RUN sed -i "s:{{data_root}}:${DOCKERDATADIR}:" ${WEB_INIT_SCRIPT}

# "Setting another thing that I don't know what it does yet"
RUN sed -i '/player_url/ s|None|"http://localhost"|' ${WEB_CONFIG}

WORKDIR ${SERVER_DIR}
# "Hang on to your butts..."
CMD python server.py

VOLUME ["/data"]
EXPOSE 80 443
