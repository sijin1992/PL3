local tips = require("util.TipsMessage"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local messageBox = require("util.MessageBox"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local player = require("app.Player"):getInstance()

local planetManager = require("app.views.PlanetScene.Manager.PlanetManager"):getInstance()

local planetMachine = require("app.views.PlanetScene.Manager.PlanetMachine"):getInstance()

local planetArmyManager = require("app.views.PlanetScene.Manager.PlanetArmyManager"):getInstance()

local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()

local g_sendList = require("util.SendList"):getInstance()

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local PlanetDiamondLayer = class("PlanetDiamondLayer", cc.load("mvc").ViewBase)

PlanetDiamondLayer.RESOURCE_FILENAME = "PlanetScene/PlanetDiamondLayer.csb"

PlanetDiamondLayer.RUN_TIMELINE = true

PlanetDiamondLayer.NEED_ADJUST_POSITION = true

PlanetDiamondLayer.haveWangzuoNode = false
PlanetDiamondLayer.haveTowerNode = false

PlanetDiamondLayer.wangzuoNode = nil


PlanetDiamondLayer.RESOURCE_BINDING = {
	--["Button_1"]   = {["varname"] = "btn"},
}

local node_tag = {
	kBg = 90,
	kStarYun = 91,
	kLightStar = 92,
	kStar = 94,
	kStone = 95,
	kYun = 93,
	kGezi = 101,
	kGrid = 102,
	kRes = 103,
	kResText = 104,
	kIcon = 105,
	kLine = 106,
	kShip = 107,
	kShipIcon = 108,
	kChoose = 109,
	kRed = 110,
}

local winSize = cc.Director:getInstance():getWinSize()

local schedulerEntry = nil
local schedulerEntry1 = nil
local schedulerTower = nil

local cube_w = g_Planet_Grid_Info.cube_w
local cube_h = g_Planet_Grid_Info.cube_h

local max_row = g_Planet_Grid_Info.row
local max_col = g_Planet_Grid_Info.col

local max_w = max_row*cube_w
local max_h = max_col*cube_h

local star_move_ = 0.15--0.5
local star_yun_move_1 = 0.111--0.333
local star_yun_move_2 = 0.1--0.25
local qiu_move_1 = 0.225--0.75
local qiu_move_2 = 0.25--0.8
local stone_move = 0.25--0.8

local star_yun_move_3 = 0.1
local qiu_move_3 = 0.225


local move_top = 0.6
local move_middle = 0.3
local move_bottom = 0.03
local speed_node_list = {move_top,move_middle,move_bottom}

local can_star_move = true

local default_size = {width = 1136, height = 768}

local screen_diff_pos = {{x = -winSize.width/2, y = winSize.height/2}, {x = -winSize.width/2, y = -winSize.height/2}, {x = winSize.width/2, y = -winSize.height/2}, {x = winSize.width/2, y = winSize.height/2}, {x = 0, y = winSize.height/2}, {x = 0, y = -winSize.height/2}, {x = -winSize.width/2, y = 0}, {x = winSize.width/2, y = 0}, {x = -winSize.width/4, y = winSize.height/2}, {x = winSize.width/4, y = winSize.height/2}, {x = winSize.width/2, y = winSize.height/4}, {x = winSize.width/2, y = -winSize.height/4}, {x = -winSize.width/4, y = -winSize.height/2}, {x = winSize.width/4, y = -winSize.height/2}, {x = -winSize.width/2, y = winSize.height/4}, {x = -winSize.width/2, y = -winSize.height/4}}

local lv_grid = {x = -627.5, y = -101.5}

local g_friction = 0.933333

local bg_node_move = {star_yun_move_1, star_yun_move_2, star_move_, qiu_move_1, qiu_move_2, stone_move,star_yun_move_3,qiu_move_3,qiu_move_3, 1}

local come_in_type = 1 --1基地  2目标点
local come_in_pos = {x = 0, y = 0} 
----------add by jinxin
PlanetDiamondLayer.attack_time_list = {}

------------------ BEGIN REGION WJJ --------------------

PlanetDiamondLayer.IS_DEBUG_LOG_VERBOSE = false
PlanetDiamondLayer._debug_count_create = 0

PlanetDiamondLayer.IS_DISABLE_DRAG = false
PlanetDiamondLayer.IS_DISABLE_DRAG_UPDATE = false
PlanetDiamondLayer.IS_DISABLE_DRAG_TOUCH = true
PlanetDiamondLayer.IS_DISABLE_OLD_MOVE_NODE = false

PlanetDiamondLayer.IS_UPDATE_NODES = true
PlanetDiamondLayer.IS_DRAG_GUAN_XING = false
PlanetDiamondLayer.IS_MOVE_DELTA_ADD = true

PlanetDiamondLayer.DRAG_UPDATE_YOUXIANJI = 1
PlanetDiamondLayer.DRAG_UPDATE_RES_INTERVAL = 1 * 1
PlanetDiamondLayer.DRAG_UPDATE_BIGNODE_INTERVAL = 1 * 30
PlanetDiamondLayer.RATE_DRAG_MOVED = 1

PlanetDiamondLayer.prevTileLoadTime = -1
PlanetDiamondLayer.prevTileMoveTime = -1

PlanetDiamondLayer.exConfig = require("util.ExConfig"):getInstance()

PlanetDiamondLayer.IS_TEST_DIAN_CI_TA = false

local initM = 0.0009
local initN = 0.0009

-----------------------------------------------------
-- ADD WJJ 20180621
PlanetDiamondLayer.IS_DEBUG_LOG_LOCAL = false

function PlanetDiamondLayer:_print(_log)
	if( self.IS_DEBUG_LOG_LOCAL ) then
		print(_log)
	end
end

-- function PlanetDiamondLayer:onCreate(data)

-- end


-----------------------------------------------------

function PlanetDiamondLayer:onCreate(data)
	self.data_ = data
    self.attack_time_list = {}
end

function PlanetDiamondLayer:onEnter()
  
	printInfo("PlanetDiamondLayer:onEnter()")

end

function PlanetDiamondLayer:onExit()
	
	printInfo("PlanetDiamondLayer:onExit()")
end


function PlanetDiamondLayer:createSelectNode( m,n )

	local rn = self:getResourceNode()

	local info = planetManager:getInfoByRowCol(m,n)
	if rn:getChildByName('selectNode') ~= nil then
		rn:getChildByName('selectNode'):removeFromParent()

		if rn:getChildByName("node2_"..self.choose_.m.."_"..self.choose_.n) then
			rn:getChildByName("node2_"..self.choose_.m.."_"..self.choose_.n):setVisible(true)
		end

		return
	end

	if info ~= nil then

		local pos1 = info.pos_list[1]

		if rn:getChildByName("node2_"..pos1.x.."_"..pos1.y) then

			rn:getChildByName("node2_"..pos1.x.."_"..pos1.y):setVisible(false)

			self.choose_.m = pos1.x
			self.choose_.n = pos1.y
		end
	else
		self.choose_.m = initM
		self.choose_.n = initN
	end

	local function getPos( element_info )
		if #element_info.pos_list == 1 then
			return self:getPosByCoordinate(element_info.pos_list[1].x, element_info.pos_list[1].y)
		else

			local rowcol_min = 0
			local rowcol_max = 0

			for i3,v3 in ipairs(element_info.pos_list) do
				if rowcol_min == 0 then
					rowcol_min = i3
				else
					if element_info.pos_list[rowcol_min].x + element_info.pos_list[rowcol_min].y > v3.x + v3.y then
						rowcol_min = i3
					end
				end

				if rowcol_max == 0 then
					rowcol_max = i3
				else
					if element_info.pos_list[rowcol_max].x + element_info.pos_list[rowcol_max].y < v3.x + v3.y then
						rowcol_max = i3
					end
				end
				
			end

			local pos = {}
			if rowcol_min == rowcol_max then
				pos = self:getPosByCoordinate(element_info.pos_list[rowcol_max].x, element_info.pos_list[rowcol_max].y)
			else

				local p1 = self:getPosByCoordinate(element_info.pos_list[rowcol_max].x, element_info.pos_list[rowcol_max].y)
				local p2 = self:getPosByCoordinate(element_info.pos_list[rowcol_min].x, element_info.pos_list[rowcol_min].y)

				pos.x = ( p1.x + p2.x )/2
				pos.y = ( p1.y + p2.y )/2
			end


			return pos
		end
	end


	if info == nil then

		local data = {bool = true, info = {pos = {m,n}}}

		local node =require("app.views.PlanetScene.PlanetSelectNode"):setPlanetSelectNode(data , rn)
		node:setPosition(self:getPosByCoordinate(m,n))
		node:setLocalZOrder(node_tag.kChoose)
		node:setName("selectNode")
		rn:addChild(node)

	else
		local list = Split(info.global_key, "_")

		local node_id = tonumber(list[1])
		local guid = tonumber(list[2])

		print("getInfoByNodeGUID", node_id, guid, planetManager:getInfoByNodeGUID(node_id, guid))
		local data = {bool = false, info = {guid = guid, node_id = node_id, pos = {m,n}}}

		local node =require("app.views.PlanetScene.PlanetSelectNode"):setPlanetSelectNode(data , rn)
		node:setPosition(getPos(info))
		node:setLocalZOrder(node_tag.kChoose)
		node:setName("selectNode")
		rn:addChild(node)

	end
	cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("PlanetSelectNodeOpen")
end

function PlanetDiamondLayer:checkTouch( pos ) --


	local x = pos.x 
	local y = pos.y 

	local m = math.floor(x/cube_w - y/cube_h)
	local n = math.floor(x/cube_w + y/cube_h)

	--local scale = winSize.width/winSize.height
	--if scale>2.2 then
	--	n = n - 3
	--	print("1111111111111111111",scale)
	--elseif scale>2.0 then
	--	n = n - 2
	--	print("22222222222222222222",scale)
	--end

	print("check",m,n,x,y,cube_w,cube_h)

	print("check big",self:checkTouchBig(cc.p(pos.x + max_w/2, pos.y)))
	if self:checkTouchBig(cc.p(pos.x + max_w/2, pos.y)) == 0 then
		return
	end 

	self:createSelectNode(m,n)
	-- return m,n

end

function PlanetDiamondLayer:checkTouchBig( pos )
	local rn = self:getResourceNode()

	local x = pos.x 
	local y = pos.y 

	local m = math.floor(x/max_w - y/max_h)
	local n = math.floor(x/max_w + y/max_h)

	for i,v in ipairs(CONF.PLANETWORLD.getIDList()) do
		local conf = CONF.PLANETWORLD.get(v)

		if conf.ROW == m and conf.COL == n then
			return conf.ID
		end
	end

	return 0

	--self:checkAround(m,n)

	-- print("around",#self:checkAround(m,n))
end

function PlanetDiamondLayer:checkDistance(  )

	local function getRowCol( )
		local tu_pos = cc.p(self.mid_pos.x, self.mid_pos.y) 

		local win_pos = cc.p(default_size.width/2 , default_size.height/2)

		local diff = cc.pSub(win_pos, tu_pos)
		-- print("diff",diff.x,diff.y)

		local xx,yy = getScreenDiffLocation()

		local ox = 0
		local oy = 0
		if CC_DESIGN_RESOLUTION.autoscale == "FIXED_HEIGHT" then
			ox = (winSize.width - CC_DESIGN_RESOLUTION.width) /2
			oy = yy/2 - math.abs((winSize.height - CC_DESIGN_RESOLUTION.height) /2)
		end

		local pos = cc.p(diff.x + xx/2 - ox, diff.y + yy/2 - oy)
		
		local rn = self:getResourceNode()

		local x = pos.x 
		local y = pos.y 

		local m = math.floor(x/cube_w - y/cube_h)
		local n = math.floor(x/cube_w + y/cube_h)

		return m,n
	end

	local rn = self:getResourceNode()

	if planetManager:getPlanetElement() == nil then
		return
	end

	local base_pos = planetManager:getUserBaseElementPos()

	if base_pos == nil then
		return
	end

	local base_ditu_pos = self:getPosByCoordinate(base_pos.x, base_pos.y)

	-- local win_pos = cc.p(default_size.width/2, default_size.height/2)
	local win_pos = cc.p(self:getParent():getUILayer():getResourceNode():getChildByName("Button_fanhui"):getPosition())

	local m,n = getRowCol()

	local diff = {}
	diff.x = base_pos.x - m
	diff.y = base_pos.y - n

	local length = math.floor(Tools.getLength(diff))

	self:getParent():getUILayer():getResourceNode():getChildByName("Button_fanhui"):getChildByName("text"):setString(length..CONF:getStringValue("Light"))

	self:getParent():getUILayer():getResourceNode():getChildByName("jiantou"):setRotation(90 - getAngleByPos(win_pos, base_ditu_pos))

	if length <= 3 then
		self:getParent():getUILayer():getResourceNode():getChildByName("Button_fanhui"):setVisible(false)
		self:getParent():getUILayer():getResourceNode():getChildByName("jiantou"):setVisible(false)
	else
		self:getParent():getUILayer():getResourceNode():getChildByName("Button_fanhui"):setVisible(true)
		self:getParent():getUILayer():getResourceNode():getChildByName("jiantou"):setVisible(true)
	end


	-------------------------------------------------------------
	local function resetUIFindText( )

		local m,n = self:getMidPos()

		local str = "#FFFFFF02(#F3E4A902X:#FFFFFF02"..m..",#F3E4A902Y:#FFFFFF02"..n..")"

		if self:getMidNodeID() == 0 then
			str = "#FFFFFF02  "
		end

		self:getParent():getUILayer():resetFindText(str)
	end

	resetUIFindText()

end

function PlanetDiamondLayer:checkAround( m,n )

	local around = {{0,0}, {1,0}, {-1,0}, {0,-1}, {0,1}, {-1,-1}, {-1,1}, {1,-1}, {1,1}}

	local intersect = {}

	local around_dis = {}

	local diff = {{x = -max_w/2, y = 0}, {x = 0, y = max_h/2}, {x = max_w/2, y = 0}, {x = 0, y = -max_h/2}}

	local screen_pos = {{x = winSize.width/2, y = 0}, {x = winSize.width, y = winSize.height/2}, {x = winSize.width/2, y = winSize.height}, {x = 0, y = winSize.height/2}}

	local xx,yy = getScreenDiffLocation()

	for i,v in ipairs(around) do
		local mm = m + v[1]
		local nn = n + v[2]

		for i2,v2 in ipairs(CONF.PLANETWORLD.getIDList()) do
			local conf = CONF.PLANETWORLD.get(v2)

			if conf.ROW == mm and conf.COL == nn then
				local xj = true				

				local dis = {num = 0, type = 0, gezi_type = 0}

				for i3,v3 in ipairs(diff) do

					local x = self.mid_pos.x + (mm*max_w/2 + nn*max_w/2) + v3.x
					local y = self.mid_pos.y + (mm*max_h/2 - nn*max_h/2) + v3.y

					for i4,v4 in ipairs(screen_pos) do
						if dis.num == 0 then
							dis.num = cc.pGetDistance(cc.p(x,y), cc.p(v4.x,v4.y))
							dis.type = i4
							dis.gezi_type = i3
						else
							if dis.num > cc.pGetDistance(cc.p(x,y), cc.p(v4.x,v4.y)) then
								dis.num = cc.pGetDistance(cc.p(x,y), cc.p(v4.x,v4.y))
								dis.type = i4
								dis.gezi_type = i3
							end
						end
					end
				end
				
				print("disssss",dis.num, dis.gezi_type,dis.type,conf.ID)

				-- if i == 1 then
					local x = self.mid_pos.x + (mm*max_w/2 + nn*max_w/2) + diff[dis.gezi_type].x
					local y = self.mid_pos.y + (mm*max_h/2 - nn*max_h/2) + diff[dis.gezi_type].y

					 if dis.type == 1 or dis.type == 3 then
						if y <= winSize.height/2 then

							local distance = math.abs(y)
							if winSize.width > distance/max_h*2*max_w then
								xj = false
							end

						else

							local distance = math.abs(y - winSize.height)
							if winSize.width > distance/max_h*2*max_w then
								xj = false
							end

						end

					elseif dis.type == 2 or dis.type == 4 then
						if x <= winSize.width/2 then

							local distance = math.abs(x)
							if winSize.height > distance/max_w*2*max_h then
								xj = false

							end

						else

							local distance = math.abs(x - winSize.width)
							if winSize.height > distance/max_w*2*max_h then
								xj = false

							end

						end
					end

				-- end


				if xj then
					local tt = {num = dis.num, id = conf.ID}
					table.insert(around_dis , tt)

				end

				break

			end
		end
	end

	local min_num = 0
	for i,v in ipairs(around_dis) do
		if min_num == 0 then
			min_num = v.num
		else
			if min_num > v.num then
				min_num = v.num
			end
		end
	end

	for i,v in ipairs(around_dis) do
		if v.num == min_num then
			table.insert(intersect, v.id)
		end
	end

	return intersect

end

function PlanetDiamondLayer:SetNodePos( _node,diff )
	local pp = cc.p(_node:getPosition())
	_node:setPosition(cc.p(pp.x+diff.x,pp.y+diff.y))
end

-- ADD BY WJJ
function PlanetDiamondLayer:moveBaseLayerWJJ( diff,refresh )
	local rn = self:getResourceNode()
	self:SetNodePos( rn,diff )
	if refresh then
		self:getBigNode()
	end
end

function PlanetDiamondLayer:moveNode( diff,refresh )
	self:_print("@@@@ PlanetDiamondLayer moveNode")
	local move_time_begin = os.clock()
	-- print("move_time begin", move_time_begin)

	-- disable move... wjj 20180621
	if(self.IS_DISABLE_DRAG) then
		-- do return false end
	end

	if(self.IS_DISABLE_OLD_MOVE_NODE) then
		self:moveBaseLayerWJJ( diff,refresh )
		do return false end
	end



	local rn = self:getResourceNode()

	for i,v in ipairs(self.cubes) do
		self:_print("@@@@ cubes node name: " .. tostring(v:getName()))
		local pp = cc.p(v:getPosition())
		v:setPosition(cc.p(pp.x+diff.x,pp.y+diff.y))
	end

	for i,v in ipairs(self.gezis) do
		self:_print("@@@@ gezis node name: " .. tostring(v:getName()))
		local pp = cc.p(v:getPosition())
		v:setPosition(cc.p(pp.x+diff.x,pp.y+diff.y))
	end
	
	local star = rn:getChildByName("star")
	local star_pos = cc.p(star:getPosition())

	if star_pos.x > default_size.width then
		star_pos.x = star_pos.x - default_size.width 
	elseif star_pos.x < -default_size.width then
		star_pos.x = star_pos.x + default_size.width
	end

	if star_pos.y > default_size.height then
		star_pos.y = star_pos.y - default_size.height
	elseif star_pos.y < -default_size.height then
		star_pos.y = star_pos.y + default_size.height
	end

	if can_star_move then
		star:setPosition(cc.p(star_pos.x+diff.x*star_move_,star_pos.y+diff.y*star_move_))
	else
		star:setPosition(cc.p(default_size.width/2, default_size.height/2))
	end
	
	self:_print("@@@@ star node name: " .. tostring(star:getName()))

	self.mid_pos.x = self.mid_pos.x + diff.x
	self.mid_pos.y = self.mid_pos.y + diff.y

	for i,v in ipairs(self.now_see_list) do
		if v.node_list then
			for i2,v2 in ipairs(v.node_list) do
				self:_print("@@@@ now_see_list node name: " .. tostring(v2:getName()))
				local s_pos = cc.p(v2:getPosition())
				v2:setPosition(cc.p(s_pos.x+diff.x,s_pos.y+diff.y))
			end
		end
	end

	if rn:getChildByName("selectNode") then
		local pos = cc.p(rn:getChildByName("selectNode"):getPosition())
		rn:getChildByName("selectNode"):setPosition(cc.p(pos.x+diff.x,pos.y+diff.y))
	end
	
	for i,v in ipairs(self._pam:getArmyList()) do
		if v.line then
			for i2,v2 in ipairs(v.line) do
				self:_print("@@@@ getArmyList node name: " .. tostring(v2:getName()))
				local s_pos = cc.p(v2:getPosition())
				v2:setPosition(cc.p(s_pos.x+diff.x,s_pos.y+diff.y))
			end
			
		end

		if v.ship then
			self:_print("@@@@ getArmyList v.ship name: " .. tostring(v.ship:getName()))
			local s_pos = cc.p(v.ship:getPosition())
			v.ship:setPosition(cc.p(s_pos.x+diff.x,s_pos.y+diff.y))
		end
	end

	-- for i,v in ipairs(self.bg_icon) do
	-- 	local pos = cc.p(v.icon:getPosition())
	-- 	v.icon:setPosition(cc.p(pos.x+diff.x*v.speed,pos.y+diff.y*v.speed))
	-- end

	-- for i=1,10 do
	-- 	local pos = cc.p(rn:getChildByName("bg_node_"..i):getPosition())
	-- 	local _node = rn:getChildByName("bg_node_"..i)
	-- 	_node:setPosition(cc.p(pos.x+diff.x*bg_node_move[i],pos.y+diff.y*bg_node_move[i]))
	-- 	self:_print("@@@@ bg_node_ name: " .. tostring(_node:getName()))
	-- end
	for i=1,#speed_node_list do
		local pos = cc.p(rn:getChildByName("bg_node_"..i):getPosition())
		local _node = rn:getChildByName("bg_node_"..i)
		_node:setPosition(cc.p(pos.x+diff.x*bg_node_move[i],pos.y+diff.y*bg_node_move[i]))
		self:_print("@@@@ bg_node_ name: " .. tostring(_node:getName()))
	end
	if refresh then
		self:getBigNode()
	end

	local move_time_ended = os.clock()
	-- print("move_time ended", move_time_ended)
	local _passed = move_time_ended - move_time_begin
	if( _passed > 0.02 ) then
		print("move_time PASSED: ", _passed)
	end

end

function PlanetDiamondLayer:moveLayer( m, n, id )

	self:_print(string.format("PlanetDiamondLayer:moveLayer m: %s n: %s id: %s",tostring(m),tostring(n),tostring(id)))

	self.see_ship = 0

	can_star_move = false

	local mid_diff = cc.p(default_size.width/2 - self.mid_pos.x - cube_w/2 , default_size.height/2 - self.mid_pos.y )

	if(false == self.IS_DISABLE_DRAG) then
		self:moveNode(mid_diff,true)
	end

	can_star_move = false

	local x = -(m*max_w/2 + n*max_w/2)
	local y = -(-m*max_h/2 + n*max_h/2)

	local diff = cc.p(x,y)

	if(false == self.IS_DISABLE_DRAG) then
		self:moveNode(diff,true)
	end

	can_star_move = true

	for i,v in ipairs(self.now_see_list) do
		if v.node_list then
			for i2,v2 in ipairs(v.node_list) do
				v2:removeFromParent()
			end
		end
	end

	self.now_see_list = {}

	-- for i=1,7 do
	-- 	for i,v in ipairs(self:getResourceNode():getChildByName("bg_node_"..i):getChildren()) do
	-- 		v:removeFromParent()
	-- 	end
		
	-- end

	local tt = {id = id, node_list = {}}
	table.insert(self.now_see_list, tt)

	self:sendMessage({id})

	self:checkDistance()

end

function PlanetDiamondLayer:moveByRowCol( m, n, id)

	self:_print(string.format("PlanetDiamondLayer:moveByRowCol m: %s n: %s id: %s",tostring(m),tostring(n),tostring(id)))

	self.see_ship = 0

	local mid_diff = cc.p(default_size.width/2 - self.mid_pos.x - cube_w/2, default_size.height/2 - self.mid_pos.y )

	if(false == self.IS_DISABLE_DRAG) then
		self:moveNode(mid_diff)
	end

	local x = -(m*cube_w/2 + n*cube_w/2)
	local y = -(-m*cube_h/2 + n*cube_h/2)

	local diff = cc.p(x,y)

	if(false == self.IS_DISABLE_DRAG) then
		self:moveNode(diff)
	end


	-- for i,v in ipairs(self.now_see_list) do
	-- 	if v.node_list then
	-- 		for i2,v2 in ipairs(v.node_list) do
	-- 			v2:removeFromParent()
	-- 		end
	-- 	end
	-- end

	-- local function checkId( id )
	-- 	for i,v in ipairs(self.now_see_list) do
	-- 		if v.id == id then
	-- 			return true
	-- 		end
	-- 	end

	-- 	return false
	-- end

	-- for i,v in ipairs(id) do

	-- 	if not checkId(v) then
	-- 		local tt = {id = v, node_list = {}}
	-- 		table.insert(self.now_see_list, tt)
	-- 	end
	-- end

	-- for i,v in ipairs(id) do
	-- 	print("mmmmmmm",i,v)
	-- end

	-- self:sendMessage(id)
	local lc = cc.p(winSize.width/2, winSize.height/2)

	local tu_pos = cc.p(self.mid_pos.x - max_w/2, self.mid_pos.y) 

	local diff = cc.pSub(lc, tu_pos)
	-- print("diff",diff.x,diff.y)

	local xx,yy = getScreenDiffLocation()

	local ox = 0
	local oy = 0
	if CC_DESIGN_RESOLUTION.autoscale == "FIXED_HEIGHT" then
		ox = (winSize.width - CC_DESIGN_RESOLUTION.width) /2
		oy = yy/2 - math.abs((winSize.height - CC_DESIGN_RESOLUTION.height) /2)
	end

	local pos = cc.p(diff.x + xx/2 - ox, diff.y + yy/2 - oy)
	local pos_id = self:checkTouchBig(pos)

	local big_id = {}

	if pos_id ~= 0 then
		table.insert(big_id,pos_id)
	end


	for i,v in ipairs(screen_diff_pos) do
		local pp = cc.p(pos.x + v.x, pos.y + v.y)
		local id = self:checkTouchBig(pp)

		if id ~= 0 then
			local has = false
			for i2,v2 in ipairs(big_id) do
				if v2 == id then
					has = true
					break
				end
			end

			if not has then
				table.insert(big_id,id)
			end
		end
	end

	if not Tools.isEmpty(big_id) then
		table.insert(big_id, tonumber(Split(planetManager:getPlanetUserBaseElementKey(), "_")[1]))
		self:changeInfo(big_id)
	end

	self:checkDistance()
end

function PlanetDiamondLayer:moveToJinCityNode( ... )

	local node_id = tonumber(Split(planetManager:getPlanetUserBaseElementKey(), "_")[1])
	local base_conf = CONF.PLANETWORLD.get(node_id)
	local base_x = base_conf.ROW 
	local base_y = base_conf.COL 

	local min_city_id = 0
	local min_diff = 100000
	for i,v in ipairs(CONF.PLANETCITY.getIDList()) do
		local conf = CONF.PLANETWORLD.get(v)
		local diff = math.sqrt(math.pow(conf.ROW - base_x,2) + math.pow(conf.COL - base_y,2))
		if diff < min_diff then
			min_diff = diff 
			min_city_id = v
		end
	end

	local conf = CONF.PLANETWORLD.get(min_city_id)
	self:moveLayer(conf.ROW, conf.COL, min_city_id)
end

function PlanetDiamondLayer:moveToJinResNode( ... )

	local base_pos = planetManager:getUserBaseElementPos()
	local base_x = base_pos.x
	local base_y = base_pos.y
	local node_id = tonumber(Split(planetManager:getPlanetUserBaseElementKey(), "_")[1])

	local min_diff = 100000
	local min_x = 0
	local min_y = 0

	if planetManager:getInfoByNodeID(node_id) then
		for i,v in ipairs(planetManager:getInfoByNodeID(node_id)) do

			if v.type == 2 then

				local x = v.pos_list[1].x 
				local y = v.pos_list[1].y 

				local diff = math.sqrt(math.pow(x - base_x,2) + math.pow(y - base_y,2))
				if diff < min_diff then
					min_x = x 
					min_y = y
				end
			end

		end

		self:moveByRowCol(min_x, min_y, {node_id})
	end
	
end

function PlanetDiamondLayer:moveBackUserBase()
    local globalkey = planetManager:getPlanetUser().base_global_key
    if globalkey == nil then
        return
    end
	local node_id = tonumber(Split(globalkey, "_")[1])

	local pos = planetManager:getUserBaseElementPos()

	if pos and node_id then
		self:moveByRowCol(pos.x, pos.y, {node_id})
	end
end

function PlanetDiamondLayer:moveByShip()



	local army = nil 
	for i,v in ipairs(self._pam:getArmyList()) do
		if Split(v.info.user_key, "_")[1] == player:getName() and tonumber(Split(v.info.user_key, "_")[2]) == self.see_ship then

			self:_print(string.format("PlanetDiamondLayer:moveByShip v.ship:getName: %s",tostring(v.ship:getName())))

			local mid_diff = cc.p(default_size.width/2 - self.mid_pos.x , default_size.height/2 - self.mid_pos.y )

			if(false == self.IS_DISABLE_DRAG) then
				self:moveNode(mid_diff)
			end

			local pos = cc.p(v.ship:getPosition())
			local win_pos = cc.p(winSize.width/2, winSize.height/2)

			local diff_pos = cc.pSub(win_pos, pos)

			if(false == self.IS_DISABLE_DRAG) then
				self:moveNode(diff_pos)
			end

			if v.ship and v.ship:getChildByName("menu") then
				v.ship:getChildByName("menu"):getChildByName("time"):setString(CONF:getStringValue("yidong_time")..":"..formatTime((v.info.need_time - v.info.sub_time) - (player:getServerTime() - v.info.begin_time)))
				v.ship:getChildByName("menu"):setRotation(-v.ship:getRotation())
			end

			local lc = cc.p(winSize.width/2, winSize.height/2)

			local tu_pos = cc.p(self.mid_pos.x - max_w/2, self.mid_pos.y) 

			local diff = cc.pSub(lc, tu_pos)
			-- print("diff",diff.x,diff.y)

			local xx,yy = getScreenDiffLocation()

			local ox = 0
			local oy = 0
			if CC_DESIGN_RESOLUTION.autoscale == "FIXED_HEIGHT" then
				ox = (winSize.width - CC_DESIGN_RESOLUTION.width) /2
				oy = yy/2 - math.abs((winSize.height - CC_DESIGN_RESOLUTION.height) /2)
			end

			local pos = cc.p(diff.x + xx/2 - ox, diff.y + yy/2 - oy)
			local pos_id = self:checkTouchBig(pos)

			local big_id = {}

			if pos_id ~= 0 then
				table.insert(big_id,pos_id)
			end


			for i,v in ipairs(screen_diff_pos) do
				local pp = cc.p(pos.x + v.x, pos.y + v.y)
				local id = self:checkTouchBig(pp)

				if id ~= 0 then
					local has = false
					for i2,v2 in ipairs(big_id) do
						if v2 == id then
							has = true
							break
						end
					end

					if not has then
						table.insert(big_id,id)
					end
				end
			end

			if not Tools.isEmpty(big_id) then
				table.insert(big_id, tonumber(Split(planetManager:getPlanetUserBaseElementKey(), "_")[1]))
				self:changeInfo(big_id)
			end

			break

		end
	end
end

function PlanetDiamondLayer:resetSee_list(big_id_list)

	for i=#self.now_see_list,1,-1 do
		local has = false

		for i2,v2 in ipairs(big_id_list) do

			if self.now_see_list[i].id == v2 then
				has = true
				break
			end

		end

		if not has then
			if self.now_see_list[i].node_list then
				for m,n in ipairs(self.now_see_list[i].node_list) do
					n:removeFromParent()
				end

				self.now_see_list[i].node_list = {}
			end

			table.remove(self.now_see_list, i)
		end
	end

	for i,v in ipairs(big_id_list) do

		local has_id = false
		local has_node = false
		for i2,v2 in ipairs(self.now_see_list) do 

			if v2.id == v then
				has_id = true

				if not Tools.isEmpty(v2.node_list) then
					has_node = true
				end

				break
			end

		end

		if not has_id then
			local tt = {id = v, node_list = {}}
			table.insert(self.now_see_list, tt)
		end
	end
end

function PlanetDiamondLayer:changeInfo( big_id_list )
	self:resetSee_list(big_id_list)
	local need_get_id_list = {}
	for i,v in ipairs(big_id_list) do

		local has_id = false
		local has_node = false
		for i2,v2 in ipairs(self.now_see_list) do 

			if v2.id == v then
				has_id = true

				if not Tools.isEmpty(v2.node_list) then
					has_node = true
				end

				break
			end

		end

		if not has_node then
			table.insert(need_get_id_list, v)
		end

		if not has_id then
			table.insert(need_get_id_list, v)
		end
	end
	
	if not Tools.isEmpty(need_get_id_list) then
		self:sendMessage(big_id_list)
	end
end

function PlanetDiamondLayer:sendMessage( list )
	if Tools.isEmpty(list) then
		return
	end

	local strData = Tools.encode("PlanetGetReq", {
		node_id_list = list,
		type = 2,
	 })
	-- GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData)
	g_sendList:addSend({define = "CMD_PLANET_GET_REQ", strData = strData, key = "planet_get_type_2"})

	-- gl:retainLoading()
end

function PlanetDiamondLayer:getPosByCoordinate( m,n )
	
	local x = m*cube_w/2 + n*cube_w/2 + self.mid_pos.x
	local y = -m*cube_h/2 + n*cube_h/2 + self.mid_pos.y

	x = x + cube_w/2
	local pos = cc.p(x,y)

	return pos

end

function PlanetDiamondLayer:resetNode2Info( node_2, info )

	local x = tonumber(Split(node_2:getName(), "_")[2])
	local y = tonumber(Split(node_2:getName(), "_")[3])
	local node_1 = self:getResourceNode():getChildByName("node1_"..x.."_"..y)

	if x == self.choose_.m and y == self.choose_.n and self:getResourceNode():getChildByName("selectNode") then
		node_2:setVisible(false)
	else
		node_2:setVisible(true)
	end

	local icon = node_1:getChildByName("icon")
	local back = node_2:getChildByName("back")
	local text = node_2:getChildByName("text")
	local group = node_2:getChildByName("group")
	local name = node_2:getChildByName("name")
	local line = node_2:getChildByName("line")

	-- icon:setScale(0.4)

	if info.type == 1 then

		local base_data = info.base_data

		if base_data.info.building_level_list[1] == nil or base_data.info.building_level_list[1] == 0 then
			base_data.info.building_level_list[1] = 1
		end

		local lv = CONF.BUILDING_1.get(base_data.info.building_level_list[1])
		self._print("@@@@ icon setTexture : " .. tostring(lv or " nil") )

		icon:setTexture("PlanetIcon/"..lv.IMAGE..".png")

		local max_destroy = CONF.PARAM.get("planet_destroy_value_limit").PARAM
		local now_destroy = base_data.destroy_value
		if now_destroy/max_destroy*100 >= CONF.PARAM.get("spaceport_fire").PARAM then
			node_1:getChildByName("huo_texiao"):setVisible(true)

			animManager:runAnimByCSB(node_1:getChildByName("huo_texiao"), "PlanetScene/sfx/kongjianzhanzhuoshao/zhaohuo.csb", "1")
		else
			node_1:getChildByName("huo_texiao"):setVisible(false)
		end

		if base_data.shield_start_time > 0 then
			if player:getServerTime() - base_data.shield_start_time <= base_data.shield_time then
				node_1:getChildByName("shield"):setVisible(true)
				-- animManager:runAnimByCSB(node_1:getChildByName("shield"), "PlanetScene/sfx/kongjianzhan/shield.csb", "1")
			else
				node_1:getChildByName("shield"):setVisible(false)
			end
		else
			node_1:getChildByName("shield"):setVisible(false)
		end

		if base_data.info.group_nickname ~= nil and base_data.info.group_nickname ~= "" then

			node_2:getChildByName("name"):setString(base_data.info.nickname)
			node_2:getChildByName("group"):setString(base_data.info.group_nickname)

			if base_data.info.user_name == player:getName() then
				node_2:getChildByName("text"):setString(CONF:getStringValue("My_station"))

				node_2:getChildByName("line"):setTexture("PlanetScene/ui/base_line_g.png")
				node_2:getChildByName("back"):loadTexture("PlanetScene/ui/my_res.png")
			else

				text:setVisible(false)

				node_2:getChildByName("line"):setVisible(false)
				node_2:getChildByName("name"):setVisible(true)
				node_2:getChildByName("group"):setVisible(true)
				node_2:getChildByName("di_3"):setVisible(true)
				node_2:getChildByName("di_2"):setVisible(true)
				node_2:getChildByName("di_1"):setVisible(false)

				node_2:getChildByName("back"):setContentSize(cc.size(1,50))
				if player:checkPlayerIsInGroup(base_data.info.user_name) then
					node_2:getChildByName("line"):setTexture("PlanetScene/ui/base_line.png")
					node_2:getChildByName("back"):loadTexture("PlanetScene/ui/group_res.png")

					name:setTextColor(cc.c4b(156,255,182,255))
					-- name:enableShadow(cc.c4b(156,255,182,255), cc.size(0.5,0.5))

					group:setTextColor(cc.c4b(156,255,182,255))
					-- group:enableShadow(cc.c4b(156,255,182,255), cc.size(0.5,0.5))
					if base_data.info.user_name ~= player:getName() then
						name:setTextColor(cc.c4b(156,217,255,255))
						-- name:enableShadow(cc.c4b(156,217,255,255), cc.size(0.5,0.5))
						group:setTextColor(cc.c4b(156,217,255,255))
						-- group:enableShadow(cc.c4b(156,217,255,255), cc.size(0.5,0.5))
					end
				else
					node_2:getChildByName("line"):setTexture("PlanetScene/ui/base_line_r.png")
					node_2:getChildByName("back"):loadTexture("PlanetScene/ui/enemy_res.png")

					name:setTextColor(cc.c4b(255,70,70,255))
					-- name:enableShadow(cc.c4b(255,70,70,255), cc.size(0.5,0.5))

					group:setTextColor(cc.c4b(255,70,70,255))
					-- group:enableShadow(cc.c4b(255,70,70,255), cc.size(0.5,0.5))
				end

			end

		else
			text:setString(base_data.info.nickname)	

			text:setVisible(true)

			node_2:getChildByName("line"):setVisible(false)
			node_2:getChildByName("name"):setVisible(false)
			node_2:getChildByName("group"):setVisible(false)
			node_2:getChildByName("di_3"):setVisible(false)
				node_2:getChildByName("di_2"):setVisible(false)
				node_2:getChildByName("di_1"):setVisible(true)

			node_2:getChildByName("back"):setContentSize(cc.size(1,25))

			if base_data.info.user_name == player:getName() then
				text:setString(CONF:getStringValue("My_station"))
			end

			if base_data.info.user_name == player:getName() then
				node_2:getChildByName("line"):setTexture("PlanetScene/ui/base_line_g.png")
				node_2:getChildByName("back"):loadTexture("PlanetScene/ui/my_res.png")

				text:setTextColor(cc.c4b(156,255,182,255))
				-- text:enableShadow(cc.c4b(156,255,182,255), cc.size(0.5,0.5))

			else
				node_2:getChildByName("line"):setTexture("PlanetScene/ui/base_line_r.png")
				node_2:getChildByName("back"):loadTexture("PlanetScene/ui/enemy_res.png")

				text:setTextColor(cc.c4b(255,70,70,255))
				-- text:enableShadow(cc.c4b(255,70,70,255), cc.size(0.5,0.5))
			end
		end

	elseif info.type == 2 then

		local res_data = info.res_data

		local conf = CONF.PLANET_RES.get(info.res_data.id)

		icon:setTexture("PlanetIcon/"..conf.RES_ID..".png")

		text:setTextColor(cc.c4b(255,244,156,255))
		-- text:enableShadow(cc.c4b(255,244,156,255), cc.size(0.5,0.5))

		if res_data.user_name ~= "" then
			if res_data.user_name == player:getName() then
				back:loadTexture("PlanetScene/ui/my_res.png")
				text:setTextColor(cc.c4b(156,255,182,255))
				-- text:enableShadow(cc.c4b(156,255,182,255), cc.size(0.5,0.5))
			else
				if player:checkPlayerIsInGroup( res_data.user_name ) then
					back:loadTexture("PlanetScene/ui/group_res.png")
					text:setTextColor(cc.c4b(156,255,182,255))
					-- text:enableShadow(cc.c4b(156,255,182,255), cc.size(0.5,0.5))
				else
					back:loadTexture("PlanetScene/ui/enemy_res.png")
					text:setTextColor(cc.c4b(255,70,70,255))
					-- text:enableShadow(cc.c4b(255,70,70,255), cc.size(0.5,0.5))
				end

			end

		else
			if res_data.hasMonster then
				back:loadTexture("PlanetScene/ui/monster_res.png")
			else
				back:loadTexture("PlanetScene/ui/noPeople_res.png")
			end

		end

		text:setString("Lv."..conf.LEVEL.." "..CONF:getStringValue(conf.NAME))

	elseif info.type == 3 then

		local ruins_data = info.ruins_data

		local conf = CONF.PLANET_RUINS.get(info.ruins_data.id)

		icon:setTexture("PlanetIcon/"..conf.RES_ID..".png")
		text:setTextColor(cc.c4b(255,244,156,255))
		-- text:enableShadow(cc.c4b(255,244,156,255), cc.size(0.5,0.5))

		if ruins_data.user_name ~= "" then
			if ruins_data.user_name == player:getName() then
				back:loadTexture("PlanetScene/ui/my_res.png")

				text:setTextColor(cc.c4b(156,255,182,255))
				-- text:enableShadow(cc.c4b(156,255,182,255), cc.size(0.5,0.5))
			else
				if player:checkPlayerIsInGroup( ruins_data.user_name ) then
					back:loadTexture("PlanetScene/ui/group_res.png")

					text:setTextColor(cc.c4b(156,217,255,255))
					-- text:enableShadow(cc.c4b(156,217,255,255), cc.size(0.5,0.5))
				else
					back:loadTexture("PlanetScene/ui/enemy_res.png")

					text:setTextColor(cc.c4b(255,70,70,255))
					-- text:enableShadow(cc.c4b(255,70,70,255), cc.size(0.5,0.5))
				end

			end

		else
			back:loadTexture("PlanetScene/ui/monster_res.png")
		end

		text:setString("Lv."..conf.LEVEL.." "..CONF:getStringValue(conf.NAME))
	elseif info.type == 4 then

		text:setVisible(false)
		back:setVisible(false)

		local boss_data = info.boss_data
		local boss_conf = CONF.PLANETBOSS.get(boss_data.id)
		icon:setTexture("PlanetIcon/"..boss_conf.ICON..".png")

		node_2:getChildByName("boss_text"):setString(CONF:getStringValue(boss_conf.NAME))

		node_2:getChildByName("boss_text"):setVisible(true)
		node_2:getChildByName("boss_back"):setVisible(true)
		node_2:getChildByName("xue"):setVisible(true)
		node_2:getChildByName("xuetiao"):setVisible(true)
		node_2:getChildByName("xue_text"):setVisible(true)
		node_2:getChildByName("led"):setVisible(true)

		local xue_max = 0
		local add_boss_xue = false
		for i,v in ipairs(boss_conf.MONSTER_LIST) do
			if v ~= 0 then
				if v < 0 then
					if add_boss_xue == false then
						xue_max = CONF.AIRSHIP.get(math.abs(v)).LIFE + xue_max
						add_boss_xue = true
					end
				else
					xue_max = CONF.AIRSHIP.get(math.abs(v)).LIFE + xue_max
				end
			end
		end

		local xue_now = 0
		if #boss_data.monster_hp_list == 0 then
			xue_now = xue_max
		else
			for i,v in ipairs(boss_data.monster_hp_list) do
				xue_now = xue_now + v
			end
		end

		local percent = math.floor(xue_now/xue_max*100)
		node_2:getChildByName("xue"):setContentSize(cc.size(node_2:getChildByName("xue"):getTag()*(xue_now/xue_max), node_2:getChildByName("xue"):getContentSize().height))
		node_2:getChildByName("xue_text"):setString(percent.."%")

		local time = boss_conf.REMOVE_TIME - (player:getServerTime() - boss_data.create_time)
		node_2:getChildByName("led"):getChildByName("text"):setString(formatTime(time))

	elseif info.type == 5 then

		local city_data = info.city_data

		icon:setTexture("PlanetIcon/"..CONF.PLANETCITY.get(city_data.id).ICON..".png")

		text:setString(CONF:getStringValue(CONF.PLANETCITY.get(city_data.id).NAME))
		node_2:getChildByName("line"):setTexture("PlanetScene/ui/line_4.png")

		local back = node_2:getChildByName("biaotidi")
		back:setTexture("PlanetScene/ui/biaotidi_red.png")


		local city_data = info.city_data
		local group_info = city_data.temp_info
		local conf = CONF.PLANETCITY.get(city_data.id)

		if city_data.hasMonster == false and city_data.groupid == "" then
			text:setString(CONF:getStringValue(conf.NAME))
		else
			text:setVisible(false)
			group:setVisible(true)
			name:setVisible(true)
			line:setVisible(true)

			name:setString(CONF:getStringValue(conf.NAME))
			group:setString(CONF:getStringValue("AI occupy"))

		end


		if city_data.hasMonster then
			

		else
			print("city_data.groupid",city_data.groupid)
			if city_data.groupid ~= "" and city_data.groupid ~= nil then
				text:setVisible(false)
				group:setVisible(true)
				name:setVisible(true)
				line:setVisible(true)

				name:setString(CONF:getStringValue(conf.NAME))
				group:setString(group_info.nickname)

				if player:isGroup() then
					if player:getGroupData().groupid == city_data.groupid then
						name:setTextColor(cc.c4b(156,217,255,255))
						-- name:enableShadow(cc.c4b(156,217,255,255), cc.size(0.5,0.5))

						group:setTextColor(cc.c4b(156,217,255,255))
						-- group:enableShadow(cc.c4b(156,217,255,255), cc.size(0.5,0.5))
						back:setTexture("PlanetScene/ui/biaotidi.png")
					else
						--hong
						name:setTextColor(cc.c4b(255,70,70,255))
						-- name:enableShadow(cc.c4b(255,70,70,255), cc.size(0.5,0.5))

						group:setTextColor(cc.c4b(255,70,70,255))
						-- group:enableShadow(cc.c4b(255,70,70,255), cc.size(0.5,0.5))
					end

				else

					--hong
					name:setTextColor(cc.c4b(255,70,70,255))
					-- name:enableShadow(cc.c4b(255,70,70,255), cc.size(0.5,0.5))

					group:setTextColor(cc.c4b(255,70,70,255))
					-- group:enableShadow(cc.c4b(255,70,70,255), cc.size(0.5,0.5))
				end
			else
				text:setVisible(true)
				group:setVisible(false)
				name:setVisible(false)
				line:setVisible(false)
			end

		end

		--if city_data.status == 1 then -- he
			--[[node_2:getChildByName("back_he"):setVisible(true)
			node_2:getChildByName("icon_he"):setVisible(true)
			node_2:getChildByName("ins_he"):setVisible(true)
			node_2:getChildByName("time_he"):setVisible(true)
			node_2:getChildByName("led"):setVisible(false)

			node_2:getChildByName("ins_he"):setString(CONF:getStringValue("peace"))

			local server_date = player:getServerDate()
			local TIME1 = {}
			local TIME2 = {}
			for k,v in ipairs(conf.TIME) do
				if k%2 == 0 then
					table.insert(TIME2,v)
				else
					table.insert(TIME1,v)
				end
			end

			local next_order
			for i=1,#TIME1 do
				if server_date.wday >= TIME1[i] then
					if TIME1[i + 1] then
						if server_date.wday < TIME1[i + 1] then
							next_order = i + 1
						end
					else
						next_order = 1
					end
				end
			end

			local he_time
			for k,v in ipairs(TIME1) do
				if v == server_date.wday then
					if server_date.hour < TIME2[k] then
						he_time = TIME2[k]
					end
					break
				end
			end

			local now_time = os.time(server_date)
			local he_date = Tools.clone(server_date)
			
			if he_time then
				he_date.hour = he_time 
				he_date.min = 0
				he_date.sec = 0
			else
				he_date.day = he_date.day + math.abs(TIME1[next_order] - server_date.wday)
				he_date.hour = TIME2[next_order] 
				he_date.min = 0
				he_date.sec = 0
			end
			local end_time = os.time(he_date)

			local time = end_time - now_time 

			node_2:getChildByName("time_he"):setString(formatTime(time))]]

		--else
			node_2:getChildByName("back_he"):setVisible(false)
			node_2:getChildByName("icon_he"):setVisible(false)
			node_2:getChildByName("ins_he"):setVisible(false)
			node_2:getChildByName("time_he"):setVisible(false)
			node_2:getChildByName("led"):setVisible(false)

			node_2:getChildByName("led"):getChildByName("text"):setString(formatTime(conf.DURATION - (player:getServerTime() - city_data.status_begin_time)))

		--end
	elseif info.type == 6 then
		local city_res_data = info.city_res_data
		local conf_cityRes = CONF.PLANETCITYRES.get(city_res_data.id)
		local conf = CONF.PLANET_RES.get(info.city_res_data.id)
		icon:setTexture("PlanetIcon/"..conf.RES_ID..".png")

		text:setTextColor(cc.c4b(CONF.ETextColor.kRed.r, CONF.ETextColor.kRed.g, CONF.ETextColor.kRed.b, 255))
		-- text:enableShadow(cc.c4b(CONF.ETextColor.kRed.r, CONF.ETextColor.kRed.g, CONF.ETextColor.kRed.b, 255), cc.size(0.5,0.5))
		local user_list = city_res_data.user_list
		if city_res_data.groupid then
			if city_res_data.groupid ~= "" then
				if player:isGroup() then
					if player:getGroupData().groupid == city_res_data.groupid then
						text:setTextColor(cc.c4b(CONF.ETextColor.kGreen.r, CONF.ETextColor.kGreen.g, CONF.ETextColor.kGreen.b, 255))
						-- text:enableShadow(cc.c4b(CONF.ETextColor.kGreen.r, CONF.ETextColor.kGreen.g, CONF.ETextColor.kGreen.b, 255), cc.size(0.5,0.5))
						back:loadTexture("PlanetScene/ui/group_res.png")
					else
						back:loadTexture("PlanetScene/ui/enemy_res.png")
					end
				else
					back:loadTexture("PlanetScene/ui/enemy_res.png")
				end
			else
				text:setTextColor(cc.c4b(255,255,255,255))
				-- text:enableShadow(cc.c4b(255,255,255,255),cc.size(0.5,0.5))
				back:loadTexture("PlanetScene/ui/monster_res.png")
			end
		else
			text:setTextColor(cc.c4b(255,255,255,255))
			-- text:enableShadow(cc.c4b(255,255,255,255),cc.size(0.5,0.5))
			back:loadTexture("PlanetScene/ui/monster_res.png")
		end
		local str = CONF:getStringValue(conf.NAME)
		if city_res_data.restore_start_time == 0 then
			node_1:getChildByName("repair"):setVisible(false)
		else
			node_1:getChildByName("repair"):setVisible(true)
			local time = conf_cityRes.TIME - (player:getServerTime()-city_res_data.restore_start_time)
			if time <= 0 then time = 0 end
			if time > conf_cityRes.TIME then time = conf_cityRes.TIME end
			node_1:getChildByName("repair"):getChildByName("time"):setString(formatTime(time))
		end
		text:setString("Lv."..conf.LEVEL.." "..CONF:getStringValue(conf.NAME))

    elseif info.type == 11 then  --星系野怪

        text:setVisible(false)
		back:setVisible(false)

		local monster_data = info.monster_data
        if monster_data.isDead == 1 then
            node_1:getChildByName("icon"):setVisible(false)
        	node_2:getChildByName("boss_text"):setVisible(false)
		    node_2:getChildByName("boss_back"):setVisible(false)
            node_2:getChildByName("xue"):setVisible(false)
		    node_2:getChildByName("xuetiao"):setVisible(false)
		    node_2:getChildByName("xue_text"):setVisible(false)
            node_2:getChildByName("led"):setVisible(false)
            node_2:getChildByName("di_1"):setVisible(false)
        else
		    local monster_conf = CONF.PLANETCREEPS.get(monster_data.id)
            node_1:getChildByName("icon"):setVisible(true)
		    icon:setTexture("PlanetIcon/"..monster_conf.RES_ID..".png")

		    node_2:getChildByName("boss_text"):setString("Lv"..monster_conf.LEVEL.."."..CONF:getStringValue(monster_conf.NAME))
		    node_2:getChildByName("boss_text"):setVisible(true)
		    node_2:getChildByName("boss_back"):setVisible(true)
		    node_2:getChildByName("led"):setVisible(false)
            node_2:getChildByName("di_1"):setVisible(false)
            node_2:getChildByName("xue"):setVisible(true)
		    node_2:getChildByName("xuetiao"):setVisible(true)
		    node_2:getChildByName("xue_text"):setVisible(true)

		    local xue_max = 0
    	    for i,v in ipairs(monster_conf.MONSTER_LIST) do
    		    if v ~= 0 then
    			    xue_max = CONF.AIRSHIP.get(math.abs(v)).LIFE + xue_max
    		    end
    	    end

    	    local xue_now = 0
    	    if #monster_data.monster_hp_list == 0 then
    		    xue_now = xue_max
    	    else
    		    for i,v in ipairs(monster_data.monster_hp_list) do
    			    xue_now = xue_now + v
    		    end
    	    end

    	    local percent = math.floor(xue_now/xue_max*100)
    	    node_2:getChildByName("xue"):setContentSize(cc.size(node_2:getChildByName("xue"):getTag()*(xue_now/xue_max), node_2:getChildByName("xue"):getContentSize().height))
    	    node_2:getChildByName("xue_text"):setString(percent.."%")
        end
    elseif info.type == 12 then
		local wangzuo_data = info.wangzuo_data
    	local conf = CONF.PLANETCITY.get(wangzuo_data.id)
    	icon:setTexture("PlanetIcon/"..CONF.PLANETCITY.get(wangzuo_data.id).ICON..".png")
		node_2:getChildByName("line"):setTexture("PlanetScene/ui/line_4.png")
		local back = node_2:getChildByName("biaotidi")
		text:setVisible(false)
		group:setVisible(true)
		name:setVisible(true)
		line:setVisible(true)
		name:setString(CONF:getStringValue(CONF.PLANETCITY.get(wangzuo_data.id).NAME))
		if wangzuo_data.user_name and wangzuo_data.user_name ~= "" then
			group:setString(wangzuo_data.user_info.nickname)
		end
		if wangzuo_data.groupid and wangzuo_data.groupid ~= "" then
			local group_info = wangzuo_data.temp_info
			node_2:getChildByName("star_icon"):setVisible(true)
			group:setString(wangzuo_data.temp_info.leader_name)
			node_2:getChildByName("star_icon"):getChildByName("icon"):setTexture("StarLeagueScene/ui/icon_star_0"..group_info.icon_id..".png")
			node_2:getChildByName("star_icon"):setPositionX(group:getPositionX()-group:getContentSize().width/2)
		else
			node_2:getChildByName("star_icon"):setVisible(false)
		end
		name:setTextColor(cc.c4b(255,70,70,255))
		group:setTextColor(cc.c4b(255,70,70,255))
		back:setVisible(false)
		node_2:getChildByName("di_3"):setVisible(true)
		node_2:getChildByName("di_2"):setVisible(true)
		node_2:getChildByName("di_2"):setTexture("PlanetScene/ui/wangzuo_bg.png")
		node_2:getChildByName("di_3"):setTexture("PlanetScene/ui/wangzuo_bg.png")
		-- back:setTexture("PlanetScene/ui/biaotidi_red.png")
		if player:isGroup() then
			if player:getGroupData().groupid == wangzuo_data.groupid then
				group:setTextColor(cc.c4b(156,217,255,255))
				name:setTextColor(cc.c4b(156,217,255,255))
				-- back:setTexture("PlanetScene/ui/biaotidi.png")
			end
		else
			if player:getName() == wangzuo_data.user_name then
				group:setTextColor(cc.c4b(156,217,255,255))
				name:setTextColor(cc.c4b(156,217,255,255))
			end
		end 

		if wangzuo_data.status == 1 then
			node_2:getChildByName("back_he"):setVisible(true)
			node_2:getChildByName("icon_he"):setVisible(true)
			node_2:getChildByName("ins_he"):setVisible(true)
			node_2:getChildByName("time_he"):setVisible(true)
			node_2:getChildByName("led"):setVisible(false)
			node_2:getChildByName("ins_he"):setString(CONF:getStringValue("peace"))
			if not wangzuo_data.user_name or wangzuo_data.user_name == "" then
				group:setString(CONF:getStringValue("notOpen"))
			end
			local last_openTime = 0
			local open_confWday = conf.TIME[1]
			local open_confHour = conf.TIME[2]
			local first_openTime = wangzuo_data.create_time + CONF.PARAM.get("throne_first_open").PARAM
			local addTime = 0
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
			node_2:getChildByName("time_he"):setString(formatTime(addTime))
			if not node_1:getChildByName("wangzuoTexiao") then
				local texiao = cc.CSLoader:createNode("PlanetScene/sfx/wangzuo/wangzuo.csb")
				animManager:runAnimByCSB(texiao, "PlanetScene/sfx/wangzuo/wangzuo.csb", "1")
				texiao:setName("wangzuoTexiao")
				node_1:addChild(texiao)
			end
			-- dump(os.date("*t",player:getServerTime()+addTime))
		elseif wangzuo_data.status == 2 then
			local time = 0
			node_2:getChildByName("back_he"):setVisible(false)
			node_2:getChildByName("icon_he"):setVisible(false)
			node_2:getChildByName("ins_he"):setVisible(false)
			node_2:getChildByName("time_he"):setVisible(false)
			node_2:getChildByName("led"):setVisible(true)
			local star_time = wangzuo_data.status_begin_time
			local attack_time = conf.DURATION
			if player:getServerTime() < (attack_time+star_time) then
				time = (attack_time+star_time) - player:getServerTime()
			else
				time = (attack_time+star_time+CONF.PARAM.get("throne_add_time").PARAM) - player:getServerTime()
			end
			if not wangzuo_data.user_name or wangzuo_data.user_name == "" then
				group:setString(CONF:getStringValue("no occupy"))
			end
			node_2:getChildByName("led"):getChildByName("text"):setString(formatTime(time))
			if node_1:getChildByName("wangzuoTexiao") then
				node_1:getChildByName("wangzuoTexiao"):removeFromParent()
			end
		end
    elseif info.type == 13 then ------ tower
        local tower_data = info.tower_data
        local conf = CONF.PLANETTOWER.get(tower_data.id)

        back:setVisible(false)
        node_2:getChildByName("di_1"):setVisible(false)
        text:setVisible(false)
        icon:setTexture("PlanetIcon/"..conf.ICON..".png")

        ---- effects
        local function creatEffect(i)
            if not node_1:getChildByName("anim_"..i) then
                local path = "PlanetScene/sfx/fangyuta/fangyuta_"..i..".csb"
                local node_anim = cc.CSLoader:createNode(path)
                animManager:runAnimByCSB(node_anim, path, i)
                node_anim:setName("anim_"..i)
                node_1:addChild(node_anim)
            end
        end
        local function removeEffect(i)
            if node_1:getChildByName("anim_"..i) then
				node_1:getChildByName("anim_"..i):removeFromParent()
			end
        end

        creatEffect(3)
        ---- on-state
        if tower_data.status == 1 then -- 1:peace
            group:setVisible(false)
            node_2:getChildByName("di_3"):setVisible(false)
            node_2:getChildByName("star_icon"):setVisible(false)
            creatEffect(1)
            removeEffect(4)
            self.attack_time_list = {}
        else -- 2：contend
            group:setVisible(true)
            group:setTextColor(cc.c4b(255,70,70,255))
            node_2:getChildByName("di_3"):setVisible(true)
            removeEffect(1)
            ---- occupy-state
            if tower_data.groupid and tower_data.groupid ~= "" then -- group
                local group_info = tower_data.temp_info
                node_2:getChildByName("star_icon"):setVisible(true)
                group:setString(tower_data.user_info.nickname)
                node_2:getChildByName("star_icon"):getChildByName("icon"):setTexture("StarLeagueScene/ui/icon_star_0"..group_info.icon_id..".png")
				node_2:getChildByName("star_icon"):setPositionX(group:getPositionX()-group:getContentSize().width/2)
                if player:isGroup() and player:getGroupData().groupid == tower_data.groupid then
					group:setTextColor(cc.c4b(156,217,255,255))
                end
            else
                node_2:getChildByName("star_icon"):setVisible(false)
                if tower_data.user_name and tower_data.user_name ~= "" then -- person
                    group:setString(tower_data.user_info.nickname)
                    if player:getName() == tower_data.user_name then
                        group:setTextColor(cc.c4b(156,217,255,255))
                    end
                else -- nobody
                    group:setString(CONF:getStringValue("no occupy"))
                end
            end
            ---- attack-state
            local index = TableFindIdFromValue(self.attack_time_list,tower_data.id)
            if tower_data.is_attack then -- attack
                creatEffect(4)
		        -- rotate laser
		        require("util.ExWangzuoHelper"):getInstance():SetDiancita_Jiguang(node_1, "anim_",4)
                if index == 0 then
                    table.insert(self.attack_time_list,{id = tower_data.id,time = tower_data.occupy_begin_time,state = true,isplay = false ,node = node_1})
                else
                    if self.attack_time_list[index].time ~= tower_data.occupy_begin_time then
                        self.attack_time_list[index].time = tower_data.occupy_begin_time
                    end
                    self.attack_time_list[index].state = true
                end
            else -- Do not
                removeEffect(4)
                if index ~= 0 then
                    self.attack_time_list[index].state = false
                end
            end
        end
	end
end

function PlanetDiamondLayer:createNodeByInfoo( info, x, y )

	-- ADD WJJ 20180620
	self._debug_count_create = self._debug_count_create + 1

	self:_print("#### LUA PlanetDiamondLayer createNodeByInfo BEGIN >>>>>>>>>>>>>>>>>")
	self:_print("#### LUA x: " .. tostring(x) .. "  y: " .. tostring(y))
	self:_print("#### LUA info: " .. tostring(info))

		--1:base 2:res 3:ruins 4:boss 5:city 11:monster 13：tower

		local type_ins = {"base" ,"res" ,"ruins" ,"boss" ,"city"}

--		local node_1 = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/ResourceNode_1.csb")
--		local node_2 = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/ResourceNode_2.csb")
        local node_1 = cc.CSLoader:createNode("PlanetScene/ResourceNode_1.csb")
        local node_2 = cc.CSLoader:createNode("PlanetScene/ResourceNode_2.csb")

		node_1:setName("node1_"..x.."_"..y)	
		node_2:setName("node2_"..x.."_"..y)

		if x == self.choose_.m and y == self.choose_.n and self:getResourceNode():getChildByName("selectNode") then
			node_2:setVisible(false)
		end

		local icon = node_1:getChildByName("icon")
		local back = node_2:getChildByName("back")
		local text = node_2:getChildByName("text")
		local group = node_2:getChildByName("group")
		local name = node_2:getChildByName("name")
		local line = node_2:getChildByName("line")

		-- icon:setScale(0.4)

		if info.type == 1 then

			local base_data = info.base_data

			if base_data.info.building_level_list[1] == nil or base_data.info.building_level_list[1] == 0 then
				base_data.info.building_level_list[1] = 1
			end

			local lv = CONF.BUILDING_1.get(base_data.info.building_level_list[1])
			self:_print("@@@@ icon setTexture : " .. tostring(lv or " nil") )

			icon:setTexture("PlanetIcon/"..lv.IMAGE..".png")

			-- FUCK, do not hide jidi pic!!! WJJ
			-- icon:setVisible(false)

			-----------------------
			if( self.exConfig.IS_EFFECT_ON_TILE_ENABLED ) then
				local sfx_name = string.format("PlanetScene/sfx/StationEffect/%s.csb", CONF.BUILDING_1.get(base_data.info.building_level_list[1]).IMAGE_SFX)
				local sfx = require("app.ExResInterface"):getInstance():FastLoad(sfx_name)
				if( sfx ~= nil )then
					animManager:runAnimByCSB(sfx, sfx_name, "1")
					node_1:addChild(sfx)
				end
			end
			-----------------------

			node_1:setLocalZOrder(1)

			-----------------------
			if( self.exConfig.IS_EFFECT_ON_TILE_ENABLED ) then
			local max_destroy = CONF.PARAM.get("planet_destroy_value_limit").PARAM
			local now_destroy = base_data.destroy_value
			if now_destroy/max_destroy*100 >= CONF.PARAM.get("spaceport_fire").PARAM then
				node_1:getChildByName("huo_texiao"):setVisible(true)

				animManager:runAnimByCSB(node_1:getChildByName("huo_texiao"), "PlanetScene/sfx/kongjianzhanzhuoshao/zhaohuo.csb", "1")
			else
				node_1:getChildByName("huo_texiao"):setVisible(false)
			end
			end
			-----------------------

			node_1:getChildByName("huo_texiao"):setLocalZOrder(3)

			-- if( self.exConfig.IS_EFFECT_ON_TILE_ENABLED ) then
			if base_data.shield_start_time > 0 then
				if player:getServerTime() - base_data.shield_start_time <= base_data.shield_time then
					node_1:getChildByName("shield"):setVisible(true)
					animManager:runAnimByCSB(node_1:getChildByName("shield"), "PlanetScene/sfx/kongjianzhan/shield.csb", "1")
				else
					node_1:getChildByName("shield"):setVisible(false)
				end
			else
				node_1:getChildByName("shield"):setVisible(false)
			end

			node_1:getChildByName("shield"):setLocalZOrder(2)
			-- end
			-----------------------

			if base_data.info.group_nickname ~= nil and base_data.info.group_nickname ~= "" then

				node_2:getChildByName("name"):setString(base_data.info.nickname)
				node_2:getChildByName("group"):setString(base_data.info.group_nickname)

				if base_data.info.user_name == player:getName() then
					node_2:getChildByName("text"):setString(CONF:getStringValue("My_station"))

					node_2:getChildByName("line"):setTexture("PlanetScene/ui/base_line_g.png")
					node_2:getChildByName("back"):loadTexture("PlanetScene/ui/my_res.png")
					node_2:getChildByName("text"):setTextColor(cc.c4b(156,255,182,255))
					-- node_2:getChildByName("text"):enableShadow(cc.c4b(156,255,182,255), cc.size(0.5,0.5))
				else

					text:setVisible(false)

					node_2:getChildByName("line"):setVisible(false)
					node_2:getChildByName("name"):setVisible(true)
					node_2:getChildByName("group"):setVisible(true)
					node_2:getChildByName("di_2"):setVisible(true)
					node_2:getChildByName("di_3"):setVisible(true)
					node_2:getChildByName("di_1"):setVisible(false)
					node_2:getChildByName("back"):setContentSize(cc.size(1,50))

					if player:checkPlayerIsInGroup(base_data.info.user_name) then
						name:setTextColor(cc.c4b(156,255,182,255))
						-- name:enableShadow(cc.c4b(156,255,182,255), cc.size(0.5,0.5))

						group:setTextColor(cc.c4b(156,255,182,255))
						-- group:enableShadow(cc.c4b(156,255,182,255), cc.size(0.5,0.5))
						if base_data.info.user_name ~= player:getName() then
							name:setTextColor(cc.c4b(156,217,255,255))
							-- name:enableShadow(cc.c4b(156,217,255,255), cc.size(0.5,0.5))
							group:setTextColor(cc.c4b(156,217,255,255))
							-- group:enableShadow(cc.c4b(156,217,255,255), cc.size(0.5,0.5))
						end
					else
						node_2:getChildByName("line"):setTexture("PlanetScene/ui/base_line_r.png")
						node_2:getChildByName("back"):loadTexture("PlanetScene/ui/enemy_res.png")

						name:setTextColor(cc.c4b(255,36,36,255))
						-- name:enableShadow(cc.c4b(255,36,36,255), cc.size(0.5,0.5))

						group:setTextColor(cc.c4b(255,36,36,255))
						-- group:enableShadow(cc.c4b(255,36,36,255), cc.size(0.5,0.5))
					end

				end

			else
				text:setString(base_data.info.nickname)	

				if base_data.info.user_name == player:getName() then
					text:setString(CONF:getStringValue("My_station"))

					text:setTextColor(cc.c4b(156,255,182,255))
					-- text:enableShadow(cc.c4b(156,255,182,255), cc.size(0.5,0.5))
				end

				if base_data.info.user_name == player:getName() then
					node_2:getChildByName("line"):setTexture("PlanetScene/ui/base_line_g.png")
					node_2:getChildByName("back"):loadTexture("PlanetScene/ui/my_res.png")
				else
					node_2:getChildByName("line"):setTexture("PlanetScene/ui/base_line_r.png")
					node_2:getChildByName("back"):loadTexture("PlanetScene/ui/enemy_res.png")

					text:setTextColor(cc.c4b(255,70,70,255))
					-- text:enableShadow(cc.c4b(255,70,70,255), cc.size(0.5,0.5))
				end
			end
		elseif info.type == 2 then

			local res_data = info.res_data

			local conf = CONF.PLANET_RES.get(info.res_data.id)

			icon:setTexture("PlanetIcon/"..conf.RES_ID..".png")
			text:setTextColor(cc.c4b(255,244,156,255))
			-- text:enableShadow(cc.c4b(255,244,156,255), cc.size(0.5,0.5))

			-----------------------
			if( self.exConfig.IS_EFFECT_ON_TILE_ENABLED ) then
			local te_list = {"", "ziyuankuang1","ziyuankuang2","ziyuankuang3"}
			local texiao = require("app.ExResInterface"):getInstance():FastLoad(string.format("PlanetScene/sfx/%s/%s.csb", te_list[conf.TYPE],te_list[conf.TYPE]))
			animManager:runAnimByCSB(texiao, string.format("PlanetScene/sfx/%s/%s.csb", te_list[conf.TYPE],te_list[conf.TYPE]), "1")
			node_1:addChild(texiao)
			end
			-----------------------

			if res_data.user_name ~= "" then
				if res_data.user_name == player:getName() then
					back:loadTexture("PlanetScene/ui/my_res.png")
					text:setTextColor(cc.c4b(156,255,182,255))
					-- text:enableShadow(cc.c4b(156,255,182,255), cc.size(0.5,0.5))
				else
					if player:checkPlayerIsInGroup( res_data.user_name ) then
						back:loadTexture("PlanetScene/ui/group_res.png")
						text:setTextColor(cc.c4b(156,217,255,255))
						-- text:enableShadow(cc.c4b(156,217,255,255), cc.size(0.5,0.5))
					else
						back:loadTexture("PlanetScene/ui/enemy_res.png")
						text:setTextColor(cc.c4b(255,70,70,255))
						-- text:enableShadow(cc.c4b(255,70,70,255), cc.size(0.5,0.5))
					end

				end
			else
				if res_data.hasMonster then
					back:loadTexture("PlanetScene/ui/monster_res.png")
				else
					back:loadTexture("PlanetScene/ui/noPeople_res.png")
				end

			end

			text:setString("Lv."..conf.LEVEL.." "..CONF:getStringValue(conf.NAME))
		elseif info.type == 3 then

			local ruins_data = info.ruins_data

			local conf = CONF.PLANET_RUINS.get(info.ruins_data.id)

			icon:setTexture("PlanetIcon/"..conf.RES_ID..".png")
			text:setTextColor(cc.c4b(255,244,156,255))
			-- text:enableShadow(cc.c4b(255,244,156,255), cc.size(0.5,0.5))

			-----------------------
			if( self.exConfig.IS_EFFECT_ON_TILE_ENABLED ) then

			local te_list = {"ziyuankuang4","ziyuankuang6"}
			local texiao = require("app.ExResInterface"):getInstance():FastLoad(string.format("PlanetScene/sfx/%s/%s.csb", te_list[conf.TYPE],te_list[conf.TYPE]))
			animManager:runAnimByCSB(texiao, string.format("PlanetScene/sfx/%s/%s.csb", te_list[conf.TYPE],te_list[conf.TYPE]), "1")
			node_1:addChild(texiao)
			end
			-----------------------

			if ruins_data.user_name ~= "" then
				if ruins_data.user_name == player:getName() then
					back:loadTexture("PlanetScene/ui/my_res.png")
				else
					if player:checkPlayerIsInGroup( ruins_data.user_name ) then
						back:loadTexture("PlanetScene/ui/group_res.png")
					else
						back:loadTexture("PlanetScene/ui/enemy_res.png")
					end

				end

			else
				back:loadTexture("PlanetScene/ui/monster_res.png")
			end

			text:setString("Lv."..conf.LEVEL.." "..CONF:getStringValue(conf.NAME))
		elseif info.type == 4 then

			text:setVisible(false)
			back:setVisible(false)

			local boss_data = info.boss_data
			local boss_conf = CONF.PLANETBOSS.get(boss_data.id)
			icon:setTexture("PlanetIcon/"..boss_conf.ICON..".png")

			node_2:getChildByName("boss_text"):setString(CONF:getStringValue(boss_conf.NAME))

			node_2:getChildByName("boss_text"):setVisible(true)
			node_2:getChildByName("boss_back"):setVisible(true)
			node_2:getChildByName("xue"):setVisible(true)
			node_2:getChildByName("xuetiao"):setVisible(true)
			node_2:getChildByName("xue_text"):setVisible(true)
			node_2:getChildByName("led"):setVisible(true)

			local xue_max = 0
			local add_boss_xue = false
			for i,v in ipairs(boss_conf.MONSTER_LIST) do
				if v ~= 0 then
					if v < 0 then
						if add_boss_xue == false then
							xue_max = CONF.AIRSHIP.get(math.abs(v)).LIFE + xue_max
							add_boss_xue = true
						end
					else
						xue_max = CONF.AIRSHIP.get(math.abs(v)).LIFE + xue_max
					end
				end
			end

			local xue_now = 0
			if #boss_data.monster_hp_list == 0 then
				xue_now = xue_max
			else
				for i,v in ipairs(boss_data.monster_hp_list) do
					xue_now = xue_now + v
				end
			end

			local percent = math.floor(xue_now/xue_max*100)
			node_2:getChildByName("xue"):setContentSize(cc.size(node_2:getChildByName("xue"):getTag()*(xue_now/xue_max), node_2:getChildByName("xue"):getContentSize().height))
			node_2:getChildByName("xue_text"):setString(percent.."%")

			local time = boss_conf.REMOVE_TIME - (player:getServerTime() - boss_data.create_time)
			node_2:getChildByName("led"):getChildByName("text"):setString(formatTime(time))
		elseif info.type == 5 then

			local city_data = info.city_data

			icon:setTexture("PlanetIcon/"..CONF.PLANETCITY.get(city_data.id).ICON..".png")

			text:setString(CONF:getStringValue(CONF.PLANETCITY.get(city_data.id).NAME))
			node_2:getChildByName("line"):setTexture("PlanetScene/ui/line_4.png")

			local back = node_2:getChildByName("biaotidi")
			back:setTexture("PlanetScene/ui/biaotidi_red.png")

			-----------------------
			if( self.exConfig.IS_EFFECT_ON_TILE_ENABLED ) then
			local texiao = require("app.ExResInterface"):getInstance():FastLoad(string.format("PlanetScene/sfx/ziyuankuang5/ziyuankuang5.csb"))
			animManager:runAnimByCSB(texiao, string.format("PlanetScene/sfx/ziyuankuang5/ziyuankuang5.csb"), "1")
			node_1:addChild(texiao)
			end
			-----------------------
			local group_info = city_data.temp_info
			local conf = CONF.PLANETCITY.get(city_data.id)


			if city_data.hasMonster == false and city_data.groupid == "" then
				text:setString(CONF:getStringValue(conf.NAME))
			else
				text:setVisible(false)
				group:setVisible(true)
				name:setVisible(true)
				line:setVisible(true)

				name:setString(CONF:getStringValue(conf.NAME))
				group:setString(CONF:getStringValue("AI occupy"))

			end


			if city_data.hasMonster then
				

			else

				if city_data.groupid ~= "" and city_data.groupid ~= nil then
					text:setVisible(false)
					group:setVisible(true)
					name:setVisible(true)
					line:setVisible(true)

					name:setString(CONF:getStringValue(conf.NAME))
					group:setString(group_info.nickname)

					if player:isGroup() then
						if player:getGroupData().groupid == city_data.groupid then
							name:setTextColor(cc.c4b(156,217,255,255))
							-- name:enableShadow(cc.c4b(156,217,255,255), cc.size(0.5,0.5))

							group:setTextColor(cc.c4b(156,217,255,255))
							-- group:enableShadow(cc.c4b(156,217,255,255), cc.size(0.5,0.5))

							back:setTexture("PlanetScene/ui/biaotidi.png")
						else
							--hong
							name:setTextColor(cc.c4b(255,70,70,255))
							-- name:enableShadow(cc.c4b(255,70,70,255), cc.size(0.5,0.5))

							group:setTextColor(cc.c4b(255,70,70,255))
							-- group:enableShadow(cc.c4b(255,70,70,255), cc.size(0.5,0.5))
						end

					else

						--hong
						name:setTextColor(cc.c4b(255,70,70,255))
						-- name:enableShadow(cc.c4b(255,70,70,255), cc.size(0.5,0.5))

						group:setTextColor(cc.c4b(255,70,70,255))
						-- group:enableShadow(cc.c4b(255,70,70,255), cc.size(0.5,0.5))
					end
				end

			end


			--if city_data.status == 1 then -- he
				--[[node_2:getChildByName("back_he"):setVisible(true)
				node_2:getChildByName("icon_he"):setVisible(true)
				node_2:getChildByName("ins_he"):setVisible(true)
				node_2:getChildByName("time_he"):setVisible(true)
				node_2:getChildByName("led"):setVisible(false)

				node_2:getChildByName("ins_he"):setString(CONF:getStringValue("peace"))

				local server_date = player:getServerDate()
				local TIME1 = {}
				local TIME2 = {}
				for k,v in ipairs(conf.TIME) do
					if k%2 == 0 then
						table.insert(TIME2,v)
					else
						table.insert(TIME1,v)
					end
				end

				local next_order
				for i=1,#TIME1 do
					if server_date.wday >= TIME1[i] then
						if TIME1[i + 1] then
							if server_date.wday < TIME1[i + 1] then
								next_order = i + 1
							end
						else
							next_order = 1
						end
					end
				end

				local he_time
				for k,v in ipairs(TIME1) do
					if v == server_date.wday then
						if server_date.hour < TIME2[k] then
							he_time = TIME2[k]
						end
						break
					end
				end

				local now_time = os.time(server_date)
				local he_date = Tools.clone(server_date)
				
				if he_time then
					he_date.hour = he_time 
					he_date.min = 0
					he_date.sec = 0
				else
					he_date.day = he_date.day + math.abs(TIME1[next_order] - server_date.wday)
					he_date.hour = TIME2[next_order] 
					he_date.min = 0
					he_date.sec = 0
				end
				local end_time = os.time(he_date)

				local time = end_time - now_time 

				node_2:getChildByName("time_he"):setString(formatTime(time))]]

			--else
				node_2:getChildByName("back_he"):setVisible(false)
				node_2:getChildByName("icon_he"):setVisible(false)
				node_2:getChildByName("ins_he"):setVisible(false)
				node_2:getChildByName("time_he"):setVisible(false)
				node_2:getChildByName("led"):setVisible(false)

				node_2:getChildByName("led"):getChildByName("text"):setString(formatTime(conf.DURATION - (player:getServerTime() - city_data.status_begin_time)))

			--end	
		elseif info.type == 6 then
			local city_res_data = info.city_res_data

			local conf = CONF.PLANET_RES.get(city_res_data.id)
			local conf_cityRes = CONF.PLANETCITYRES.get(city_res_data.id)
			icon:setTexture("PlanetIcon/"..conf.RES_ID..".png")
			text:setTextColor(cc.c4b(CONF.ETextColor.kRed.r, CONF.ETextColor.kRed.g, CONF.ETextColor.kRed.b, 255))
			-- text:enableShadow(cc.c4b(CONF.ETextColor.kRed.r, CONF.ETextColor.kRed.g, CONF.ETextColor.kRed.b, 255), cc.size(0.5,0.5))

			-----------------------
			if( self.exConfig.IS_EFFECT_ON_TILE_ENABLED ) then
			local te_list = {"", "ziyuankuang1","ziyuankuang2","ziyuankuang3"}
			local texiao = require("app.ExResInterface"):getInstance():FastLoad(string.format("PlanetScene/sfx/%s/%s.csb", te_list[conf.TYPE],te_list[conf.TYPE]))
			animManager:runAnimByCSB(texiao, string.format("PlanetScene/sfx/%s/%s.csb", te_list[conf.TYPE],te_list[conf.TYPE]), "1")
			node_1:addChild(texiao)
			end
			-----------------------

			local user_list = city_res_data.user_list
			if city_res_data.groupid then
				if city_res_data.groupid ~= "" then
					if player:isGroup() then
						if player:getGroupData().groupid == city_res_data.groupid then
							text:setTextColor(cc.c4b(CONF.ETextColor.kGreen.r, CONF.ETextColor.kGreen.g, CONF.ETextColor.kGreen.b, 255))
							-- text:enableShadow(cc.c4b(CONF.ETextColor.kGreen.r, CONF.ETextColor.kGreen.g, CONF.ETextColor.kGreen.b, 255), cc.size(0.5,0.5))
							back:loadTexture("PlanetScene/ui/group_res.png")
						else
							back:loadTexture("PlanetScene/ui/enemy_res.png")
						end
					else
						back:loadTexture("PlanetScene/ui/enemy_res.png")
					end
				else
					text:setTextColor(cc.c4b(255,255,255,255))
					-- text:enableShadow(cc.c4b(255,255,255,255),cc.size(0.5,0.5))
					back:loadTexture("PlanetScene/ui/monster_res.png")
				end
			else
				text:setTextColor(cc.c4b(255,255,255,255))
				-- text:enableShadow(cc.c4b(255,255,255,255),cc.size(0.5,0.5))
				back:loadTexture("PlanetScene/ui/monster_res.png")
			end
			-- local str = CONF:getStringValue(conf.NAME)
			if city_res_data.restore_start_time == 0 then
				node_1:getChildByName("repair"):setVisible(false)
			else
				node_1:getChildByName("repair"):setVisible(true)
				local time = conf_cityRes.TIME - (player:getServerTime()-city_res_data.restore_start_time)
				if time <= 0 then time = 0 end
				if time > conf_cityRes.TIME then time = conf_cityRes.TIME end
				node_1:getChildByName("repair"):getChildByName("time"):setString(formatTime(time))
			end
			text:setString("Lv."..conf.LEVEL.." "..CONF:getStringValue(conf.NAME))

        elseif info.type == 11 then  --星系野怪
            text:setVisible(false)
			back:setVisible(false)

			local monster_data = info.monster_data
            if monster_data.isDead == 1 then
                node_1:getChildByName("icon"):setVisible(false)
                node_2:getChildByName("boss_text"):setVisible(false)
			    node_2:getChildByName("boss_back"):setVisible(false)
                node_2:getChildByName("xue"):setVisible(false)
			    node_2:getChildByName("xuetiao"):setVisible(false)
			    node_2:getChildByName("xue_text"):setVisible(false)
                node_2:getChildByName("led"):setVisible(false)
                node_2:getChildByName("di_1"):setVisible(false)
            else

			    local monster_conf = CONF.PLANETCREEPS.get(monster_data.id)
                node_1:getChildByName("icon"):setVisible(true)
			    icon:setTexture("PlanetIcon/"..monster_conf.RES_ID..".png")

			    node_2:getChildByName("boss_text"):setString("Lv"..monster_conf.LEVEL.."."..CONF:getStringValue(monster_conf.NAME))
			    node_2:getChildByName("boss_text"):setVisible(true)
			    node_2:getChildByName("boss_back"):setVisible(true)
			    node_2:getChildByName("led"):setVisible(false)
                node_2:getChildByName("di_1"):setVisible(false)
                node_2:getChildByName("xue"):setVisible(true)
			    node_2:getChildByName("xuetiao"):setVisible(true)
			    node_2:getChildByName("xue_text"):setVisible(true)

			    local xue_max = 0
    		    for i,v in ipairs(monster_conf.MONSTER_LIST) do
    			    if v ~= 0 then
    				    xue_max = CONF.AIRSHIP.get(math.abs(v)).LIFE + xue_max
    			    end
    		    end

    		    local xue_now = 0
    		    if #monster_data.monster_hp_list == 0 then
    			    xue_now = xue_max
    		    else
    			    for i,v in ipairs(monster_data.monster_hp_list) do
    				    xue_now = xue_now + v
    			    end
    		    end

    		    local percent = math.floor(xue_now/xue_max*100)
    		    node_2:getChildByName("xue"):setContentSize(cc.size(node_2:getChildByName("xue"):getTag()*(xue_now/xue_max), node_2:getChildByName("xue"):getContentSize().height))
    		    node_2:getChildByName("xue_text"):setString(percent.."%")
            end
        elseif info.type == 12 then
        	local wangzuo_data = info.wangzuo_data
        	local conf = CONF.PLANETCITY.get(wangzuo_data.id)

        	icon:setTexture("PlanetIcon/"..CONF.PLANETCITY.get(wangzuo_data.id).ICON..".png")
			node_2:getChildByName("line"):setTexture("PlanetScene/ui/line_4.png")
			local back = node_2:getChildByName("biaotidi")
			text:setVisible(false)
			group:setVisible(true)
			name:setVisible(true)
			line:setVisible(true)
			name:setString(CONF:getStringValue(CONF.PLANETCITY.get(wangzuo_data.id).NAME))
			if wangzuo_data.user_name and wangzuo_data.user_name ~= "" then
				group:setString(wangzuo_data.user_info.nickname)
			end
			if wangzuo_data.groupid and wangzuo_data.groupid ~= "" then
				local group_info = wangzuo_data.temp_info
				node_2:getChildByName("star_icon"):setVisible(true)
				group:setString(wangzuo_data.temp_info.leader_name)
				node_2:getChildByName("star_icon"):getChildByName("icon"):setTexture("StarLeagueScene/ui/icon_star_0"..group_info.icon_id..".png")
				node_2:getChildByName("star_icon"):setPositionX(group:getPositionX()-group:getContentSize().width/2)
			else
				node_2:getChildByName("star_icon"):setVisible(false)
			end
			name:setTextColor(cc.c4b(255,70,70,255))
			group:setTextColor(cc.c4b(255,70,70,255))
			back:setVisible(false)
			node_2:getChildByName("di_3"):setVisible(true)
			node_2:getChildByName("di_2"):setVisible(true)
			node_2:getChildByName("di_2"):setTexture("PlanetScene/ui/wangzuo_bg.png")
			node_2:getChildByName("di_3"):setTexture("PlanetScene/ui/wangzuo_bg.png")
			-- back:setTexture("PlanetScene/ui/biaotidi_red.png")
			if player:isGroup() then
				if player:getGroupData().groupid == wangzuo_data.groupid then
					group:setTextColor(cc.c4b(156,217,255,255))
					name:setTextColor(cc.c4b(156,217,255,255))
					-- back:setTexture("PlanetScene/ui/biaotidi.png")
				end
			else
				if player:getName() == wangzuo_data.user_name then
					group:setTextColor(cc.c4b(156,217,255,255))
					name:setTextColor(cc.c4b(156,217,255,255))
				end
			end 

			if wangzuo_data.status == 1 then
				node_2:getChildByName("back_he"):setVisible(true)
				node_2:getChildByName("icon_he"):setVisible(true)
				node_2:getChildByName("ins_he"):setVisible(true)
				node_2:getChildByName("time_he"):setVisible(true)
				node_2:getChildByName("led"):setVisible(false)
				node_2:getChildByName("ins_he"):setString(CONF:getStringValue("peace"))
				local last_openTime = 0
				local open_confWday = conf.TIME[1]
				local open_confHour = conf.TIME[2]
				if not wangzuo_data.user_name or wangzuo_data.user_name == "" then
					group:setString(CONF:getStringValue("notOpen"))
				end
				local first_openTime = wangzuo_data.create_time + CONF.PARAM.get("throne_first_open").PARAM
				local addTime = 0
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
				node_2:getChildByName("time_he"):setString(formatTime(addTime))
				if not node_1:getChildByName("wangzuoTexiao") then
					local texiao = cc.CSLoader:createNode("PlanetScene/sfx/wangzuo/wangzuo.csb")
					animManager:runAnimByCSB(texiao, "PlanetScene/sfx/wangzuo/wangzuo.csb", "1")
					texiao:setName("wangzuoTexiao")
					node_1:addChild(texiao)
				end
			elseif wangzuo_data.status == 2 then
				local time = 0
				node_2:getChildByName("back_he"):setVisible(false)
				node_2:getChildByName("icon_he"):setVisible(false)
				node_2:getChildByName("ins_he"):setVisible(false)
				node_2:getChildByName("time_he"):setVisible(false)
				node_2:getChildByName("led"):setVisible(true)
				local star_time = wangzuo_data.status_begin_time
				local attack_time = conf.DURATION
				if player:getServerTime() < (attack_time+star_time) then
					time = (attack_time+star_time) - player:getServerTime()
				else
					time = (attack_time+star_time+CONF.PARAM.get("throne_add_time").PARAM) - player:getServerTime()
				end
				if not wangzuo_data.user_name or wangzuo_data.user_name == "" then
					group:setString(CONF:getStringValue("no occupy"))
				end
				node_2:getChildByName("led"):getChildByName("text"):setString(formatTime(time))
				if node_1:getChildByName("wangzuoTexiao") then
					node_1:getChildByName("wangzuoTexiao"):removeFromParent()
				end
			end
			self.wangzuoNode = node_1
        elseif info.type == 13 then ------ tower
            local tower_data = info.tower_data
        	local conf = CONF.PLANETTOWER.get(tower_data.id)

            back:setVisible(false)
            node_2:getChildByName("di_1"):setVisible(false)
            text:setVisible(false)
        	icon:setTexture("PlanetIcon/"..conf.ICON..".png")

            -- effects
            local function creatEffect(i)
                if not node_1:getChildByName("anim_"..i) then
                    local path = "PlanetScene/sfx/fangyuta/fangyuta_"..i..".csb"
                    local node_anim = cc.CSLoader:createNode(path)
                    animManager:runAnimByCSB(node_anim, path, i)
                    node_anim:setName("anim_"..i)
                    node_1:addChild(node_anim)
                end
            end
            local function removeEffect(i)
                if node_1:getChildByName("anim_"..i) then
			        node_1:getChildByName("anim_"..i):removeFromParent()
		        end
            end

            creatEffect(3)
            ---- on-state
            if tower_data.status == 1 then -- 1:peace
                group:setVisible(false)
                creatEffect(1)
                removeEffect(4)
                self.attack_time_list = {}
            else -- 2：contend
                group:setVisible(true)
                group:setTextColor(cc.c4b(255,70,70,255))
                node_2:getChildByName("di_3"):setVisible(true)
                removeEffect(1)
                ---- occupy-state
                if tower_data.groupid and tower_data.groupid ~= "" then -- group
                    local group_info = tower_data.temp_info
                    node_2:getChildByName("star_icon"):setVisible(true)
                    group:setString(tower_data.user_info.nickname)
                    node_2:getChildByName("star_icon"):getChildByName("icon"):setTexture("StarLeagueScene/ui/icon_star_0"..group_info.icon_id..".png")
				    node_2:getChildByName("star_icon"):setPositionX(group:getPositionX()-group:getContentSize().width/2)
                    if player:isGroup() and player:getGroupData().groupid == tower_data.groupid then
					    group:setTextColor(cc.c4b(156,217,255,255))
                    end
                else
                    node_2:getChildByName("star_icon"):setVisible(false)
                    if tower_data.user_name and tower_data.user_name ~= "" then -- person
                        group:setString(tower_data.user_info.nickname)
                        if player:getName() == tower_data.user_name then
                            group:setTextColor(cc.c4b(156,217,255,255))
                        end
                    else -- nobody
                        group:setString(CONF:getStringValue("no occupy"))
                    end
                end

                ---- attack-state
                local index = TableFindIdFromValue(self.attack_time_list,tower_data.id)
                if tower_data.is_attack then -- attack
                    creatEffect(4)
		            -- rotate laser
		            require("util.ExWangzuoHelper"):getInstance():SetDiancita_Jiguang(node_1, "anim_",4)
                    if index == 0 then
                        table.insert(self.attack_time_list,{id = tower_data.id,time = tower_data.occupy_begin_time,state = true,isplay = false,node = node_1})
                    else
                        if self.attack_time_list[index].time ~= tower_data.occupy_begin_time then
                            self.attack_time_list[index].time = tower_data.occupy_begin_time
                        end
                        self.attack_time_list[index].state = true
                    end
                else -- Do not
                    removeEffect(4)
                    if index ~= 0 then
                        self.attack_time_list[index].state = false
                    end
                end
            end

		end

		-- local label = cc.Label:createWithTTF(string.format("%s\n(%d,%d)", type_ins[info.type],x,y), "fonts/cuyabra.ttf", 26)
		-- label:setPosition(cc.p(sprite:getContentSize().width/2, sprite:getContentSize().height/2))
		-- sprite:addChild(label)

		self:_print("#### LUA PlanetDiamondLayer createNodeByInfo END >>>>>>>>>>>>>>>>>")

		return node_1,node_2
end

function PlanetDiamondLayer:updateInfo( node_list )

	-- message PlanetNode{
	-- 	required int32 id = 1;
	-- 	repeated PlanetElement element_list = 2;
	-- 	repeated string army_line_key_list = 3;
	-- };
	local id_list = {}
	for i,v in ipairs(node_list) do
		table.insert(id_list,v.id)
	end
	self:resetSee_list(id_list)

	for i,v in ipairs(node_list) do

		local haveId = false
		for i2,v2 in ipairs(self.now_see_list) do
			
			if v.id == v2.id then
				haveId = true
				if v2.node_list then
					for i3=#v2.node_list,1,-1 do
						local x = tonumber(Split(v2.node_list[i3]:getName(), "_")[2])
						local y = tonumber(Split(v2.node_list[i3]:getName(), "_")[3])

						local has = false
						for i4,v4 in ipairs(v.element_list) do
							if v4.pos_list[1].x == x and v4.pos_list[1].y == y then
								has = true
								break
							end
						end

						if not has then
							self:_print("updateInfo remove", x,y)
							v2.node_list[i3]:removeFromParent()
							table.remove(v2.node_list, i3)
						end
					end

				end

			end

		end
	end
end

------------------ BEGIN REGION WJJ --------------------

function PlanetDiamondLayer:createTileAtPos(pos_list, info, now_see_info)
	local rowcol_min = 0
	local rowcol_max = 0

	for i3,v3 in ipairs(pos_list) do
		if rowcol_min == 0 then
			rowcol_min = i3
		else
			if pos_list[rowcol_min].x + pos_list[rowcol_min].y > v3.x + v3.y then
				rowcol_min = i3
			end
		end

		if rowcol_max == 0 then
			rowcol_max = i3
		else
			if pos_list[rowcol_max].x + pos_list[rowcol_max].y < v3.x + v3.y then
				rowcol_max = i3
			end
		end
		
	end

	local pos = {}
	if rowcol_min == rowcol_max then
		pos = self:getPosByCoordinate(pos_list[rowcol_max].x, pos_list[rowcol_max].y)
	else

		local p1 = self:getPosByCoordinate(pos_list[rowcol_max].x, pos_list[rowcol_max].y)
		local p2 = self:getPosByCoordinate(pos_list[rowcol_min].x, pos_list[rowcol_min].y)

		pos.x = ( p1.x + p2.x )/2
		pos.y = ( p1.y + p2.y )/2
	end

	local n1,n2 = self:createNodeByInfoo(info, pos_list[1].x,pos_list[1].y)


	n1:setPosition(cc.p(pos.x,pos.y))
	n1:setLocalZOrder(node_tag.kRes)
	self:getResourceNode():addChild(n1)

	table.insert(now_see_info.node_list,n1)

	n2:setPosition(cc.p(pos.x,pos.y))
	n2:setLocalZOrder(node_tag.kResText)
	self:getResourceNode():addChild(n2)

	table.insert(now_see_info.node_list,n2)

end

------------------ END REGION WJJ --------------------
-- TODO



function PlanetDiamondLayer:createDiamondNode( )
	
	self.haveWangzuoNode = false
    self.haveTowerNode = false
	local rn = self:getResourceNode()

	-- DEBUG WJJ 20180704
	if( self.IS_DEBUG_LOG_LOCAL ) then
		local _ii = 1
		for i9,v9 in ipairs(self.now_see_list) do
			local _id = v9.id
			self:_print(string.format(" @@@@ %s: now_see_list[%i9]  name: %s ", tostring(_ii),tostring(i9), tostring(_id) ))
			_ii = _ii + 1
		end
	end

	local c_x,c_y = self:getMidPos()

	--ADD WJJ 180706
	local tileHelper = require("util.ExTileMapHelper"):getInstance()
	local tiles_list_relative_center = tileHelper:GetTileListOfCenterPos(c_x,c_y)

	local _repeated_count = 1
	local _is_skip = false

	for i,v in ipairs(self.now_see_list) do
		-- ADD WJJ 180704
		-- do not run too much  once
		if( _is_skip ) then
			return
		end

		local info_list = planetManager:getInfoByNodeID(v.id)

        if info_list ~= nil then
            local Deadlist = {}
            for i,v in ipairs(info_list) do
                if v.type == 12 then
                    if not self.haveTowerNode then
                        self.haveTowerNode = true
                    end
                    break
                elseif v.type == 11 then
                    local monster_data = v.monster_data
                    if monster_data.isDead == 1 then
                        table.insert (Deadlist,i)
                        local node_2 = rn:getChildByName("node2_"..v.pos_list[1].x.."_"..v.pos_list[1].y)
                        if node_2 ~= nil then
					        self:resetNode2Info(node_2, v)
                        end
                    end
                end
	        end
            if Deadlist ~= nil then
                table.sort(Deadlist,function(a,b)return (a> b) end)

                for i,v in ipairs(Deadlist) do
        	        table.remove(info_list, v)
                end
            end
        end

		if info_list then

			------------------ BEGIN REGION WJJ --------------------
			-- DEBUG WJJ 20180704
			if( self.IS_DEBUG_LOG_LOCAL ) then
				_repeated_count = _repeated_count + 1
				self:_print(string.format(" @@@@ _repeated_count: %s ", tostring(_repeated_count) ))
				local _i = 1
				for i2,v2 in ipairs(info_list) do
					local _name = "node2_"..v2.pos_list[1].x .. "_" .. v2.pos_list[1].y
					self:_print(string.format(" @@@@ %s: info_list[%i2]  name: %s ", tostring(_i),tostring(i2), _name ))
					_i = _i + 1
				end
			end
			for i2,v2 in ipairs(info_list) do
				if v2.type == 12 then
					self.haveWangzuoNode = true
					break
				end
			end
			------------------ END REGION WJJ --------------------
			local youhua_shunxu_i = 1
			for i2,v2 in ipairs(info_list) do

				local _x_load = v2.pos_list[1].x
				local _y_load = v2.pos_list[1].y

				------------------ BEGIN REGION WJJ --------------------
				-- TODO
				local is_shunxu, shunxu_x, shunxu_y = tileHelper:GetTileFromCenter(youhua_shunxu_i, tiles_list_relative_center)

                if self.haveTowerNode or self.haveWangzuoNode then
                    shunxu_x = _x_load
					shunxu_y = _y_load
                else
                    self.attack_time_list = {}
                end

				if( is_shunxu ) then
					_x_load = shunxu_x
					_y_load = shunxu_y
				end

				local _name = "node2_".. tostring(_x_load) .."_".. tostring(_y_load)
	


				self:_print(string.format(" @@@@ createDiamondNode name: %s ", _name ))
				local is_load = rn:getChildByName(_name) == nil

				local shunxu_tile_info = {}
				local is_shunxu_ok = false
				if( is_load and is_shunxu ) then
					is_shunxu_ok, shunxu_tile_info = tileHelper:GetTileInfoAtPos(info_list, shunxu_x, shunxu_y)
					is_shunxu_ok = is_shunxu_ok and (shunxu_tile_info ~= nil)

				end

				-- re check old x y   is load
				if( is_load and is_shunxu and (is_shunxu_ok == false) ) then
					--[[
					-- use old random load tile
					_x_load = v2.pos_list[1].x
					_y_load = v2.pos_list[1].y
					_name = "node2_".. tostring(_x_load) .."_".. tostring(_y_load)
					is_load = rn:getChildByName(_name) == nil
					]]
					is_load = false
				end

			------------------ END REGION WJJ --------------------

				if is_load then
					self:getParent():getUILayer():setLoadingVisible(true)
					local pos_list = v2.pos_list
					local tile_info = v2
					if( is_shunxu_ok ) then
						pos_list = shunxu_tile_info.pos_list
						tile_info = shunxu_tile_info
					end

					self:createTileAtPos(pos_list, tile_info, v)
					self:_print( string.format( "@@@@ createDiamondNode clock: %s", os.clock() ) ) 
					_is_skip = true
					return
				else
					youhua_shunxu_i = youhua_shunxu_i + 1
				end
			end --  for

		end --  if
	end --  for

	self:getParent():getUILayer():setLoadingVisible(false)

	if( self.IS_DEBUG_LOG_VERBOSE ) then
		if( self._debug_count_create > 0 ) then
			self:_print("###LUA DEBUG createNodeByInfoo count: " .. tostring( self._debug_count_create ))
		end
	end 
end

function PlanetDiamondLayer:setCanTouch( flag )
	self.canTouch = true
end

function PlanetDiamondLayer:getNowSeeID( ... )
	
	local list = {}
	for i,v in ipairs(self.now_see_list) do
		if v.node_list then
			if not Tools.isEmpty(v.node_list) then
				table.insert(list, v.id)
			end

		end
		
	end

	return list

end

function PlanetDiamondLayer:getNodeTag( type )

	for i,v in pairs(node_tag) do
		if i == type then
			return v
		end
	end

	return nil
end

function PlanetDiamondLayer:getNowSeeList( ... )
	return self.now_see_list
end

function PlanetDiamondLayer:resetCityNodeInfo( group_info )
	
	local rn = self:getResourceNode()

	local info = planetManager:getInfoByGroupId(group_info.groupid)
	if info == nil then
		return
	end

	if rn:getChildByName("node2_"..info.pos_list[1].x.."_"..info.pos_list[1].y) then

		local node_2 = rn:getChildByName("node2_"..info.pos_list[1].x.."_"..info.pos_list[1].y)

		local back = node_2:getChildByName("back")
		local text = node_2:getChildByName("text")
		local group = node_2:getChildByName("group")
		local name = node_2:getChildByName("name")
		local line = node_2:getChildByName("line")

		local city_data = info.city_data

		if city_data.hasMonster == false and city_data.groupid == "" then
			text:setString(CONF:getStringValue(CONF.PLANETCITY.get(city_data.id).NAME))
		else
			text:setVisible(false)
			group:setVisible(true)
			name:setVisible(true)
			line:setVisible(true)

			name:setString(CONF:getStringValue(CONF.PLANETCITY.get(city_data.id).NAME))
			group:setString(CONF:getStringValue("AI occupy"))

		end


		if city_data.hasMonster then
			

		else

			if city_data.groupid ~= "" then
				text:setVisible(false)
				group:setVisible(true)
				name:setVisible(true)
				line:setVisible(true)

				name:setString(CONF:getStringValue(CONF.PLANETCITY.get(city_data.id).NAME))
				group:setString(group_info.nickname)

				if player:isGroup() then
					if player:getGroupData().groupid == city_data.groupid then
						name:setTextColor(cc.c4b(156,217,255,255))
						-- name:enableShadow(cc.c4b(156,217,255,255), cc.size(0.5,0.5))

						group:setTextColor(cc.c4b(156,217,255,255))
						-- group:enableShadow(cc.c4b(156,217,255,255), cc.size(0.5,0.5))
					else
						--hong
						name:setTextColor(cc.c4b(255,70,70,255))
						-- name:enableShadow(cc.c4b(255,70,70,255), cc.size(0.5,0.5))

						group:setTextColor(cc.c4b(255,70,70,255))
						-- group:enableShadow(cc.c4b(255,70,70,255), cc.size(0.5,0.5))
					end

				else

					--hong
					name:setTextColor(cc.c4b(255,70,70,255))
					-- name:enableShadow(cc.c4b(255,70,70,255), cc.size(0.5,0.5))

					group:setTextColor(cc.c4b(255,70,70,255))
					-- group:enableShadow(cc.c4b(255,70,70,255), cc.size(0.5,0.5))
				end
			end

		end

	end

end

function PlanetDiamondLayer:createInfoNode(ship_info)

	local function createNode( ship_info )
		local node = require("app.ExResInterface"):getInstance():FastLoad("FormScene/FormShipInfoNode.csb")

		node:getChildByName("weapon_text"):setString(CONF:getStringValue("weapon"))
		node:getChildByName("equip_text"):setString(CONF:getStringValue("equip"))
		node:getChildByName("gem_text"):setString(CONF:getStringValue("gem"))

		local skill_conf = CONF.WEAPON.get(ship_info.skill)
		node:getChildByName("skill_icon"):loadTexture("WeaponIcon/"..skill_conf.ICON_ID..".png")
		node:getChildByName("skill_name"):setString(CONF:getStringValue(skill_conf.NAME_ID))
		-- rn:getChildByName("skill_ins"):setString("  "..setMemo(skill_conf, 4))

		local label = cc.Label:createWithTTF("  "..setMemo(skill_conf, 4), "fonts/cuyabra.ttf", 19)
		label:setAnchorPoint(cc.p(0,1))
		label:setPosition(cc.p(node:getChildByName("skill_ins"):getPosition()))
		label:setLineBreakWithoutSpace(true)
		label:setMaxLineWidth(300)
		label:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
		-- label:enableShadow(cc.c4b(255, 255, 255, 255),cc.size(0.5,0.5))
		node:addChild(label)

		node:getChildByName("skill_ins"):removeFromParent()

		local weapon_ccs = {"ui_brackets_weapon_", "weapon_bg_", "weapon_icon_", "weapon_name_", "weapon_lv_", "weapon_lv_num_"}
		local equip_ccs = {"equip_text", "equip_line", "ui_brackets_equip", "equip_item"}
		local gem_ccs = {"gem_text", "gem_line", "ui_brackets_gem", "gem_item"}
		local hh = 86

		for i=1,3 do
			for i2,v2 in ipairs(weapon_ccs) do
				node:getChildByName(v2..i):setPositionY(node:getChildByName(v2..i):getPositionY() - (label:getContentSize().height - hh))
			end
		end

		for i,v in ipairs(equip_ccs) do
			node:getChildByName(v):setPositionY(node:getChildByName(v):getPositionY() - (label:getContentSize().height - hh))
		end

		for i,v in ipairs(gem_ccs) do
			node:getChildByName(v):setPositionY(node:getChildByName(v):getPositionY() - (label:getContentSize().height - hh))
		end
	   
		local weapon_list = {}
		for i,v in ipairs(ship_info.weapon_list) do
			if v ~= 0 then
				table.insert(weapon_list, v)
			end
		end

		for i,v in ipairs(weapon_list) do
			local weapon = player:getWeaponByID(v)
			local weapon_conf = CONF.WEAPON.get(weapon.weapon_id)
			node:getChildByName("weapon_icon_"..i):loadTexture("WeaponIcon/"..weapon_conf.ICON_ID..".png")
			node:getChildByName("weapon_name_"..i):setString(CONF:getStringValue(weapon_conf.NAME_ID))
			node:getChildByName("weapon_lv_num_"..i):setString(weapon_conf.LEVEL)

			node:getChildByName("weapon_lv_"..i):setPositionX(node:getChildByName("weapon_name_"..i):getPositionX() + node:getChildByName("weapon_name_"..i):getContentSize().width + 10)
			node:getChildByName("weapon_lv_num_"..i):setPositionX(node:getChildByName("weapon_lv_"..i):getPositionX() + node:getChildByName("weapon_lv_"..i):getContentSize().width )
		end

		for i=#weapon_list+1,3 do
			for i2,v2 in ipairs(weapon_ccs) do
				node:getChildByName(v2..i):removeFromParent()
			end
		end

		local hh = 50 * (3-#weapon_list)

		for i,v in ipairs(equip_ccs) do
			node:getChildByName(v):setPositionY(node:getChildByName(v):getPositionY() +  hh)
		end

		for i,v in ipairs(gem_ccs) do
			node:getChildByName(v):setPositionY(node:getChildByName(v):getPositionY() +  hh)
		end

		-- for i=#weapon_list+1,3 do
		--     for i2,v2 in ipairs(weapon_ccs) do
		--         node:getChildByName(v2..i):setPositionY(node:getChildByName(v2..i):getPositionY() - (label:getContentSize().height - hh))
		--     end
		-- end

		local equip_list = {}
		for i,v in ipairs(ship_info.equip_list) do
			if v ~= 0 then
				table.insert(equip_list, v)
			end
		end

		local equip_item_pos = cc.p(node:getChildByName("equip_item"):getPosition())
		for i,v in ipairs(equip_list) do
			local equip_info = player:getEquipByGUID(v)
			if equip_info then
				local equip_conf = CONF.EQUIP.get(equip_info.equip_id)

				local equip_node = require("util.ItemNode"):create():init(equip_info.equip_id, nil, equip_info.strength)
				equip_node:setPosition(cc.p(equip_item_pos.x + (i-1)*65, equip_item_pos.y))
				equip_node:setScale(node:getChildByName("equip_item"):getScale())
				node:addChild(equip_node)
			end
		end

		node:getChildByName("equip_item"):setVisible(false)

		local gem_list = {}
		for i,v in ipairs(ship_info.gem_list) do
			if v ~= 0 then
				table.insert(gem_list, v)
			end
		end

		local gem_item_pos = cc.p(node:getChildByName("gem_item"):getPosition())
		for i,v in ipairs(gem_list) do
			local equip_node = require("util.ItemNode"):create():init(v, nil)
			equip_node:setPosition(cc.p(gem_item_pos.x + (i-1)*65, gem_item_pos.y))
			equip_node:setScale(node:getChildByName("gem_item"):getScale())
			node:addChild(equip_node)

		end

		node:getChildByName("gem_item"):setVisible(false)

		return node
	end

	
	local rn = require("app.ExResInterface"):getInstance():FastLoad("FormScene/FormShipInfo.csb")
	local conf = CONF.AIRSHIP.get(ship_info.id)

	rn:getChildByName("ship_upgrade"):setString(CONF:getStringValue("break")..":")
	for i=1,6 do
		rn:getChildByName("star_"..i):setPositionX(rn:getChildByName("ship_upgrade"):getContentSize().width + rn:getChildByName("ship_upgrade"):getPositionX() + 20 + (i-1)*20)
	end

	if ship_info.ship_break == nil then
		ship_info.ship_break = 0
	end

--	for i=ship_info.ship_break+1,6 do
		-- rn:getChildByName("star_"..i):setTexture("LevelScene/ui/star_outline.png")
		-- rn:getChildByName("star_"..i):setScale(1)
--		rn:getChildByName("star_"..i):removeFromParent()
--	end
    ShowShipStar(rn,ship_info.ship_break,"star_")

	rn:getChildByName("Image_3"):loadTexture("ShipImage/"..conf.ICON_ID..".png")
	rn:getChildByName("ship_bg"):setTexture("RankLayer/ui/ui_avatar_"..conf.QUALITY..".png")
	rn:getChildByName("quality"):setTexture("ShipQuality/quality_"..conf.QUALITY..".png")
	rn:getChildByName("ship_icon"):loadTexture("RoleIcon/"..conf.ICON_ID..".png")
	rn:getChildByName("ship_name"):setString(CONF:getStringValue(conf.NAME_ID))
	rn:getChildByName("ship_lv_num"):setString("Lv."..ship_info.level)
	rn:getChildByName("ship_fight_num"):setString(player:calShipFightPowerByInfo(ship_info))
	rn:getChildByName("ship_type"):loadTexture("ShipType/"..conf.TYPE..".png")


	-- local cal_info = player:calShipByInfo(ship_info)
	local cal_info = ship_info
	rn:getChildByName("ship_hp"):setString(CONF:getStringValue("Attr_2")..":")
	rn:getChildByName("ship_hp_num"):setString(cal_info.attr[CONF.EShipAttr.kHP])
	rn:getChildByName("ship_atk"):setString(CONF:getStringValue("Attr_3")..":")
	rn:getChildByName("ship_atk_num"):setString(cal_info.attr[CONF.EShipAttr.kAttack])
	rn:getChildByName("ship_def"):setString(CONF:getStringValue("Attr_4")..":")
	rn:getChildByName("ship_def_num"):setString(cal_info.attr[CONF.EShipAttr.kDefence])
	rn:getChildByName("ship_speed"):setString(CONF:getStringValue("Attr_5")..":")
	rn:getChildByName("ship_speed_num"):setString(cal_info.attr[CONF.EShipAttr.kSpeed])
	rn:getChildByName("ship_e_atk"):setString(CONF:getStringValue("Attr_20")..":")
	rn:getChildByName("ship_e_atk_num"):setString(cal_info.attr[CONF.EShipAttr.kEnergyAttack])
	rn:getChildByName("ship_dur"):setString(CONF:getStringValue("durable")..":")
	rn:getChildByName("ship_dur_num"):setString(ship_info.durable)
	rn:getChildByName("ship_dur_max"):setString("/"..Tools.getShipMaxDurable(ship_info))

	if ship_info.durable < Tools.getShipMaxDurable(ship_info)/10 then
		rn:getChildByName("ship_dur_max"):setTextColor(cc.c4b(255,145,136,255))
		-- rn:getChildByName("ship_dur_max"):enableShadow(cc.c4b(255,145,136,255), cc.size(0.5,0.5))
	end

	local diff = 10
	rn:getChildByName("ship_hp_num"):setPositionX(rn:getChildByName("ship_hp"):getPositionX() + rn:getChildByName("ship_hp"):getContentSize().width + diff)
	rn:getChildByName("ship_atk_num"):setPositionX(rn:getChildByName("ship_atk"):getPositionX() + rn:getChildByName("ship_atk"):getContentSize().width + diff)
	rn:getChildByName("ship_def_num"):setPositionX(rn:getChildByName("ship_def"):getPositionX() + rn:getChildByName("ship_def"):getContentSize().width + diff)
	rn:getChildByName("ship_speed_num"):setPositionX(rn:getChildByName("ship_speed"):getPositionX() + rn:getChildByName("ship_speed"):getContentSize().width + diff)
	rn:getChildByName("ship_e_atk_num"):setPositionX(rn:getChildByName("ship_e_atk"):getPositionX() + rn:getChildByName("ship_e_atk"):getContentSize().width + diff)
	rn:getChildByName("ship_dur_num"):setPositionX(rn:getChildByName("ship_dur"):getPositionX() + rn:getChildByName("ship_dur"):getContentSize().width + diff)
	rn:getChildByName("ship_dur_max"):setPositionX(rn:getChildByName("ship_dur_num"):getPositionX() + rn:getChildByName("ship_dur_num"):getContentSize().width)

	-- local list = rn:getChildByName("list")
	self.svd_ = require("util.ScrollViewDelegate"):create(rn:getChildByName("list"), cc.size(0,0), cc.size(386,480))

	local info_node = createNode(ship_info)

	self.svd_:addElement(info_node)

	rn:getChildByName("ok"):getChildByName("text"):setString(CONF:getStringValue("closed"))
	rn:getChildByName("ok"):addClickEventListener(function ( ... )
		rn:removeFromParent()
	end)

	rn:getChildByName("back"):setSwallowTouches(true)
	rn:getChildByName("back"):addClickEventListener(function ( ... )
		rn:removeFromParent()

	end)

	return rn

end

function PlanetDiamondLayer:getMidPos( ... )
	local tu_pos = cc.p(self.mid_pos.x, self.mid_pos.y) 

	local lc = cc.p(winSize.width/2,winSize.height/2)
	local diff = cc.pSub(lc, tu_pos)

	local xx,yy = getScreenDiffLocation()

	local ox = 0
	local oy = 0
	if CC_DESIGN_RESOLUTION.autoscale == "FIXED_HEIGHT" then
		ox = (winSize.width - CC_DESIGN_RESOLUTION.width) /2
		oy = yy/2 - math.abs((winSize.height - CC_DESIGN_RESOLUTION.height) /2)
	end

	local pos = cc.p(diff.x + xx/2 - ox, diff.y + yy/2 - oy)

	local x = pos.x 
	local y = pos.y 

	local m = math.floor(x/cube_w - y/cube_h)
	local n = math.floor(x/cube_w + y/cube_h)

	return m,n
end

function PlanetDiamondLayer:getMidNodeID( ... )
	local tu_pos = cc.p(self.mid_pos.x - max_w/2, self.mid_pos.y) 

	local lc = cc.p(winSize.width/2,winSize.height/2)
	local diff = cc.pSub(lc, tu_pos)
	-- print("diff",diff.x,diff.y)

	local xx,yy = getScreenDiffLocation()

	local ox = 0
	local oy = 0
	if CC_DESIGN_RESOLUTION.autoscale == "FIXED_HEIGHT" then
		ox = (winSize.width - CC_DESIGN_RESOLUTION.width) /2
		oy = yy/2 - math.abs((winSize.height - CC_DESIGN_RESOLUTION.height) /2)
	end

	local pos = cc.p(diff.x + xx/2 - ox, diff.y + yy/2 - oy)
	local pos_id = self:checkTouchBig(pos)


	return pos_id
end

function PlanetDiamondLayer:checkMoveCan( diff )


	local min_x = 0
	local max_x = 0
	local min_y = 0
	local max_y = 0

	for i,v in ipairs(CONF.PLANETWORLD.getIDList()) do
		local conf = CONF.PLANETWORLD.get(v)
		if conf.ROW < min_x then
			min_x = conf.ROW
		end

		if conf.ROW > max_x then
			max_x = conf.ROW
		end

		if conf.COL < min_y then
			min_y = conf.COL
		end

		if conf.COL > max_y then
			max_y = conf.COL 
		end
	end

	local tu_pos = cc.p(self.mid_pos.x + diff.x - max_w/2, self.mid_pos.y + diff.y) 

	local lc = cc.p(568,384)
	local diff = cc.pSub(lc, tu_pos)
	-- print("diff",diff.x,diff.y)

	local xx,yy = getScreenDiffLocation()

	local ox = 0
	local oy = 0
	if CC_DESIGN_RESOLUTION.autoscale == "FIXED_HEIGHT" then
		ox = (winSize.width - CC_DESIGN_RESOLUTION.width) /2
		oy = yy/2 - math.abs((winSize.height - CC_DESIGN_RESOLUTION.height) /2)
	end

	local pos = cc.p(diff.x + xx/2 - ox, diff.y + yy/2 - oy)

	local rn = self:getResourceNode()

	local m = math.floor(pos.x/max_w - pos.y/max_h)
	local n = math.floor(pos.x/max_w + pos.y/max_h)
	
	if m >= min_x and m <= max_x and n >= min_y and n <= max_y then
		return true
	end

	-- local pos_id = self:checkTouchBig(pos)

	-- local big_id = {}

	-- local not_in_num = 0

	-- if pos_id ~= 0 then
	-- 	table.insert(big_id,pos_id)
	-- end

	-- for i,v in ipairs(screen_diff_pos) do
	-- 	local pp = cc.p(pos.x + v.x, pos.y + v.y)
	-- 	local id = self:checkTouchBig(pp)

	-- 	if id ~= 0 then
	-- 		table.insert(big_id,id)
			
	-- 	end
	-- end

	-- if #big_id >= #screen_diff_pos/2 then
	-- 	return true
	-- end

	self:_print(string.format("@@@@@@@@@@ PlanetDiamondLayer:checkMoveCan FALSE!! diff.x: %s, diff.y: %s ", tostring(diff.x), tostring(diff.y)))

	return false
end

function PlanetDiamondLayer:openResWarAnimation( pos,tag,ship_name )
	local rn = self:getResourceNode()

	if rn:getChildByName("node1_"..pos.x.."_"..pos.y) then
		if rn:getChildByName("node1_"..pos.x.."_"..pos.y):getChildByName("warAni_"..pos.x.."_"..pos.y) then

			return
		end
	else
		return
		
	end

	if ship_name then
		if rn:getChildByName(ship_name) then
			self:runAction(cc.Sequence:create(cc.DelayTime:create(0.3), cc.CallFunc:create(function ( ... )
				if rn:getChildByName(ship_name) then
					rn:getChildByName(ship_name):setVisible(false)
				end
			end)))

			rn:getChildByName(ship_name):setVisible(false)
		end
	end

	local node = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/sfx/feichaunyidong/animation"..tag..".csb")
	-- node:setPosition(self:getPosByCoordinate(pos.x, pos.y))
	node:setName("warAni_"..pos.x.."_"..pos.y)

	rn:getChildByName("node1_"..pos.x.."_"..pos.y):addChild(node, node_tag.kShip)

	animManager:runAnimOnceByCSB(node, "PlanetScene/sfx/feichaunyidong/animation"..tag..".csb", "1", function ( ... )
		node:removeFromParent()

		if rn:getChildByName(ship_name) then
			rn:getChildByName(ship_name):setVisible(true)
		end
	end)

end


-- ADD WJJ 20180621
function PlanetDiamondLayer:OnInit()
	
end

function PlanetDiamondLayer:OnDrag()
	
end

function PlanetDiamondLayer:SetTimeMoveTile()
	self.prevTileMoveTime = Tools.clock()
end

function PlanetDiamondLayer:SetTimeLoadTile()
	self.prevTileLoadTime = Tools.clock()
end

function PlanetDiamondLayer:IsTimeToMoveTile()
	local now = Tools.clock()
	local is_move = now > self.prevTileMoveTime + self.exConfig.TILE_MOVE_INTERVAL
	self:_print(string.format(" @@@ IsTimeToMoveTile is_move: %s ,now=%s,prev=%s,conf=%s ",  tostring(is_move),tostring(now),tostring(self.prevTileMoveTime),tostring(self.exConfig.TILE_MOVE_INTERVAL)))
	return is_move
end

function PlanetDiamondLayer:IsTimeToLoadTile()
	local now = Tools.clock()
	local is_load = now > self.prevTileLoadTime + self.exConfig.TILE_LOAD_INTERVAL
	self:_print(string.format(" @@@ IsTimeToLoadTile is_load: %s   ",  tostring(is_load)))
	return is_load
end



function PlanetDiamondLayer:onEnterTransitionFinish()
	printInfo("PlanetDiamondLayer:onEnterTransitionFinish()")
	if g_System_Guide_Id ~= 0 then
		systemGuideManager:createGuideLayer(g_System_Guide_Id)
	end

	self:runAction(cc.Sequence:create(cc.DelayTime:create(0.5), cc.CallFunc:create(function ( ... )
		local strData = Tools.encode("PlanetGetReq", {
			type = 1,
		 })
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData)
	end)))

	self.cubes = {}
	self.gezis = {}
	self.bg_icon = {}

	self.choose_ = {m = 0, n = 0}
	self.canTouch = true
	self.frist = true
	self.see_ship = 0
	self.show_5 = true

	self.warAni_list = {}
	self.now_see_list = {} -- id, node_list

	self.mid_pos = {x = default_size.width/2, y = default_size.height/2}

	local rn = self:getResourceNode()

	rn:getChildByName("red"):setLocalZOrder(node_tag.kRed)
	rn:getChildByName("red"):getChildByName("Sprite_1"):setScale(winSize.width/rn:getChildByName("red"):getChildByName("Sprite_1"):getContentSize().width, winSize.height/rn:getChildByName("red"):getChildByName("Sprite_1"):getContentSize().height)
	animManager:runAnimByCSB(rn:getChildByName("red"), "PlanetScene/sfx/shanping/shanping.csb", "1")

	self._pam = planetArmyManager:create(self)
	self._pam:clearArmyList()

	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_UPDATE_TIMESTAMP_REQ"),"0")
	-- g_sendList:addSend({define = "CMD_UPDATE_TIMESTAMP_REQ", strData = "0", key = "update_time"})

	animManager:runAnimByCSB(rn:getChildByName("bg"), "PlanetScene/sfx/background.csb", "1")

	local function randowRGB( ... )
		local r = 0
		local g = 0
		local b = 0

		for i=1,10 do
			r = math.random(1,255)
			g = math.random(1,255)
			b = math.random(1,255)
		end

		return r/255,g/255,b/255

	end

	local function drawCube( row,col,m,n,red,green,blue )

		local diff_x = cube_w/2*row - cube_w/2*col 
		local diff_y = cube_h/2*row + cube_h/2*col
		-- diff_x = cube_w*row
		-- diff_y = cube_h*rol

		local x = default_size.width/2 + m*max_w/2 + n*max_w/2
		local y = default_size.height/2 - m*max_h/2 + n*max_h/2
		local x_mid = x
		local y_mid = y - max_col/2*cube_h

		-- local drawNode = cc.DrawNode:create()
		-- drawNode:drawRect(cc.p(x_mid+diff_x,y_mid+diff_y), cc.p(x_mid+cube_w/2+diff_x ,(y_mid - cube_h/2)+diff_y), cc.p(x_mid+cube_w+diff_x,y_mid+diff_y), cc.p(x_mid+cube_w/2+diff_x,(y_mid + cube_h/2)+diff_y), cc.c4f(red,green,blue,1))

		local mm,nn = self:checkTouch(pos)
		local label = cc.Label:createWithTTF(string.format("(%d,%d)", mm,nn), "fonts/cuyabra.ttf", 26)
		label:setPosition(cc.p(pos.x, pos.y))
		label:setTextColor(cc.c4b(red*255,green*255,blue*255,255))
		-- label:enableShadow(cc.c4b(red*255,green*255,blue*255,255), cc.size(0.5,0.5))
		local pos = cc.p(x_mid+di(red*255,green*255,blue*255,255), cc.size(0.5,0.5))

		return label
	end

	local function createNode( m,n,index )
		-- local r,g,b = randowRGB()

		-- for i=0,max_row-1 do
		-- 	for j=0,max_col-1 do
		-- 		local drawNode = drawCube(i,j,m,n,r,g,b)
		-- 		rn:addChild(drawNode)

		-- 		table.insert(self.cubes, drawNode)
		-- 	end
		-- end

		local x = default_size.width/2 + m*max_w/2 + n*max_w/2
		local y = default_size.height/2 - m*max_h/2 + n*max_h/2

		local diff = {{x = -max_w/4, y = 0}, {x = 0, y = max_h/4}, {x = max_w/4, y = 0}, {x = 0, y = -max_h/4}}

		for i,v in ipairs(diff) do
			local gezi = cc.Sprite:create("PlanetScene/ui/gezi.png")
			gezi:setPosition(cc.p(x+v.x,y+v.y))
			gezi:setTag(index*10+i)
			gezi:setName("gezi_"..index.."_"..i)
			gezi:setLocalZOrder(node_tag.kGezi)
			rn:addChild(gezi)

			table.insert(self.gezis, gezi)
		end

		local grid = cc.Sprite:create("PlanetScene/ui/grid.png")

		local x_d
		local y_d 
		for i=1,3 do
			x_d = math.random(0,3)
			y_d = math.random(0,9)
		end

		grid:setPosition(cc.p(x + cube_w*x_d/2 + cube_w*y_d/2 + lv_grid.x , y - x_d*cube_h/2 + y_d*cube_h/2 + lv_grid.y))
		grid:setLocalZOrder(node_tag.kGrid)
		grid:setOpacity(255*0.8)
		rn:addChild(grid)

		table.insert(self.gezis, grid)

		-- for j=1,2 do
		-- 	for i=1,3 do
		-- 		x_d = math.random(16)
		-- 		y_d = math.random(16)
		-- 	end

		-- 	local star_yun_1 = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/sfx/xingyun/xingyun.csb")
		-- 	animManager:runAnimByCSB(star_yun_1, "PlanetScene/sfx/xingyun/xingyun.csb", "1")
		-- 	star_yun_1:setPosition(cc.p(x + cube_w*x_d/2 + cube_w*y_d/2 , y - x_d*cube_h/2 + y_d*cube_h/2))
		-- 	star_yun_1:setLocalZOrder(node_tag.kStarYun)
		-- 	rn:getChildByName("bg_node_1"):addChild(star_yun_1)

		-- 	local tt = {icon = star_yun_1, speed = star_yun_move_1}
		-- 	table.insert(self.bg_icon, tt)

		-- 	for i=1,3 do
		-- 		x_d = math.random(16)
		-- 		y_d = math.random(16)
		-- 	end

		-- 	local star_yun_2 = cc.Sprite:createWithSpriteFrameName("PlanetScene/ui/bg_star_yun_2.png")
		-- 	star_yun_2:setPosition(cc.p(x + cube_w*x_d/2 + cube_w*y_d/2 , y - x_d*cube_h/2 + y_d*cube_h/2))
		-- 	star_yun_2:setLocalZOrder(node_tag.kStarYun)
		-- 	rn:getChildByName("bg_node_2"):addChild(star_yun_2)

		-- 	local tt = {icon = star_yun_2, speed = star_yun_move_2}
		-- 	table.insert(self.bg_icon, tt)

		-- 	for i=1,3 do
		-- 		x_d = math.random(16)
		-- 		y_d = math.random(16)
		-- 	end

		-- 	local bg_qiu_1 = cc.Sprite:createWithSpriteFrameName("PlanetScene/ui/bg_qiu_1.png")
		-- 	bg_qiu_1:setPosition(cc.p(x + cube_w*x_d/2 + cube_w*y_d/2 , y - x_d*cube_h/2 + y_d*cube_h/2))
		-- 	bg_qiu_1:setLocalZOrder(node_tag.kStar)
		-- 	rn:getChildByName("bg_node_4"):addChild(bg_qiu_1)

		-- 	local tt = {icon = bg_qiu_1, speed = qiu_move_1}
		-- 	table.insert(self.bg_icon, tt)

		-- 	for i=1,3 do
		-- 		x_d = math.random(16)
		-- 		y_d = math.random(16)
		-- 	end

		-- 	local bg_qiu_2 = cc.Sprite:createWithSpriteFrameName("PlanetScene/ui/bg_qiu_2.png")
		-- 	bg_qiu_2:setPosition(cc.p(x + cube_w*x_d/2 + cube_w*y_d/2 , y - x_d*cube_h/2 + y_d*cube_h/2))
		-- 	bg_qiu_2:setLocalZOrder(node_tag.kStar)
		-- 	rn:getChildByName("bg_node_5"):addChild(bg_qiu_2)

		-- 	local tt = {icon = bg_qiu_2, speed = qiu_move_2}
		-- 	table.insert(self.bg_icon, tt)


		-- 	for i=1,3 do
		-- 		x_d = math.random(16)
		-- 		y_d = math.random(16)
		-- 	end

		-- 	local light_star = cc.Sprite:createWithSpriteFrameName("PlanetScene/ui/light_star.png")
		-- 	light_star:setPosition(cc.p(x + cube_w*x_d/2 + cube_w*y_d/2 , y - x_d*cube_h/2 + y_d*cube_h/2))
		-- 	light_star:setLocalZOrder(node_tag.kLightStar)
		-- 	rn:getChildByName("bg_node_3"):addChild(light_star)

		-- 	local tt = {icon = light_star, speed = star_move_}
		-- 	table.insert(self.bg_icon, tt)

		-- 	for i=1,3 do
		-- 		x_d = math.random(16)
		-- 		y_d = math.random(16)
		-- 	end

		-- 	local bg_star_yun_3 = cc.Sprite:createWithSpriteFrameName("PlanetScene/ui/bg_star_yun_3.png")
		-- 	bg_star_yun_3:setPosition(cc.p(x + cube_w*x_d/2 + cube_w*y_d/2 , y - x_d*cube_h/2 + y_d*cube_h/2))
		-- 	bg_star_yun_3:setLocalZOrder(node_tag.kLightStar)
		-- 	rn:getChildByName("bg_node_7"):addChild(bg_star_yun_3)

		-- 	local tt = {icon = bg_star_yun_3, speed = star_yun_move_3}
		-- 	table.insert(self.bg_icon, tt)

		-- 	for i=1,3 do
		-- 		x_d = math.random(16)
		-- 		y_d = math.random(16)
		-- 	end

		-- 	local bg_qiu_3 = cc.Sprite:createWithSpriteFrameName("PlanetScene/ui/bg_qiu_3.png")
		-- 	bg_qiu_3:setPosition(cc.p(x + cube_w*x_d/2 + cube_w*y_d/2 , y - x_d*cube_h/2 + y_d*cube_h/2))
		-- 	bg_qiu_3:setLocalZOrder(node_tag.kLightStar)
		-- 	rn:getChildByName("bg_node_8"):addChild(bg_qiu_3)

		-- 	local tt = {icon = bg_qiu_3, speed = qiu_move_3}
		-- 	table.insert(self.bg_icon, tt)

		-- 	for i=1,3 do
		-- 		x_d = math.random(16)
		-- 		y_d = math.random(16)
		-- 	end

		-- 	local bg_star_yun_1 = cc.Sprite:createWithSpriteFrameName("PlanetScene/ui/bg_star_yun_1.png")
		-- 	bg_star_yun_1:setPosition(cc.p(x + cube_w*x_d/2 + cube_w*y_d/2 , y - x_d*cube_h/2 + y_d*cube_h/2))
		-- 	bg_star_yun_1:setLocalZOrder(node_tag.kLightStar)
		-- 	rn:getChildByName("bg_node_10"):addChild(bg_star_yun_1)

		-- 	local tt = {icon = bg_star_yun_1, speed = qiu_move_3}
		-- 	table.insert(self.bg_icon, tt)
			


		-- 	for i=1,3 do
		-- 		x_d = math.random(16)
		-- 		y_d = math.random(16)
		-- 	end

		-- 	local yun = cc.Sprite:createWithSpriteFrameName("PlanetScene/ui/yun.png")
		-- 	yun:setPosition(cc.p(x + cube_w*x_d/2 + cube_w*y_d/2 , y - x_d*cube_h/2 + y_d*cube_h/2))
		-- 	yun:setLocalZOrder(node_tag.kYun)
		-- 	rn:getChildByName("bg_node_9"):addChild(yun)

		-- 	local tt = {icon = yun, speed = 1}
		-- 	table.insert(self.bg_icon, tt)
		-- end

		

		-- for j=1,2 do
		-- 	for i=1,3 do
		-- 		x_d = math.random(16)
		-- 		y_d = math.random(16)
		-- 	end

		-- 	local bg_stone_1 = cc.Sprite:createWithSpriteFrameName("PlanetScene/ui/bg_stone_1.png")
		-- 	bg_stone_1:setPosition(cc.p(x + cube_w*x_d/2 + cube_w*y_d/2 , y - x_d*cube_h/2 + y_d*cube_h/2))
		-- 	bg_stone_1:setLocalZOrder(node_tag.kStone)
		-- 	rn:getChildByName("bg_node_6"):addChild(bg_stone_1)

		-- 	local tt = {icon = bg_stone_1, speed = stone_move}
		-- 	table.insert(self.bg_icon, tt)

		-- 	for i=1,3 do
		-- 		x_d = math.random(16)
		-- 		y_d = math.random(16)
		-- 	end

		-- 	local bg_stone_2 = cc.Sprite:createWithSpriteFrameName("PlanetScene/ui/bg_stone_2.png")
		-- 	bg_stone_2:setPosition(cc.p(x + cube_w*x_d/2 + cube_w*y_d/2 , y - x_d*cube_h/2 + y_d*cube_h/2))
		-- 	bg_stone_2:setLocalZOrder(node_tag.kStone)
		-- 	rn:getChildByName("bg_node_6"):addChild(bg_stone_2)

		-- 	local tt = {icon = bg_stone_2, speed = stone_move}
		-- 	table.insert(self.bg_icon, tt)
		-- end
		for i=1,10 do
			if rn:getChildByName("bg_node_3"):getChildByName(index.."addyun_"..i) then
				rn:getChildByName("bg_node_3"):getChildByName(index.."addyun_"..i):removeFromParent()
			end
			local indexx = math.random(1,6)
			local yun 
			if indexx <= 5 then
				 yun = cc.Sprite:create("PlanetScene/ui/bg_star_yun_"..indexx..".png")
			else
				 yun = cc.Sprite:create("PlanetScene/ui/yun.png")
			end
			for i=1,3 do
				x_d = math.random(16)
				y_d = math.random(16)
			end
			yun:setPosition(cc.p(x + cube_w*x_d/2 + cube_w*y_d/2 , y - x_d*cube_h/2 + y_d*cube_h/2))
			yun:setLocalZOrder(node_tag.kYun)
			yun:setName(index.."addyun_"..i)
			rn:getChildByName("bg_node_3"):addChild(yun)

			local tt = {icon = yun, speed = move_bottom}
			table.insert(self.bg_icon, tt)
		end
		for i=1,3 do
			if rn:getChildByName("bg_node_2"):getChildByName(index.."addqiu_"..i) then
				rn:getChildByName("bg_node_2"):getChildByName(index.."addqiu_"..i):removeFromParent()
			end
			local inde = math.random(1,6)
			local qiu 
			if inde <= 5 then
				qiu = cc.Sprite:create("PlanetScene/ui/bg_qiu_"..inde..".png")
			else
				qiu = cc.Sprite:create("PlanetScene/ui/light_star.png")
			end
			for i=1,3 do
				x_d = math.random(16)
				y_d = math.random(16)
			end
			qiu:setPosition(cc.p(x + cube_w*x_d/2 + cube_w*y_d/2 , y - x_d*cube_h/2 + y_d*cube_h/2))
			qiu:setLocalZOrder(node_tag.kStar)
			qiu:setName(index.."addqiu_"..i)
			rn:getChildByName("bg_node_2"):addChild(qiu)

			local tt = {icon = qiu, speed = move_middle}
			table.insert(self.bg_icon, tt)
		end
		for j=1,2 do
			for i=1,3 do
				x_d = math.random(16)
				y_d = math.random(16)
			end
			if rn:getChildByName("bg_node_1"):getChildByName(index.."add_bg_stone_1") then
				rn:getChildByName("bg_node_1"):getChildByName(index.."add_bg_stone_1"):removeFromParent()
			end
			local bg_stone_1 = cc.Sprite:create("PlanetScene/ui/bg_stone_1.png")
			bg_stone_1:setPosition(cc.p(x + cube_w*x_d/2 + cube_w*y_d/2 , y - x_d*cube_h/2 + y_d*cube_h/2))
			bg_stone_1:setLocalZOrder(node_tag.kStone)
			bg_stone_1:setName(index.."add_bg_stone_1")
			rn:getChildByName("bg_node_1"):addChild(bg_stone_1)

			local tt = {icon = bg_stone_1, speed = move_top}
			table.insert(self.bg_icon, tt)

			for i=1,3 do
				x_d = math.random(16)
				y_d = math.random(16)
			end
			if rn:getChildByName("bg_node_1"):getChildByName(index.."add_bg_stone_2") then
				rn:getChildByName("bg_node_1"):getChildByName(index.."add_bg_stone_2"):removeFromParent()
			end
			local bg_stone_2 = cc.Sprite:create("PlanetScene/ui/bg_stone_2.png")
			bg_stone_2:setPosition(cc.p(x + cube_w*x_d/2 + cube_w*y_d/2 , y - x_d*cube_h/2 + y_d*cube_h/2))
			bg_stone_2:setLocalZOrder(node_tag.kStone)
			bg_stone_2:setName(index.."add_bg_stone_2")
			rn:getChildByName("bg_node_1"):addChild(bg_stone_2)

			local tt = {icon = bg_stone_2, speed = move_top}
			table.insert(self.bg_icon, tt)
		end
		


	end


	local function createNoneNode( m,n,index )

		local x = default_size.width/2 + m*max_w/2 + n*max_w/2
		local y = default_size.height/2 - m*max_h/2 + n*max_h/2

		local diff = {{x = -max_w/4, y = 0}, {x = 0, y = max_h/4}, {x = max_w/4, y = 0}, {x = 0, y = -max_h/4}}

		local picture = CONF.PARAM.get("empty_node_picture").PARAM
		for i,v in ipairs(diff) do
			local gezi = cc.Sprite:create("PlanetScene/ui/"..picture[math.random(1,#picture)] ..".png")
			if gezi then
				gezi:setPosition(cc.p(x+v.x,y+v.y))
				gezi:setTag(index*10+i)
				gezi:setName("gezi_"..index.."_"..i)
				gezi:setLocalZOrder(node_tag.kGezi)
				rn:addChild(gezi)

				table.insert(self.gezis, gezi)
			end
		end
		local x_d
		local y_d 
		for i=1,10 do
			if rn:getChildByName("bg_node_3"):getChildByName(index.."addyun_"..i) then
				rn:getChildByName("bg_node_3"):getChildByName(index.."addyun_"..i):removeFromParent()
			end
			local indexx = math.random(1,6)
			local yun 
			if indexx <= 5 then
				 yun = cc.Sprite:create("PlanetScene/ui/bg_star_yun_"..indexx..".png")
			else
				 yun = cc.Sprite:create("PlanetScene/ui/yun.png")
			end
			for i=1,3 do
				x_d = math.random(16)
				y_d = math.random(16)
			end
			yun:setPosition(cc.p(x + cube_w*x_d/2 + cube_w*y_d/2 , y - x_d*cube_h/2 + y_d*cube_h/2))
			yun:setLocalZOrder(node_tag.kYun)
			yun:setName(index.."addyun_"..i)
			rn:getChildByName("bg_node_3"):addChild(yun)

			local tt = {icon = yun, speed = move_bottom}
			table.insert(self.bg_icon, tt)
		end
		for i=1,3 do
			if rn:getChildByName("bg_node_2"):getChildByName(index.."addqiu_"..i) then
				rn:getChildByName("bg_node_2"):getChildByName(index.."addqiu_"..i):removeFromParent()
			end
			local inde = math.random(1,6)
			local qiu 
			if inde <= 5 then
				qiu = cc.Sprite:create("PlanetScene/ui/bg_qiu_"..inde..".png")
			else
				qiu = cc.Sprite:create("PlanetScene/ui/light_star.png")
			end
			for i=1,3 do
				x_d = math.random(16)
				y_d = math.random(16)
			end
			qiu:setPosition(cc.p(x + cube_w*x_d/2 + cube_w*y_d/2 , y - x_d*cube_h/2 + y_d*cube_h/2))
			qiu:setLocalZOrder(node_tag.kStar)
			qiu:setName(index.."addqiu_"..i)
			rn:getChildByName("bg_node_2"):addChild(qiu)

			local tt = {icon = qiu, speed = move_middle}
			table.insert(self.bg_icon, tt)
		end
		for j=1,2 do
			for i=1,3 do
				x_d = math.random(16)
				y_d = math.random(16)
			end
			if rn:getChildByName("bg_node_1"):getChildByName(index.."add_bg_stone_1") then
				rn:getChildByName("bg_node_1"):getChildByName(index.."add_bg_stone_1"):removeFromParent()
			end
			local bg_stone_1 = cc.Sprite:create("PlanetScene/ui/bg_stone_1.png")
			bg_stone_1:setPosition(cc.p(x + cube_w*x_d/2 + cube_w*y_d/2 , y - x_d*cube_h/2 + y_d*cube_h/2))
			bg_stone_1:setLocalZOrder(node_tag.kStone)
			bg_stone_1:setName(index.."add_bg_stone_1")
			rn:getChildByName("bg_node_1"):addChild(bg_stone_1)

			local tt = {icon = bg_stone_1, speed = move_top}
			table.insert(self.bg_icon, tt)

			for i=1,3 do
				x_d = math.random(16)
				y_d = math.random(16)
			end
			if rn:getChildByName("bg_node_1"):getChildByName(index.."add_bg_stone_2") then
				rn:getChildByName("bg_node_1"):getChildByName(index.."add_bg_stone_2"):removeFromParent()
			end
			local bg_stone_2 = cc.Sprite:create("PlanetScene/ui/bg_stone_2.png")
			bg_stone_2:setPosition(cc.p(x + cube_w*x_d/2 + cube_w*y_d/2 , y - x_d*cube_h/2 + y_d*cube_h/2))
			bg_stone_2:setLocalZOrder(node_tag.kStone)
			bg_stone_2:setName(index.."add_bg_stone_2")
			rn:getChildByName("bg_node_1"):addChild(bg_stone_2)

			local tt = {icon = bg_stone_2, speed = move_top}
			table.insert(self.bg_icon, tt)
		end
	
	end

	local minX = 0
	local maxX = 0
	local minY = 0
	local maxY = 0
	local tmpNodeList = {}
	for i,v in ipairs(CONF.PLANETWORLD.getIDList()) do
		local conf = CONF.PLANETWORLD.get(i)
		createNode(conf.ROW,conf.COL,i)
		minX = math.min(conf.ROW,minX)
		maxX = math.max(conf.ROW,maxX)
		minY = math.min(conf.COL,minY)
		maxY = math.max(conf.COL,maxY)
		table.insert(tmpNodeList,{conf.ROW,conf.COL})
	end

	local function havePos(x,y)
		for i,v in ipairs(tmpNodeList) do
			if x == v[1] and y == v[2] then
				return true
			end
		end
		return false
	end
	--print("################## start pos")
	local index = CONF.PLANETWORLD.count()+1
	for i=minX, maxX do
		for j=minY, maxY do
			if havePos(i,j) == false then
				--print("x=",i,"y=",j)
				createNoneNode(i,j,index)
				index = index+1
			end
		end
	end
	--print("################## end pos")
	-- message PlanetArmyLine{

-- 	required string user_key = 1;//(user_name)_(army_guid)
-- 	repeated int32 node_id_list = 2;
-- 	repeated PlanetPoint move_list = 3;
-- 	required int64 begin_time = 4;
-- 	repeated int64 need_time = 5;
-- };

	local function update( dt )
		local _began_clock = os.clock()
		-- self:_print(string.format("_began_clock: %s", tostring(_began_clock)))

		self._pam:update(dt)

		if self.see_ship ~= 0 then
			self:moveByShip()
		end

		-- do not drag and create tile one time ...
		local diff = {x = self.move_fx_ * self.RATE_DRAG_MOVED, y = self.move_fy_ * self.RATE_DRAG_MOVED}
		local is_drag = ((math.abs(self.move_fx_) > 0.1 or math.abs(self.move_fy_)  > 0.1)) and self:checkMoveCan(diff)

		if( (self.touchMove_ == false ) and
			 ( (self:IsTimeToMoveTile() == false) or (is_drag == false) ) ) then
		if( self.IS_UPDATE_NODES ) then
			-- do not create every frame... WJJ
			if( self:IsTimeToLoadTile() ) then
				self:SetTimeLoadTile()
				self:createDiamondNode()
			end
		end
		else
			self:_print(string.format(" ___ do not create tile now: %s", tostring(os.clock())))

		end

-------------------------
	
	if( self:IsTimeToMoveTile() ) then

		local diff = {x = self.move_fx_ * self.RATE_DRAG_MOVED, y = self.move_fy_ * self.RATE_DRAG_MOVED}
		if ((math.abs(self.move_fx_) > 0.1 or math.abs(self.move_fy_)  > 0.1)) and self:checkMoveCan(diff) then
			self:SetTimeMoveTile()

			self:_print(string.format("PlanetDiamondLayer update BEFORE = ZERO self.move_fx_: %s \nself.move_fy_: %s",tostring(self.move_fx_),tostring(self.move_fy_)))

			-- fuck old programmers... do not use 2 local.. WJJ
			-- local diff = {x = self.move_fx_, y = self.move_fy_}

			if(false == self.IS_DISABLE_DRAG_UPDATE) then
				self:moveNode(diff,true)
			end
			
			if(self.IS_DRAG_GUAN_XING) then
				self.move_fx_ = self.move_fx_ * g_friction
				self.move_fy_ = self.move_fy_ * g_friction
			else
				self.move_fx_ = 0
				self.move_fy_ = 0
			end
		end
	end
	-- if 2887
 -------------------------

		self:checkDistance()
         	-- local tower_data = info.tower_data
		-- require("util.ExWangzuoHelper"):getInstance():Debug_Diancita(tower_data.occupy_begin_time, tower_data.is_attack)

		local _end_clock = os.clock()
		-- self:_print(string.format("_end_clock: %s", tostring(_end_clock)))
		local _passed = _end_clock - _began_clock
		if ( _passed > 0.02 ) then
			self:_print(string.format("passed: %s", tostring(_passed)))
		end


	end

	self:scheduleUpdateWithPriorityLua(update, self.DRAG_UPDATE_YOUXIANJI)

	local function updateRes( dt )		
		for i,v in ipairs(planetManager:getInfoList()) do
			if v.info then
				for i2,v2 in ipairs(v.info) do
					if rn:getChildByName("node2_"..v2.pos_list[1].x.."_"..v2.pos_list[1].y) then
						local node_2 = rn:getChildByName("node2_"..v2.pos_list[1].x.."_"..v2.pos_list[1].y)

						self:resetNode2Info(node_2, v2)
					end
				end
			end
		end

		local has = false
		for i,v in ipairs(self._pam:getArmyList()) do
			local move_list_num = table.getn(v.info.move_list)
			print("@@@@@@@@@@@@",type(planetManager:getUserBaseElementPos()))
			if move_list_num > 0 and v.info.move_list[move_list_num].x == planetManager:getUserBaseElementPos().x and v.info.move_list[move_list_num].y == planetManager:getUserBaseElementPos().y then

				local user_key = v.info.user_key

				local type
				local name = Split(user_key, "_")[1]

				if name == player:getName() then
					type = 1
				else
					if player:checkPlayerIsInGroup(name) then
						type = 2
					else
						type = 3
					end

				end

				if type == 3 then
					has = true
					break
				end
			end
		end

		if has then
			rn:getChildByName("red"):setVisible(true)
		else
			rn:getChildByName("red"):setVisible(false)
		end

		-- for i,v in ipairs(self.now_see_list) do
		-- 	print("hehehehee" ,v.create_bg)
		-- 	if not Tools.isEmpty(v.node_list) and not v.create_bg then

		-- 		local m = CONF.PLANETWORLD.get(v.id).ROW
		-- 		local n = CONF.PLANETWORLD.get(v.id).COL

		-- 		local x = self.mid_pos.x + m*max_w/2 + n*max_w/2
		-- 		local y = self.mid_pos.y - m*max_h/2 + n*max_h/2

		-- 		local x_d = 0
		-- 		local y_d = 0

		-- 		local random_num = 13

		-- 		for j=1,2 do
					
		-- 			for i=1,3 do
		-- 				x_d = math.random(random_num)
		-- 				y_d = math.random(random_num)
		-- 			end

		-- 			-- local star_yun_1 = cc.Sprite:createWithSpriteFrameName("PlanetScene/ui/bg_star_yun_1.png")
		-- 			local star_yun_1 = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/sfx/xingyun/xingyun.csb")
		-- 			animManager:runAnimByCSB(star_yun_1, "PlanetScene/sfx/xingyun/xingyun.csb", "1")
		-- 			star_yun_1:setPosition(cc.p(x + cube_w*x_d/2 + cube_w*y_d/2 , y - x_d*cube_h/2 + y_d*cube_h/2))
		-- 			star_yun_1:setLocalZOrder(node_tag.kStarYun)
		-- 			rn:getChildByName("bg_node_1"):addChild(star_yun_1)

		-- 			local tt = {icon = star_yun_1, speed = star_yun_move_1}
		-- 			table.insert(self.bg_icon, tt)

		-- 			for i=1,3 do
		-- 				x_d = math.random(random_num)
		-- 				y_d = math.random(random_num)
		-- 			end

		-- 			local star_yun_2 = cc.Sprite:createWithSpriteFrameName("PlanetScene/ui/bg_star_yun_2.png")
		-- 			star_yun_2:setPosition(cc.p(x + cube_w*x_d/2 + cube_w*y_d/2 , y - x_d*cube_h/2 + y_d*cube_h/2))
		-- 			star_yun_2:setLocalZOrder(node_tag.kStarYun)
		-- 			rn:getChildByName("bg_node_2"):addChild(star_yun_2)

		-- 			local tt = {icon = star_yun_2, speed = star_yun_move_2}
		-- 			table.insert(self.bg_icon, tt)

		-- 			for i=1,3 do
		-- 				x_d = math.random(random_num)
		-- 				y_d = math.random(random_num)
		-- 			end

		-- 			local bg_qiu_1 = cc.Sprite:createWithSpriteFrameName("PlanetScene/ui/bg_qiu_1.png")
		-- 			bg_qiu_1:setPosition(cc.p(x + cube_w*x_d/2 + cube_w*y_d/2 , y - x_d*cube_h/2 + y_d*cube_h/2))
		-- 			bg_qiu_1:setLocalZOrder(node_tag.kStar)
		-- 			rn:getChildByName("bg_node_4"):addChild(bg_qiu_1)

		-- 			local tt = {icon = bg_qiu_1, speed = qiu_move_1}
		-- 			table.insert(self.bg_icon, tt)

		-- 			for i=1,3 do
		-- 				x_d = math.random(random_num)
		-- 				y_d = math.random(random_num)
		-- 			end

		-- 			local bg_qiu_2 = cc.Sprite:createWithSpriteFrameName("PlanetScene/ui/bg_qiu_2.png")
		-- 			bg_qiu_2:setPosition(cc.p(x + cube_w*x_d/2 + cube_w*y_d/2 , y - x_d*cube_h/2 + y_d*cube_h/2))
		-- 			bg_qiu_2:setLocalZOrder(node_tag.kStar)
		-- 			rn:getChildByName("bg_node_5"):addChild(bg_qiu_2)

		-- 			local tt = {icon = bg_qiu_2, speed = qiu_move_2}
		-- 			table.insert(self.bg_icon, tt)


		-- 			for i=1,3 do
		-- 				x_d = math.random(random_num)
		-- 				y_d = math.random(random_num)
		-- 			end

		-- 			local light_star = cc.Sprite:createWithSpriteFrameName("PlanetScene/ui/light_star.png")
		-- 			light_star:setPosition(cc.p(x + cube_w*x_d/2 + cube_w*y_d/2 , y - x_d*cube_h/2 + y_d*cube_h/2))
		-- 			light_star:setLocalZOrder(node_tag.kLightStar)
		-- 			rn:getChildByName("bg_node_3"):addChild(light_star)

		-- 			local tt = {icon = light_star, speed = star_move_}
		-- 			table.insert(self.bg_icon, tt)

		-- 			for i=1,3 do
		-- 				x_d = math.random(random_num)
		-- 				y_d = math.random(random_num)
		-- 			end

		-- 			local yun = cc.Sprite:createWithSpriteFrameName("PlanetScene/ui/yun.png")
		-- 			yun:setPosition(cc.p(x + cube_w*x_d/2 + cube_w*y_d/2 , y - x_d*cube_h/2 + y_d*cube_h/2))
		-- 			yun:setLocalZOrder(node_tag.kYun)
		-- 			rn:getChildByName("bg_node_7"):addChild(yun)

		-- 			local tt = {icon = yun, speed = 1}
		-- 			table.insert(self.bg_icon, tt)
		-- 		end

				

		-- 		for j=1,4 do
		-- 			for i=1,3 do
		-- 				x_d = math.random(random_num)
		-- 				y_d = math.random(random_num)
		-- 			end

		-- 			local bg_stone_1 = cc.Sprite:createWithSpriteFrameName("PlanetScene/ui/bg_stone_1.png")
		-- 			bg_stone_1:setPosition(cc.p(x + cube_w*x_d/2 + cube_w*y_d/2 , y - x_d*cube_h/2 + y_d*cube_h/2))
		-- 			bg_stone_1:setLocalZOrder(node_tag.kStone)
		-- 			rn:getChildByName("bg_node_6"):addChild(bg_stone_1)

		-- 			local tt = {icon = bg_stone_1, speed = stone_move}
		-- 			table.insert(self.bg_icon, tt)

		-- 			for i=1,3 do
		-- 				x_d = math.random(random_num)
		-- 				y_d = math.random(random_num)
		-- 			end

		-- 			local bg_stone_2 = cc.Sprite:createWithSpriteFrameName("PlanetScene/ui/bg_stone_2.png")
		-- 			bg_stone_2:setPosition(cc.p(x + cube_w*x_d/2 + cube_w*y_d/2 , y - x_d*cube_h/2 + y_d*cube_h/2))
		-- 			bg_stone_2:setLocalZOrder(node_tag.kStone)
		-- 			rn:getChildByName("bg_node_6"):addChild(bg_stone_2)

		-- 			local tt = {icon = bg_stone_2, speed = stone_move}
		-- 			table.insert(self.bg_icon, tt)
		-- 		end

		-- 		v.create_bg = true
		-- 	end
		-- end


	end
    local function TowerAttack(dt)
--        print("--------------------------bool",self.haveTowerNode)
        if not self.haveTowerNode or Tools.isEmpty(self.attack_time_list) then
            return
        end
        local tower_attack_time = CONF.PARAM.get("tower_attack_time").PARAM
	    local now_time = player:getServerTime()
        for k,v in ipairs(self.attack_time_list) do
            if v.state then
                if (now_time - v.time) ~= 0 and (now_time - v.time) % tower_attack_time == 0 then
				    local list = {}
				    for i,v in ipairs(self.now_see_list) do
				 	    if not Tools.isEmpty(v.node_list) then
				 		    table.insert(list,v.id)
				 	    end
				    end

				    local strData = Tools.encode("PlanetGetReq", {
                    node_id_list = list,
				 	type = 2,
				    })
                    v.isplay = true
                    g_sendList:addSend({define = "CMD_PLANET_GET_REQ", strData = strData, key = "planet_get_type_2"})
--                    print("------------------------------attacksend",v.id,now_time - v.time,tower_attack_time)
                else
--                    print("------------------------------cd,id,time",v.id,now_time - v.time)
                end
            end
        end
    end
    schedulerTower = scheduler:scheduleScriptFunc(TowerAttack, self.DRAG_UPDATE_YOUXIANJI, false)
	schedulerEntry = scheduler:scheduleScriptFunc(updateRes, self.DRAG_UPDATE_RES_INTERVAL, false)

	-- local update_bigNode = function()
	-- 	if Tools.isEmpty(self.now_see_list) == false then
	-- 		local list = {}
	-- 		for i,v in ipairs(self.now_see_list) do
	-- 			if not Tools.isEmpty(v.node_list) then
	-- 				table.insert(list,v.id)
	-- 			end
	-- 		end
	-- 		if not Tools.isEmpty(list) then
	-- 			local strData = Tools.encode("PlanetGetReq", {
	-- 				node_id_list = list,
	-- 				type = 2,
	-- 			 })
	-- 			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData)
	-- 		end
	-- 	end
	-- end
	-- schedulerEntry1 = scheduler:scheduleScriptFunc(update_bigNode, self.DRAG_UPDATE_BIGNODE_INTERVAL, false)
	self.touchMove_ = false
	self.move_fx_ = 0
	self.move_fy_ = 0
	local function onTouchesBegan(touches, event)
		for i,v in ipairs(self._pam:getArmyList()) do
			if Split(v.info.user_key, "_")[1] == player:getName() and tonumber(Split(v.info.user_key, "_")[2]) == self.see_ship then
				
				if v.ship:getChildByName("menu") then
					v.ship:getChildByName("menu"):removeFromParent()
				end

				self.canTouch = false

			end
		end

		self.see_ship = 0

		self.move_fx_ = 0
		self.move_fy_ = 0 

		self.touchMove_ = false
		return true
	end

	local function onTouchesMoved(touches, event)
		if self:isVisible() == false or self:getParent():getWorldLayer() then
			return
		else
			if not self.canTouch then
				self.canTouch = true
				return
			end
		end
		local touch = touches

		local diff = touch:getDelta()
		-- ADD WJJ 20180622
		if( self.IS_MOVE_DELTA_ADD) then
			self.move_fx_ = self.move_fx_ + diff.x
			self.move_fy_ = self.move_fy_ + diff.y
			self:_print(string.format("PlanetDiamondLayer: MOVE_DELTA_ADD   x: %s, y: %s ", tostring(self.move_fx_), tostring(self.move_fy_)) )
		else
			self.move_fx_ = diff.x
			self.move_fy_ = diff.y
		end
		self:OnDrag()
		if math.abs(diff.x) < g_click_delta and math.abs(diff.y) < g_click_delta then
			
		else
			self.touchMove_ = true
		end
		if( self.IS_DISABLE_DRAG_TOUCH) then
			self:_print("PlanetDiamondLayer:onTouchesMoved DISABLED! " )
			do return end
		end
		if self:checkMoveCan(diff) then
			self:_print(string.format("PlanetDiamondLayer:onTouchesMoved diff: %s ",tostring(diff) ) )
			if(false == self.IS_DISABLE_DRAG_TOUCH) then
				self:moveNode(diff,true)
				-- self:moveBaseLayerWJJ(diff,true)
			end
		else
			-- tips:tips("bianjie")
		end

		self:checkDistance()
		print("onTouchesMoved end")
	end

	local function onTouchesEnded(touches, event)
		local touchMove_last = self.touchMove_
		self.touchMove_ = false
		if self:isVisible() == false or self:getParent():getWorldLayer() then
			return
		else
			if not self.canTouch then
				self.canTouch = true
				return
			end
		end

		local touch = touches

		local lc = touch:getLocation()

		if not touchMove_last then

			local touchShip = false
			for i,v in ipairs(self._pam:getArmyList()) do

				if Split(v.info.user_key, "_")[1] == player:getName() then

					local ship = v.ship:getChildByName("Node_1"):getChildByName("Sprite_1")

					local ln = ship:convertToNodeSpace(lc)

					local s = ship:getContentSize()
					local rect = cc.rect(0, 0, s.width, s.height)
					
					if cc.rectContainsPoint(rect, ln) then

						if rn:getChildByName("selectNode") then
							rn:getChildByName("selectNode"):removeFromParent()
						end
						
						touchShip = true
						self.see_ship = tonumber(Split(v.info.user_key, "_")[2])

						local node = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/ShipMenu.csb")
						node:setName("menu")

						node:getChildByName("check"):getChildByName("text"):setString(CONF:getStringValue("Check"))
						node:getChildByName("check"):addClickEventListener(function ( ... )

							self.canTouch = false

							-- local dl_node = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/DefensiveLineup.csb")
							-- dl_node:getChildByName("title"):setString(CONF:getStringValue("Team information"))
							-- dl_node:getChildByName("back"):addClickEventListener(function ( ... )
							-- 	dl_node:removeFromParent()
							-- end)

							-- dl_node:getChildByName("change"):getChildByName("text"):setString(CONF:getStringValue("closed"))
							-- dl_node:getChildByName("change"):addClickEventListener(function ( ... )
							-- 	dl_node:removeFromParent()
							-- end)

							local user_info = planetManager:getPlanetUser()

							local ship_num = 0

							for i,v in ipairs(user_info.army_list) do
								if v.guid == self.see_ship then
                                    local isfind = false
									for i2,v2 in ipairs(v.lineup) do
										if v2 ~= 0 and not isfind then
											ship_num = ship_num + 1
											for i3,v3 in ipairs(v.ship_list) do
												if v2 == v3.guid then
													-- local conf = CONF.AIRSHIP.get(v3.id)
													-- local ship = dl_node:getChildByName("ship_"..ship_num)
													-- ship:getChildByName("icon"):setTexture("RoleIcon/"..conf.ICON_ID..".png")
													-- ship:getChildByName("background"):loadTexture("RankLayer/ui/ui_avatar_"..conf.QUALITY..".png")
													-- ship:getChildByName("shipType"):setTexture("ShipType/"..conf.TYPE..".png")
													-- ship:getChildByName("lvNum"):setString(v3.level)

													-- for j=v3.ship_break+1,6 do
													-- 	ship:getChildByName("star_"..j):setVisible(false)
													-- end

													-- ship:getChildByName("background"):addClickEventListener(function ( ... )
													-- 	local node = self:createInfoNode(v3)
													-- 	node:setPosition(cc.p(dl_node:getChildByName("back"):getPositionX() - node:getChildByName("landi"):getContentSize().width/2, dl_node:getChildByName("back"):getPositionY() + node:getChildByName("landi"):getContentSize().height/2))
													-- 	dl_node:addChild(node)
													-- end)
													self:getApp():addView2Top("PlanetScene/DefensiveLineupNode", {info = v3, isPlanet = false,guid = self.see_ship})
                                                    isfind = true
                                                    break

												end
											end
										end
									end
								end
							end

							-- for i=ship_num+1,5 do
							-- 	dl_node:getChildByName("ship_"..i):setVisible(false)
							-- end

							-- -- rn:addChild(dl_node, node_tag.kShipIcon)
							-- local xx,yy = getScreenDiffLocation()
							-- dl_node:setPosition(cc.p(-xx/2,-yy/2))
							-- -- dl_node:setPosition(cc.exports.VisibleRect:center())
							-- display:getRunningScene():addChild(dl_node)

							-- local function onTouchBegan(touch, event)

							-- 	return true
							-- end

							-- local function onTouchEnded(touch, event)

								
							-- end

							-- local listener = cc.EventListenerTouchOneByOne:create()
							-- listener:setSwallowTouches(true)
							-- listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
							-- listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
							-- local eventDispatcher = dl_node:getEventDispatcher()
							-- eventDispatcher:addEventListenerWithSceneGraphPriority(listener, dl_node)
						end)
 
						local element_pos = planetManager:getUserBaseElementPos()
						if v.info.move_list[2].x == element_pos.x and v.info.move_list[2].y == element_pos.y then
							node:getChildByName("back"):setVisible(false)
                            if node:getChildByName("Image2") then
							    node:getChildByName("Image2"):setVisible(false)
                            end
						end

						node:getChildByName("back"):getChildByName("text"):setString(CONF:getStringValue("back"))
						node:getChildByName("back"):addClickEventListener(function ( ... )

							local function func( ... )
								if player:getItemNumByID(17003) <= 0 then
									tips:tips(CONF:getStringValue("item not enought"))
									return
								end

								local strData = Tools.encode("PlanetRideBackReq", {
									army_guid = {self.see_ship},
									type = 2,
								 })
								g_sendList:addSend({define = "CMD_PLANET_RIDE_BACK_REQ", strData = strData, key = "army_ride_back_"..self.see_ship})
							end

							local node = require("util.TipsNode"):createWithUseNode(CONF:getStringValue("ship_base"), 17003, 1, func)
							self:addChild(node)
							tipsAction(node)

							self.canTouch = false

						end)

						node:getChildByName("speed_up"):getChildByName("text"):setString(CONF:getStringValue("expedite"))
						node:getChildByName("speed_up"):addClickEventListener(function ( ... )

							-- if player:getItemNumByID(17011) <= 0 and player:getItemNumByID(17012) <= 0 and player:getItemNumByID(17013) <= 0 then
							-- 	tips:tips(CONF:getStringValue("item not enought"))
							-- 	return
							-- end

							-- local strData = Tools.encode("PlanetSpeedUpReq", {
							-- 	army_key = player:getName().."_"..self.see_ship,
							-- 	type = 1,
							--  })
							-- g_sendList:addSend({define = "CMD_PLANET_SPEED_UP_REQ", strData = strData, key = "army_speed_up_"..self.see_ship})

							local move_num = #v.info.move_list
							local infos = planetManager:getInfoByRowCol(v.info.move_list[move_num].x, v.info.move_list[move_num].y)

							local army_info = nil
							for m,n in ipairs(planetManager:getPlanetUser().army_list) do
								if n.guid == self.see_ship then
									army_info = n
									break
								end
							end

							self:getApp():addView2Top("PlanetScene/PlanetAddSpeedLayer",{res_info = infos, army_info = army_info})

						end)

						node:getChildByName("move"):setString("("..v.info.move_list[2].x..","..v.info.move_list[2].y..")")
						node:getChildByName("move_line"):setContentSize(cc.size(node:getChildByName("move"):getContentSize().width, node:getChildByName("move_line"):getContentSize().height))

						node:getChildByName("time"):setString(CONF:getStringValue("yidong_time")..":"..formatTime((v.info.need_time - v.info.sub_time) - (player:getServerTime() - v.info.begin_time)))

						node:getChildByName("btn_move"):addClickEventListener(function ( ... )
							self.see_ship = 0

							self:moveByRowCol(v.info.move_list[2].x, v.info.move_list[2].y, v.info.node_id_list)

							node:removeFromParent()
						end)

						node:getChildByName("move"):addClickEventListener(function ( ... )
							self.see_ship = 0

							self:moveByRowCol(v.info.move_list[2].x, v.info.move_list[2].y, v.info.node_id_list)

							node:removeFromParent()
						end)

						local rota = v.ship:getRotation()
						node:setRotation(-rota)

						v.ship:addChild(node, node_tag.kShipIcon)

					end

				end
			end

			if touchShip then
				self.canTouch = false
				return
			end

			local tu_pos = cc.p(self.mid_pos.x, self.mid_pos.y) 

			local diff = cc.pSub(lc, tu_pos)
			-- print("diff",diff.x,diff.y)

			local xx,yy = getScreenDiffLocation()

			local ox = 0
			local oy = 0
			if CC_DESIGN_RESOLUTION.autoscale == "FIXED_HEIGHT" then
				ox = (winSize.width - CC_DESIGN_RESOLUTION.width) /2	
  				oy = yy/2 - math.abs((winSize.height - CC_DESIGN_RESOLUTION.height) /2)

  				print(winSize.width,CC_DESIGN_RESOLUTION.width,scaley, ox,oy)
			end
			

			local pos = cc.p(diff.x + xx/2 - ox, diff.y + yy/2 - oy)
			self:checkTouch(pos)
		else

			local tu_pos = cc.p(self.mid_pos.x - max_w/2, self.mid_pos.y) 

			local diff = cc.pSub(lc, tu_pos)
			-- print("diff",diff.x,diff.y)

			local xx,yy = getScreenDiffLocation()

			local ox = 0
			local oy = 0
			if CC_DESIGN_RESOLUTION.autoscale == "FIXED_HEIGHT" then
				ox = (winSize.width - CC_DESIGN_RESOLUTION.width) /2
				oy = yy/2 - math.abs((winSize.height - CC_DESIGN_RESOLUTION.height) /2)
			end

			local pos = cc.p(diff.x + xx/2 - ox, diff.y + yy/2 - oy)
			local pos_id = self:checkTouchBig(pos)

			local big_id = {}

			if pos_id ~= 0 then
				table.insert(big_id,pos_id)
			end


			for i,v in ipairs(screen_diff_pos) do
				local pp = cc.p(pos.x + v.x, pos.y + v.y)
				local id = self:checkTouchBig(pp)

				if id ~= 0 then
					local has = false
					for i2,v2 in ipairs(big_id) do
						if v2 == id then
							has = true
							break
						end
					end

					if not has then
						table.insert(big_id,id)
					end
				end
			end

			if not Tools.isEmpty(big_id) then
				self:changeInfo(big_id)
			end
		end

		
	end

	local listener = cc.EventListenerTouchOneByOne:create()
	-- local listener = cc.EventListenerTouchAllAtOnce:create()
	listener:setSwallowTouches(false)
	listener:registerScriptHandler(onTouchesBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	listener:registerScriptHandler(onTouchesMoved,cc.Handler.EVENT_TOUCH_MOVED )
	listener:registerScriptHandler(onTouchesEnded,cc.Handler.EVENT_TOUCH_ENDED )
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)

	-- self.three_time = player:getServerTime()
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
					self:updateInfo(proto.node_list)

					planetManager:setInfoList(proto.node_list)
                    -- TowerAttack
                    if self.haveTowerNode and not Tools.isEmpty(self.attack_time_list) then
--                        print("--------------------------receive")
                        local now_time = player:getServerTime()
                        for k,v in ipairs(self.attack_time_list) do
                            if v.state and v.isplay then
--                                print("------------------------------attackreceive",v.id,now_time - v.time)
                                v.node:getChildByName("anim_2"):setVisible(true)
                                require("util.ExWangzuoHelper"):getInstance():SetDiancita_Jiguang(v.node, "anim_",2)
                                animManager:runAnimOnceByCSB(v.node:getChildByName("anim_2"),"PlanetScene/sfx/fangyuta/fangyuta_2.csb", "2",
                                function ( ... )
				                    v.node:getChildByName("anim_2"):setVisible(false)
                                    v.isplay = false
--                                    print("--------------------------over",v.id)
									if self.haveWangzuoNode then
										for m,n in ipairs(proto.node_list) do
											for o,p in ipairs(n.element_list) do
												if p.type == 13 then
													local num = 0
													if Tools.isEmpty(p.tower_data.attack_hp) == false then
														for o1,p1 in ipairs(p.tower_data.attack_hp) do
															for o2,p2 in ipairs(p1.ship_hp_list) do
																num = num + tonumber(p2)
															end
														end
													end
													if num > 0 then
														local label = require("app.ExResInterface"):getInstance():FastLoad("BattleScene/HurtValue.csb")
														label:getChildByName("crit_sub_num"):setString("-"..tostring(num))
														animManager:runAnimOnceByCSB(label, "BattleScene/HurtValue.csb", "big_sub", function ()
															label:removeFromParent()
														end)
														self.wangzuoNode:addChild(label)
													end
												end
											end
										end
									end
			                    end)
                            end
                        end
                    end
                    --------------

					local list = {}
					for i,v in ipairs(proto.node_list) do
						print("node army_line_key_list", v.id, #v.army_line_key_list)
						for i2,v2 in ipairs(v.army_line_key_list) do
							if Tools.isEmpty(list) then
								table.insert(list,v2)
							else

								local has = false
								for i3,v3 in ipairs(list) do
									if v3 == v2 then
										has = true
										break
									end
								end

								if not has then
									table.insert(list,v2)
								end

							end
						end

					end

					print("type 2 to 4 list num", #list)

					if not Tools.isEmpty(list) then

						local strData = Tools.encode("PlanetGetReq", {
							army_line_key_list = list,
							type = 4,
						 })
						GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData)
						-- g_sendList:addSend({define = "CMD_PLANET_GET_REQ", strData = strData})
					else
						self._pam:setArmyList({})
					end

					-- 	local three_line = {
					-- 		user_key = "10002080001_1",
					-- 		move_list = {
					-- 			{x = 128, y = 80},
					-- 			{x = 118, y = 68},
					-- 			{x = 130, y = 56},
					-- 			{x = 103, y = 56},
					-- 			{x = 103, y = 40},
					-- 		},
					-- 		node_id_list = {22,24,23},
					-- 		begin_time = self.three_time,
					-- 		need_time = 30,
					-- 		sub_time = 0,

					-- 		status = 1,
					-- 		status_machine = 1,
					-- 	}

					-- self._pam:setArmyList({three_line})


				elseif proto.type == 1 then

					planetManager:setPlanetUser(proto.planet_user)

					local list = {planetManager:getPlanetUser().base_global_key}

					for i,v in ipairs(planetManager:getPlanetUser().army_list) do
						if v.status ~= 1 and v.status ~= 2 and v.status ~= 3 then
							table.insert(list, v.element_global_key)
						end
					end

					local strData = Tools.encode("PlanetGetReq", {
						element_global_key_list = list,
						type = 3,
					 })
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData)
					-- g_sendList:addSend({define = "CMD_PLANET_GET_REQ", strData = strData})

				elseif proto.type == 3 then

					planetManager:setPlanetElement(proto.element_list)

					if self.frist then
						self.frist = false
						local flag = true

						if self.data_ then
							if self.data_.move_info then
								flag = false

								self:moveByRowCol(self.data_.move_info.pos.x, self.data_.move_info.pos.y, self.data_.move_info.node_id_list)

								return
							end

							if self.data_.come_in_type then
								come_in_type = self.data_.come_in_type

								self.data_.come_in_type = nil
							end
						end

						if come_in_type == 2 then
							flag = false

							self:moveByRowCol(come_in_pos.x, come_in_pos.y, {getNodeIDByGlobalPos(come_in_pos)})

							come_in_type = 0
						end

						if flag then
							local node_id = tonumber(Split(planetManager:getPlanetUser().base_global_key, "_")[1])

							local pos = planetManager:getUserBaseElementPos()
							if pos then
								self:moveByRowCol(pos.x, pos.y, {node_id})
							end
						end
					end

					self:checkDistance()

					-- local strData = Tools.encode("PlanetGetReq", {
					-- 	node_id_list = {node_id},
					-- 	type = 2,
					--  })
					-- GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData)

				elseif proto.type == 4 then

					self._pam:setArmyList(proto.planet_army_line_list)

				elseif proto.type == 5 then

					if self.show_5 == false then
						self.show_5 = true
						return
					end


					print("shoudao 555555555555")

					print(self.choose_.m, self.choose_.n)

					-- message PlanetMailUser{
					-- 	required OtherUserInfo info = 1;
					-- 	repeated PlanetPoint pos_list = 2;
					-- 	repeated int32 ship_hp_list = 4;
					-- 	repeated AirShip ship_list = 5;
					-- };

					local info = planetManager:getInfoByRowCol(self.choose_.m, self.choose_.n)

					local english = {"a", "b", "c", "d", "e"}

					local station_amry_layer = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/otherNodeLayer/SeeStationedArmyLayer.csb")
					station_amry_layer:setName("station_amry_layer")
					station_amry_layer:getChildByName("title"):setString(CONF:getStringValue("team_browse"))
					station_amry_layer:getChildByName("close"):addClickEventListener(function ( ... )
						station_amry_layer:removeFromParent()
					end)

					local svd = require("util.ScrollViewDelegate"):create(station_amry_layer:getChildByName("list"),cc.size(0,0), cc.size(662,143))

					if info.type == 1 then

						local num = 0
						for i,v in ipairs(proto.mail_user_list) do

							local flag = true
							if v.info.user_name == info.base_data.info.user_name then
								flag = false
							end

							if flag then

								num = num + 1
								local node = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/otherNodeLayer/SeeStationedArmyNode.csb")
								node:getChildByName("army_num"):setString(CONF:getStringValue("Team "..english[num]))
								node:getChildByName("name"):setString(v.info.nickname)
								node:getChildByName("lv"):setString("Lv."..v.info.level)
								node:getChildByName("power"):setString(CONF:getStringValue("combat")..":"..v.info.power)

								node:getChildByName("lv"):setPositionX(node:getChildByName("name"):getPositionX() + node:getChildByName("name"):getContentSize().width)

								local item_pos = cc.p(node:getChildByName("item_pos"):getPosition())

								for i2,v2 in ipairs(v.ship_list) do
									local conf = CONF.AIRSHIP.get(v2.id)

									local ship_item = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/PlanetShip.csb")
									ship_item:setScale(0.9)
                                    ship_item:getChildByName("shipType"):setTexture("ShipType/"..v2.type..".png")
                                    ship_item:getChildByName("lvNum"):setString(v2.level)
                                    ship_item:getChildByName("icon"):setVisible(false)
                                    ship_item:getChildByName("icon2"):setVisible(true)
									ship_item:getChildByName("icon2"):setTexture("ShipImage/"..conf.ICON_ID..".png")
									ship_item:getChildByName("background"):loadTexture("RankLayer/ui/ui_avatar_"..conf.QUALITY..".png")

									ship_item:getChildByName("background"):addClickEventListener(function ( ... )
										local node = self:createInfoNode(v2)
										node:setPosition(cc.p(station_amry_layer:getChildByName("back"):getPositionX() - node:getChildByName("landi"):getContentSize().width/2, station_amry_layer:getChildByName("back"):getPositionY() + node:getChildByName("landi"):getContentSize().height/4 + 20))
										station_amry_layer:addChild(node)
									end)

									ship_item:setPosition(cc.p(item_pos.x + (i2-1)*80, item_pos.y))

									node:addChild(ship_item)
								end

								node:getChildByName("btn"):getChildByName("text"):setString(CONF:getStringValue("disband"))
								if info.global_key ~= planetManager:getPlanetUserBaseElementKey() then
									if v.info.user_name ~= player:getName() then
										node:getChildByName("btn"):setVisible(false)
									else
										node:getChildByName("btn"):getChildByName("text"):setString(CONF:getStringValue("huicheng"))
									end
								end

								node:getChildByName("btn"):addClickEventListener(function ( ... )
									if player:getName() == Split(info.base_data.guarde_list[i], "_")[1] then
										local strData = Tools.encode("PlanetRideBackReq", {
											army_guid = {tonumber(Split(info.base_data.guarde_list[i], "_")[2])},
											type = 2,
										 })
										g_sendList:addSend({define = "CMD_PLANET_RIDE_BACK_REQ", strData = strData, key = "army_ride_back_"..tonumber(Split(info.base_data.guarde_list[i], "_")[2])})

										station_amry_layer:removeFromParent()
									else

										local strData = Tools.encode("PlanetRaidReq", {
											type_list = {8},
											element_global_key = info.global_key,
											army_key = info.base_data.guarde_list[i],
										 })
										GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_RAID_REQ"),strData)
									end
								end)

								svd:addElement(node)
							end
						end
						if num == 0 then
							station_amry_layer:getChildByName("wenzi"):setString(CONF:getStringValue("no fleet"))
							station_amry_layer:getChildByName("wenzi"):setVisible(true)
						end
					elseif info.type == 5 then
						for i,v in ipairs(proto.mail_user_list) do

							local flag = true
							if info.global_key == planetManager:getPlanetUserBaseElementKey() and v.info.user_name == player:getName() then
								flag = false
							end

							if flag then
								local node = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/otherNodeLayer/SeeStationedArmyNode.csb")
								node:getChildByName("army_num"):setString(CONF:getStringValue("Team "..english[i]))
								node:getChildByName("name"):setString(v.info.nickname)
								node:getChildByName("lv"):setString("Lv."..v.info.level)
								node:getChildByName("power"):setString(CONF:getStringValue("combat")..":"..v.info.power)

								node:getChildByName("lv"):setPositionX(node:getChildByName("name"):getPositionX() + node:getChildByName("name"):getContentSize().width + 10)
								node:getChildByName("power"):setPositionX(node:getChildByName("lv"):getPositionX() + node:getChildByName("lv"):getContentSize().width + 30)

								local item_pos = cc.p(node:getChildByName("item_pos"):getPosition())

								for i2,v2 in ipairs(v.ship_list) do
									local conf = CONF.AIRSHIP.get(v2.id)

									local ship_item = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/PlanetShip.csb")
									ship_item:setScale(0.9)
                                    ship_item:getChildByName("shipType"):setTexture("ShipType/"..v2.type..".png")
                                    ship_item:getChildByName("lvNum"):setString(v2.level)
                                    ship_item:getChildByName("icon"):setVisible(false)
                                    ship_item:getChildByName("icon2"):setVisible(true)
									ship_item:getChildByName("icon2"):setTexture("ShipImage/"..conf.ICON_ID..".png")
									ship_item:getChildByName("background"):loadTexture("RankLayer/ui/ui_avatar_"..conf.QUALITY..".png")


									ship_item:getChildByName("icon2"):addClickEventListener(function ( ... )
										local node = self:createInfoNode(v2)
										node:setPosition(cc.p(station_amry_layer:getChildByName("back"):getPositionX() - node:getChildByName("landi"):getContentSize().width/2, station_amry_layer:getChildByName("back"):getPositionY() + node:getChildByName("landi"):getContentSize().height/4 + 20))
										station_amry_layer:addChild(node)
									end)

									ship_item:setPosition(cc.p(item_pos.x + (i2-1)*80, item_pos.y))

									node:addChild(ship_item)
								end

								node:getChildByName("btn"):getChildByName("text"):setString(CONF:getStringValue("disband"))
								if player:getGroupData().job == 3 then
									if v.info.user_name ~= player:getName() then
										node:getChildByName("btn"):setVisible(false)
									else
										node:getChildByName("btn"):getChildByName("text"):setString(CONF:getStringValue("huicheng"))
									end
								end

								node:getChildByName("btn"):addClickEventListener(function ( ... )

									if player:getName() == Split(info.city_data.guarde_list[i], "_")[1] then
										local strData = Tools.encode("PlanetRideBackReq", {
											army_guid = {tonumber(Split(info.city_data.guarde_list[i], "_")[2])},
											type = 2,
										 })
										g_sendList:addSend({define = "CMD_PLANET_RIDE_BACK_REQ", strData = strData, key = "army_ride_back_"..tonumber(Split(info.city_data.guarde_list[i], "_")[2])})

										station_amry_layer:removeFromParent()
									else

										local strData = Tools.encode("PlanetRaidReq", {
											type_list = {8},
											element_global_key = info.global_key,
											army_key = info.city_data.guarde_list[i],
										 })
										GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_RAID_REQ"),strData)
									end
								end)

								svd:addElement(node)
							end
						end
					end

					local function onTouchBegan(touch, event)

						return true
					end

					local function onTouchEnded(touch, event)

						
					end

					local listener = cc.EventListenerTouchOneByOne:create()
					listener:setSwallowTouches(true)
					listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
					listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
					local eventDispatcher = station_amry_layer:getEventDispatcher()
					eventDispatcher:addEventListenerWithSceneGraphPriority(listener, station_amry_layer)

					local xx,yy = getScreenDiffLocation()
					station_amry_layer:setPosition(cc.p(-xx/2,-yy/2))
                    -- station_amry_layer:setPosition(cc.exports.VisibleRect:leftBottom())
					display:getRunningScene():addChild(station_amry_layer)
                    -- rn:addChild(station_amry_layer)
					-- self:addChild(station_amry_layer, node_tag.kChoose)
				end

			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_UPDATE_TIMESTAMP_RESP") then

			local proto = Tools.decode("UpdateTimeStampResp",strData)

			if proto.result == 0 then
				self._pam:setTime(player:getServerTime())
			end
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_PLANET_RIDE_BACK_RESP") then

			local proto = Tools.decode("PlanetRideBackResp",strData)

			if proto.result == "OK" then
				local event = cc.EventCustom:new("UserBaseUpdated")
				cc.Director:getInstance():getEventDispatcher():dispatchEvent(event) 
			end
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_PLANET_SPEED_UP_RESP") then

			local proto = Tools.decode("PlanetSpeedUpResp",strData)
			print("PlanetSpeedUpResp", proto.result)

			if proto.result == 0 then

				-- self._pam:setTime(player:getServerTime())

				-- local list = {}
				-- for i,v in ipairs(self.now_see_list) do
				-- 	if not Tools.isEmpty(v.node_list) then
				-- 		table.insert(list,v.id)
				-- 	end
				-- end

				-- local strData = Tools.encode("PlanetGetReq", {
				-- 	type = 1,
				--  })
				-- GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData)

				local user_info = planetManager:getPlanetUser()

				for i,v in ipairs(user_info.army_list) do
					if v.guid == self.see_ship then

						planetManager:setPlanetUserArmy(i, proto.army)
						self._pam:setArmyByUserKey(proto.army.line.user_key, proto.army.line) 
						cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("updatePlanetUser")

						break
					end
				end

			elseif proto.result == 1 then
				tips:tips(CONF:getStringValue("item not enought"))
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_PLANET_MOVE_BASE_RESP") then
			local proto = Tools.decode("PlanetMoveBaseResp",strData)

			print('PlanetMoveBaseResp result',proto.result)

			if proto.result == "OK" then

				print("cccccccccccc",self.choose_.m, self.choose_.n)

				local texiao = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/sfx/kongjainzhanqianyi/qianyi.csb")
				texiao:setPosition(self:getPosByCoordinate(self.choose_.m, self.choose_.n))
				rn:addChild(texiao, node_tag.kChoose)

				animManager:runAnimOnceByCSB(texiao, "PlanetScene/sfx/kongjainzhanqianyi/qianyi.csb", "1", function ( ... )
					local list = {}
					for i,v in ipairs(self.now_see_list) do
						if not Tools.isEmpty(v.node_list) then
							table.insert(list,v.id)
						end
					end
					if not Tools.isEmpty(list) then
						local strData = Tools.encode("PlanetGetReq", {
							node_id_list = list,
							type = 2,
						 })
						-- GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData)
						g_sendList:addSend({define = "CMD_PLANET_GET_REQ", strData = strData, key = "planet_get_type_2"})

					end

					local strData = Tools.encode("PlanetGetReq", {
						type = 1,
					 })
					-- GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData)
					g_sendList:addSend({define = "CMD_PLANET_GET_REQ", strData = strData, key = "planet_get_type_1"})

					self.frist = false

				end)
				if checkNodeIDByGlobalPos(cc.p(self.choose_.m, self.choose_.n)) then
					self:moveByRowCol(self.choose_.m, self.choose_.n, {getNodeIDByGlobalPos(cc.p(self.choose_.m, self.choose_.n))})

					if rn:getChildByName("selectNode") then
						rn:getChildByName("selectNode"):removeFromParent()
					end
				end
				
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_PLANET_RAID_RESP") then

			-- gl:releaseLoading()

			local proto = Tools.decode("PlanetRaidResp",strData)
			print('PlanetRaidResp..',proto.result)
			if proto.result == 'OK' then
				local event = cc.EventCustom:new("nodeUpdated")
				-- event.node_id_list = {tonumber(Tools.split(self.data_.element_global_key, "_")[1])}
				event.node_id_list = {}
				cc.Director:getInstance():getEventDispatcher():dispatchEvent(event) 

				planetManager:setPlanetUser(proto.planet_user)

				local list = {proto.planet_user.base_global_key}

				for i,v in ipairs(proto.planet_user.army_list) do
					table.insert(list, v.element_global_key)
				end


				local strData = Tools.encode("PlanetGetReq", {
					element_global_key_list = list,
					type = 3,
				 })
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData)
				
				-- self:getApp():removeTopView()

				if display:getRunningScene():getChildByName("station_amry_layer") then

					-- print(" raid    jinlai")

					display:getRunningScene():getChildByName("station_amry_layer"):removeFromParent()

					-- local info = planetManager:getInfoByRowCol(self.choose_.m, self.choose_.n)
					-- if Tools.isEmpty(info.base_data.guarde_list) then
					-- 	-- tips:tips("no duiwu")
					-- else
					-- 	local strData = Tools.encode("PlanetGetReq", {
					-- 			army_key_list = info.base_data.guarde_list,
					-- 			type = 5,
					-- 		 })
					-- 	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData) 
					-- end
				end


			end

		-- elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_GROUP_RESP") then

		-- 	local proto = Tools.decode("GetGroupResp",strData)

		-- 	if proto.result == 0 then
		-- 		self:resetCityNodeInfo(proto.other_group_info)
		-- 		planetManager:setGroupInfo(proto.other_group_info)
  --       	end
 		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_PLANET_TOWER_RESP") then
 			local proto = Tools.decode("PlanetTowerResp",strData)
 			print("PlanetTowerResp result",proto.result)
 			if proto.result == 0 then
	 			for i,v in ipairs(planetManager:getInfoList()) do
					if v.info then
						for i2,v2 in ipairs(v.info) do
							if rn:getChildByName("node2_"..v2.pos_list[1].x.."_"..v2.pos_list[1].y) then
								local node_2 = rn:getChildByName("node2_"..v2.pos_list[1].x.."_"..v2.pos_list[1].y)
								if v2.type == 13 and Tools.isEmpty(proto.element) == false then
									if v2.global_key == proto.element.global_key then
										v.info[i2] = proto.element
									end
								end
								self:resetNode2Info(node_2, v2)
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
	local rn = self:getResourceNode()
	self.planetSelectListener_ = cc.EventListenerCustom:create("PlanetMenuOpen", function (event)
		if rn:getChildByName('selectNode') ~= nil then
			rn:getChildByName('selectNode'):removeFromParent()

			if rn:getChildByName("node2_"..self.choose_.m.."_"..self.choose_.n) then
				rn:getChildByName("node2_"..self.choose_.m.."_"..self.choose_.n):setVisible(false)
			end
		end		
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.planetSelectListener_, FixedPriority.kNormal)

	self.updateSelectListener_ = cc.EventListenerCustom:create("PlanetUpdateSelect", function (event)

		local m = self.choose_.m
		local n = self.choose_.n

		local info = planetManager:getInfoByRowCol(m,n)
		if rn:getChildByName('selectNode') ~= nil then
			rn:getChildByName('selectNode'):removeFromParent()

			if rn:getChildByName("node2_"..self.choose_.m.."_"..self.choose_.n) then
				rn:getChildByName("node2_"..self.choose_.m.."_"..self.choose_.n):setVisible(true)
			end
		else
			return
		end

		-- local pos = self:getPosByCoordinate(m,n)
		-- if self:checkTouchBig(cc.p(pos.x + max_w/2, pos.y)) == 0 then
		-- 	return
		-- end 

		-- if info ~= nil then
		-- 	if rn:getChildByName("node2_"..m..n) then
		-- 		rn:getChildByName("node2_"..m..n):setVisible(false)

		-- 		self.choose_.m = m
		-- 		self.choose_.n = n
		-- 	end
		-- end

		-- if info == nil then

		-- 	local data = {bool = true, info = {pos = {m,n}}}

		-- 	local node =require("app.views.PlanetScene.PlanetSelectNode"):setPlanetSelectNode(data , rn)
		-- 	node:setPosition(self:getPosByCoordinate(m,n))
		-- 	node:setLocalZOrder(node_tag.kChoose)
		-- 	node:setName("selectNode")
		-- 	rn:addChild(node)

		-- else
		-- 	local list = Split(info.global_key, "_")

		-- 	local node_id = tonumber(list[1])
		-- 	local guid = tonumber(list[2])

		-- 	print("getInfoByNodeGUID", node_id, guid, planetManager:getInfoByNodeGUID(node_id, guid))
		-- 	local data = {bool = false, info = {guid = guid, node_id = node_id}}

		-- 	local node =require("app.views.PlanetScene.PlanetSelectNode"):setPlanetSelectNode(data , rn)
		-- 	node:setPosition(self:getPosByCoordinate(m,n))
		-- 	node:setLocalZOrder(node_tag.kChoose)
		-- 	node:setName("selectNode")
		-- 	rn:addChild(node)

		-- end
		-- cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("PlanetSelectNodeOpen")
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.updateSelectListener_, FixedPriority.kNormal)

	self.armyListener_ = cc.EventListenerCustom:create("nodeUpdated", function (event)

		local list = {}
		for i,v in ipairs(self.now_see_list) do
			if not Tools.isEmpty(v.node_list) then
				table.insert(list,v.id)
			end
		end

		if not Tools.isEmpty(list) then
			local strData = Tools.encode("PlanetGetReq", {
				node_id_list = list,
				type = 2,
			 })
			-- GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData)
			g_sendList:addSend({define = "CMD_PLANET_GET_REQ", strData = strData, key = "planet_get_type_2",node_list = list})

		end

		-- self._pam:setIsSend(true)
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.armyListener_, FixedPriority.kNormal)

	self.baseListener_ = cc.EventListenerCustom:create("UserBaseUpdated", function ()
		local strData = Tools.encode("PlanetGetReq", {
			type = 1,
		 })
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData)
		-- g_sendList:addSend({define = "CMD_PLANET_GET_REQ", strData = strData, key = "planet_get_type_1"})

		-- self._pam:setIsSend(true)
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.baseListener_, FixedPriority.kNormal)

	self.seeShipListener_ = cc.EventListenerCustom:create("seeShipUpdated", function (event)

		print("seeShipUpdated", event.guid)

		if self.see_ship ~= 0 then
			for i,v in ipairs(self._pam:getArmyList()) do

				if Split(v.info.user_key, "_")[1] == player:getName() and tonumber(Split(v.info.user_key, "_")[2]) == self.see_ship then
					if v.ship and v.ship:getChildByName("menu") then
						v.ship:getChildByName("menu"):removeFromParent()
					end
					break
				end

			end
		end

		if event.guid then
			self.see_ship = event.guid
		end

		for i,v in ipairs(self._pam:getArmyList()) do

			if Split(v.info.user_key, "_")[1] == player:getName() and tonumber(Split(v.info.user_key, "_")[2]) == self.see_ship then

				if rn:getChildByName("selectNode") then
					rn:getChildByName("selectNode"):removeFromParent()
				end

				if v.ship:getChildByName("menu") then
					v.ship:getChildByName("menu"):removeFromParent()
				end

				local node = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/ShipMenu.csb")
				node:setName("menu")

				node:getChildByName("check"):getChildByName("text"):setString(CONF:getStringValue("Check"))
				node:getChildByName("check"):addClickEventListener(function ( ... )

					self.canTouch = false

					-- local dl_node = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/DefensiveLineup.csb")
					-- dl_node:getChildByName("title"):setString(CONF:getStringValue("Team information"))
					-- dl_node:getChildByName("back"):addClickEventListener(function ( ... )
					-- 	dl_node:removeFromParent()
					-- end)

					-- dl_node:getChildByName("change"):getChildByName("text"):setString(CONF:getStringValue("closed"))
					-- dl_node:getChildByName("change"):addClickEventListener(function ( ... )
					-- 	dl_node:removeFromParent()
					-- end)

					local user_info = planetManager:getPlanetUser()

					local ship_num = 0

					for i,v in ipairs(user_info.army_list) do
						if v.guid == self.see_ship then
                            local isfind = false
							for i2,v2 in ipairs(v.lineup) do
								if v2 ~= 0 and not isfind then
									ship_num = ship_num + 1
									for i3,v3 in ipairs(v.ship_list) do
										if v2 == v3.guid then
											-- local conf = CONF.AIRSHIP.get(v3.id)
											-- local ship = dl_node:getChildByName("ship_"..ship_num)
											-- ship:getChildByName("icon"):setTexture("RoleIcon/"..conf.ICON_ID..".png")
											-- ship:getChildByName("background"):loadTexture("RankLayer/ui/ui_avatar_"..conf.QUALITY..".png")
											-- ship:getChildByName("shipType"):setTexture("ShipType/"..conf.TYPE..".png")
											-- ship:getChildByName("lvNum"):setString(v3.level)

											-- for j=v3.ship_break+1,6 do
											-- 	ship:getChildByName("star_"..j):setVisible(false)
											-- end

											-- ship:getChildByName("background"):addClickEventListener(function ( ... )
											-- 	local node = self:createInfoNode(v3)
											-- 	node:setPosition(cc.p(dl_node:getChildByName("back"):getPositionX() - node:getChildByName("landi"):getContentSize().width/2, dl_node:getChildByName("back"):getPositionY() + node:getChildByName("landi"):getContentSize().height/2))
											-- 	dl_node:addChild(node)
											-- end)
											self:getApp():addView2Top("PlanetScene/DefensiveLineupNode", {info = v3, isPlanet = false,guid = self.see_ship})
                                            isfind = true
                                            break
										end
									end
								end
							end
						end
					end

					-- for i=ship_num+1,5 do
					-- 	dl_node:getChildByName("ship_"..i):setVisible(false)
					-- end

					-- -- rn:addChild(dl_node, node_tag.kShipIcon)
					-- local xx,yy = getScreenDiffLocation()
					-- dl_node:setPosition(cc.p(-xx/2,-yy/2))
					-- display:getRunningScene():addChild(dl_node)

					-- local function onTouchBegan(touch, event)

					-- 	return true
					-- end

					-- local function onTouchEnded(touch, event)

						
					-- end

					-- local listener = cc.EventListenerTouchOneByOne:create()
					-- listener:setSwallowTouches(true)
					-- listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
					-- listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
					-- local eventDispatcher = dl_node:getEventDispatcher()
					-- eventDispatcher:addEventListenerWithSceneGraphPriority(listener, dl_node)
				end)

				local element_pos = planetManager:getUserBaseElementPos()
				local move_num = #v.info.move_list
				if v.info.move_list[move_num].x == element_pos.x and v.info.move_list[move_num].y == element_pos.y then
					node:getChildByName("back"):setVisible(false)
					if node:getChildByName("Image2") then
						node:getChildByName("Image2"):setVisible(false)
					end
				end

				node:getChildByName("back"):getChildByName("text"):setString(CONF:getStringValue("back"))
				node:getChildByName("back"):addClickEventListener(function ( ... )
					local function func( ... )
						if player:getItemNumByID(17003) <= 0 then
							tips:tips(CONF:getStringValue("item not enought"))
							return
						end

						local strData = Tools.encode("PlanetRideBackReq", {
							army_guid = {self.see_ship},
							type = 2,
						 })
						g_sendList:addSend({define = "CMD_PLANET_RIDE_BACK_REQ", strData = strData, key = "army_ride_back_"..self.see_ship})
					end

					local node = require("util.TipsNode"):createWithUseNode(CONF:getStringValue("ship_base"), 17003, 1, func)
					self:addChild(node)
					tipsAction(node)

					self.canTouch = false
				end)

				node:getChildByName("speed_up"):getChildByName("text"):setString(CONF:getStringValue("expedite"))
				node:getChildByName("speed_up"):addClickEventListener(function ( ... )

					-- if player:getItemNumByID(17011) <= 0 and player:getItemNumByID(17012) <= 0 and player:getItemNumByID(17013) <= 0 then
					-- 	tips:tips(CONF:getStringValue("item not enought"))
					-- 	return
					-- end

					-- local strData = Tools.encode("PlanetSpeedUpReq", {
					-- 	army_key = player:getName().."_"..self.see_ship,
					-- 	type = 1,
					--  })
					-- g_sendList:addSend({define = "CMD_PLANET_SPEED_UP_REQ", strData = strData, key = "army_speed_up_"..self.see_ship})

					local move_num = #v.info.move_list
					local infos = planetManager:getInfoByRowCol(v.info.move_list[move_num].x, v.info.move_list[move_num].y)

					local army_info = nil
					for m,n in ipairs(planetManager:getPlanetUser().army_list) do
						if n.guid == self.see_ship then
							army_info = n
							break
						end
					end

					self:getApp():addView2Top("PlanetScene/PlanetAddSpeedLayer",{res_info = infos, army_info = army_info})

				end)

				node:getChildByName("move"):setString("("..v.info.move_list[2].x..","..v.info.move_list[2].y..")")
				node:getChildByName("move_line"):setContentSize(cc.size(node:getChildByName("move"):getContentSize().width, node:getChildByName("move_line"):getContentSize().height))


				node:getChildByName("time"):setString(CONF:getStringValue("yidong_time")..":"..formatTime((v.info.need_time - v.info.sub_time) - (player:getServerTime() - v.info.begin_time)))

				node:getChildByName("btn_move"):addClickEventListener(function ( ... )
					self.see_ship = 0

					self:moveByRowCol(v.info.move_list[2].x, v.info.move_list[2].y, v.info.node_id_list)

					node:removeFromParent()
				end)

				node:getChildByName("move"):addClickEventListener(function ( ... )
					self.see_ship = 0

					self:moveByRowCol(v.info.move_list[2].x, v.info.move_list[2].y, v.info.node_id_list)

					node:removeFromParent()
				end)

				local rota = v.ship:getRotation()
				node:setRotation(-rota)

				print("v.ship add")
				v.ship:addChild(node, node_tag.kShipIcon)

				break
			end

		end
		
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.seeShipListener_, FixedPriority.kNormal)

	self.canTouchListener_ = cc.EventListenerCustom:create("resetCanTouch", function (event)
		self.canTouch = false

		if rn:getChildByName('selectNode') ~= nil then
			rn:getChildByName('selectNode'):removeFromParent()

			if rn:getChildByName("node2_"..self.choose_.m.."_"..self.choose_.n) then
				rn:getChildByName("node2_"..self.choose_.m.."_"..self.choose_.n):setVisible(true)
			end

			return
		end
		
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.canTouchListener_, FixedPriority.kNormal)

	self.show5Listener_ = cc.EventListenerCustom:create("resetShow5", function (event)
		self.show_5 = false

		
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.show5Listener_, FixedPriority.kNormal)

	self.moveToUserResListener_ = cc.EventListenerCustom:create("moveToUserRes", function (event)
		local pos = event.pos

		if checkNodeIDByGlobalPos(pos) then
			self:moveByRowCol(pos.x, pos.y, {getNodeIDByGlobalPos(pos)})

			if rn:getChildByName("selectNode") then
				rn:getChildByName("selectNode"):removeFromParent()
			end

--			self:createSelectNode(pos.x, pos.y)
		end
		
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.moveToUserResListener_, FixedPriority.kNormal)

	self.updateListener_ = cc.EventListenerCustom:create("newPlanetMsg", function (event)
		local node_id_list = event.node_id_list

		local flag = false
		for i,v in ipairs(self.now_see_list) do
			for i2,v2 in ipairs(node_id_list) do
				if v.id == v2 then
					flag = true
					break
				end
			end
		end

		if flag then
			local list = {}
			for i,v in ipairs(self.now_see_list) do
				if not Tools.isEmpty(v.node_list) then
					table.insert(list,v.id)
				end
			end

			if not Tools.isEmpty(list) then
				local strData = Tools.encode("PlanetGetReq", {
					node_id_list = list,
					type = 2,
				 })
				-- GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData)
				g_sendList:addSend({define = "CMD_PLANET_GET_REQ", strData = strData, key = "planet_get_type_2"})

			end
		end
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.updateListener_, FixedPriority.kNormal)

	self.groupListener_ = cc.EventListenerCustom:create("group_main", function (event)

		local list = {}
		for i,v in ipairs(self.now_see_list) do
			if not Tools.isEmpty(v.node_list) then
				table.insert(list,v.id)
			end
		end

		if not Tools.isEmpty(list) then
			local strData = Tools.encode("PlanetGetReq", {
				node_id_list = list,
				type = 2,
			 })
			-- GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData)
			g_sendList:addSend({define = "CMD_PLANET_GET_REQ", strData = strData, key = "planet_get_type_2"})

		end
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.groupListener_, FixedPriority.kNormal)

	self.resetChooseListener_ = cc.EventListenerCustom:create("resetChoose", function (event)
		if self.choose_.m ~= initM or self.choose_.n ~= initN then
			return
		end

		self.choose_.m = event.m 
		self.choose_.n = event.n

		-- local texiao = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/sfx/kongjainzhanqianyi/qianyi.csb")
		-- texiao:setPosition(self:getPosByCoordinate(planetManager:getUserBaseElementPos().x, planetManager:getUserBaseElementPos().y))
		-- rn:addChild(texiao, node_tag.kChoose)

		-- animManager:runAnimOnceByCSB(texiao, "PlanetScene/sfx/kongjainzhanqianyi/qianyi.csb", "1", function ( ... )

			
			local strData = Tools.encode("PlanetMoveBaseReq", {
					type = 1,
					pos = {x=self.choose_.m,y=self.choose_.n},
				 })
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_MOVE_BASE_REQ"),strData) 

		-- end)
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.resetChooseListener_, FixedPriority.kNormal)

	self.moveToJinResListener_ = cc.EventListenerCustom:create("moveToJinRes", function (event)

		self:moveToJinResNode()
		
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.moveToJinResListener_, FixedPriority.kNormal)

	self.moveToJinCityListener_ = cc.EventListenerCustom:create("moveToJinCity", function (event)

		self:moveToJinCityNode()
		
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.moveToJinCityListener_, FixedPriority.kNormal)

	self.changeCTListener_ = cc.EventListenerCustom:create("changeCT", function (event)

		come_in_type = 2

		local m,n = self:getMidPos()
		come_in_pos.x = m 
		come_in_pos.y = n
		
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.changeCTListener_, FixedPriority.kNormal)


	-- self:OnInit()
end
-- FUCK, this is end of onEnterTransitionFinish, WJJ

function PlanetDiamondLayer:getBigNode()
	local tu_pos = cc.p(self.mid_pos.x - max_w/2, self.mid_pos.y)
	local winSize = cc.Director:getInstance():getWinSize()
	local lc = {x = winSize.width/2,y = winSize.height/2}
	local diff = cc.pSub(lc, tu_pos)
	-- print("diff",diff.x,diff.y)

	local xx,yy = getScreenDiffLocation()

	local ox = 0
	local oy = 0
	if CC_DESIGN_RESOLUTION.autoscale == "FIXED_HEIGHT" then
		ox = (winSize.width - CC_DESIGN_RESOLUTION.width) /2
		oy = yy/2 - math.abs((winSize.height - CC_DESIGN_RESOLUTION.height) /2)
	end

	local pos = cc.p(diff.x + xx/2 - ox, diff.y + yy/2 - oy)
	local pos_id = self:checkTouchBig(pos)

	local big_id = {}

	if pos_id ~= 0 then
		table.insert(big_id,pos_id)
	end


	for i,v in ipairs(screen_diff_pos) do
		local pp = cc.p(pos.x + v.x, pos.y + v.y)
		local id = self:checkTouchBig(pp)

		if id ~= 0 then
			local has = false
			for i2,v2 in ipairs(big_id) do
				if v2 == id then
					has = true
					break
				end
			end

			if not has then
				table.insert(big_id,id)
			end
		end
	end

	if not Tools.isEmpty(big_id) then
		self:changeInfo(big_id)
	end
end

function PlanetDiamondLayer:onExitTransitionStart()

	printInfo("PlanetDiamondLayer:onExitTransitionStart()")

	self._pam:clearArmyList()

	if self.data_ then
		self.data_ = nil
	end

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
	eventDispatcher:removeEventListener(self.armyListener_)
	eventDispatcher:removeEventListener(self.baseListener_)
	eventDispatcher:removeEventListener(self.seeShipListener_)
	eventDispatcher:removeEventListener(self.planetSelectListener_)
	eventDispatcher:removeEventListener(self.updateSelectListener_)
	eventDispatcher:removeEventListener(self.canTouchListener_)
	eventDispatcher:removeEventListener(self.moveToUserResListener_)
	eventDispatcher:removeEventListener(self.updateListener_)
	eventDispatcher:removeEventListener(self.show5Listener_)
	eventDispatcher:removeEventListener(self.groupListener_)
	eventDispatcher:removeEventListener(self.resetChooseListener_)
	eventDispatcher:removeEventListener(self.moveToJinResListener_)
	eventDispatcher:removeEventListener(self.moveToJinCityListener_)
	eventDispatcher:removeEventListener(self.changeCTListener_)

	if schedulerEntry ~= nil then
		scheduler:unscheduleScriptEntry(schedulerEntry)
	end
	if schedulerEntry1 ~= nil then
		scheduler:unscheduleScriptEntry(schedulerEntry1)
	end

    if schedulerTower ~= nil then
		scheduler:unscheduleScriptEntry(schedulerTower)
	end

	if self.svd_ then
		self.svd_:clear()
	end
end

------------------------------------------------------------------------

function PlanetDiamondLayer:TryShootOnceByTimer(tower_data, creatEffect, node_1)
	local is_time_shoot = require("util.ExWangzuoHelper"):getInstance():Diancita_IsTimeShoot( tower_data.occupy_begin_time, tower_data.is_attack )
	if( is_time_shoot ) then
	        creatEffect(2, true)
		require("util.ExWangzuoHelper"):getInstance():SetDiancita_Jiguang(node_1, "anim_",2)
	end
end

function PlanetDiamondLayer:OnSchedulerUpdate()
	print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
	print("TODO dian ci ta    shoot once check time ")
	print(tostring(os.time()))
	print("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
	

	
	-- local tower_data = info.tower_data
	-- local is_time_shoot = require("util.ExWangzuoHelper"):getInstance():Diancita_IsTimeShoot( tower_data.occupy_begin_time, tower_data.is_attack )
end

------------------------------------------------------------------------

-- ADD WJJ 20180813
cc.exports.G_INSTANCE_PlanetDiamondLayer = PlanetDiamondLayer

return PlanetDiamondLayer