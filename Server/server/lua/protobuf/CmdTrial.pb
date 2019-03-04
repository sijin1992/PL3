
Ò	
CmdTrial.protoAirShip.proto
Item.protoTrial.protoUserSync.proto"1
TrialAddTicketReq
item_id (
num ("V
TrialAddTicketResp
result (
	user_sync (2	.UserSync

ticket_num (" 
TrialGetTimesReq
type ("7
TrialGetTimesResp
result (

ticket_num ("=
TrialAreaReq
type (
area_id (
lineup ("=
TrialAreaResp
result (
	user_sync (2	.UserSync"$
TrialGetRewardReq
copy_id ("S
TrialGetRewardResp
result (
	user_sync (2	.UserSync
copy_id ("E
TrialBuilding
	user_name (	
lineup (
	id_lineup ("+
TrialGetBuildingInfoReq
level_id ("_
TrialGetBuildingInfoResp
result (
type (%
building_info (2.TrialBuilding"G
TrialPveStartReq
type (
level_id (
target_name (	"°
TrialPveStartResp
result (
	user_sync (2	.UserSync
attack_list (2.AirShip
hurter_list (2.AirShip
level_id (
hp_list (
type ("Q
TrialPveEndReq
level_id (
result (
star (
hp_list ("„
TrialPveEndResp
result (
	user_sync (2	.UserSync
level_id (
reward_flag (
get_item_list (2.Pair