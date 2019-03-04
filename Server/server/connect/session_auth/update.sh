#!/bin/sh

sPath=$(cd $(dirname $0); pwd);
cd $sPath;

kill -s TERM $(cat /usr/local/services/star_server/svr80001/logic/lock/session_auth.lock);
#sleep 3;

make clean;
make;

mv $sPath/session_auth /usr/local/services/star_server/bin/logic/connect/session_auth/;

cd /usr/local/services/star_server/svr80001/logic/conf;
../../../bin/logic/connect/session_auth/session_auth connect.ini queue_pipe.ini;
