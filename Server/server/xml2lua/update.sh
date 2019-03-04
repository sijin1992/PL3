#!/bin/sh

sPath=$(cd $(dirname $0); pwd);
cd $sPath;

make clean;
make;

mv -f all_config.lua /usr/local/services/star_server/bin/logic/main_logic/lua;
mv -f *.lua          /usr/local/services/star_server/bin/logic/main_logic/lua/config;

