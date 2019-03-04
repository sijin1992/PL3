
local tips = require("util.TipsMessage"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local WangZuoBuffAppoint = class("WangZuoBuffAppoint", cc.load("mvc").ViewBase)

local player = require("app.Player"):getInstance()

local app = require("app.MyApp"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

WangZuoBuffAppoint.RESOURCE_FILENAME = "PlanetScene/wangzuo/appointLayer.csb"

WangZuoBuffAppoint.RUN_TIMELINE = true

WangZuoBuffAppoint.NEED_ADJUST_POSITION = true

WangZuoBuffAppoint.RESOURCE_BINDING = {
	--["Button_1"]   = {["varname"] = "btn"},
}

function WangZuoBuffAppoint:onCreate( data )
	self.data_ = data
end

function WangZuoBuffAppoint:onEnter()

end

function WangZuoBuffAppoint:onExit()
	
end

function WangZuoBuffAppoint:onEnterTransitionFinish()
	printInfo("WangZuoBuffAppoint:onEnterTransitionFinish()")
	local rn = self:getResourceNode()
	local conf = CONF.TITLE_BUFF.get(self.data_.id)
	self.svd_ = require("util.ScrollViewDelegate"):create(rn:getChildByName('list'),cc.size(0,5), cc.size(815,110))
	rn:getChildByName("list"):setScrollBarEnabled(false)
	rn:getChildByName("title"):setString(CONF:getStringValue("appointing_a_player"))
	rn:getChildByName("close"):addClickEventListener(function()
		self:getApp():removeTopView()
		end)
	rn:getChildByName("shuaxin"):addClickEventListener(function()
		local strData = Tools.encode("GetFriendsInfoReq", {
				type = 4,
				index = 1,
				num = 5,
			})
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_FRIENDS_INFO_REQ"),strData)
		gl:retainLoading()
		end)
	rn:getChildByName("shuaxin"):getChildByName("text"):setString(CONF:getStringValue("shuaxin"))
	rn:getChildByName("find"):addClickEventListener(function()
		if rn:getChildByName("find_text"):getText() == "" then
			tips:tips(CONF:getStringValue("ContentIsEmpty"))
			return
		end
		local strData = Tools.encode("GetFriendsInfoReq", {
			type = 0,
			nickname = rn:getChildByName("find_text"):getText(),
		})
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_FRIENDS_INFO_REQ"),strData)
		gl:retainLoading()
		end)
	rn:getChildByName("find"):getChildByName("text"):setString(CONF:getStringValue("search"))
	local strData = Tools.encode("GetFriendsInfoReq", {
			type = 4,
			index = 1,
			num = 5,
		})
	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_FRIENDS_INFO_REQ"),strData)
	gl:retainLoading()

	local placeHolder = rn:getChildByName("find_text")
	-- local inputText = rn:getChildByName("input_text")
	local placeHolderColor = placeHolder:getTextColor()
	local fontColor = placeHolder:getTextColor()	
	local fontName = placeHolder:getFontName()
	local fontSize = placeHolder:getFontSize()

	local back = rn:getChildByName(string.format("text_back"))

	local edit = ccui.EditBox:create(back:getContentSize(),"Common/ui/chat_bottom.png")
	rn:addChild(edit)
	edit:setPosition(cc.p(back:getPosition()))
	edit:setPlaceHolder(CONF:getStringValue("InputPlayerName"))
	edit:setInputFlag(cc.EDITBOX_INPUT_FLAG_INITIAL_CAPS_WORD)
	edit:setPlaceholderFont(fontName,fontSize)
	edit:setPlaceholderFontColor(fontColor)
	edit:setFont(fontName,fontSize)
	edit:setFontColor(fontColor)
	edit:setReturnType(1)
	edit:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
	edit:setName("find_text")

	back:removeFromParent()
	
	placeHolder:removeFromParent()

	local function recvMsg()
		print("WangZuoBuff:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_FRIENDS_INFO_RESP") then
			gl:releaseLoading()
			local proto = Tools.decode("GetFriendsInfoResp",strData)
			print("GetFriendsInfoResp result",proto.result, proto.type)
			if proto.result == 0 then
				self.svd_:clear()
				for k,v in ipairs(proto.list) do
					local node = cc.CSLoader:createNode("FriendLayer/enemy_list_item.csb")
					node:getChildByName("botton"):loadTextures("Common/newUI/button_blue.png","Common/newUI/button_blue_light.png")
					node:getChildByName("botton"):getChildByName("text"):setString(CONF:getStringValue("appointment"))
					node:getChildByName("botton"):addClickEventListener(function()
						if player:getName() == v.user_name then
							tips:tips(CONF:getStringValue("cant_appointment_own"))
							return
						end
						local strData = Tools.encode("PlanetWangZuoTitleReq", {
								type = 2,
								user_name = v.user_name,
								title = self.data_.id,
							})
						GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PANET_WANGZUO_TITLE_REQ"),strData)
						gl:retainLoading()
						end)
					node:getChildByName("name"):setString(v.nickname)
					node:getChildByName("lv_num"):setString(v.level)
					node:getChildByName("fight_num"):setString(v.power)
					if v.group_nickname and v.group_nickname ~= "" then
						node:getChildByName("xingmeng"):setString(CONF:getStringValue("covenant")..":")
						node:getChildByName("xingmeng_name"):setString(v.group_nickname)
					else
						node:getChildByName("xingmeng"):setVisible(false)
						node:getChildByName("xingmeng_name"):setVisible(false)
					end
					self.svd_:addElement(node)

				end
			else
				if proto.type == 0 then
					tips:tips(CONF:getStringValue("NotExist"))
				end
        	end
        elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_PANET_WANGZUO_TITLE_RESP") then
        	gl:releaseLoading()
        	local proto = Tools.decode("PLanetWangZuoTitleResp",strData)
			print("PLanetWangZuoTitleResp result",proto.result, proto.type)
			if proto.result == 0 then
				if  proto.type == 2 then
					tips:tips(CONF:getStringValue("appointment_success"))
					self:getApp():removeTopView()
				end
			end
		end
	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)
end

function WangZuoBuffAppoint:onExitTransitionStart()

	printInfo("WangZuoBuffAppoint:onExitTransitionStart()")
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
end

return WangZuoBuffAppoint