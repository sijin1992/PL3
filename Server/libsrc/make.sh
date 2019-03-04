#!/bin/sh

MAKEDIR="binary codeset coding/base64 coding/url coding/html coding/md5 coding/sha1 random time shm mem_alloc net process_manager struct log ini lock mysql_wrap"
LIBDIR=../lib
LIBNAME=libxoxxoo.a

buildTarget()
{
	mkdir -p $LIBDIR/objs
	for dir in $MAKEDIR
	do
		make -C $dir
		if [ "$?" -eq "0" ]
		then
			echo "-----------------make $dir ok-----------------------"
			cp $dir/*.o $LIBDIR/objs/
		else
			echo "-----------------make $dir fail---------------------"
			exit
		fi
	done
	
        ar rcs $LIBDIR/$LIBNAME $LIBDIR/objs/*.o
}

cleanTarget()
{
	rm $LIBDIR/$LIBNAME
	rm $LIBDIR/objs/*.o
	for dir in $MAKEDIR
	do
		make -C $dir clean
	done
}

if [ $# -lt 1 ]
then
	echo "$0 [all|clean]"
else
	if [ "$1" = "all" ]
	then
		buildTarget
	elif [ "$1" = "clean" ]
	then
		cleanTarget
	fi
fi
