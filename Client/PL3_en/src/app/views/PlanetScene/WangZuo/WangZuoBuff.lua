
local gl = require("util.GlobalLoading"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local WangZuoBuff = class("WangZuoBuff", cc.load("mvc").ViewBase)

local player = require("app.Player"):getInstance()

local app = require("app.MyApp"):getInstance()

WangZuoBuff.RESOURCE_FILENAME = "PlanetScene/wangzuo/buffLayer.csb"

WangZuoBuff.RUN_TIMELINE = true

WangZuoBuff.NEED_ADJUST_POSITION = true

WangZuoBuff.RESOURCE_BINDING = {
	--["Button_1"]   = {["varname"] = "btn"},
}

WangZuoBuff.chooseTitle = 1
WangZuoBuff.chooseBuff = 1
WangZuoBuff.buffInfo = {}

local schedulerEntry = nil


function WangZuoBuff:onCreate( data )
	self.data_ = data[1]
end

function WangZuoBuff:onEnter()

end

function WangZuoBuff:onExit()
	
end

function WangZuoBuff:createBuffNode(buffID,owner)
	local conf = CONF.TITLE_BUFF.get(buffID)
	local node = cc.CSLoader:createNode("PlanetScene/wangzuo/buffNode.csb")
	node:getChildByName("shouhuo_ins"):setString(CONF:getStringValue(conf.MEMO_ID))
	if owner and owner ~= "" then
		node:getChildByName("work_type"):setString(owner)
	else
		node:getChildByName("work_type"):setString(CONF:getStringValue("wu_text"))
	end
	node:getChildByName("head"):setTexture("PlanetScene/wangzuo/buffIcon/"..conf.ICON..".png")
	if conf.STR_DEBUFF == 1 then
		node:getChildByName("shouhuo_ins"):setTextColor(cc.c4b(243,57,57,255))
		node:getChildByName("back"):loadTextures("PlanetScene/wangzuo/ui/bg_red.png","PlanetScene/wangzuo/ui/bg_red_light.png")
		node:getChildByName("head_di"):setTexture("PlanetScene/wangzuo/ui/icon_red.png")
	end
	return node
end

function WangZuoBuff:clickBtn(debuff,proto)
	local bufftype = debuff and 1 or 0
	self.svd_:clear()
	for k,id in ipairs(CONF.TITLE_BUFF.getIDList()) do
		if CONF.TITLE_BUFF.get(id).STR_DEBUFF and CONF.TITLE_BUFF.get(id).STR_DEBUFF == bufftype then
			local node = self:createBuffNode(id)
			local buffowner = {}
			if Tools.isEmpty(proto.title_list.wangzuo_title_list) == false then
				for k,v in ipairs(proto.title_list.wangzuo_title_list) do
					if v.title == id then
						for k1,v1 in ipairs(proto.user_list) do
							if v.user_name == v1.user_name then
								node:getChildByName("work_type"):setString(v1.nickname)
								node:getChildByName("head"):setTexture("HeroImage/"..v1.icon_id..".png")
								buffowner = v1
							end
						end
					end
				end
			end
			node:setTag(id)
			local function func()
				self:getApp():addView2Top("PlanetScene/WangZuo/WangZuoBuffDetail",{buffowner = buffowner,id = id,state = self.data_.status,king = self.data_.user_info.user_name})
			end
			local callback = {node = node:getChildByName("back"), func = func}
			self.svd_:addElement(node,{callback = callback})
		end
	end
end

function WangZuoBuff:onEnterTransitionFinish()
	printInfo("WangZuoBuff:onEnterTransitionFinish()")
	local rn = self:getResourceNode()
	self.svd_ = require("util.ScrollViewDelegate"):create(rn:getChildByName('list'),cc.size(0,1), cc.size(145,190))
	rn:getChildByName("title"):setString(CONF:getStringValue("title_2"))
	rn:getChildByName("choose"):getChildByName("text1"):setString(CONF:getStringValue("jedi_warrior"))
	rn:getChildByName("choose"):getChildByName("text2"):setString(CONF:getStringValue("seven_deadly_sins"))
	rn:getChildByName("choose"):getChildByName("btn2"):setOpacity(0)
	rn:getChildByName("choose"):getChildByName("btn1"):addClickEventListener(function()
		if self.chooseTitle == 1 then
			return
		end
		self.chooseTitle = 1
		local strData = Tools.encode("PlanetWangZuoTitleReq", {
				type = 1,
			})
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PANET_WANGZUO_TITLE_REQ"),strData)
		gl:retainLoading()
		rn:getChildByName("choose"):getChildByName("btn2"):setOpacity(0)
		rn:getChildByName("choose"):getChildByName("btn1"):setOpacity(255)
		end)
	rn:getChildByName("choose"):getChildByName("btn2"):addClickEventListener(function()
		if self.chooseTitle == 2 then
			return
		end
		self.chooseTitle = 2
		local strData = Tools.encode("PlanetWangZuoTitleReq", {
				type = 1,
			})
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PANET_WANGZUO_TITLE_REQ"),strData)
		gl:retainLoading()
		rn:getChildByName("choose"):getChildByName("btn1"):setOpacity(0)
		rn:getChildByName("choose"):getChildByName("btn2"):setOpacity(255)
		end)
	rn:getChildByName("Button_wen"):addClickEventListener(function()
		local node = createIntroduceNode(CONF:getStringValue("title_explain"))
		self:addChild(node)
		end)
	rn:getChildByName("close"):addClickEventListener(function()
		-- self:removeFromParent()
		self:getApp():removeTopView()
		end)

	
	if not self.data_.user_name or self.data_.user_name == "" then
		rn:getChildByName("King"):setVisible(false)
	else
		rn:getChildByName("King"):setVisible(true)
		if Tools.isEmpty(self.data_.user_info) == false then
			rn:getChildByName("King"):getChildByName("role"):loadTexture("HeroImage/"..math.floor(self.data_.user_info.icon_id/100)..".png")
			rn:getChildByName("King"):getChildByName("text3"):setString(self.data_.user_info.nickname)
		end
		rn:getChildByName("King"):getChildByName("text1"):setString(CONF:getStringValue("feudal_lord"))
		rn:getChildByName("King"):getChildByName("text2"):setVisible(false)
		if self.data_.groupid and self.data_.groupid ~= "" then
			rn:getChildByName("King"):getChildByName("text2"):setVisible(true)
			rn:getChildByName("King"):getChildByName("text3"):setString(self.data_.temp_info.leader_name)
			rn:getChildByName("King"):getChildByName("text2"):setString(CONF:getStringValue("covenant")..":"..self.data_.temp_info.nickname)
		end
	end
	local buffuser = self.data_.user_info
	rn:getChildByName("King"):getChildByName("Image_9"):addClickEventListener(function()
		local id
		for k,v in ipairs(CONF.TITLE_BUFF.getIDList()) do
			if CONF.TITLE_BUFF.get(v).STR_DEBUFF == 2 then
				id = v
			end
		end
		self:getApp():addView2Top("PlanetScene/WangZuo/WangZuoBuffDetail",{buffowner = buffuser,state = self.data_.status,id = id,king = self.data_.user_info.user_name})
		end)
	local strData = Tools.encode("PlanetWangZuoTitleReq", {
			type = 1,
		})
	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PANET_WANGZUO_TITLE_REQ"),strData)
	gl:retainLoading()

	rn:getChildByName("list"):setScrollBarEnabled(false)
	local function recvMsg()
		print("WangZuoBuff:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_PANET_WANGZUO_TITLE_RESP") then
			local proto = Tools.decode("PLanetWangZuoTitleResp",strData)
			gl:releaseLoading()
			print("PLanetWangZuoTitleResp result",proto.result, proto.type)
			if proto.result == 0 then
				if proto.type == 1 then
					self:clickBtn(self.chooseTitle == 2,proto)
				elseif proto.type == 2 then
					-- for k,v in ipairs(proto.title_list.wangzuo_title_list) do
					-- 	if rn:getChildByName('list'):getChildByTag(v.title) then
					-- 		for k1,v1 in ipairs(proto.user_list) do
					-- 			if v.user_name == v1.user_name then
					-- 				rn:getChildByName('list'):getChildByTag(v.title):getChildByName("work_type"):setString(v1.nickname)
					-- 				rn:getChildByName('list'):getChildByTag(v.title):getChildByName("head"):setTexture("HeroImage/"..v1.icon_id..".png")
					-- 			end
					-- 		end
					-- 	end
					-- end
					self:clickBtn(self.chooseTitle == 2,proto)
				end
        	end
			
		end
	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)
end

function WangZuoBuff:onExitTransitionStart()

	printInfo("WangZuoBuff:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
	if schedulerEntry ~= nil then
		scheduler:unscheduleScriptEntry(schedulerEntry)
	end

end

return WangZuoBuff