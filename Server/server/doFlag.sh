#!/bin/sh

doall()
{
	cd flagsvr
	./flagsvr.sh $1
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
