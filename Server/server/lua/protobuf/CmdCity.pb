
³
CmdCity.proto
Item.proto
City.protoUserSync.proto",
CityRoomBuildReq
type (

id ("c
CityRoomBuildResp
result (
	room_info (2	.CityRoom 
	city_room (2.CityRoomInfo"!
CityRoomIncomeReq
type ("F
CityRoomIncomeResp
result ( 
	city_room (2.CityRoomInfo".
CityRoomLevelupReq
type (

id ("e
CityRoomLevelupResp
result (
	room_info (2	.CityRoom 
	city_room (2.CityRoomInfo"+
CityTreeCropReq
type (

id ("j
CityTreeCropResp
result ("

fruit_info (2.CityTreeFruit"

fruit_list (2.CityTreeFruit""
CityTreeLevelupReq
type ("G
CityTreeLevelupResp
result ( 
	city_tree (2.CityTreeInfo"-
DefenceLevelupReq
type (

id ("H
DefenceLevelupResp
result ("
defence_list (2.CityDefence"
FarmLevelupReq
type ("?
FarmLevelupResp
result (
	farm_info (2	.FarmInfo"
FarmPlantReq
type ("
FarmPlantResp
result ("
MineLevelupReq
type ("!
MineLevelupResp
result ("

MineDigReq
type (";
MineDigResp
result (
	mine_info (2	.MineInfo"$
GetHomeSatusReq
	home_type ("@
GetHomeSatusResp
result (
	user_sync (2	.UserSync"$
GetResourceReq

land_index ("€
GetResourceResp
result (
	user_sync (2	.UserSync

land_index (
resource_type (
resource_num (">
UpgradeResLandReq

land_index (
resource_type ("„
UpgradeResLandResp
result (
	user_sync (2	.UserSync

land_index (
resource_type (
building_time ("&
RemoveResLandReq

land_index (":
RemoveResLandResp
result (
building_time ("*
CancelResBuildingReq

land_index ("E
CancelResBuildingResp
result (
	user_sync (2	.UserSync"%
SpeedUpBuildReq

land_index ("T
SpeedUpBuildResp
result (
	user_sync (2	.UserSync

land_index (