#!/bin/sh

sPath=$(cd $(dirname $0); pwd);
cd $sPath;

kill -s TERM $(cat /usr/local/services/star_server/svr80001/logic/lock/main_logic.lock);

make clean;
make;
#sleep 3;

mv $sPath/main_logic /usr/local/services/star_server/bin/logic/main_logic;

cd /usr/local/services/star_server/svr80001/logic/main_logic;
#../../../bin/logic/main_logic/main_logic ../conf/main_logic.ini ../conf/queue_pipe.ini 0 xxooxx.bin;
