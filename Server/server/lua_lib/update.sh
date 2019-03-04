#!/bin/sh

sPath=$(cd $(dirname $0); pwd);
cd $sPath;

make clean;
make;

mv $sPath/*.so /usr/local/services/star_server/bin/logic/main_logic/lua/;
