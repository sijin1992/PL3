#!/bin/sh

PROC_NAME=main_robot
SEVERS="10.10.1.25 2001"
OUTPUTFILE=robot.out
USER_PER_ROBOT=20
ROBOT_NAME="newrobot"

start()
{
	echo "with robotnum $1"
	./$PROC_NAME $1 $USER_PER_ROBOT $ROBOT_NAME $SEVERS > $OUTPUTFILE &
}

stop()
{
	killall -TERM $PROC_NAME
}

forcestop()
{
        killall -9 $PROC_NAME
}

if [ $# -lt 1 ]
then
	echo "$0 [start|stop|forcestop]"
else
	if [ "$1" = "start" ]
	then
		if [ $# -lt 2 ]
		then
			echo "$0 start robotnum"
		else
			start $2
		fi
	elif [ "$1" = "stop" ]
	then
		stop
	elif [ "$1" = "force" ]
        then
                forcestop
        else
        	echo "$0 [start|stop|forcestop]"
        fi
fi

