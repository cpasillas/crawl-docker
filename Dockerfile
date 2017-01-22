FROM python:2

ENV HOME /root
ENV LC_ALL C.UTF-8

RUN apt-get update && \
    apt-get -y install build-essential \
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

RUN pip install tornado==3.2.2

RUN mkdir /data

WORKDIR /root
# Crawl code for compilation
RUN git clone https://github.com/crawl/crawl.git

# Build Crawl Versions
RUN mkdir -p /root/crawlout/trunk
WORKDIR /root/crawl
RUN git submodule update --init

# Build Trunk
WORKDIR /root/crawl/crawl-ref/source
RUN make -j 4 WEBTILES=y SAVEDIR=/data/saves/trunk
RUN cp crawl /root/crawlout/trunk
RUN cp -R dat /root/crawlout/trunk

# Build 0.19
RUN mkdir -p /root/crawlout/0.19
WORKDIR /root/crawl
RUN git checkout stone_soup-0.19
RUN git submodule update --init
WORKDIR /root/crawl/crawl-ref/source
RUN make WEBTILES=y SAVEDIR=/data/saves/0.19 
RUN cp crawl /root/crawlout/0.19
RUN cp -R dat /root/crawlout/0.19

# Switch back to master for running the webserver later
RUN git checkout master

WORKDIR /root
RUN apt-get update
RUN apt-get install -y vim
ARG CACHE_DATE=2017-01-20
# Personal crawl config.py for webserver
RUN git clone https://github.com/cpasillas/crawl-web-config.git
# Copy personal config into crawl source dir for running web server
RUN cp /root/crawl-web-config/config.py /root/crawl/crawl-ref/source/webserver/config.py
RUN cp /root/crawl-web-config/webtiles-init-player.sh /root/crawl/crawl-ref/source/util/webtiles-init-player.sh
# URL you are serving on, changeable here for development purposes
RUN sed -i '/player_url/ s|None|"http://192.168.99.100:8080"|' /root/crawl/crawl-ref/source/webserver/config.py
WORKDIR /root/crawl/crawl-ref/source
CMD python ./webserver/server.py

VOLUME ["/data"]
EXPOSE 80 443

