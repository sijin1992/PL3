#!/bin/sh

sPath=$(cd $(dirname $0); pwd);
cd $sPath;

kill -s TERM $(cat /usr/local/services/star_server/svr80001/db/lock/mysql_helper.lock);
kill -s TERM $(cat /usr/local/services/star_server/svr80001/db/lock/dbsvr.lock);
#sleep 3;

make clean;
make;

mv $sPath/mysql_helper /usr/local/services/star_server/bin/db/dbsvr/;
mv $sPath/dbsvr /usr/local/services/star_server/bin/db/dbsvr/;

cd /usr/local/services/star_server/svr80001/db/conf;
../../../bin/db/dbsvr/mysql_helper dbsvr.ini queue_pipe.ini;
../../../bin/db/dbsvr/dbsvr dbsvr.ini queue_pipe.ini 0;
