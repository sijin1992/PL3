./issue.sh centre
./issue.sh logic
./issue.sh db
rm -rf /usr/local/services/star_server/bin/logic/main_logic/lua
rsync -ar ../issue/ /usr/local/services/star_server/bin/
