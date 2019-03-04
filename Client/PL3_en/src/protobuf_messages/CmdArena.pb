
ä

CmdArena.protoAirShip.protoUserInfo.protoUserSync.protoOtherInfo.proto"Ç
ArenaInfoData
rank (
	user_name (	
power (
nickname (	
score (
icon_id (
level (
ship_guid_list (
ship_id_list	 (
ship_level_list
 ("—
ArenaRecordData
enemy_user_name (	'
other_user_info (2.OtherUserInfo
time (
	add_score (
	add_point (
result ("u
ArenaRecordDataList
	user_name (	
current_enemy_user_name (	*
record_info_list (2.ArenaRecordData"
ArenaInfoReq
type ("Ö
ArenaInfoResp
result (
	user_sync (2	.UserSync
my_info (2.ArenaInfoData"

their_info (2.ArenaInfoData
	cur_3_day (
last_reflesh ()
record_list (2.ArenaRecordDataList"/
ArenaAddTimesReq
type (
times ("A
ArenaAddTimesResp
result (
	user_sync (2	.UserSync"(
ArenaGetDailyRewardReq
result ("G
ArenaGetDailyRewardResp
result (
	user_sync (2	.UserSync"?
ArenaChallengeReq
type (
rank (
result ("´
ArenaChallengeResp
result (
	user_sync (2	.UserSync
attack_list (2.AirShip
hurter_list (2.AirShip
	get_score (
	add_point (
type ("
ArenaTitleReq
type (">
ArenaTitleResp
result (
	user_sync (2	.UserSyncBH