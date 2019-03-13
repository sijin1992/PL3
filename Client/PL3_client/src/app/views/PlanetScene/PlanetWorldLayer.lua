
local tips = require("util.TipsMessage"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local messageBox = require("util.MessageBox"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local winSize = cc.Director:getInstance():getWinSize()

local player = require("app.Player"):getInstance()


local planetManager = require("app.views.PlanetScene.Manager.PlanetManager"):getInstance()

local PlanetWorldLayer = class("PlanetWorldLayer", cc.load("mvc").ViewBase)

PlanetWorldLayer.RESOURCE_FILENAME = "PlanetScene/WorldLayer.csb"

PlanetWorldLayer.RUN_TIMELINE = true

PlanetWorldLayer.NEED_ADJUST_POSITION = true

PlanetWorldLayer.RESOURCE_BINDING = {
	--["Button_1"]   = {["varname"] = "btn"},
}

local schedulerEntry = nil

local cube_w = 230/10
local cube_h = 133/10

PlanetWorldLayer.wangzuoData = {}

function PlanetWorldLayer:onEnter()
  
	printInfo("PlanetWorldLayer:onEnter()")

end

function PlanetWorldLayer:onExit()
	
	printInfo("PlanetWorldLayer:onExit()")
end

function PlanetWorldLayer:checkRnPos( scale )

	local rn = self:getResourceNode()
	
	local nowContentSize_width = rn:getContentSize().width * scale
    local nowContentSize_height = rn:getContentSize().height * scale

    self:setRnAnchorPoint(cc.p(0.5,0.5))

    local pos = cc.p(rn:getPosition())

    if pos.x + nowContentSize_width/2 < winSize.width or pos.x - nowContentSize_width/2 > 0 or pos.y + nowContentSize_height/2 < winSize.height or pos.y - nowContentSize_height/2 > 0 then
    	return false
    end

    return true

end

function PlanetWorldLayer:setRnAnchorPoint( ap )
	
	local rn = self:getResourceNode()

	local first_ap = cc.p(rn:getAnchorPoint())
	local first_pos = cc.p(rn:getPosition())

	local nowContentSize_width = rn:getContentSize().width * rn:getScale()
    local nowContentSize_height = rn:getContentSize().height * rn:getScale()

    local diff_x = (ap.x - first_ap.x)*nowContentSize_width
    local diff_y = (ap.y - first_ap.y)*nowContentSize_height

    rn:setAnchorPoint(ap)
    rn:setPosition(cc.p(first_pos.x + diff_x, first_pos.y + diff_y))

end

function PlanetWorldLayer:resetAnchorPoint(type)

	local rn = self:getResourceNode()

	--shezhi dao jiao
	local first_ap = rn:getAnchorPoint()
	local first_pos = cc.p(rn:getPosition())
	local nowContentSize_width = rn:getContentSize().width * rn:getScale()
    local nowContentSize_height = rn:getContentSize().height * rn:getScale()

	local win_pos = {{x = 0, y = 0}, {x = winSize.width, y = 0}, {x = winSize.width, y = winSize.height}, {x = 0, y = winSize.height}}
	local anchor_pos = {{x = 0, y = 0}, {x = 1, y = 0}, {x = 1, y = 1}, {x = 0, y = 1}, {x = 0.5, y = 0.5}}

	if type == 1 then

		self:setRnAnchorPoint(cc.p(0.0,0.0))

	 	local rn_pos = cc.p(rn:getPosition())
	 	local win_pos = cc.p(winSize.width/2, winSize.height/2)

	 	local pos = cc.pSub(win_pos, rn_pos)

	 	local index = 0

	 	if pos.x <= nowContentSize_width/2 and pos.y >= nowContentSize_height/2 then
	 		index = 4
	 	elseif pos.x <= nowContentSize_width/2 and pos.y <= nowContentSize_height/2 then
	 		index = 1
	 	elseif pos.x >= nowContentSize_width/2 and pos.y <= nowContentSize_height/2 then
	 		index = 2
	 	elseif pos.x >= nowContentSize_width/2 and pos.y >= nowContentSize_height/2 then
	 		index = 3
	 	end


	 	self:setRnAnchorPoint(cc.p(anchor_pos[index].x, anchor_pos[index].y))
	elseif type == 2 then

 	--shezhi pinmu zhongjian

	 	self:setRnAnchorPoint(cc.p(0,0))

	 	local rn_pos = cc.p(rn:getPosition())
	 	local win_pos = cc.p(winSize.width/2, winSize.height/2)

	 	local pos = cc.pSub(win_pos, rn_pos)

	 	local x = pos.x / nowContentSize_width
	 	local y = pos.y / nowContentSize_height

	 	self:setRnAnchorPoint(cc.p(x, y))
	end

end

function PlanetWorldLayer:resetUI( info_list )
	for i,v in ipairs(info_list) do
		local conf = CONF.PLANETWORLD.get(v.id)
		if conf.TYPE == 2 then
			local node = self:getResourceNode():getChildByName(v.id)

			local info 
			for i2,v2 in ipairs(v.element_list) do
				if v2.type == 5 then
					info = v2
					break
				end
			end

			if info and node then
				if info.city_data.groupid ~= nil and info.city_data.groupid ~= "" then
					if  info.city_data.groupid  ==   player:getGroupData().groupid then

						node:getChildByName("bgNode"):getChildByName("bg"):loadTexture("PlanetScene/ui/world_g.png")
					else
						node:getChildByName("bgNode"):getChildByName("bg"):loadTexture("PlanetScene/ui/world_r.png")
					end
				else
					node:getChildByName("bgNode"):getChildByName("bg"):loadTexture("PlanetScene/ui/world_w.png")

				end

				--if info.city_data.status == 1 then
				--	node:getChildByName("bgNode"):getChildByName("bg"):loadTexture("PlanetScene/ui/world_w.png")
				--	node:getChildByName("warning"):setVisible(false)
				--else
					--node:getChildByName("bgNode"):getChildByName("bg"):loadTexture("PlanetScene/ui/world_y.png")
					--if node:getChildByName("warning") then
					--	node:getChildByName("warning"):setVisible(true)
					--end
				--end
			end
		end
	end
end


function PlanetWorldLayer:onEnterTransitionFinish()
	printInfo("PlanetWorldLayer:onEnterTransitionFinish()")

	self.get_city_info = false

	local rn = self:getResourceNode()
	rn:setAnchorPoint(cc.p(0.5, 0.5))
	rn:setPosition(cc.exports.VisibleRect:center())

	local list = {}

	local mainnode = rn:getChildByName("1")
	for i,v in ipairs(CONF.PLANETWORLD.getIDList()) do

		local node = rn:getChildByName(tostring(v))
		if node then		
			if node:getChildByName("text") then
				node:getChildByName("text"):removeFromParent()
			end

			--if node:getChildByName("warning") then
			--	animManager:runAnimByCSB( node:getChildByName("warning"), "PlanetScene/sfx/warning/warning.csb", "1")
			--end

			local nn = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/WorldNode.csb")
			nn:setName("bgNode")
			nn:setVisible(false)
			node:addChild(nn)

			local conf = CONF.PLANETWORLD.get(v)
			if conf.TYPE == 2 then
				node:loadTexture("PlanetScene/ui/world_city_"..conf.NATION..".png")
				node:setContentSize(cc.size(30,30))
				nn:setPosition(cc.p(33,-13))

				table.insert(list, v)
			elseif conf.TYPE == 1 then
				node:loadTexture("PlanetScene/ui/world_normal_"..conf.NATION..".png")
				node:setContentSize(cc.size(14,14))
				nn:setPosition(cc.p(7,-7))
				nn:setScale(0.5)
			end
			if i > 1 then
				local x = conf.ROW
				local y = conf.COL
				local m = mainnode:getPositionX() + math.floor(x + y) * 70
				local n = mainnode:getPositionY() - math.floor(x - y) * 42
				node:setPosition(cc.p(m , n - 50))
			end
		end
	end
	mainnode:setPositionY(mainnode:getPositionY() - 50)


	animManager:runAnimByCSB(rn:getChildByName("dingwei"), "PlanetScene/sfx/dingwei.csb", "1")
	local my_base_node_id = tostring(Split(planetManager:getUserBaseElementInfo().global_key, "_")[1])
	local my_base_pos = cc.p(rn:getChildByName(my_base_node_id):getPosition())
	rn:getChildByName("dingwei"):setPosition(cc.p(my_base_pos.x, my_base_pos.y))


	local world_node = cc.CSLoader:createNode("PlanetScene/WorldNode2.csb")
	world_node:setName("WorldNode2")
	world_node:setPosition(cc.p(-5,winSize.height-5))
	self:addChild(world_node)
	world_node:setVisible(false)

    local des_node = cc.CSLoader:createNode("PlanetScene/WorldDesNode.csb")
    des_node:getChildByName("Text_1"):setString(CONF:getStringValue("space_station_position"))
    des_node:getChildByName("Text_2"):setString(CONF:getStringValue("region"))
    des_node:getChildByName("Text_3"):setString(CONF:getStringValue("judian"))
    des_node:getChildByName("Text_4"):setString(CONF:getStringValue("throne"))
	des_node:setName("WorldDesNode")
	des_node:setPosition(cc.p(-5,5))
	self:addChild(des_node)
	des_node:setVisible(true)

	local strData = Tools.encode("PlanetGetReq", {
		node_id_list = {1},
		type = 2,
	 })
	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData)
	local function update( ... )
		if not self.get_city_info then
			local strData = Tools.encode("PlanetGetReq", {
				node_id_list = list,
				type = 2,
			 })
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData)
		end
		if Tools.isEmpty(self.wangzuoData) == false then
			if self:getChildByName("WorldNode2") then
				self:getChildByName("WorldNode2"):setVisible(true)
				local king_name = CONF:getStringValue("feudal_lord")..":"
				if Tools.isEmpty(self.wangzuoData.user_info) == false then
					king_name = king_name .. self.wangzuoData.user_info.nickname
				else
					king_name = king_name .. CONF:getStringValue("wu_text")
				end
				local addTime = 0
				local conf = CONF.PLANETCITY.get(self.wangzuoData.id)
				if self.wangzuoData.status == 1 then
					local last_openTime = 0
					local open_confWday = conf.TIME[1]
					local open_confHour = conf.TIME[2]
					local first_openTime = self.wangzuoData.create_time + CONF.PARAM.get("throne_first_open").PARAM
					if player:getServerTime() < first_openTime then	
						local open_date = os.date("*t",first_openTime)
						if open_date.wday ~= open_confWday then
							local addDay = 0
							local wday1 = open_date.wday - 1
							if wday1 == 0 then
								wday1 = 7 
							end
							local wday2 = open_confWday - 1
							if wday2 == 0 then
								wday2 = 7 
							end
							if wday2 - wday1 > 0 then
								addDay = wday2 - wday1
							else
								addDay = 7 - math.abs(wday2 - wday1)
							end
							addTime = os.time({year = open_date.year, month = open_date.month, day = open_date.day+addDay, hour = open_confHour}) - player:getServerTime()
						else
							if open_date.hour < open_confHour then
								addTime = os.time({year = open_date.year, month = open_date.month, day = open_date.day, hour = open_confHour}) - first_openTime
							else
								addTime = 7*24*3600 - math.abs(os.time({year = open_date.year, month = open_date.month, day = open_date.day, hour = open_confHour}) - first_openTime)
							end
						end
					else
						first_openTime = os.time()
						local open_date = os.date("*t",first_openTime)
						if open_date.wday ~= open_confWday then
							local addDay = 0
							local wday1 = open_date.wday - 1
							if wday1 == 0 then
								wday1 = 7 
							end
							local wday2 = open_confWday - 1
							if wday2 == 0 then
								wday2 = 7 
							end
							if wday2 - wday1 > 0 then
								addDay = wday2 - wday1
							else
								addDay = 7 - math.abs(wday2 - wday1)
							end
							addTime = os.time({year = open_date.year, month = open_date.month, day = open_date.day+addDay, hour = open_confHour}) - player:getServerTime()
						else
							if open_date.hour < open_confHour then
								addTime = os.time({year = open_date.year, month = open_date.month, day = open_date.day, hour = open_confHour}) - first_openTime
							else
								addTime = 7*24*3600 - math.abs(os.time({year = open_date.year, month = open_date.month, day = open_date.day, hour = open_confHour}) - first_openTime)
							end
						end
					end
				elseif self.wangzuoData.status == 2 then
					local star_time = self.wangzuoData.status_begin_time
					local attack_time = conf.DURATION
					if player:getServerTime() < (attack_time+star_time) then
						addTime = (attack_time+star_time) - player:getServerTime()
					else
						addTime = (attack_time+star_time+CONF.PARAM.get("throne_add_time").PARAM) - player:getServerTime()
					end
				end
				self:getChildByName("WorldNode2"):getChildByName("king"):setString(king_name)
				self:getChildByName("WorldNode2"):getChildByName("time"):setString(formatTime(addTime))
				self:getChildByName("WorldNode2"):getChildByName("state"):setString("保护状态:")
				if self.wangzuoData.status == 2 then
					self:getChildByName("WorldNode2"):getChildByName("state"):setString("争夺状态:")
				end
				self:getChildByName("WorldNode2"):getChildByName("state"):setPositionX(self:getChildByName("WorldNode2"):getChildByName("time"):getPositionX()-self:getChildByName("WorldNode2"):getChildByName("time"):getContentSize().width)
			end
		end
	end

	schedulerEntry = scheduler:scheduleScriptFunc(update, 1, false)

	if self:getParent():getDiamondLayer() then
		self:getParent():getDiamondLayer():setVisible(false)
		self:getParent():getDiamondLayer():setCanTouch(false)
	end

	if self:getParent():getUILayer() then
		self:getParent():getUILayer():setVisible(false)
	end


	for i,v in ipairs(CONF.PLANETWORLD.getIDList()) do
		if rn:getChildByName(tostring(v)) then
			if rn:getChildByName(tostring(v)):getChildByName("bgNode") then
				rn:getChildByName(tostring(v)):getChildByName("bgNode"):getChildByName("text"):setString(CONF:getStringValue(CONF.PLANETWORLD.get(v).NAME))
			end
		end
	end

	local btn_close = ccui.Button:create("CityScene/ui3/btn_common_black.png", "CityScene/ui3/btn_common_light.png")
	btn_close:setPosition(cc.p(winSize.width - 60, 50))
	btn_close:setName("btn_close")
	btn_close:addClickEventListener(function ( ... )
		cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")

		self:getParent():getUILayer():setVisible(true)
		local diamondLayer = self:getParent():getDiamondLayer()

		diamondLayer:setVisible(true)

		self:getParent():removeWorldLayer()
	end)
	self:addChild(btn_close)

	local sptite = cc.Sprite:create("Common/newUI/button_back.png")
	sptite:setPosition(cc.p(40,35))
	btn_close:addChild(sptite)
	sptite:setScale(0.8)

	local label = cc.Label:createWithTTF(CONF:getStringValue("back"), "fonts/cuyabra.ttf", 23)
	label:setPosition(cc.p(55, -12))
	-- label:enableShadow(cc.c4b(93, 153, 178, 255),cc.size(0.5,0.5))
	sptite:addChild(label)

	-- rn:getChildByName("close"):addClickEventListener(function ( ... )
	-- 	cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")

	-- 	self:getParent():getUILayer():setVisible(true)
	-- 	local diamondLayer = self:getParent():getDiamondLayer()

	-- 	diamondLayer:setVisible(true)

	-- 	-- local pos = planetManager:getUserBaseElementPos()
	-- 	-- local key = planetManager:getPlanetUserBaseElementKey()
	-- 	-- diamondLayer:moveByRowCol(pos.x, pos.y, {tonumber(Split(key, "_")[1])})

	-- 	self:getParent():removeWorldLayer()
	-- end)

	-- self:runAction(cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(function ( ... )
	-- 	print("self:setRnAnchorPoint(cc.p(0.0,0.0))")
	-- 	self:setRnAnchorPoint(cc.p(0.0,0.0))
	-- end), cc.DelayTime:create(1), cc.CallFunc:create(function ( ... )
	-- 	print("self:setRnAnchorPoint(cc.p(1,0.0))")
	-- 	self:setRnAnchorPoint(cc.p(1,0.0))
	-- end), cc.DelayTime:create(1), cc.CallFunc:create(function ( ... )
	-- 	print("self:setRnAnchorPoint(cc.p(1,1))")
	-- 	self:setRnAnchorPoint(cc.p(1, 1))
	-- end), cc.DelayTime:create(1), cc.CallFunc:create(function ( ... )
	-- 	print("self:setRnAnchorPoint(cc.p(0.0,1))")
	-- 	self:setRnAnchorPoint(cc.p(0.0,1))
	-- end), cc.DelayTime:create(1), cc.CallFunc:create(function ( ... )
	-- 	print("self:setRnAnchorPoint(cc.p(0.5,0.5))")
	-- 	self:setRnAnchorPoint(cc.p(0.5,0.5))
	-- end)))
	



	-- for i,v in ipairs(rn:getChildren()) do
	-- 	if v:getName() ~= "bg" then

	-- 		v:addClickEventListener(function ( ... )
	-- 			local conf = CONF.PLANETWORLD.get(tonumber(v:getName()))

	-- 			self:getParent():getDiamondLayer():moveLayer(conf.ROW, conf.COL)

	-- 			self:removeFromParent()
	-- 		end)
			
	-- 	end
	-- end

	self.isTouch_ = false

	self.touchDistance = 0

	self.touch_type = 1 --1dan 2shuang

	local touch_layer = cc.Layer:create()

	self.touches_ = {}
    local function onTouchEvent(eventType, touches)
        if eventType == "began" then

        	if Tools.isEmpty(selftouches_) then
        		self.touch_type = 1
        	else
        		self.touch_type = 2
        	end

        	local tt = {x = touches[1], y = touches[2], id = touches[3], isMove = false}
        	table.insert(self.touches_, tt)

            return true
        elseif  eventType == "moved" then
		-- add wjj 20180802
		local is_quanmianping = require("util.ExConfigScreenAdapterFixedHeight"):getInstance():IsFixScreenEnabled()
		if( is_quanmianping ) then
			do return end
		end
        	for i,v in ipairs(self.touches_) do
        		if v.id == touches[3] then
        			local diff_x = self.touches_[i].x - touches[1] 
        			local diff_y = self.touches_[i].y - touches[2]
        			if math.abs(diff_x) < g_click_delta and math.abs(diff_y) < g_click_delta then
			
					else
						if v.isMove == false then
	        				v.isMove = true
	        			 	break
	        			end
					end
        			
        		end
        	end

        	if table.getn(self.touches_) >= 2 then
        		local index = 0 
        		for i,v in ipairs(self.touches_) do
        			if v.id == touches[3] then
        				index = i 
        				break
        			end
        		end

        		if index == 1 then

        			local dis_began = cc.pGetDistance(cc.p(self.touches_[1].x, self.touches_[1].y), cc.p(self.touches_[2].x, self.touches_[2].y))

        			local dis_now = cc.pGetDistance(cc.p(touches[1], touches[2]), cc.p(self.touches_[2].x, self.touches_[2].y))

        			local scale = rn:getScale()*dis_now/dis_began
        			if rn:getScale()*dis_now/dis_began < 1 then
        				scale = 1
        			end

        			if not self:checkRnPos(scale) then
	        			if scale < rn:getScale() then
	        				self:resetAnchorPoint(1)
	        			-- else
	        			-- 	self:resetAnchorPoint(2)
	        			end
	        		end

	        		if scale > CONF.PARAM.get("ratio").PARAM/100 then
	        			scale = CONF.PARAM.get("ratio").PARAM/100 
	        		end

        			rn:setScale(scale)


        		elseif index == 2 then
        			local dis_began = cc.pGetDistance(cc.p(self.touches_[1].x, self.touches_[1].y), cc.p(self.touches_[2].x, self.touches_[2].y))

        			local dis_now = cc.pGetDistance(cc.p(touches[1], touches[2]), cc.p(self.touches_[1].x, self.touches_[1].y))

        			local scale = rn:getScale()*dis_now/dis_began
        			if rn:getScale()*dis_now/dis_began < 1 then
        				scale = 1
        			end

        			if not self:checkRnPos(scale) then
	        			if scale < rn:getScale() then
	        				self:resetAnchorPoint(1)
	        			-- else
	        			-- 	self:resetAnchorPoint(2)
	        			end
	        		end

	        		if scale > CONF.PARAM.get("ratio").PARAM/100 then
	        			scale = CONF.PARAM.get("ratio").PARAM/100 
	        		end

        			rn:setScale(scale)
 	
        		end

        		self.touches_[index].x = touches[1]
        		self.touches_[index].y = touches[2]

        	else

        		if self.touch_type == 2 then
        			return
        		end
        	
        		local diff_x = self.touches_[1].x - touches[1] 
        		local diff_y = self.touches_[1].y - touches[2]

        		self:setRnAnchorPoint(cc.p(0.5,0.5))

        		local pos = cc.p(rn:getPosition())

        		local nowContentSize_width = rn:getContentSize().width * rn:getScale()
        		local nowContentSize_height = rn:getContentSize().height * rn:getScale()

        		local x = pos.x - diff_x
				if x < winSize.width - nowContentSize_width/2 then
					x = winSize.width - nowContentSize_width/2
				elseif x > (nowContentSize_width/2) then
					x = nowContentSize_width/2
				end

        		local y = pos.y - diff_y

        		if y < (winSize.height - nowContentSize_height/2) then
        			y = winSize.height - nowContentSize_height/2
        		elseif y > (nowContentSize_height/2) then
        			y = nowContentSize_height/2
        		end

        		--print("setposition", x, y, diff_x,winSize.width, nowContentSize_width/2)
        		--rn:setPosition(cc.p(x,y))

        		self.touches_[1].x = touches[1]
        		self.touches_[1].y = touches[2]

        		if self.touch_type == 1 then
        			local move_in = false

	        		for i,v in ipairs(CONF.PLANETWORLD.getIDList()) do
	        			local node = rn:getChildByName(tostring(v))

	        			local ln = node:convertToNodeSpace(cc.p(touches[1], touches[2]))

						local s = node:getContentSize()
						local rect = cc.rect(0, 0, s.width*rn:getScale(), s.height*rn:getScale())
						
						if cc.rectContainsPoint(rect, ln) then

							local pos = cc.p(node:getPosition())
							rn:getChildByName("bg_light"):setPosition(cc.p(pos.x, pos.y))

							move_in = true

							break
						end
	        		end

	        		if move_in then
	        			return
	        		else
	        			rn:getChildByName("bg_light"):setPositionX(-10000)
	        		end
	        	end

        	end

        	if rn:getScale() >= CONF.PARAM.get("thumbnail").PARAM/100 then
        		for i,v in ipairs(rn:getChildren()) do
        			if v:getChildByName("bgNode") then
        				 v:getChildByName("bgNode"):setVisible(true)
        			end
	        		
        		end
        	else
        		for i,v in ipairs(rn:getChildren()) do
        			if v:getChildByName("bgNode") then
	        			 v:getChildByName("bgNode"):setVisible(false)
	        		end
        		end
        	end

        elseif eventType == "ended" then

        	if #self.touches_ == 1 then

        		local isMove = false

        		for i,v in ipairs(self.touches_) do
	        		if v.id == touches[3] then
	        			isMove = v.isMove
	        			break
	        		end
	        	end

	        	if isMove == false then
	        		if self.touch_type == 1 then
		        		for i,v in ipairs(CONF.PLANETWORLD.getIDList()) do
		        			local node = rn:getChildByName(tostring(v))

		        			local ln = node:convertToNodeSpace(cc.p(touches[1], touches[2]))

							local s = node:getContentSize()
							local rect = cc.rect(0, 0, s.width*rn:getScale(), s.height*rn:getScale())
							
							if cc.rectContainsPoint(rect, ln) then

								local pos = cc.p(node:getPosition())
								rn:getChildByName("bg_light"):setPosition(cc.p(pos.x, pos.y))

								cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
								local conf = CONF.PLANETWORLD.get(v)

								self:getParent():getUILayer():setVisible(true)
								local diamondLayer = self:getParent():getDiamondLayer()

								diamondLayer:setVisible(true)
								diamondLayer:moveLayer(conf.ROW, conf.COL, conf.ID)

								self:getParent():removeWorldLayer()

								return

							end
		        		end
		        	end
	        	end
        	end


        	for i,v in ipairs(self.touches_) do
        		if v.id == touches[3] then
        			table.remove(self.touches_, i)
        			break
        		end
        	end

        elseif eventType == "cancelled" then
 			for i,v in ipairs(self.touches_) do
        		if v.id == touches[3] then
        			table.remove(self.touches_, i)
        			break
        		end
        	end
        end
    end
   	touch_layer:setTouchEnabled(true)
    touch_layer:registerScriptTouchHandler(onTouchEvent,true)


    self:addChild(touch_layer)

    local function recvMsg()
		--print("PlanetDiamondLayer:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_RESP") then

			local proto = Tools.decode("PlanetGetResp",strData)
			print("PlanetGetResp result",proto.result, proto.type)

			-- gl:releaseLoading()

			if proto.result ~= 0 then
				print("error :",proto.result, proto.type)
			else

				if proto.type == 2 then
					local has_num = 0 
					for i,v in ipairs(list) do
						for i2,v2 in ipairs(proto.node_list) do
							if v2.id == v then
								has_num = has_num + 1
								break
							end
						end
					end

					if has_num == #list then
						self.get_city_info = true
						self:resetUI(proto.node_list)
					end
					
					for k,v in ipairs(proto.node_list) do
						for k1,v1 in ipairs(v.element_list) do
							if v1.type == 12 then
								if Tools.isEmpty(self.wangzuoData) then
									self.wangzuoData = v1.wangzuo_data
								end
							end
						end
					end
				end
			end
		end
	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)


end

function PlanetWorldLayer:onExitTransitionStart()

	printInfo("PlanetWorldLayer:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)

	if schedulerEntry ~= nil then
		scheduler:unscheduleScriptEntry(schedulerEntry)
	end

end

return PlanetWorldLayer