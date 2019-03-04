#!/bin/sh
sPath=$(cd $(dirname $0); pwd);
#echo $sPath;

clear()
{
	for i in 1
	do
		cd ${sPath}"/svr8000"${i}"/monitor/"
	
		sh cleanup.sh
	done
}
start()
{
	for i in 1
	do
		cd $sPath;
		cd svr8000$i/logic/main_logic/;
		sh main_logic.sh restart;
		sleep 3
	done
}

centre()
{
	cd $sPath;
	cd centre/
	sh svr_centre.sh restart
}

clear
sleep 2
start
sleep 3
centre
