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

RUN mkdir -p /root/crawlout/trunk
RUN mkdir -p /root/crawlout/0.19

RUN mkdir -p /data/rcs
RUN mkdir -p /data/shared
RUN mkdir -p /data/webserver/game_data
WORKDIR /root
RUN git clone https://github.com/crawl/crawl.git

WORKDIR /root/crawl
RUN git submodule update --init

WORKDIR /root/crawl/crawl-ref/source
RUN make WEBTILES=y SAVEDIR=/data/trunk SHAREDDIR=/data/shared WEBDIR=/data/webserver/game_data

RUN cp crawl /root/crawlout/trunk

#RUN git checkout stone_soup-0.19
#WORKDIR /root/crawl
#RUN git submodule update --init
#WORKDIR /root/crawl/crawl-ref/source
#RUN make WEBTILES=y SAVEDIR=/data/0.19 SHARDDIR=/data/shared WEBDIR=/data/webdir
#RUN cp crawl /root/crawlout/0.19
#RUN cp webserver /root/crawlout/0.19

# URL you are serving on
RUN sed -i '/player_url/ s|None|http://192.168.99.100:8080|' /root/crawl/crawl-ref/source/webserver/config.py


#RUN git checkout master
WORKDIR /root/crawlout
CMD python /root/crawl/crawl-ref/source/webserver/server.py

VOLUME ["/data"]
EXPOSE 80 443

