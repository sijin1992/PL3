#!/bin/sh

sPath=$(cd $(dirname $0); pwd);
cd $sPath;

kill -s TERM $(cat /usr/local/services/star_server/svr80001/logic/lock/gateway.lock);
#sleep 3;

make clean;
make;

mv $sPath/gateway /usr/local/services/star_server/bin/logic/connect/gateway/;

cd /usr/local/services/star_server/svr80001/logic/conf;
../../../bin/logic/connect/gateway/gateway gateway.ini queue_pipe.ini;
