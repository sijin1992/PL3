if not json then
	require "cocos.cocos2d.json"
end

local MyApp = class("MyApp", cc.load("mvc").AppBase)

local function registerAllProtobuf()
	
	local pbAllName = {
		"cmd_define.pb",
		"AirShip.pb",
		"Item.pb",
		"Stage.pb",
		"OtherInfo.pb",
		"PveInfo.pb",
		"PvpInfo.pb",
		"Planet.pb",
		"Mail.pb",
		"FlagShip.pb",
		"Weapon.pb",
		"Equip.pb",
		"Home.pb",
		"Trial.pb",
		"Activity.pb",
		"Group.pb",
		"Building.pb",
		"UserInfo.pb",
		"Slave.pb",
		"UserSync.pb",
		"CmdLogin.pb",
		"CmdWeapon.pb",
		"CmdPve.pb",
		"CmdPvp.pb",
		"CmdUser.pb",
		"CmdSync.pb",
		"CmdEquip.pb",
		"CmdBuilding.pb",
		"CmdTrial.pb",
		"CmdHome.pb",
		"CmdMail.pb",
		"heartBeatResp.pb",
		"CmdArena.pb",
		"CmdGroup.pb",
		"CmdPlanet.pb",
		"CmdSlave.pb",
		"CmdActivity.pb",
	}
	local pb = require "protobuf"
	for i=1, #pbAllName do

		--local fullpath = cc.FileUtils:getInstance():fullPathForFilename()
		--Tools.register_file(fullpath)
		local buffer = GameHandler.handler_c.readFile("src/protobuf_messages/"..pbAllName[i])
		pb.register(buffer)

	end
end

function MyApp:onCreate()
	math.newrandomseed()
	registerAllProtobuf()
end

function MyApp:getInstance()
	if self.instance == nil then
		self.instance = self:create()
	end  
		
	return self.instance  
end 

return MyApp
