#!/bin/sh

doall()
{
	cd main_logic
	./main_logic.sh $1
	cd ../

	cd tcplinker
	./tcplinker.sh $1
	cd ../

	cd connect
	./connect.sh $1
	./policy.sh $1
	./httpcb.sh $1
	cd session_auth
	./session_auth.sh $1
	cd ../gateway
	./gateway.sh $1
	cd ../../
}

if [ $# -lt 1 ]
then
        echo "$0 [start|stop|debug]"
else
        doall $1 
fi
