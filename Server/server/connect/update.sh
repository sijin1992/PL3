#!/bin/sh

sPath=$(cd $(dirname $0); pwd);
cd $sPath;

kill -s TERM $(cat /usr/local/services/star_server/svr80001/logic/lock/connect.lock);
kill -s TERM $(cat /usr/local/services/star_server/svr80001/logic/lock/httpcb.lock);
#sleep 3;

make clean;
make;

mv $sPath/connect /usr/local/services/star_server/bin/logic/connect/;
mv $sPath/httpcb /usr/local/services/star_server/bin/logic/connect/;

cd /usr/local/services/star_server/svr80001/logic/conf;
../../../bin/logic/connect/connect connect.ini queue_pipe.ini;
../../../bin/logic/connect/httpcb httpcb.ini queue_pipe.ini;

