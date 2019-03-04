local pb = require "protobuf"
local proto_path = "../../../bin/logic/main_logic/lua/protobuf/"

pb.register_file(proto_path.."AirShip.pb")
pb.register_file(proto_path.."Item.pb")
pb.register_file(proto_path.."Stage.pb")
pb.register_file(proto_path.."OtherInfo.pb")
pb.register_file(proto_path.."Activity.pb")
pb.register_file(proto_path.."PveInfo.pb")
pb.register_file(proto_path.."PvpInfo.pb")
pb.register_file(proto_path.."Planet.pb")
pb.register_file(proto_path.."Mail.pb")
pb.register_file(proto_path.."FlagShip.pb")
pb.register_file(proto_path.."Weapon.pb")
pb.register_file(proto_path.."Equip.pb")
pb.register_file(proto_path.."Group.pb")
pb.register_file(proto_path.."Home.pb")

pb.register_file(proto_path.."Building.pb")
pb.register_file(proto_path.."Trial.pb")
pb.register_file(proto_path.."UserInfo.pb")
pb.register_file(proto_path.."gm_cmd.pb")

function do_send_mail(user_name, req_buff, user_buff, mail_buff)

	local req = pb.decode("DBSendMailReq", req_buff)
	local user_info = pb.decode("UserInfo", user_buff)
	local mail_list = pb.decode("MailList", mail_buff)
	if (rawget(mail_list, "mail_list")) == nil then
		mail_list.mail_list = {}
	end
	local t = req.time
	if req.type == 10 then 
		t = 0
	elseif t > 0 then 
		t = os.time() + t * 60 
	end
	local mailCount = #mail_list.mail_list

	local guid = 1
	if mailCount > 0 then
		guid = mail_list.mail_list[mailCount].guid + 1
	end


	mail = {
		type = req.type,
		from = req.from,
		subject = req.subject,
		message = string.gsub(string.gsub(req.message, "\n", "<$>"),"\r",""),
		stamp = os.time(),
		guid = guid,
		expiry_stamp = t,
		tid = 0,
		item_list = req.item_list,
	}

	table.insert(mail_list.mail_list, mail)

	user_buff = pb.encode("UserInfo", user_info)
	mail_buff = pb.encode("MailList", mail_list)
	return user_buff, mail_buff
end