#!/bin/sh

ISSUE_PATH=../issue/

if [ $# -lt 1 ]
then
        echo "$0 [type=logic db flag all]"
else

    if [ "$1" = "logic" ]
    then
	./install.sh logic $ISSUE_PATH/logic 
    elif [ "$1" = "db" ]
    then
	./install.sh db $ISSUE_PATH/db 
	elif [ "$1" = "centre" ]
	then
	./install.sh centre $ISSUE_PATH/svr_centre
    elif [ "$1" = "all" ]
    then
	./install.sh logic $ISSUE_PATH/logic 
	./install.sh db $ISSUE_PATH/db 
	./install.sh centre $ISSUE_PATH/svr_centre
	cp client_tool/new_client $ISSUE_PATH/tools
    elif [ "$1" = "init" ]
    then
    	./initissue.sh $ISSUE_PATH `pwd`
    elif [ "$1" = "tool" ]
    then
        cp client_tool/new_client $ISSUE_PATH/tools
    else
    	echo "./issue init|logic|db|centre|all"
    fi
fi
