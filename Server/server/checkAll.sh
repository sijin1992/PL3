#!/bin/sh


if [ $# -lt 1 ]
then
	echo "$0 [lock dir]"
else
	for LOCK_FILE in `ls $1/*.lock`
	do
		ps -p `cat $LOCK_FILE` | grep -v PID
	done
fi
