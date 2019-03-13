local player = require("app.Player"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local ChatLayer = class("ChatLayer", cc.load("mvc").ViewBase)

local gl = require("util.GlobalLoading"):getInstance()

ChatLayer.RESOURCE_FILENAME = "ChatLayer/ChatLayer.csb"
ChatLayer.NEED_ADJUST_POSITION = true
ChatLayer.RESOURCE_BINDING = {
	["close"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

local selectSize = cc.size(93,27)
local NormalSize = cc.size(99,38)

local lan_1 = 904
local lan_2 = 580

function ChatLayer:OnBtnClick(event)
	printInfo(event.name)

	if event.name == "ended" then

		if event.target:getName() == "close" then
			playEffectSound("sound/system/return.mp3")
			self:removeFromParent()
		end
	end

end

function ChatLayer:onCreate(data)
	self.data_ = data
end

function ChatLayer:formatTime( time )
	local hour = math.floor(time/3600);
	local minute = math.fmod(math.floor(time/60), 60)
	local second = math.fmod(time, 60)

	if hour<10 then
		hour = string.format("0%s",hour)
	end

	if minute<10 then
		minute = string.format("0%s",minute)
	end

	if second<10 then
		second = string.format("0%s",second)
	end

	local rtTime = string.format("%s:%s", hour, minute)
	return rtTime
end


function ChatLayer:resetNode(typename,data)

	local rn = self:getResourceNode()

	if typename == "star" then
		if not self.hasGroup then
			tips:tips(CONF:getStringValue("you no group"))
			return
		end
	end

	if typename == "planet" then
		if not self.isStar then
			tips:tips(CONF:getStringValue("NotInPlanet"))
			return
		end
	end

	if typename == "slave" then
		if player:getLevel() < CONF.FUNCTION_OPEN.get("slave_open").GRADE then
			tips:tips(CONF:getStringValue("level_slave"))
			return
		end
	end

	if self.typename_ == typename then
		return
	end

	local function getTypeNum( name )
		if name == "world" then
			return 1 
		elseif name == "chat" then
			return 2 
		elseif name == "star" then
			return 3
		elseif name == "planet" then
			return 4
		elseif name == "slave" then
			return 5
		end
	end 

	-- local num = getTypeNum(self.typename_)
	if self.typename_ ~= "" then
		rn:getChildByName(self.typename_.."_text"):setTextColor(cc.c4b(209,209,209,255))
		-- rn:getChildByName(self.typename_.."_text"):enableShadow(cc.c4b(209,209,209,255),cc.size(0.5,0.5))
		rn:getChildByName(self.typename_.."_text"):setFontSize(23)
	end

	-- num = getTypeNum(typename)
	rn:getChildByName(typename.."_text"):setTextColor(cc.c4b(255,244,198,255))
	-- rn:getChildByName(typename.."_text"):enableShadow(cc.c4b(255,244,198,255),cc.size(0.5,0.5))
	rn:getChildByName(typename.."_text"):setFontSize(27)

	self.typename_ = typename

	-- if typename == "chat" then
	-- 	self:getResourceNode():getChildByName("lanbu"):setVisible(false)
	-- else
	-- 	self:getResourceNode():getChildByName("lanbu"):setVisible(true)
	-- end

	if self:getChildByName("chatNode") then
		self:getChildByName("chatNode"):removeFromParent()
	end

	-- if typename == "chat" or typename == "league" then
	-- 	self:getResourceNode():getChildByName("laba"):setVisible(false)
	-- elseif typename == "world" or typename == "star" then
	-- 	self:getResourceNode():getChildByName("laba"):setVisible(false)
	-- end

	if typename == "chat" then
		rn:getChildByName("tc_bottom"):setContentSize(cc.size(lan_2, 390))
	else
		rn:getChildByName("tc_bottom"):setContentSize(cc.size(lan_1, 390))
	end

	self:setSend(true)

	for i,v in ipairs(self.labs) do
		local labs = rn:getChildByName(v)

		local flag = true
		if i == 3 then
			if self.hasGroup == false then
				flag = false
			end
		elseif i == 4 then
			if self.isStar == false then
				flag = false
			end
		end

		if flag then
			if i == getTypeNum(typename) then
				labs:setOpacity(255)
			else
				labs:setOpacity(0)
			end
		end
	end

	-- self.svd_:clear()

	local perNode = rn:getChildByName("node")
	if perNode == nil then
		return
	end
	local nodePos = cc.p(perNode:getPosition())
	perNode:removeFromParent()

	local node = nil
	if typename == "world" then
		node = require("app.views.ChatLayer.WorldNode"):create()
	elseif typename == "chat" then
		node = require("app.views.ChatLayer.ChatNode"):create()
	elseif typename == "star" then
		player:setChatStarPoint(false)
		rn:getChildByName("star_point"):setVisible(false)
		node = require("app.views.ChatLayer.StarLeagueNode"):create()
	elseif typename == "planet" then
		node = require("app.views.ChatLayer.PlanetNode"):create()
		-- self:setSend(false)
	elseif typename == "slave" then
		node = require("app.views.ChatLayer.SlaveNode"):create()
		self:setSend(false)

	end


	rn:addChild(node)	
	node:setName("node")
	node:setPosition(nodePos)

	node:init(self,data)
end

function ChatLayer:onEnterTransitionFinish()

	printInfo("ChatLayer:onEnterTransitionFinish()")

	local eventDispatcher = self:getEventDispatcher()

	self.broadcast = false
	self.typename_ = ""

	self.labs = {"world", "chat", "star", "planet", "slave"}

	local rn = self:getResourceNode()
	rn:getChildByName("star_point"):setVisible(player:getChatStarPoint())

	-- rn:getChildByName("title"):setString(CONF:getStringValue("chat"))
	rn:getChildByName("send"):getChildByName("text"):setString(CONF:getStringValue("send"))
	rn:getChildByName("world_text"):setString(CONF:getStringValue("worldChat"))
	rn:getChildByName("chat_text"):setString(CONF:getStringValue("privateChat"))
	rn:getChildByName("star_text"):setString(CONF:getStringValue("covenant"))
	rn:getChildByName("planet_text"):setString(CONF:getStringValue("planetOccupation"))
	rn:getChildByName("slave_text"):setString(CONF:getStringValue("slave"))
	-- rn:getChildByName("list"):setScrollBarEnabled(false)
	-- self.svd_ = require("util.ScrollViewDelegate"):create(rn:getChildByName("list"),cc.size(10,10), cc.size(584,66))

	local placeHolder = rn:getChildByName("send_text")
	-- local inputText = rn:getChildByName("input_text")
	local placeHolderColor = placeHolder:getTextColor()
	local fontColor = placeHolder:getTextColor()
	local fontName = placeHolder:getFontName()
	local fontSize = placeHolder:getFontSize()
	local maxLength = placeHolder:getMaxLength()

	local back = rn:getChildByName(string.format("text_back"))

	local edit = ccui.EditBox:create(placeHolder:getContentSize(),"aa")
	rn:addChild(edit)
	edit:setPosition(cc.p(placeHolder:getPosition()))
	edit:setPlaceHolder(CONF:getStringValue("InputMsg"))
	edit:setInputFlag(cc.EDITBOX_INPUT_FLAG_INITIAL_CAPS_WORD)
	edit:setPlaceholderFont(fontName,fontSize)
	edit:setPlaceholderFontColor(cc.c3b(255,255,255))
	edit:setFont(fontName,fontSize)
	edit:setFontColor( cc.c3b(255,255,255))
	edit:setReturnType(1)
	edit:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
	edit:setMaxLength(maxLength)
	edit:setName("send_text")

	if self.data_.msg then
		edit:setText(self.data_.msg)
	end

	-- back:removeFromParent()
	
	placeHolder:removeFromParent()

	tipsAction(self, cc.p(0,0))

	rn:getChildByName("send"):addClickEventListener(function (name)
		local param = CONF.PARAM.get("chat open").PARAM
		local param_level = param[1]
		local str_conf = CONF:getStringValue("chat open") 
		if self:getChannel() == 0 then
			param_level = param[1]
			str_conf = CONF:getStringValue("chat open")
		elseif self:getChannel() == 1 then
			param_level = param[2]
			str_conf = CONF:getStringValue("chat open 2")
		elseif self:getChannel() == 2 then
			param_level = param[3]
			str_conf = CONF:getStringValue("chat open 3")
		end
		if player:getLevel() < param_level  then
			local str = string.gsub(str_conf,"#",param_level)
			tips:tips(str)
			return
		end
		playEffectSound("sound/system/click.mp3")
		if edit:getText() == "" then
			tips:tips(CONF:getStringValue("text is empty"))
		else

			local str = changeChatString(edit:getText())

			print(self.user_name)
			local recver = {
				uid = self.user_name,
			}

			local my_recver = {
				uid = player:getName(), 
				nickname = player:getNickName(),
				vip = player:getVipLevel(),
				level = player:getLevel(),

			}

			local minor = nil
			if self.typename_ == "planet" then
				minor = {1, self.data_.area}
			else
				minor = {}
			end

			local strData = Tools.encode("ChatReq", {
				recver = recver,
				msg = str,
				channel = self:getChannel(),
				sender = my_recver,
				type = self:getBroadCast(),
				minor = minor,
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_CHAT_REQ"),strData)

			gl:retainLoading()  

		end
	end)

	rn:getChildByName("laba"):setLocalZOrder(200)

	rn:getChildByName("laba"):addClickEventListener(function ( sender )
		local param = CONF.PARAM.get("chat open").PARAM
		if player:getLevel() < param[1]  then
			local str = string.gsub(CONF:getStringValue("chat open"),"#",param[1])
			tips:tips(str)
			return
		end
		if player:getBuildingInfo(1).level < param[2] then

			return
		end
		playEffectSound("sound/system/click.mp3")
		if self.broadcast then
			rn:getChildByName("laba"):loadTexture("Common/ui/icon_laba_gray.png")
			self.broadcast = false
		else
			rn:getChildByName("laba"):loadTexture("Common/ui/icon_laba.png")
			self.broadcast = true   
		end
	end)

	if player:getGroupData().groupid == "" then
		self.hasGroup = false
	else
		self.hasGroup = true
	end

	if self.data_.name == "planet" then
		self.isStar = true
	else
		self.isStar = false
	end

	if self.hasGroup == false then
		-- rn:getChildByName("labs_3"):loadTexture("Common/ui/botton_gray.png")
	end

	if self.isStar == false then
		-- rn:getChildByName("labs_4"):loadTexture("Common/ui/botton_gray.png")
	end

	-- reset
	if self.data_.name then

		if self.data_.user_name then
			self:resetNode(self.data_.name, {user_name = self.data_.user_name})
		else
			if self.data_.name == "planet" then
				self:resetNode(self.data_.name, {area = self.data_.area})
			else
				self:resetNode(self.data_.name, {user_name = ""})
			end
		end
	else

	   self:resetNode("world", {})
	end

	rn:getChildByName("world"):addClickEventListener(function ( sender )
		playEffectSound("sound/system/tab.mp3")
		self:resetNode("world", {})
	end)

	rn:getChildByName("chat"):addClickEventListener(function ( sender )
		playEffectSound("sound/system/tab.mp3")
		if self.data_.user_name then
			self:resetNode("chat", {user_name = self.data_.name})
		else
			self:resetNode("chat", {user_name = ""})
		end
	end)

	rn:getChildByName("star"):addClickEventListener(function ( sender )
		playEffectSound("sound/system/tab.mp3")
		-- if self.hasGroup then
			self:resetNode("star", {})
		-- else
		-- 	tips:tips("no group")
		-- end
	end)

	rn:getChildByName("planet"):addClickEventListener(function ( sender )
		playEffectSound("sound/system/tab.mp3")
		-- if self.isStar then
			self:resetNode("planet", {area = self.data_.area})
		-- else
			-- tips:tips("not at xingqiuzhanling")
		-- end
	end)

	rn:getChildByName("slave"):addClickEventListener(function ( ... )
		self:resetNode("slave",{})
	end)

	rn:getChildByName("back"):addClickEventListener(function ( sender )
		playEffectSound("sound/system/return.mp3")
		-- if self.typename_ == "world" or self.typename_ == "xingmeng" or self.typename_ == "star" then
			if rn:getChildByName("node"):getResourceNode():getChildByName("click_node") then
				rn:getChildByName("node"):getResourceNode():getChildByName("click_node"):removeFromParent()
			end
		-- end
	end)

	-- animManager:runAnimOnceByCSB(rn, "ChatLayer/ChatLayer.csb", "intro", function ( ... )
	-- end)



	local function recvMsg()
		print("ChatLayer:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()
		if cmd == Tools.enum_id("CMD_DEFINE","CMD_CHAT_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("ChatResp",strData)
			printInfo("ChatResp")
			if proto.result == "FAIL" then
				print("ChatResp error :",proto.result)
			elseif proto.result == "DIRTY" then
				tips:tips(CONF:getStringValue("dirty_message"))
			elseif proto.result == "BLACK" then
				tips:tips(CONF:getStringValue("InBlacklist"))
			else
				print("chat ok")
				rn:getChildByName("send_text"):setText("")                
			end

		end
	   
	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

    require("util.ExConfigScreenAdapter"):getInstance():onFixQuanmianping_Chat(self)
end

function ChatLayer:getChannel()
	if self.typename_ == "world" then
		return 0
	elseif self.typename_ == "chat" then
		return 1 
	elseif self.typename_ == "star" then
		return 2
	elseif self.typename_ == "planet" then
		return 0
	elseif self.typename_ == "slave" then
		return 0
	end

end

function ChatLayer:getBroadCast( ... )
	if self.broadcast then
		return 1
	else
		return 0 
	end
end

function ChatLayer:setUserName( name )
	self.user_name = name
end

function ChatLayer:setSend( flag )
	local rn = self:getResourceNode()
	if flag then
		rn:getChildByName("send"):setEnabled(true)
		rn:getChildByName("send"):setTouchEnabled(true)
	else
		rn:getChildByName("send"):setEnabled(false)
		rn:getChildByName("send"):setTouchEnabled(false)
	end
end

function ChatLayer:onExitTransitionStart()
	printInfo("ChatLayer:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
	
end


return ChatLayer