#!/bin/sh

sPath=$(cd $(dirname $0); pwd);
cd $sPath;

kill -s TERM $(cat /usr/local/services/star_server/ghttpcb/lock/httpcb.lock);
#sleep 3;

#make clean;
make;

mv $sPath/global_httpcb /usr/local/services/star_server/ghttpcb/;

cd /usr/local/services/star_server/ghttpcb/;
./global_httpcb conf/global_httpcb.ini;
