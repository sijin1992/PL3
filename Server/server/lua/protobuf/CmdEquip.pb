
ï

CmdEquip.protoEquip.proto
Item.protoUserSync.proto"H
EquipLevelUpReq

id (
	add_value (
add_new_player ("Q
EquipLevelUpResp
result (
equip (2.Equip
add_new_player ("
EquipEnchaseReq

id (""
EquipEnchaseResp
result ("T
ShipEquipReq
	ship_guid (
equip_index_list (
equip_guid_list ("ƒ
ShipEquipResp
result (
	user_sync (2	.UserSync
	ship_guid (
equip_index_list (
equip_guid_list ("5
StrengthEquipReq

equip_guid (
count ("U
StrengthEquipResp
result (
	user_sync (2	.UserSync

equip_guid ("*
ResolveEquipReq
equip_guid_list ("^
ResolveEquipResp
result (
	user_sync (2	.UserSync
get_item_list (2.Item"D
CreateEquipReq
type (
equip_id (

forge_guid ("W
CreateEquipResp
result (
	user_sync (2	.UserSync
get_equip_guid ("/
ResolveBlueprintReq
	item_list (2.Pair"b
ResolveBlueprintResp
result (
	user_sync (2	.UserSync
get_item_list (2.Pair"M
GemEquipReq
type (
	ship_guid (
index (
gem_id ("<
GemEquipResp
result (
	user_sync (2	.UserSync"2
	MixGemReq
gem_list (2.Gem
count ("i

MixGemResp
result (
	user_sync (2	.UserSync

mix_result (
remain_list (2.Gem