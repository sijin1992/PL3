#!/bin/sh

if [ $# -lt 2 ]
then
        echo "$0 [type=logic db flag] [dir] "
else 
    	
    DESDIR=$2
    if [ "$1" = "logic" ]
    then
	mkdir -p $DESDIR/connect/session_auth
	mkdir -p $DESDIR/connect/gateway
	cp connect/connect $DESDIR/connect/
	cp connect/policy $DESDIR/connect/
	cp connect/session_auth/session_auth $DESDIR/connect/session_auth/
	cp connect/gateway/gateway $DESDIR/connect/gateway/
	cp connect/httpcb $DESDIR/connect/
	mkdir -p $DESDIR/main_logic
	cp main_logic/main_logic $DESDIR/main_logic/
	mkdir -p $DESDIR/main_logic/lua
	rsync -ar --delete lua/ $DESDIR/main_logic/lua/
    elif [ "$1" = "db" ]
    then
	mkdir -p $DESDIR/dbsvr
	cp dbsvr/db_tool $DESDIR/dbsvr/
	cp dbsvr/dbsvr $DESDIR/dbsvr/
	cp dbsvr/mysql_helper $DESDIR/dbsvr/
	mkdir -p $DESDIR/dbsvr/lua
	rsync -ar --delete dbsvr/lua/ $DESDIR/dbsvr/lua/
    elif [ "$1" = "log" ]
    then
	mkdir -p $DESDIR/logsvr
        cp logsvr/logsvr $DESDIR/logsvr/
	cp tcplinker/tcplinker $DESDIR/
    elif [ "$1" = "centre" ]
    then
	cp svr_centre/svr_centre $DESDIR/
	mkdir -p $DESDIR/log
	mkdir -p $DESDIR/lock
	cp svr_centre/svr_centre.sh $DESDIR/
    fi
fi
