local g_player = require("app.Player"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local UpgradeLayer = class("UpgradeLayer", cc.load("mvc").ViewBase)

local app = require("app.MyApp"):getInstance()

UpgradeLayer.NEED_ADJUST_POSITION = true

UpgradeLayer.RESOURCE_FILENAME = "WeaponDevelopScene/UpgradeLayer.csb"


function UpgradeLayer:onCreate(data)
	self.weaponID_ = data.id
end

function UpgradeLayer:resetInfo( weaponID )
	local rn = self:getResourceNode()
	local conf = CONF.WEAPON.get(weaponID)
	assert(conf,"error")
	local nextConf = CONF.WEAPON.check(weaponID + 1)
	local icon = rn:getChildByName("icon")
	local width = icon:getContentSize().width	
	local weapon_info = g_player:getWeaponByID(weaponID)

	local need = conf.MATERIAL_NUM
	local function onUpgrade( )
		if g_player:getItemNumByID(conf.MATERIAL_ID) < need then
			local jumpTab = {}
            local cfg_item = CONF.ITEM.get(conf.MATERIAL_ID)
            if cfg_item and cfg_item.JUMP then
                table.insert(jumpTab,cfg_item.JUMP)
            end
            if Tools.isEmpty(jumpTab) == false and not self:getChildByName("JumpChoseLayer") then
            	jumpTab.scene = "UpgradeLayer"
                local center = cc.exports.VisibleRect:center()
                local layer = app:createView("ShipsScene/JumpChoseLayer",jumpTab)
                tipsAction(layer, cc.p(center.x + (rn:getContentSize().width/2 - center.x), center.y + (rn:getContentSize().height/2 - center.y)))
                layer:setName("JumpChoseLayer")
                self:addChild(layer)
            end  
			tips:tips(CONF.STRING.get("res_not_enough").VALUE)
			return
		end

		local building_info = g_player:getBuildingInfo(CONF.EBuilding.kWeaponDevelop)
		if building_info.level < nextConf.BUILDING_LEVEL then
			tips:tips(CONF.STRING.get("Building_lvl_not_enought").VALUE)
			return
		end
		playEffectSound("sound/system/click.mp3")
		local strData = Tools.encode("WeaponUpgradeReq", {    
           	 		guid = weapon_info.guid,
            			weapon_id = weaponID,
       		})
        		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_WEAPON_UPGRADE_REQ"),strData)
   		gl:retainLoading()

   		
	end
	rn:getChildByName("upgrade"):addClickEventListener(onUpgrade)

	local function setData( conf )
		rn:getChildByName("needNode"):removeFromParent()
		rn:getChildByName("costNode"):removeFromParent()
		local lvNode = rn:getChildByName("lvNode")
		lvNode:getChildByName("cur_level"):setString(1)
		lvNode:getChildByName("new_level"):setVisible(false)
		lvNode:getChildByName("lv_arrow"):setVisible(false)
		local powerNode = rn:getChildByName("powerNode")
		powerNode:getChildByName("cur_wp2"):setString(conf.FIGHT_POWER)
		powerNode:getChildByName("wp_arrow"):setVisible(false)
		powerNode:getChildByName("new_wp2"):setVisible(false)
		local detailNode = rn:getChildByName("detailNode")
		detailNode:getChildByName("prop_string"):setString(setMemo(conf ,4))
		--detailNode:getChildByName("prop_string"):setString(CONF.STRING.get(conf.MEMO_ID).VALUE)
		--print("value ===",CONF.STRING.get(conf.MEMO_ID).VALUE)
		rn:getChildByName("upgrade"):setVisible(false)
	end 

	if weapon_info then --当前拥有的 ***可升级，满级，不可升级 共三种情况 
		icon:loadTexture(string.format("WeaponIcon/%d.png", conf.ICON_ID))
		if nextConf then 
			local lvNode = rn:getChildByName("lvNode")
			lvNode:getChildByName("cur_level"):setString(tostring(conf.LEVEL))
			lvNode:getChildByName("new_level"):setString(tostring(nextConf.LEVEL))
	
			local detailNode = 	rn:getChildByName("detailNode")
			--detailNode:getChildByName("prop_string"):setString(CONF.STRING.get(nextConf.MEMO_ID).VALUE)
			--print("value ===",CONF.STRING.get(conf.MEMO_ID).VALUE)
			detailNode:getChildByName("prop_string"):setString(setMemo(conf ,4))

			local costNode = rn:getChildByName("costNode")
			local path = CONF.ITEM.get(conf.MATERIAL_ID).ICON_ID
			costNode:getChildByName("item_icon"):setTexture(string.format("ItemIcon/%d.png", path))
			costNode:getChildByName("item_num"):setString(tostring(conf.MATERIAL_NUM))
			if g_player:getItemNumByID(conf.MATERIAL_ID) < conf.MATERIAL_NUM then
				costNode:getChildByName("item_num"):setTextColor(cc.c4b(255,0,0,255))
			end

			local needNode = rn:getChildByName("needNode")
			local need = needNode:getChildByName("need")
			local needStr =  needNode:getChildByName("needText")
			needStr:setString(string.format("%s",CONF.STRING.get("BuildingName_4").VALUE))
			needStr:setPositionX(need:getPositionX() + needStr:getContentSize().width + 2)
    			needNode:getChildByName("needNum"):setString(string.format("Lv.%d",nextConf.BUILDING_LEVEL))
    			needNode:getChildByName("needNum"):setPositionX(needStr:getPositionX() + needStr:getContentSize().width + 2)

    			if g_player:getBuildingInfo(CONF.EBuilding.kWeaponDevelop).level < nextConf.BUILDING_LEVEL then
        				needStr:setTextColor(cc.c4b(255,0,0,255))
        			end
		else
			setData(conf)
			rn:getChildByName("max"):setVisible(true)
			rn:getChildByName("lvNode"):getChildByName("cur_level"):setString(tostring(conf.LEVEL))
		end
	else--即将开放的 --灰色
		local greyImage = mc.EffectSprite:create(string.format("WeaponIcon/%d.png", conf.ICON_ID))
	    	greyImage:setName("icon")
	    	greyImage:setPosition(icon:getPosition())
	    	greyImage:setEffect(mc.EffectGreyScale:create())
	    	greyImage:setScale(0.5)
	    	greyImage:setAnchorPoint(cc.p(0,1))
	    	icon:removeFromParent()
	    	rn:addChild(greyImage)

	    	setData(conf)
	end

	local powerNode = rn:getChildByName("powerNode")
	local curWp = powerNode:getChildByName("cur_wp")
	local curWp2 = powerNode:getChildByName("cur_wp2")
	local curRichText = powerNode:getChildByName("cur_rich_text")
	if curRichText then
		curRichText:removeFromParent()
	end

	if nextConf and weapon_info then
		curRichText = self:createWeaponInfo(conf, 1)
	else
		curRichText = createWeaponInfo(conf)
	end

	curRichText:setPosition(cc.p(curWp:getPosition()))
	curRichText:setName("cur_rich_text")
	powerNode:addChild(curRichText)
	curWp:setVisible(false)
	curWp2:setVisible(false)

	local newWp2 = powerNode:getChildByName("new_wp2")
	local newRichText = powerNode:getChildByName("new_rich_text")
	if newRichText then
		newRichText:removeFromParent()
	end
	if nextConf and weapon_info then
    		newRichText = self:createWeaponInfo(nextConf,2)
    		newRichText:setPosition(cc.p(newWp2:getPosition()))
    		newRichText:setName("new_rich_text")
    		powerNode:addChild(newRichText)

    		performWithDelay(self, function ()
    			local curRichTextPosX = curRichText:getPosition()
			-- local diffSize = curRichText:getVirtualRendererSize()
			local diffSize = curRichText:getContentSize()
		
			local x = curRichTextPosX + diffSize.width +20
    			powerNode:getChildByName("wp_arrow"):setPositionX(x)

    			x = x + 20
    			newRichText:setPositionX(x)
		end, 0.0001)
	else 
		powerNode:getChildByName("wp_arrow"):setVisible(false)
	end

	newWp2:setVisible(false)

   	rn:getChildByName("name"):setString(CONF.STRING.get(conf.NAME_ID).VALUE)
end

function UpgradeLayer:onEnterTransitionFinish()	
	local rn = self:getResourceNode()
	rn:getChildByName("costNode"):getChildByName("cost"):setString(CONF.STRING.get("Cost").VALUE)
	rn:getChildByName("needNode"):getChildByName("need"):setString(CONF.STRING.get("upgradeDemand").VALUE)
	rn:getChildByName("powerNode"):getChildByName("power"):setString(CONF.STRING.get("power").VALUE)
	--rn:getChildByName("detailNode"):getChildByName("detail"):setString(CONF.STRING.get("intro").VALUE)
	rn:getChildByName("upgrade"):getChildByName("text"):setString(CONF.STRING.get("upgrade").VALUE)

	self:resetInfo(self.weaponID_)
	local function onTouchBegan(touch, event)
		
		return true
	end

	local function onTouchEnded(touch, event)
		-- self:getApp():removeTopView()
		self:removeFromParent()
	end

	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(true)
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)

	local function recvMsg()
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_WEAPON_UPGRADE_RESP") then
			
			local proto = Tools.decode("WeaponUpgradeResp",strData)
			if proto.result == 0 then
				playEffectSound("sound/system/upgrade_skill.mp3")
				self.weaponID_ = proto.weapon_id
				self:resetInfo(self.weaponID_)
				print("result",  proto.result)
			else
				print("CMD_WEAPON_UPGRADE_RESP error:",proto.result)
			end
			gl:releaseLoading()
			-- tips:tips(CONF:getStringValue("UpgradeSucess"))

			local node = require("util.UpgradeOverNode"):createNode(CONF:getStringValue("UpgradeSucess"))
            node:setPosition(cc.exports.VisibleRect:center())
            self:getParent():addChild(node)
			cc.Director:getInstance():getEventDispatcher():dispatchEvent(cc.EventCustom:new("update_weapon_list"))
		end
	end
	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)
end

function UpgradeLayer:onExitTransitionStart()
  	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
end

function UpgradeLayer:getShowType( conf, now )
	
	local p_conf

	if now == 1 then

		local check = CONF.WEAPON.check(conf.ID + 1)
		if check then
			p_conf = CONF.WEAPON.get(conf.ID + 1)
		end
	else
		p_conf = CONF.WEAPON.get(conf.ID - 1)
	end

	local show_type = 0 
	local index = 0

	if p_conf.ATTR_PERCENT ~= conf.ATTR_PERCENT or p_conf.ENERGY_ATTR_PERCENT ~= conf.ENERGY_ATTR_PERCENT or p_conf.ATTR_VALUE ~= conf.ATTR_VALUE or p_conf.ENERGY_ATTR_VALUE ~= conf.ENERGY_ATTR_VALUE then
		show_type = 1
	else
		local flag = false
		for i,v in ipairs(conf.BUFF_ATTR_PERCENT) do
			if v ~= p_conf.BUFF_ATTR_PERCENT[i] then
				flag = true
				index = i
				break
			end
		end

		if not flag then
			for i,v in ipairs(conf.BUFF_ATTR_VALUE) do
				if v ~= p_conf.BUFF_ATTR_VALUE[i] then
					flag = true
					index = i
					break
				end
			end
		end

		if not flag then
			for i,v in ipairs(conf.BUFF_CONDITION_PERCENT) do
				if v ~= p_conf.BUFF_CONDITION_PERCENT[i] then
					flag = true
					index = i
					break
				end
			end
		end 

		if flag then
			show_type = 2
		else
			show_type = 3

		end

	end

	return show_type,index

end


function UpgradeLayer:createWeaponInfo( conf, type) --1有 2无

	print("iddddddddd",conf.ID)

	if conf == nil then
		return nil
	end

	local fontName = "fonts/cuyabra.ttf"
    local fontSize = 20

    local string_1 = ""  -- skill_power_num
    local string_2 = ""		-- skill_power_type
    local string_3 = ""		-- skill_power_num_2
    local string_4 = ""		-- skill_power_type_2

    local show_type, index = self:getShowType(conf, type)   -- 

    if show_type == 1 then


	    if conf.SIGN == 0 then

	  		string_1 = ""
	  		string_2 = CONF:getStringValue("null")
	  		string_3 = ""
	  		string_4 = ""

	    else

	        if conf.ATTR_PERCENT == 0 then

	            string_1 = ""
	            string_2 = ""
	        else

	            string_1 = math.abs(conf.ATTR_PERCENT).."%"

	            if type == 1 then
	            	string_2 = CONF:getStringValue("physical")
	            elseif type == 2 then
	            	string_2 = ""
	            end
	        end

	        if conf.ATTR_PERCENT ~= 0 or conf.ATTR_VALUE ~= 0 then
	            string_2 = string_2.."+"
	        end

	        if conf.ENERGY_ATTR_PERCENT == 0 then

	            string_3 = ""
	            string_4 = ""
	        else

	            string_3 = math.abs(conf.ENERGY_ATTR_PERCENT).."%"
	            

	            if type == 1 then
	            	string_4 = CONF:getStringValue("energy")
	            elseif type == 2 then
	            	string_4 = ""
	            end
	        end

	        if conf.ATTR_VALUE ~= 0 then
	            if conf.ATTR_PERCENT ~= 0 or conf.ENERGY_ATTR_PERCENT ~= 0 then

	                string_4 = string_4.."+"
	            end

	            string_4 = string_4..math.abs(conf.ATTR_VALUE)
	        end

	    end

	elseif show_type == 2 then

		if conf.BUFF_ATTR_PERCENT[index] ~= 0 and conf.BUFF_ATTR_VALUE[index] ~= 0 then
			string_2 = math.abs(conf.BUFF_ATTR_PERCENT[index]).."%+"..math.abs(conf.BUFF_ATTR_VALUE[index])
		else
			if conf.BUFF_ATTR_PERCENT[index] ~= 0 then
				string_2 = math.abs(conf.BUFF_ATTR_PERCENT[index]).."%"
			else
				string_2 = math.abs(conf.BUFF_ATTR_VALUE[index])
			end
		end

	elseif show_type == 3 then
		if type == 1 then
			string_2 = CONF:getStringValue("probability")
		end

		string_4 = conf.BUFF_CONDITION_PERCENT[index]

	end

	local richText = ccui.RichText:create()
    -- richText:ignoreContentAdaptWithSize(false)  
    -- richText:setContentSize(cc.size(400,24))

    local re1 = ccui.RichElementText:create( 1, cc.c3b(33, 255, 70), 255, string_1, fontName, fontSize , 2)  
    local re2 = ccui.RichElementText:create( 2, cc.c3b(255, 255, 255), 255, string_2, fontName, fontSize , 2)  
    local re3 = ccui.RichElementText:create( 3, cc.c3b(255, 230, 18), 255, string_3, fontName, fontSize , 2)  
    local re4 = ccui.RichElementText:create( 4, cc.c3b(255, 255, 255), 255, string_4, fontName, fontSize , 2)  

    richText:pushBackElement(re1)  
    richText:pushBackElement(re2)  
    richText:pushBackElement(re3)  
    richText:pushBackElement(re4)  

    richText:setAnchorPoint(cc.p(0,0.5))

    return richText
end

return UpgradeLayer
