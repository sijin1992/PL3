local ArenaRecordLayer = class("ArenaRecordLayer", cc.load("mvc").ViewBase)

local gl = require("util.GlobalLoading"):getInstance()

ArenaRecordLayer.RESOURCE_FILENAME = "ArenaScene/ArenaRecordLayer.csb"
ArenaRecordLayer.NEED_ADJUST_POSITION = true

ArenaRecordLayer.RESOURCE_BINDING = {
	["close"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

function ArenaRecordLayer:OnBtnClick(event)
	if event.name == "ended" then

		if event.target:getName() == "close" then
			playEffectSound("sound/system/return.mp3")
			self:getApp():removeTopView() 
    		end
	end
end

local function createElement(info)

	local node = require("app.ExResInterface"):getInstance():FastLoad("ArenaScene/ArenaRecordInfo.csb")

	local flag = info.result == 1 and  0 or 1
	
	node:getChildByName("result_"..flag):setVisible(false)
	node:getChildByName("result_icon_"..flag):setVisible(false)

	node:getChildByName("result_"..info.result):setString(CONF:getStringValue(info.result == 1 and "win" or "failed"))
	print("hehe", info.other_user_info.icon_id)
	node:getChildByName("headImage"):loadTexture("HeroImage/"..info.other_user_info.icon_id..".png")

	node:getChildByName("lv"):setString("Lv."..info.other_user_info.level)

	local name = info.other_user_info.nickname
	if info.other_user_info.group_nickname ~= "" and info.other_user_info.group_nickname ~= nil then
		name = "[" .. info.other_user_info.group_nickname .. "]  " .. name 
	end
	node:getChildByName("name"):setString(name)

	node:getChildByName("score"):setString(CONF:getStringValue("score") .. " +".. info.add_score)
	node:getChildByName("point"):setString(CONF:getStringValue("honor") .. " +".. info.add_point)

	node:getChildByName("time"):setString(os.date("%m/%d %H:%M:%S", info.time))


	return node
end

function ArenaRecordLayer:resetList(data)
	self.record_data = data

	if Tools.isEmpty(self.record_data.record_info_list) == true then
		return 
	end

	for i=#self.record_data.record_info_list, 1, -1 do
		self.svd_:addElement(createElement(self.record_data.record_info_list[i]))
	end
end

function ArenaRecordLayer:onEnterTransitionFinish()
	printInfo("ArenaRecordLayer:onEnterTransitionFinish()")

	local rn = self:getResourceNode()

	rn:getChildByName("title"):setString(CONF:getStringValue("arena_record_title"))

	self.svd_ = require("util.ScrollViewDelegate"):create(rn:getChildByName("scroll"),cc.size(0,2), cc.size(671,98))
	self.svd_:getScrollView():setScrollBarEnabled(false)

	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ARENA_INFO_REQ"),Tools.encode("ArenaInfoReq", {
		type = 3,
	}))
	gl:retainLoading()


	local function onTouchBegan(touch, event)
		
		return true
	end

	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(true)
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)

	local function recvMsg()
		print("ArenaRecordLayer:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_ARENA_INFO_RESP") then
			gl:releaseLoading()
			local proto = Tools.decode("ArenaInfoResp",strData)

			if proto.result ~= 0 then
				return
			end
			
			if Tools.isEmpty(proto.record_list) == true then
				return
			end

			self:resetList(proto.record_list)
		end
	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)
end


function ArenaRecordLayer:onExitTransitionStart()
	printInfo("ArenaRecordLayer:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
end

return ArenaRecordLayer