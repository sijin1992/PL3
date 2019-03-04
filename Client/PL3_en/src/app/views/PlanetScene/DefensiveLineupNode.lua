
local app = require("app.MyApp"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local player = require("app.Player"):getInstance()

local messageBox = require("util.MessageBox"):getInstance()

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local planetManager = require('app.views.PlanetScene.Manager.PlanetManager'):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local DefensiveLineupNode = class("DefensiveLineupNode", cc.load("mvc").ViewBase)

DefensiveLineupNode.RESOURCE_FILENAME = "PlanetScene/DefensiveLineup.csb"

DefensiveLineupNode.RUN_TIMELINE = true

DefensiveLineupNode.NEED_ADJUST_POSITION = true

DefensiveLineupNode.RESOURCE_BINDING = {
	--["Button_1"]   = {["varname"] = "btn"},
}

local schedulerEntry = nil

function DefensiveLineupNode:onEnter()
  
	printInfo("DefensiveLineupNode:onEnter()")

end

function DefensiveLineupNode:onExit()
	
	printInfo("DefensiveLineupNode:onExit()")
end

function DefensiveLineupNode:onCreate( data )
	self.data = data
end

function DefensiveLineupNode:createInfoNode(ship_info)

	print(" DefensiveLineupNode:createInfoNode")

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
	        local weapon = player:getWeaponByGUID(v)
	        if weapon then
		        local weapon_conf = CONF.WEAPON.get(weapon.weapon_id)
		        node:getChildByName("weapon_icon_"..i):loadTexture("WeaponIcon/"..weapon_conf.ICON_ID..".png")
		        node:getChildByName("weapon_name_"..i):setString(CONF:getStringValue(weapon_conf.NAME_ID))
		        node:getChildByName("weapon_lv_num_"..i):setString(weapon_conf.LEVEL)

		        node:getChildByName("weapon_lv_"..i):setPositionX(node:getChildByName("weapon_name_"..i):getPositionX() + node:getChildByName("weapon_name_"..i):getContentSize().width + 10)
		        node:getChildByName("weapon_lv_num_"..i):setPositionX(node:getChildByName("weapon_lv_"..i):getPositionX() + node:getChildByName("weapon_lv_"..i):getContentSize().width )
		    end
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

    for i=ship_info.ship_break+1,6 do
        -- rn:getChildByName("star_"..i):setTexture("LevelScene/ui/star_outline.png")
        -- rn:getChildByName("star_"..i):setScale(1)
        rn:getChildByName("star_"..i):removeFromParent()
    end

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

function DefensiveLineupNode:onEnterTransitionFinish()
	printInfo("DefensiveLineupNode:onEnterTransitionFinish()")

	local rn = self:getResourceNode()

	rn:getChildByName("back"):addClickEventListener(function ( ... )
		app:removeTopView()
	end)

	local info 
	if self.data.isPlanet then
		info = planetManager:getInfoByNodeGUID( self.data.info.info.node_id, self.data.info.info.guid )
	else
		info = self.data.info
	end

	local has = false
	local army_guid = nil
	if self.data.guid then
		army_guid = self.data.guid
		has = true
	elseif info then
		for i,v in ipairs(info.base_data.guarde_list) do
			if Split(v,"_")[1] == player:getName() then
				has = true
				army_guid = tonumber(Split(v,"_")[2])
				break
			end
		end

	end
	if not has then

		rn:getChildByName("change"):getChildByName("text"):setString(CONF:getStringValue("up_lineup"))

		for i=1,5 do
			rn:getChildByName("ship_"..i):setVisible(false)
			rn:getChildByName("text"):setVisible(true)
		end

		rn:getChildByName("change"):addClickEventListener(function ( ... )

			if guideManager:getGuideType() then
				app:removeTopView()
			end

			app:removeTopView()
			app:addView2Top("NewFormLayer", {from="defensiveLineup", element_global_key = info.global_key, type = 1})
		end)

	else

		rn:getChildByName("change"):getChildByName("text"):setString(CONF:getStringValue("down_lineup"))

		local user_info
		if self.data.isPlanet then
			user_info = planetManager:getPlanetUser()
		else
			user_info = player:getPlayerPlanetUser()
		end

		local ship_num = 0

		for i,v in ipairs(user_info.army_list) do
			if v.guid == army_guid then
				for i2,v2 in ipairs(v.lineup) do
					if v2 ~= 0 then
						ship_num = ship_num + 1
						for i3,v3 in ipairs(v.ship_list) do
							if v2 == v3.guid then
								local conf = CONF.AIRSHIP.get(v3.id)
								local ship = rn:getChildByName("ship_"..ship_num)
                                ship:getChildByName("icon"):setVisible(false)
--                                ship:getChildByName("icon"):setTexture("RoleIcon/"..conf.ICON_ID..".png")
                                ship:getChildByName("icon2"):setVisible(true)
                                ship:getChildByName("icon2"):setTexture("ShipImage/"..conf.DRIVER_ID..".png")
								ship:getChildByName("background"):loadTexture("RankLayer/ui/ui_avatar_"..conf.QUALITY..".png")
								ship:getChildByName("shipType"):setTexture("ShipType/"..conf.TYPE..".png")
								ship:getChildByName("lvNum"):setString(v3.level)

								for j=v3.ship_break+1,6 do
									ship:getChildByName("star_"..j):setVisible(false)
								end

								ship:getChildByName("background"):addClickEventListener(function ( ... )
									local node = self:createInfoNode(v3)
									node:setPosition(cc.p(rn:getChildByName("back"):getPositionX() - node:getChildByName("landi"):getContentSize().width/2, rn:getChildByName("back"):getPositionY() + node:getChildByName("landi"):getContentSize().height/2))
									rn:addChild(node)
								end)

							end
						end
					end
				end
			end
		end

		for i=ship_num+1,5 do
			rn:getChildByName("ship_"..i):setVisible(false)
		end

		rn:getChildByName("change"):addClickEventListener(function ( ... )

			local strData = Tools.encode("PlanetRideBackReq", {
				army_guid = {army_guid},
				type = 2,
			 })
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_RIDE_BACK_REQ"),strData) 
			
		end)
	end
	if self.data.guid then
		rn:getChildByName("change"):getChildByName("text"):setString(CONF:getStringValue("closed"))
		rn:getChildByName("change"):addClickEventListener(function ( ... )
			app:removeTopView()
		end)
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
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)

	local function recvMsg()
		printInfo("DefensiveLineupNode:recvMsg")

		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_PLANET_RIDE_BACK_RESP") then

			local proto = Tools.decode("PlanetRideBackResp",strData)

			if proto.result ~= 0 then
				printInfo("DefensiveLineupNode PlanetRideBackResp error :"..proto.result)
			else
				app:removeTopView()

			end
		end
	
	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)


end


function DefensiveLineupNode:onExitTransitionStart()

	printInfo("DefensiveLineupNode:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)

	if schedulerEntry ~= nil then
		scheduler:unscheduleScriptEntry(schedulerEntry)
	end

end

return DefensiveLineupNode