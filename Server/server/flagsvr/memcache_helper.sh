#!/bin/sh

PROC_NAME=memcache_helper
ROOT_DIR=..
PROC_CONFIG=$ROOT_DIR/conf/flagsvr.ini
PIPE_CONFIG=$ROOT_DIR/conf/queue_pipe.ini
THEPID=`cat $ROOT_DIR/lock/$PROC_NAME.lock`
start()
{
	./$PROC_NAME $PROC_CONFIG $PIPE_CONFIG 0
}

formatStart()
{
        ./$PROC_NAME $PROC_CONFIG $PIPE_CONFIG 1
}

stop()
{
	kill -s TERM $THEPID
}

forcestop()
{
        killall -s TERM $PROC_NAME
}


switch_debug()
{
	killall -s USR1 $PROC_NAME
}

if [ $# -lt 1 ]
then
	echo "$0 [start|stop|restart|format|debug]"
else
	if [ "$1" = "start" ]
	then
		start
	elif [ "$1" = "stop" ]
	then
		stop
	elif [ "$1" = "restart" ]
	then
		stop
		start
        elif [ "$1" = "format" ]
        then
                stop
                formatStart
	elif [ "$1" = "debug"  ]
        then
		switch_debug
	elif [ "$1" = "force" ]
        then
                forcestop
        fi
fi

