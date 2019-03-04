#!/bin/sh

PROC_NAME=gateway
ROOT_DIR=../..
LOCAL_CONF_DIR=../../../../star_server_conf/logic/
PROC_CONFIG=$LOCAL_CONF_DIR/gateway.ini
PIPE_CONFIG=$ROOT_DIR/conf/queue_pipe.ini
THEPID=`cat $ROOT_DIR/lock/$PROC_NAME.lock`
start()
{
	./$PROC_NAME $PROC_CONFIG $PIPE_CONFIG > /dev/null
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
#mutil proc
        killall -s USR1 $PROC_NAME
}

if [ $# -lt 1 ]
then
	echo "$0 [start|stop|restart|debug|force]"
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

