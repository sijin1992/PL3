local player = require("app.Player"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local PlanetSpyMakeSureLayer = class("PlanetSpyMakeSureLayer", cc.load("mvc").ViewBase)

local planetManager = require('app.views.PlanetScene.Manager.PlanetManager'):getInstance()

PlanetSpyMakeSureLayer.RESOURCE_FILENAME = "PlanetScene/PlanetSpyMakeSureLayer.csb"

PlanetSpyMakeSureLayer.NEED_ADJUST_POSITION = true

PlanetSpyMakeSureLayer.RESOURCE_BINDING = {
	["cancel"] = { ["varname"] = "", ["events"] = {{["event"] = "touch", ["method"] = "OnBtnClick"}}},
	["buy_SureBtn"] = { ["varname"] = "", ["events"] = {{["event"] = "touch", ["method"] = "OnBtnClick"}}},
}

function PlanetSpyMakeSureLayer:onCreate(data)
	self.data_ = data
end

function PlanetSpyMakeSureLayer:OnBtnClick( event )
	if event.name == "ended" and event.target:getName() == "cancel" then 
		self:getApp():removeTopView()
	elseif event.name == "ended" and event.target:getName() == "buy_SureBtn" then 
		if self.data_.from == 'ForgeScene' then
			local gems = player:getAllUnGemList() or {}
			local my_item = {}
			local maxCount = 0
			if Tools.isEmpty(self.data_.items) then return end
			for k,v in ipairs(self.data_.items) do
				for k1,v1 in ipairs(gems) do
					if v == v1.id then
						if not my_item[v] then 
							my_item[v] = 1
						else
							my_item[v] = my_item[v] + 1
						end
						maxCount = math.max(maxCount,v1.num)
					end
				end
			end
			for k,v in pairs(my_item) do
				for k1,v1 in ipairs(gems) do
					if v1.id == k then
						maxCount = math.min(maxCount,math.floor(v1.num/v))
					end
				end
			end
			if Tools.isEmpty(self.data_.items) or maxCount == 0 then
				return
			end
			local gem_list = {}
			for i,v in ipairs(self.data_.items) do
				if v ~= 0 then
					local has = false
					local get_index = 0
					for i2,v2 in ipairs(gem_list) do
						if v2.id == v then
							has = true
							get_index = i2
							break
						end
					end

					if has then
						gem_list[get_index].num = gem_list[get_index].num + 1
					else
						local tt = {id = v, num = 1}
						table.insert(gem_list, tt)
					end
				end
			end
			if maxCount >= 999 then
				maxCount = 999
			end
			local strData = Tools.encode("MixGemReq", {
					gem_list = gem_list,
					count = maxCount,
				})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GEM_MIX_REQ"),strData)
		else
			if Tools.isEmpty(planetManager:getPlanetUser( )) == true then
				if Tools.isEmpty(planetManager:getPlanetUser( ).army_list) == false and #planetManager:getPlanetUser( ).army_list >= CONF.BUILDING_1.get(player:getBuildingInfo(1).level).ARMY_NUM then
				   tips:tips(CONF:getStringValue("no_planet_queue"))
				   return
				end
			end

			if planetManager:getUserShield() then
				local messageBox = require("util.MessageBox"):getInstance()
				local function func( ... )
					print('type,element_global_key = ',self.data_.type,self.data_.element_global_key)
					local strData = Tools.encode("PlanetRaidReq", {
						type_list = {2},
						element_global_key = self.data_.element_global_key,
						lineup = player:getForms(),
					 })
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_RAID_REQ"),strData)

					-- node:removeFromParent()
				end
				messageBox:reset(CONF:getStringValue("shield vanish"), func)
			else
				local strData = Tools.encode("PlanetRaidReq", {
						type_list = {2},
						element_global_key = self.data_.element_global_key,
						lineup = player:getForms(),
					 })
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_RAID_REQ"),strData)

			end
		end
	end
end


function PlanetSpyMakeSureLayer:onEnterTransitionFinish( )

	local rn = self:getResourceNode()

	-- rn:getChildByName("uibg"):addClickEventListener(function ( sender )
	-- 	self:removeFromParent()
	-- end)
	rn:getChildByName("uibg"):setSwallowTouches(true)

	rn:getChildByName("Text_1_0_0_0"):setString(CONF:getStringValue("scout_affirm"))
	if self.data_.from == 'ForgeScene' then
		rn:getChildByName("Text_1_0_0_0"):setString(CONF:getStringValue("fast_tips"))
	end
	rn:getChildByName("buy_SureBtn"):getChildByName("text"):setString(CONF:getStringValue("yes"))
	rn:getChildByName("cancel"):getChildByName("text"):setString(CONF:getStringValue("cancel"))

	local function recvMsg()
		print("NewFormLayer:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()
		if cmd == Tools.enum_id("CMD_DEFINE","CMD_PLANET_RAID_RESP") then

			local proto = Tools.decode("PlanetRaidResp",strData)
			print('PlanetRaidResp..',proto.result)
			if proto.result == 'OK' then
				-- local event = cc.EventCustom:new("nodeUpdated")
				-- event.node_id_list = {tonumber(Tools.split(self.data_.element_global_key, "_")[1])}
				-- cc.Director:getInstance():getEventDispatcher():dispatchEvent(event) 

				-- planetManager:setPlanetUser(proto.planet_user)
				if self.data_.from ~= "ForgeScene" then
					self:getApp():removeTopView()
				end
			end
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GEM_MIX_RESP") then
			local proto = Tools.decode("MixGemResp",strData)
			if proto.result == 0 then
		-- 		local node = require("util.RewardNode"):createNodeWithListView(proto.remain_list)
		-- 		tipsAction(node)
		-- 		node:setPosition(cc.exports.VisibleRect:center())
		-- 		self:getParent():addChild(node)
				self:getApp():removeTopView()
			end			

		end
		
	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)
end


function PlanetSpyMakeSureLayer:onExitTransitionStart()
	printInfo("PlanetSpyMakeSureLayer:onExitTransitionStart()")
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
end

return PlanetSpyMakeSureLayer