#!/bin/sh

PROC_NAME=dbsvr
ROOT_DIR=..
LOCAL_CONF_DIR=../../../star_server_conf/db/
PROC_CONFIG=$LOCAL_CONF_DIR/dbsvr.ini
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

switch_debug()
{
	kill -s USR1 $THEPID
}

forcestop()
{
        killall -s TERM $PROC_NAME
}


info()
{
        killall -s USR2 $PROC_NAME
} 


if [ $# -lt 1 ]
then
	echo "$0 [start|stop|restart|format|debug|info|force]"
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
	 elif [ "$1" = "info" ]
        then
                info
	elif [ "$1" = "debug"  ]
        then
		switch_debug
        elif [ "$1" = "force" ]
        then
                forcestop
       else
       		echo "bad cmd"
	fi
fi

