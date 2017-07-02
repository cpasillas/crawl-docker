#!/bin/bash
git checkout $1
git submodule update --init
mkdir -p $2
cd crawl-ref/source
make clean
make -j 4 WEBTILES=y SAVEDIR=$3
cp crawl $2
cp -R dat $2
