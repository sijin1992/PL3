#!/bin/sh

sPath=$(cd $(dirname $0); pwd);
cd $sPath;

kill -s TERM $(cat /usr/local/services/star_server/svr80001/db/lock/tcplinker.lock);
kill -s TERM $(cat /usr/local/services/star_server/svr80001/logic/lock/tcplinker.lock);
#sleep 3;

#make clean;
make;

cp $sPath/tcplinker /usr/local/services/star_server/bin/db/tcplinker/;
cp $sPath/tcplinker /usr/local/services/star_server/bin/logic/tcplinker/;

cd /usr/local/services/star_server/svr80001/db/conf;
../../../bin/db/tcplinker/tcplinker tcplinker.ini queue_pipe.ini;

cd /usr/local/services/star_server/svr80001/logic/conf;
../../../bin/logic/tcplinker/tcplinker tcplinker.ini queue_pipe.ini;
