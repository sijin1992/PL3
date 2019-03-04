#!/bin/sh

sPath=$(cd $(dirname $0); pwd);
cd $sPath;

kill -s TERM $(cat /usr/local/services/star_server/centre/lock/svr_centre.lock);
#sleep 3;

#make clean;
make;

mv $sPath/svr_centre /usr/local/services/star_server/centre/;

cd /usr/local/services/star_server/centre/;
./svr_centre conf/svr_centre.ini;
