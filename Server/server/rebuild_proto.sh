cd /server/proto
sh update.sh

cd ../../


cd /server/dbsvr

cd /usr/local/services/star_server
cd ./centre
./svr_centre.sh stop
cd ../svr1/logic
./doLogic.sh stop
cd ../db
./doDB.sh stop