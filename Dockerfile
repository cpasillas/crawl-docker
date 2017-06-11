FROM python:2

ENV HOME /root
ENV LC_ALL C.UTF-8

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

RUN pip install tornado==3.2.2

RUN mkdir /data

# Crawl code for compilation
WORKDIR /root
RUN git clone https://github.com/crawl/crawl.git

# Build Main Fork Crawl Versions

# Build Trunk
#WORKDIR /root/crawl
#RUN git submodule update --init
#RUN mkdir -p /root/crawlout/trunk
#WORKDIR /root/crawl/crawl-ref/source
#RUN make -j 4 WEBTILES=y SAVEDIR=/data/saves/trunk
#RUN cp crawl /root/crawlout/trunk
#RUN cp -R dat /root/crawlout/trunk

# Build 0.19
RUN mkdir -p /root/crawlout/0.19
WORKDIR /root/crawl
RUN git checkout stone_soup-0.19
RUN git submodule update --init
WORKDIR /root/crawl/crawl-ref/source
RUN make -j 4 WEBTILES=y SAVEDIR=/data/saves/0.19 
RUN cp crawl /root/crawlout/0.19
RUN cp -R dat /root/crawlout/0.19

# Build 0.20
RUN mkdir -p /root/crawlout/0.20
WORKDIR /root/crawl
RUN git checkout stone_soup-0.20
RUN git submodule update --init
WORKDIR /root/crawl/crawl-ref/source
RUN make -j 4 WEBTILES=y SAVEDIR=/data/saves/0.20 
RUN cp crawl /root/crawlout/0.20
RUN cp -R dat /root/crawlout/0.20

# Crawl code for special versions
WORKDIR /root
RUN mkdir customcrawl
WORKDIR /root/customcrawl
RUN git clone https://github.com/cpasillas/crawl.git


# Build Manta
RUN mkdir -p /root/crawlout/manta
WORKDIR /root/customcrawl/crawl
RUN git checkout manta
RUN git submodule update --init
WORKDIR /root/customcrawl/crawl/crawl-ref/source
RUN make -j 4 WEBTILES=y SAVEDIR=/data/saves/manta
RUN cp crawl /root/crawlout/manta
RUN cp -R dat /root/crawlout/manta



# Build Turkey
RUN mkdir -p /root/crawlout/turkey
WORKDIR /root/customcrawl/crawl
RUN git checkout turkey
RUN git submodule update --init
WORKDIR /root/customcrawl/crawl/crawl-ref/source
RUN make -j 4 WEBTILES=y SAVEDIR=/data/saves/turkey
RUN cp crawl /root/crawlout/turkey
RUN cp -R dat /root/crawlout/turkey


WORKDIR /root
RUN apt-get update
RUN apt-get install -y vim
RUN apt-get install -y less

# Movable line to dirty docker cache.
ARG CACHE_DATE=2017-01-20

# Personal crawl config.py for webserver
RUN git clone https://github.com/cpasillas/crawl-web-config.git

# Copy personal config into crawl source dir for running web server
RUN cp /root/crawl-web-config/config.py /root/crawl/crawl-ref/source/webserver/config.py
RUN cp /root/crawl-web-config/webtiles-init-player.sh /root/crawl/crawl-ref/source/util/webtiles-init-player.sh
#RUN cp /root/crawl-web-config/config.py /root/customcrawl/crawl/crawl-ref/source/webserver/config.py
#RUN cp /root/crawl-web-config/webtiles-init-player.sh /root/customcrawl/crawl/crawl-ref/source/util/webtiles-init-player.sh

# URL you are serving on, changeable here for development purposes
RUN sed -i '/player_url/ s|None|"http://localhost"|' /root/crawl/crawl-ref/source/webserver/config.py
#RUN sed -i '/player_url/ s|None|"http://localhost"|' /root/customcrawl/crawl/crawl-ref/source/webserver/config.py

WORKDIR /root/crawl/crawl-ref/source
#WORKDIR /root/customcrawl/crawl/crawl-ref/source

# Select branch for webserver.
#RUN git checkout turkey
#RUN git checkout master
RUN git checkout stone_soup-0.20
CMD python ./webserver/server.py

VOLUME ["/data"]
EXPOSE 80 443

