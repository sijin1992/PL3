#!/bin/sh

sPath=$(cd $(dirname $0); pwd);
cd $sPath;
cd ..;

tar czf star.tgz star --exclude=.svn --exclude=lib --exclude=*.o --exclude=*.so --exclude=*.a
