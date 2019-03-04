cd /usr/local/services/star_server
find . -name "*.log" -exec rm {} \;
cd ./centre
./svr_centre.sh start
cd ../svr1/logic
./doLogic.sh start
cd ../db
./doDB.sh start
cd ..
