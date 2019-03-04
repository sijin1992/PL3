#!/bin/sh

sPath=$(cd $(dirname $0); pwd);
cd $sPath;

kill -s TERM $(cat /usr/local/services/star_server/svr80001/log/lock/logsvr.lock);
#sleep 3;

#make clean;
make;

mv $sPath/logsvr /usr/local/services/star_server/bin/log/logsvr/;

cd /usr/local/services/star_server/svr80001/log/conf;
../../../bin/log/logsvr/logsvr logsvr.ini queue_pipe.ini;
