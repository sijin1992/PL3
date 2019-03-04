#!/bin/sh

doall()
{
	cd dbsvr
	./mysql_helper.sh $1
	./tc_helper.sh $1
	./dbsvr.sh $1
	cd ../ 

	cd tcplinker
	./tcplinker.sh $1
	cd ../
}

if [ $# -lt 1 ]
then
        echo "$0 [start|stop|debug]"
else
        doall $1 
fi
