#!/bin/sh

sPath=$(cd $(dirname $0); pwd);
cd $sPath;

cp proto/*.proto ./;
cp proto4server/*.proto ./;

make all;
mv -f *.pb /usr/local/services/star_server/bin/logic/main_logic/lua/protobuf;
