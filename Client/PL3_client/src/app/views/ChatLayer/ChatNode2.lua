local player = require("app.Player"):getInstance()

local ChatNode2 = class("ChatNode2", cc.load("mvc").ViewBase)

ChatNode2.RESOURCE_FILENAME = "ChatLayer/chatNode.csb"

ChatNode2.NEED_ADJUST_POSITION = true

function ChatNode2:onCreate(data)
	self.data_ = data.data
end

function ChatNode2:onEnterTransitionFinish()
	local info = self.data_.info
	local node = self:getResourceNode()
	node:getChildByName("name"):setString(info.nickname)
	node:getChildByName("lv_num_0"):setString(info.level)
	node:getChildByName("fight_num"):setString(info.power)
	node:getChildByName("close"):getChildByName("text"):setString(CONF:getStringValue("closed"))
	node:getChildByName("close"):addClickEventListener(function ( ... )
		node:removeFromParent()
	end)
	node:getChildByName("head"):setTexture("HeroImage/" .. info.icon_id .. ".png")
	print("info.icon_id ----------" ,info.icon_id)
	if info.group_nickname == "" or info.group_nickname == nil then
		node:getChildByName("xxx"):setString(CONF:getStringValue("notInLeague"))
	else
		node:getChildByName("xxx"):setString(info.group_nickname)
	end 

	local labels = {"attackTime" ,"defenseTime" ,"winTime" ,"winRate" ,"battleTime"}
	local nums = {"attNum" ,"defNum" ,"winNum" ,"totalWinNum" ,"battleNum"}
	local battleList = {info.attack_count ,info.defence_count ,info.win_count ,0 ,0}

	battleList[5] = battleList[1] + battleList[2]
	if battleList[5] ==0 then
		battleList[4] = 0
	else 
		battleList[4] = math.floor(battleList[3] / battleList[5] * 100)
	end

	for i=1,5 do
		node:getChildByName(labels[i]):setString(CONF:getStringValue(labels[i]))
		node:getChildByName(nums[i]):setString(battleList[i])
	end

	if battleList[4] ~= 0 then
		node:getChildByName(nums[4]):setString(battleList[4] .. "%")
	end

	local posNode = node: getChildByName("shipPos")
	local posX = posNode:getPositionX()
	local posY = posNode:getPositionY()
	if info.id_lineup then         
		for i,v in ipairs(info.id_lineup) do
			if v ~= 0 then
				local shipInfo = player:getShipByID(v)
				local shipConf = CONF.AIRSHIP.get(v)
				local shipNode = require("app.ExResInterface"):getInstance():FastLoad("FormScene/ship_normal.csb")
				shipNode:getChildByName("background"):setTexture("RankLayer/ui/ui_avatar_" .. shipConf.QUALITY ..".png")
				shipNode:getChildByName("icon"):loadTexture("RoleIcon/".. shipConf.DRIVER_ID .. ".png")
                shipNode:getChildByName("icon"):setVisible(false)
                shipNode:getChildByName("icon2"):setVisible(true)
                shipNode:getChildByName("icon2"):setTexture("ShipImage/"..shipConf.DRIVER_ID..".png")
				shipNode:getChildByName("num"):setString(info.lv_lineup[i])
				--star
				local breakNum = info.break_lineup[i]
--				if breakNum then
--					for j=breakNum + 1,6 do
--						shipNode:getChildByName("star_" .. j):removeFromParent()
--					end
--				end
                ShowShipStar(shipNode,breakNum,"star_")

				--type
				local shipType = "Common/ui/ui_icon_"
				if shipConf.TYPE == 1 then 
					shipType = shipType .. "attack.png"
				elseif shipConf.TYPE == 2 then
					shipType = shipType .. "defense.png"
				elseif shipConf.TYPE == 3 then
					shipType = shipType .. "cure.png"
				elseif shipConf.TYPE == 4 then
					shipType = shipType .. "control.png"
				end                
				shipNode:getChildByName("type"):setTexture(shipType)

				shipNode:setPosition(cc.p(posX + (i-1)*80 , posY))
				shipNode:setScale(0.8)
				node:addChild(shipNode)
			end
		end
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
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
end

function ChatNode2:onExitTransitionStart()
	printInfo("ChatNode2:onExitTransitionStart()")

end

return ChatNode2