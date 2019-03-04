#!/bin/sh

PROC_NAME=main_logic
ROOT_DIR=..
LOCAL_CONF_DIR=../../../star_server_conf/logic/
PROC_CONFIG=$LOCAL_CONF_DIR/main_logic.ini
PIPE_CONFIG=$ROOT_DIR/conf/queue_pipe.ini
THEPID=`cat $ROOT_DIR/lock/$PROC_NAME.lock`
XXOOXX_BIN=../conf/xxooxx.bin
start()
{
	./$PROC_NAME $PROC_CONFIG $PIPE_CONFIG 0 $XXOOXX_BIN
}

formatStart()
{
	./$PROC_NAME $PROC_CONFIG $PIPE_CONFIG 1 $XXOOXX_BIN
}

gdb()
{
	echo "./$PROC_NAME $PROC_CONFIG $PIPE_CONFIG 0 $XXOOXX_BIN"
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
	kill -s USR1 $THEPID
}

switch_info()
{
	kill -s USR2 $THEPID
}

if [ $# -lt 1 ]
then
	echo "$0 [start|stop|restart|format|debug|force]"
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
	elif [ "$1" = "info"  ]
        then
		switch_info
	elif [ "$1" = "force" ]
        then
                forcestop
    elif [ "$1" = "gdb" ]
    then
        gdb
    else
    	echo "bag cmd"
    fi
fi

