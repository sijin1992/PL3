local g_player = require("app.Player"):getInstance()

local BuildInfo = class("BuildInfo", cc.load("mvc").ViewBase)

BuildInfo.RESOURCE_FILENAME = "CityScene/InfoLayer.csb"

BuildInfo.NEED_ADJUST_POSITION = true

function BuildInfo:onCreate(data)--{ BuildName = self.buildingName_ }
	self.buildingName_ = data.BuildName
end

function BuildInfo:onEnterTransitionFinish()
	local rn = self:getResourceNode()
	local name = rn:getChildByName("bg"):getChildByName("name")
	local info = rn:getChildByName("info")
	local num = tonumber(Split(self.buildingName_, "_")[2])
    rn:getChildByName("Text_1"):setString(CONF:getStringValue("level"))
    rn:getChildByName("Text_2"):setString(CONF:getStringValue("upgrade_time"))
    rn:getChildByName("Text_3"):setString(CONF:getStringValue("Promote_Combat_power"))
	self.svd = require("util.ScrollViewDelegate"):create( rn:getChildByName("list"),cc.size(2,5), cc.size(546 ,38))
	rn:getChildByName("list"):setScrollBarEnabled(false)
	self.num1 = -1 
	self.num2 = -1
	rn:getChildByName("bg"):getChildByName("close"):addClickEventListener(function()
		self:removeFromParent()
		end)
	local buildInfo = g_player:getBuildingInfo(tonumber(num))
	local fileName = "BUILDING_" .. num
	local buildConf = CONF[fileName].get(buildInfo.level)
	local idList = CONF[fileName].getIDList()
	info:setString(CONF:getStringValue(buildConf.MEMO_ID))
	name:setString(CONF:getStringValue("BuildingName_" .. num))

	print("buildInfo.level" ,buildInfo.level)
	local function addItem( level )
		local conf = CONF[fileName].get(level)
		local node = require("app.ExResInterface"):getInstance():FastLoad("CityScene/LevelNode.csb")
		node:getChildByName("lvNum"):setString(level)
		node:getChildByName("power"):setString(conf.FIGHT_POWER)
		local time = self:setCD(conf.CD)
		node:getChildByName("time"):setString(time)
		self:getStr(conf ,num ,node:getChildByName("text"))
		return node
	end 

	for i=1 ,#idList do
		local node = addItem(i)
		if i <= buildInfo.level then 
			node:getChildByName("doneBg"):setVisible(true)
--		elseif i == buildInfo.level then
--			node:getChildByName("selectedBg"):setVisible(true)
		end
		self.svd:addElement(node)
	end

	local function onTouchBegan(touch, event)
		return true
	end

	local function onTouchEnded(touch, event)
		self:removeFromParent()
	end

	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(true)
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, rn:getChildByName("back"))
end

function BuildInfo:getStr(conf ,id ,text)
	local rn = self:getResourceNode()
	local str = ""

	if id == "1" then --指挥中心
		local num1 = conf.AIRSHIP_NUM or 0
		local num2 = conf.COLLECT_NUM
		print("nuim  == = =" ,num1 ,num2)
		local n = 0 --行数
		if num1 ~= self.num1 then
			str = str .. CONF:getStringValue("shipOnLineNum") .. ":" .. num1 
			n = n + 1
		end
		if num2 ~= self.num2 then
			if n == 1 then
				str = str .. "\n"
			end
			str = str .. CONF:getStringValue("shipOutNum") .. ":" .. num2
			n = n + 1
		end  

		if n == 2 then  --显示两行文字
			text:setPositionY(text:getPositionY() + 10)
		end
		self.num1 = num1 
		self.num2 = num2
	elseif id == "3" then --飞船开发 
		if Tools.isEmpty(conf.SHIP_LIST) == false then
			str = CONF:getStringValue("openNewShip")
		end
	elseif id == "4" then --武器
		if Tools.isEmpty(conf.WEAPON_LIST) == false then 
		   str = CONF:getStringValue("openNewWeapon")
		end 
	elseif id == "5" then --科技
		if Tools.isEmpty(conf.TECH_LIST) == false then 
		   str = CONF:getStringValue("openNewTech")
		end
	elseif id == "7" then --修理 REPAIR_SPEED
		local num1 = conf.REPAIR_SPEED
		if num1 ~= self.num1 then
			str = string.format("%s :%d/%s" ,CONF:getStringValue("rapairingSpeed") ,num1 ,CONF:getStringValue("second"))
			self.num1 = num1
		end 

	end
	text:setString(str)
end

function BuildInfo:setCD( cd )  
	if cd == 0 or cd == nil then 
		return ""
	end

	local time = ""
	if cd > 60*60*24 then 
		time = time .. math.floor(cd / 60 /60 /24) .."d"
		cd = cd % (60*60*24)

	else 
		time = time .. "  "
	end
	time =time .. " "
	if cd > 60*60 then 
		local hour = math.floor(cd /60 /60)
		cd = cd % (60*60)
		if hour < 10 and hour > 0 then
			time = time .. "0" .. hour
		elseif hour == 0 then
			time = time .. "00"
		else 
			time = time .. hour
		end
	else
		time = time .. "00"
	end
	time =time .. ":"
	if cd > 60 then 
		local minute = math.floor(cd /60)
		cd = cd % (60)
		if minute < 10 then
			time = time .. "0" .. minute
		elseif minute == 0 then
			time = time .. "00"
		else 
			time = time .. minute
		end
	else
		time = time .. "00"
	end
	time =time .. ":"
	if cd < 10 then
		time = time .. "0" .. cd
	elseif cd == 0 then
		time = time .. "00"
	else 
		time = time .. cd
	end
	return time
end

function BuildInfo:onExitTransitionStart()
	printInfo("BuildInfo:onExitTransitionStart()")

end

return BuildInfo