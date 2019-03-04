#!/bin/sh

ISSUE_DIR=$1
SERVER_DIR=$2
mkdir -p $ISSUE_DIR
cp checkAll.sh $ISSUE_DIR/
cd $ISSUE_DIR
mkdir -p tools
cp $SERVER_DIR/tools/hash_tool $SERVER_DIR/tools/session_info $SERVER_DIR/tools/dbsvr_info $SERVER_DIR/tools/main_logic_info $SERVER_DIR/tools/pipe_info tools/
cp $SERVER_DIR/client_tool/new_client tools/
cp $SERVER_DIR/test/cryptpassword tools/
cp $SERVER_DIR/fixed_conf/policy.xml logic/conf
cp $SERVER_DIR/../libsrc/dirtyword/dirtyword.txt logic/conf
cd -
