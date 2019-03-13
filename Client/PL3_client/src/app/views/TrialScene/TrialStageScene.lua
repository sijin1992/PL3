local player = require("app.Player"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local messageBox = require("util.MessageBox"):getInstance()

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()

local TrialStageScene = class("TrialStageScene", cc.load("mvc").ViewBase)

TrialStageScene.RESOURCE_FILENAME = "TrialScene/TrialStageScene/TrialStageScene.csb"

TrialStageScene.RUN_TIMELINE = true

TrialStageScene.NEED_ADJUST_POSITION = true

TrialStageScene.RESOURCE_BINDING = {
	--["Button_1"]   = {["varname"] = "btn"},
	["close"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

local schedulerEntry = nil

local touchLocation = nil

local layerPosX = 0

local moveLayer = false

local touchLevel = false

function TrialStageScene:onCreate(data)

	self.data_ = data

end

function TrialStageScene:OnBtnClick(event)
	printInfo(event.name)

	if event.name == "ended" and event.target:getName() == "close" then
		printInfo("close")
		playEffectSound("sound/system/return.mp3")
		self:getApp():pushToRootView("TrialScene/TrialAreaScene")

		
	end
end

function TrialStageScene:createEnemyNode(id , index)
	
	local enemyNode = require("app.ExResInterface"):getInstance():FastLoad("TrialScene/TrialStageScene/enemyNode.csb")
	-- local enemyNode = require("app.ExResInterface"):getInstance():FastLoad("Common/EnemyNode.csb")
	local conf = CONF.TRIAL_COPY.get(id)

	local panel = enemyNode:getChildByName("Panel")
	panel:getChildByName("copy_name"):setString(CONF:getStringValue(conf.T_COPY_NAME))
	-- enemyNode:getChildByName("Panel"):getChildByName("bg"):setContentSize(cc.size(enemyNode:getChildByName("Panel"):getChildByName("copy_name"):getContentSize().width + 20, enemyNode:getChildByName("Panel"):getChildByName("bg"):getContentSize().height))
	panel:getChildByName("lv_num"):setString(conf.LEVEL_LV)

	panel:setSwallowTouches(false)

	enemyNode:getChildByName("icon"):setTag(id)

	if id == 11003 then
		enemyNode:getChildByName("icon"):setContentSize(cc.size(204,136))
	elseif id == 12004 then
		enemyNode:getChildByName("icon"):setContentSize(cc.size(140,100))
	end

	-- enemyNode:getChildByName("icon"):setAnchorPoint(cc.p(0.5,0.5))


	local function callBack( sender, eventType )

		if eventType == ccui.TouchEventType.began  then

			animManager:runAnimByCSB(self.layer_:getChildByName("guangliang_"..index), "TrialScene/sfx/gaoliang/"..self.layer_:getChildByName("guangliang_"..index):getTag()..".csb", "1")

		end
		if eventType == ccui.TouchEventType.moved  then
			animManager:runAnimByCSB(self.layer_:getChildByName("guangliang_"..index), "TrialScene/sfx/gaoliang/"..self.layer_:getChildByName("guangliang_"..index):getTag()..".csb", "1")

		end
		if eventType == ccui.TouchEventType.ended then 
			animManager:runAnimByCSB(self.layer_:getChildByName("guangliang_"..index), "TrialScene/sfx/gaoliang/"..self.layer_:getChildByName("guangliang_"..index):getTag()..".csb", "0")

			playEffectSound("sound/system/click.mp3")
			if self.selectPanel_ then
				if self.selectPanel_:isVisible() == false then
					self.selectPanel_:setVisible(true)
				end
			end

			panel:setVisible(false)
			self.selectPanel_ = panel

			if self.infoNode_ then
				self.infoNode_:removeFromParent()
				self.infoNode_ = nil
			end
			self.infoNode_ = self:createInfoNode(enemyNode:getChildByName("icon"):getTag())
			self.infoNode_:setPosition(cc.p(enemyNode:getChildByName("icon"):getPositionX(), enemyNode:getChildByName("icon"):getPositionY() + enemyNode:getChildByName("icon"):getContentSize().height/2))
			enemyNode:addChild(self.infoNode_)
		end

		if eventType == ccui.TouchEventType.canceled then  
			animManager:runAnimByCSB(self.layer_:getChildByName("guangliang_"..index), "TrialScene/sfx/gaoliang/"..self.layer_:getChildByName("guangliang_"..index):getTag()..".csb", "0")
		end
	end

	enemyNode:getChildByName("icon"):addTouchEventListener(callBack)

	local starNum = 0
	for i,v in ipairs(conf.LEVEL_ID) do
		local num = player:getTrialLevelStar(v)
		starNum = starNum + num
	end

	panel:getChildByName("now_num"):setString(starNum)
	panel:getChildByName("max_num"):setString("/"..conf.START_NUM)

	if player:getTrialCopyReward(id) == 1 then
		panel:getChildByName("btn_box"):setVisible(false)
		panel:getChildByName("box"):setVisible(true)

		panel:getChildByName("now_num"):setTextColor(cc.c4b(209, 209, 209, 255))
--		panel:getChildByName("now_num"):enableShadow(cc.c4b(209, 209, 209, 255),cc.size(0.5,0.5))

	else
		if starNum == conf.START_NUM then
			panel:getChildByName("btn_box"):setVisible(true)
			panel:getChildByName("box_light"):setVisible(true)
			panel:getChildByName("box"):setVisible(false)
		else
			panel:getChildByName("btn_box"):setVisible(true)
			panel:getChildByName("box_light"):setVisible(false)
			panel:getChildByName("box"):setVisible(false)

			-- panel:getChildByName("btn_box"):setTouchEnabled(false)
		end
	end

	if conf.LEVEL_LV > player:getLevel() then
		panel:getChildByName("bg"):setTexture("Common/newUI/sl_bottom02.png")
		panel:getChildByName("btn_box"):setEnabled(false)
		panel:getChildByName("btn_box"):setVisible(true)
		panel:getChildByName("box_light"):setVisible(false)
		panel:getChildByName("box"):setVisible(false)

		panel:getChildByName("lv_num"):setTextColor(cc.c4b(255,145,136,255))
--		panel:getChildByName("lv_num"):enableShadow(cc.c4b(255,145,136,255), cc.size(0.5,0.5))
	end

	-- if starNum == 0 then
	--     enemyNode:getChildByName("Panel"):getChildByName("star_1"):removeFromParent()
	-- elseif starNum > 1 then
	--     -- for i=2,starNum do
	--     --     local star = cc.Sprite:create("ChapterScene/ui_icon_start.png")
	--     --     star:setScale(enemyNode:getChildByName("Panel"):getChildByName("star_1"):getScale())
	--     --     star:setPosition(cc.p(enemyNode:getChildByName("Panel"):getChildByName("star_1"):getPositionX() + 30*(i-1), enemyNode:getChildByName("Panel"):getChildByName("star_1"):getPositionY()))
	--     --     enemyNode:getChildByName("Panel"):addChild(star)
	--     -- end
	--     enemyNode:getChildByName("Panel"):getChildByName("star_1"):removeFromParent()
	-- end

	local function touch( ... )
		local tag = enemyNode:getChildByName("icon"):getTag()

		local starNum = 0
		for i,v in ipairs(CONF.TRIAL_COPY.get(tag).LEVEL_ID) do
			local num = player:getTrialLevelStar(v)
			starNum = starNum + num
		end

		local node = require("app.ExResInterface"):getInstance():FastLoad("Common/RewardNode.csb")

		node:getChildByName("bg"):setSwallowTouches(true)
		node:getChildByName("bg"):addClickEventListener(function ( ... )
			node:removeFromParent()
		end)

		local rf = CONF.REWARD.get(CONF.TRIAL_COPY.get(tag).REWARD_ID)
		local items = {}

		for i,v in ipairs(rf.ITEM) do

			local itemName = v

			local item_conf = CONF.ITEM.get(itemName)

			if itemName ~= 0 then
				
				local itemNode = require("util.ItemNode"):create():init(itemName, rf.COUNT[i])

				table.insert(items, itemNode)
			end
		end

		local x,y = node:getChildByName("item"):getPosition()

		if #items%2 == 0 then
			for i,v in ipairs(items) do
					v:setPosition(15 + (i-1)*100 - #items/2*100, y)
					node:addChild(v)
			end
		else
			for i,v in ipairs(items) do
					v:setPosition(x + (i-1)*100 - (#items-1)/2*100, y)
					node:addChild(v)
			end
		end 

		node:getChildByName("item"):removeFromParent()


		if starNum < CONF.TRIAL_COPY.get(tag).START_NUM then
			node:getChildByName("yes"):getChildByName("text"):setString(CONF:getStringValue("closed"))

			node:getChildByName("yes"):addClickEventListener(function ( ... )
				node:removeFromParent()
			end)
		else
			print(player:getTrialCopyReward(tag))
			if player:getTrialCopyReward(tag) == 0 then
				node:getChildByName("yes"):getChildByName("text"):setString(CONF:getStringValue("Get"))

				node:getChildByName("yes"):addClickEventListener(function ( ... )
					playEffectSound("sound/system/click.mp3")
					local strData = Tools.encode("TrialGetRewardReq", {
						copy_id = tag
					})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_TRIAL_GET_REWARD_REQ"),strData)

					gl:retainLoading()

					node:removeFromParent()
				end)
			else
				node:getChildByName("yes"):getChildByName("text"):setString(CONF:getStringValue("has_get"))

				node:getChildByName("yes"):addClickEventListener(function ( ... )
					node:removeFromParent()
				end)

			end
		end

		self:addChild(node)
		tipsAction(node)
	end

	panel:getChildByName("btn_box"):addClickEventListener(function ( ... )
		touch()
	end)

	panel:getChildByName("touch_box"):addClickEventListener(function ( ... )
		touch()
	end)

	animManager:runAnimOnceByCSB(enemyNode, "TrialScene/TrialStageScene/enemyNode.csb", "1", function ( ... )
		if self.data_.copy_id then
			if self.data_.copy_id == enemyNode:getChildByName("icon"):getTag() then
				self:openIns()
			end
		end
	end)

	return enemyNode

end

function TrialStageScene:createInfoNode( id )
	local conf = CONF.TRIAL_COPY.get(id)

	local infoNode = require("app.ExResInterface"):getInstance():FastLoad("TrialScene/TrialStageScene/copy_info.csb")

	infoNode:getChildByName("btn"):addClickEventListener(function ( sender )
		if not moveLayer then
			touchLevel = true

			self.selectPanel_:setVisible(true)

			if self.infoNode_ then
				self.infoNode_:removeFromParent()
				self.infoNode_ = nil
			end

		end
	end)
	for i,v in ipairs(conf.LEVEL_ID) do

		local conf = CONF.TRIAL_LEVEL.get(v)

		local node = require("app.ExResInterface"):getInstance():FastLoad("TrialScene/TrialStageScene/copy_open.csb")

		local boss = false
		for ii,vv in ipairs(conf.MONSTER_ID) do
			if vv < 0 then
				boss = true
			end
		end

		node:getChildByName("ship"):loadTexture("ShipImage/"..conf.RES_LEVEL..".png")
		node:getChildByName("ship"):setContentSize(cc.size(65,45))

		if player:getLevel() < conf.LEVEL then

			node:getChildByName("btn"):loadTextures("StarOccupationLayer/ui/cj_case_gray.png", "StarOccupationLayer/ui/cj_case_gray.png", "")

			local grey = mc.EffectGreyScale:create()

			local greyImage = mc.EffectSprite:create(string.format("ShipImage/"..conf.RES_LEVEL..".png"))
			greyImage:setEffect(grey)
			greyImage:setPosition(cc.p(node:getChildByName("ship"):getPosition()))
			node:getChildByName("ship"):removeFromParent()
			node:addChild(greyImage)    
			greyImage:setName("ship")
			greyImage:setScale(65/greyImage:getContentSize().width, 45/greyImage:getContentSize().height)

			node:getChildByName("icon"):setTexture("StarLeagueScene/ui/icon_suo_dark.png")
			node:getChildByName("icon"):setLocalZOrder(2)

		else
			if player:getTrialLevelPre(v) then

				if boss then
					node:getChildByName("icon"):setTexture("Common/ui/ui_icon_boss.png")

					-- node:getChildByName("btn"):loadTextures("StarOccupationLayer/ui/ld_case.png", "StarOccupationLayer/ui/ld_case_light.png", "")
				else
					node:getChildByName("icon"):setVisible(false)
				end

			else

				if boss then

					-- node:getChildByName("btn"):loadTextures("StarOccupationLayer/ui/ld_case.png", "StarOccupationLayer/ui/ld_case_light.png", "")

					node:getChildByName("icon"):setTexture("TrialScene/ui/icon_suo_red.png")
				else
				end

				-- node:getChildByName("btn"):setTouchEnabled(false)
			end
		end

		node:getChildByName("ship"):setTag(v)

		for i=player:getTrialLevelStar(v)+1,4 do
			node:getChildByName("star_"..i):removeFromParent()
		end
		
		if player:getTrialLevelStar(v) == 1 then
			node:getChildByName("star_1"):setPositionX(node:getChildByName("icon"):getPositionX())
		elseif player:getTrialLevelStar(v) == 2 then
			node:getChildByName("star_1"):setPositionX(node:getChildByName("icon"):getPositionX() - 13)
			node:getChildByName("star_2"):setPositionX(node:getChildByName("icon"):getPositionX() + 13)
		elseif player:getTrialLevelStar(v) == 3 then
			node:getChildByName("star_1"):setPositionX(node:getChildByName("icon"):getPositionX() - 25)
			node:getChildByName("star_2"):setPositionX(node:getChildByName("icon"):getPositionX())
			node:getChildByName("star_3"):setPositionX(node:getChildByName("icon"):getPositionX() + 25)
		end

		infoNode:addChild(node)

		node:setPosition(cc.p(infoNode:getChildByName("item_"..i):getPosition()))

		node:getChildByName("btn"):addClickEventListener(function ( ... )
			playEffectSound("sound/system/click.mp3")
			if not moveLayer then
				touchLevel = true

				if player:getLevel() < conf.LEVEL then
					tips:tips(CONF:getStringValue("level_not_enought"))
					return
				end

				if player:getTrialLevelPre(node:getChildByName("ship"):getTag()) == false then
					tips:tips(CONF:getStringValue("finish pre copy"))
					return
				end

				if player:getTrialLevelStar(node:getChildByName("ship"):getTag()) == conf.START_MAX then
					tips:tips(CONF:getStringValue("trial get max star"))
					return
				end

				--进入副本界面
				if player:getTrialLevelPre(node:getChildByName("ship"):getTag()) and player:getTrialLevelStar(node:getChildByName("ship"):getTag()) ~= CONF.TRIAL_LEVEL.get(v).START_MAX then
					self.data_.slPosX = self.layer_:getPositionX()
					
					print("level_id",node:getChildByName("ship"):getTag())
					self:getApp():pushView("FightFormScene/FightFormScene", {level_id = node:getChildByName("ship"):getTag(), slPosX = self.layer_:getPositionX(), index = math.floor(self.data_.scene/100), from = "trial"})
				end
			end
		end)
	end

	return infoNode
end

function TrialStageScene:resetLayer(index)
	if self.layer_ then
		self.layer_:removeFromParent()
		self.layer_ = nil
	end

	local rn = self:getResourceNode()

	self.layer_ = require("app.ExResInterface"):getInstance():FastLoad(string.format("TrialScene/stageLayer/%d/%d.csb", index, index))
	self.layer_:setTag(index)
	rn:addChild(self.layer_)



	if self.data_.slPosX == nil then
		self.data_.slPosX = 0
	end
	self.layer_:setPositionX(self.data_.slPosX)

	for i,v in ipairs(self.layer_:getChildren()) do
		local name = v:getName()
		local filePath = string.format("TrialScene/stageLayer/%d/dachangjing/%s.csb", index, name)

		-- if name == "xingguang" then
		--     filePath = string.format("ChapterScene/Chanjing/1/xingguang.csb")
		-- end

		local file = cc.FileUtils:getInstance():isFileExist(filePath)
		if file then
			animManager:runAnimByCSB(v, filePath,  "1")
		end

	end

	--enemy
	local conf = CONF.TRIAL_SCENE.get(self.data_.scene)
	for i,v in ipairs(conf.T_COPY_LIST) do
		local enemyNode = self:createEnemyNode(v, i)
		enemyNode:setPosition(cc.p(self.layer_:getChildByName("Node_"..i):getPosition()))
		enemyNode:setName("enemyNode_"..i)
		self.layer_:addChild(enemyNode)
	end

	--building
	local building = require("app.ExResInterface"):getInstance():FastLoad("TrialScene/TrialStageScene/building.csb")
	-- building:getChildByName("building"):setTexture(conf.BUILDING_ICON)
	building:getChildByName("building"):setTag(self.data_.scene)
	building:getChildByName("building_name"):setString(CONF:getStringValue(conf.BUILDING_NAME))
	building:getChildByName("building"):setTag(conf.BUILDING_LEVEL_ID)
	building:setPosition(cc.p(self.layer_:getChildByName("building_node"):getPosition()))
	building:setName("building")
	self.layer_:addChild(building)

	if self.data_.scene == 102 then
		building:getChildByName("building"):setContentSize(cc.size(210, 89))
	end

	local texts,widths = self:getBuffString(20)
	local pos =  cc.p(building:getChildByName("buff"):getPosition())
	local posX = pos.x - widths/2
	for i,v in ipairs(texts) do
		v:setAnchorPoint(cc.p(0,0.5))

		if self.player_zhan == nil then
            if i%2 == 1 then
			    v:setTextColor(cc.c4b(209,209,209,255))
            else
                v:setTextColor(cc.c4b(33, 255, 70, 255))
            end
--			v:enableShadow(cc.c4b(209,209,209,255), cc.size(0.5,0.5))
		end
		v:setPosition(cc.p(posX, pos.y))
		posX = posX + v:getContentSize().width

		v:setName("building_buff_"..i)
		building:addChild(v)
	end
	building:getChildByName("buff"):removeFromParent()
	building:getChildByName("head"):addClickEventListener(function ( ... )
		if self.player_zhan == nil then 
			tips:tips(CONF:getStringValue('no occupy'))
			return
		end
		playEffectSound("sound/system/click.mp3")
		if building:getChildByName("building_info") then
			building:getChildByName("building_info"):removeFromParent()
			return
		end

		local building_info = require("app.ExResInterface"):getInstance():FastLoad("TrialScene/TrialStageScene/building_info.csb")
		building_info:setName("building_info")
		building:addChild(building_info)
		building:getChildByName("building_info"):getChildByName("back"):addClickEventListener(function()
			building:getChildByName("building_info"):removeFromParent()
			end)
		if self.building_lineup == nil then
			building_info:getChildByName("juntuan"):setString(CONF:getStringValue("information"))
			building_info:getChildByName("juntuan_name"):setString("")
			building_info:getChildByName("juntuan_name"):setPositionX(building_info:getChildByName("juntuan"):getPositionX() + building_info:getChildByName("juntuan"):getContentSize().width+1)
			building_info:getChildByName("player_name"):setString(CONF:getStringValue("unknown"))
			building_info:getChildByName("fight_num"):setString(CONF.TRIAL_LEVEL.get(self.data_.scene).COMBAT)

			local monsters = {}
			for i,v in ipairs(CONF.TRIAL_LEVEL.get(self.data_.scene).MONSTER_ID) do
				if v ~= 0 then
					if #monsters > 0 then
						local has = false
						for i2,v2 in ipairs(monsters) do
							if v == v2 then
								has = true
							end
						end

						if has == false then
							monsters[#monsters+1] = v
						end
					else
						monsters[1] = v
					end
				end
			end

			for i,v in ipairs(monsters) do
				local enemy = require("app.ExResInterface"):getInstance():FastLoad("Common/ItemNode.csb")
				enemy:getChildByName("num"):removeFromParent()
				enemy:getChildByName("num_m"):removeFromParent()

				local conf = CONF.AIRSHIP.get(math.abs(v))
				enemy:getChildByName("background"):setTexture("RankLayer/ui/ui_avatar_"..conf.QUALITY..".png")
				enemy:getChildByName("icon"):loadTexture("RoleIcon/"..conf.DRIVER_ID..".png")

				enemy:setPosition(cc.p(building_info:getChildByName("pos"):getPositionX() + ((i+2)%3)*55, building_info:getChildByName("pos"):getPositionY() - math.floor((i-1)/3)*55))

				enemy:setScale(0.6)
				enemy:setName("item_"..i)
				building_info:addChild(enemy)
			end
		else
			building_info:getChildByName("juntuan"):setString(CONF:getStringValue("covenant")..":")
			building_info:getChildByName("juntuan_name"):setString(self.player_zhan.group_nickname)
			building_info:getChildByName("juntuan_name"):setPositionX(building_info:getChildByName("juntuan"):getPositionX() + building_info:getChildByName("juntuan"):getContentSize().width+1)
			building_info:getChildByName("player_name"):setString(self.player_zhan.nickname)
			building_info:getChildByName("fight_num"):setString(self.player_zhan.power)

			local num = 0
			for i,v in ipairs(self.building_lineup) do
				if v ~= 0 then
					local enemy = require("app.ExResInterface"):getInstance():FastLoad("FormScene/ship_normal.csb")
					enemy:getChildByName("num"):setString(self.player_zhan.lv_lineup[i])
					enemy:getChildByName("num"):setScale(1)
					enemy:getChildByName("level"):setScale(0.7)
					enemy:getChildByName("type"):setScale(1)

					for i=1,6 do
						enemy:getChildByName("star_"..i):removeFromParent()
					end

					local conf = CONF.AIRSHIP.get(math.abs(v))
					enemy:getChildByName("background"):setTexture("RankLayer/ui/ui_avatar_"..conf.QUALITY..".png")
					enemy:getChildByName("icon"):loadTexture("RoleIcon/"..conf.DRIVER_ID..".png")
					enemy:getChildByName("type"):setTexture("ShipType/"..conf.TYPE..".png")

					enemy:setPosition(cc.p(building_info:getChildByName("pos"):getPositionX() + ((num)%3)*55, building_info:getChildByName("pos"):getPositionY() - math.floor((num)/3)*55))

					enemy:setScale(0.6)
					enemy:setName("item_"..i)
					building_info:addChild(enemy)

					num = num + 1
				end
			end

		end

	end)

	
	animManager:runAnimOnceByCSB(building, "TrialScene/TrialStageScene/building.csb", "1")

	printInfo("build"..conf.BUILDING_LEVEL_ID)
	local strData = Tools.encode("TrialGetBuildingInfoReq", {
		level_id = conf.BUILDING_LEVEL_ID
	})
	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_TRIAL_GET_BUILDING_INFO_REQ"),strData)

	gl:retainLoading()

	-- door
	local areaStr = ""
	for i=1,math.floor(self.data_.scene/100) do
		areaStr = areaStr.."I"
	end

	if conf.LAYER < CONF.TRIAL_AREA.get(math.floor(self.data_.scene/100)).T_SCENE_NUM then
		local door = require("app.ExResInterface"):getInstance():FastLoad("TrialScene/TrialStageScene/door.csb") 
		door:getChildByName("door_name"):setString(areaStr.."-"..conf.LAYER+1)
		if not player:getTrialDoorType(self.data_.scene) then
			-- door:getChildByName("icon"):Texture("TrialScene/ui/door_grey.png")
		end
		door:getChildByName("icon"):addClickEventListener(function ( sender )
			playEffectSound("sound/system/click.mp3")
	
			if player:getTrialDoorType(self.data_.scene) then

				if self.selectPanel_ then
					self.selectPanel_ = nil
				end
		
				if self.infoNode_ then
					self.infoNode_ = nil
				end
		
				self.data_.scene = self.data_.scene + 1
		
				self:resetDownInfo()
				self:resetLayer(self.data_.scene)
			else
				tips:tips(CONF:getStringValue("DoorNotOpen"))
			end
		end)

		door:setPosition(self.layer_:getChildByName("door_node"):getPosition())
		door:setName("door")
		self.layer_:addChild(door)
	end
	
	--移动
	local function onTouchBegan(touch, event)

		layerPosX = self.layer_:getPositionX()

		touchLocation = touch:getLocation()

		moveLayer = false

		touchLevel = false


		local building = self.layer_:getChildByName("building"):getChildByName("building")
		local bs = building:getContentSize()
		local b_locationInNode = building:convertToNodeSpace(touch:getLocation())
		local b_rect = cc.rect(0, 0, bs.width, bs.height)
		if cc.rectContainsPoint(b_rect, b_locationInNode) then

			animManager:runAnimByCSB(self.layer_:getChildByName("guangliang_jianzhu"), "TrialScene/sfx/gaoliang/"..self.layer_:getChildByName("guangliang_jianzhu"):getTag()..".csb","1")
		end

		return true

	end

	local function onTouchMoved(touch, event)

		local diff = touch:getDelta()
		if math.abs(diff.x) < g_click_delta or math.abs(diff.y) < g_click_delta then
			
		else
			moveLayer = true

			-- animManager:runAnimByCSB(self.layer_:getChildByName("guangliang_jianzhu"), "TrialScene/sfx/gaoliang/"..self.layer_:getChildByName("guangliang_jianzhu"):getTag()..".csb","0")
		end

		local tl = touch:getLocation()
		local is_go_left = false
		if( cc.exports.TRIAL_SCENE_DRAG_TOUCH_POS_LAST ~= nil ) then
			local last_x = cc.exports.TRIAL_SCENE_DRAG_TOUCH_POS_LAST.x
			is_go_left = tl.x - last_x > 0 
			print( string.format(" >>> shi pei >>> is_go_left: %s tl - last_x: %s ", tostring(is_go_left), tostring(tl.x - last_x) ) )
		end
		cc.exports.TRIAL_SCENE_DRAG_TOUCH_POS_LAST = tl
		
		-- ADD WJJ 20180731
		local pos_bg = layerPosX + (tl.x - touchLocation.x)
		local pos_min = -578
		local pos_max = 0
		
		local is_quanmianping = require("util.ExConfigScreenAdapterFixedHeight"):getInstance():IsFixScreenEnabled()
		if( is_quanmianping ) then
			-- go left < -290   go  right > -290
			pos_min = -290
			pos_max = 9999999

			if( is_go_left ) then
				pos_min = -9999999
				pos_max = -290
			end

			print( string.format(" >>> shi pei >>> tl.x: %s touchLocation.x: %s ", tostring(tl.x), tostring(touchLocation.x) ) )
			print( string.format(" >>> shi pei >>> tl.x - touchLocation.x: %s ", tostring(tl.x - touchLocation.x)) )
			print( string.format(" >>> shi pei >>> pos_bg: %s pos_min: %s pos_max: %s ", tostring(pos_bg), tostring(pos_min), tostring(pos_max)) )
		end

		if (is_quanmianping == false) and ((pos_bg < pos_max) and (pos_bg > pos_min)) then
			self.layer_:setPositionX(pos_bg)
		end

		-- local building = self.layer_:getChildByName("building"):getChildByName("building")
		-- local bs = building:getContentSize()
		-- local b_locationInNode = building:convertToNodeSpace(touch:getLocation())
		-- local b_rect = cc.rect(0, 0, bs.width, bs.height)
		-- if cc.rectContainsPoint(b_rect, b_locationInNode) then

		-- 	animManager:runAnimByCSB(self.layer_:getChildByName("gaoliang_jianzhu"), "TrialScene/sfx/gaoliang/"..self.layer_:getChildByName("gaoliang_jianzhu"):getTag()..".csb","1")
		-- else
		-- 	animManager:runAnimByCSB(self.layer_:getChildByName("gaoliang_jianzhu"), "TrialScene/sfx/gaoliang/"..self.layer_:getChildByName("gaoliang_jianzhu"):getTag()..".csb","0")
		-- end

	end

	local function onTouchEnded(touch, event)
		moveLayer = false
		
		if touchLevel then
			return
		end

		local rn = self:getResourceNode()

		local conf = CONF.TRIAL_SCENE.get(self.data_.scene)
		
		-- if not moveLayer then
			animManager:runAnimByCSB(self.layer_:getChildByName("guangliang_jianzhu"), "TrialScene/sfx/gaoliang/"..self.layer_:getChildByName("guangliang_jianzhu"):getTag()..".csb","0")

			local building = self.layer_:getChildByName("building"):getChildByName("building")
			local bs = building:getContentSize()
			local b_locationInNode = building:convertToNodeSpace(touch:getLocation())
			local b_rect = cc.rect(0, 0, bs.width, bs.height)
			if cc.rectContainsPoint(b_rect, b_locationInNode) then

				self.data_.slPosX = self.layer_:getPositionX()

				local str = ""
				if self.player_zhan ~= nil then
					str = self.player_zhan.user_name
					self:getApp():pushView("FightFormScene/FightFormScene", {level_id = building:getTag(), name = str, slPosX = self.layer_:getPositionX(), index = math.floor(self.data_.scene/100), id_lineup = self.building_lineup, icon_id = self.player_zhan.icon_id, power = self.player_zhan.power,nickname = self.player_zhan.nickname, from = "trial"})
				else
					self:getApp():pushView("FightFormScene/FightFormScene", {level_id = building:getTag(), name = str, slPosX = self.layer_:getPositionX(), index = math.floor(self.data_.scene/100), from = "trial"})
				end

				return
			end

			if self.selectPanel_ then
				self.selectPanel_:setVisible(true)
			end


			if self.infoNode_ then
				self.infoNode_:removeFromParent()
				self.infoNode_ = nil
			end
		-- end

	end

	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(true)
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
	listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self.layer_)
	-- add wjj 20180731
	require("util.ExConfigScreenAdapterFixedHeight"):getInstance():onFixQMP_Shilian(self.layer_)
end

function TrialStageScene:resetDownInfo()
	local rn = self:getResourceNode()
	local panel_down = rn:getChildByName("Panel_down")

	for i=1,10 do
		if panel_down:getChildByName("panel_down_text_"..i) then
			panel_down:getChildByName("panel_down_text_"..i):removeFromParent()
		end
	end

	local areaStr = ""
	for i=1,math.floor(self.data_.scene/100) do
		areaStr = areaStr.."I"
	end

	local conf = CONF.TRIAL_SCENE.get(self.data_.scene)
	panel_down:getChildByName("trial_name"):setString(areaStr.."-"..conf.LAYER)
	if conf.LAYER == 1 then
		panel_down:getChildByName("left_text"):setVisible(false)
		panel_down:getChildByName("btn_left"):setVisible(false)
		panel_down:getChildByName("right_text"):setVisible(true)
		panel_down:getChildByName("btn_right"):setVisible(true)
		panel_down:getChildByName("right_text"):setString(areaStr.."-"..conf.LAYER+1)
	elseif conf.LAYER == CONF.TRIAL_AREA.get(math.floor(self.data_.scene/100)).T_SCENE_NUM then
		panel_down:getChildByName("left_text"):setVisible(true)
		panel_down:getChildByName("btn_left"):setVisible(true)
		panel_down:getChildByName("right_text"):setVisible(false)
		panel_down:getChildByName("btn_right"):setVisible(false) 
		panel_down:getChildByName("left_text"):setString(areaStr.."-"..conf.LAYER-1)
	else
		panel_down:getChildByName("left_text"):setVisible(true)
		panel_down:getChildByName("btn_left"):setVisible(true)
		panel_down:getChildByName("right_text"):setVisible(true)
		panel_down:getChildByName("btn_right"):setVisible(true)
		panel_down:getChildByName("right_text"):setString(areaStr.."-"..conf.LAYER+1)
		panel_down:getChildByName("left_text"):setString(areaStr.."-"..conf.LAYER-1)
	end

	panel_down:getChildByName("btn_left"):addClickEventListener(function ( sender )  
		playEffectSound("sound/system/click.mp3")
		if self.selectPanel_ then
			self.selectPanel_ = nil
		end

		if self.infoNode_ then
			self.infoNode_ = nil
		end

		self.data_.scene = self.data_.scene - 1

		self:resetDownInfo()
		self:resetLayer(self.data_.scene)
		
	end)

	if not player:getTrialDoorType(self.data_.scene) then
		panel_down:getChildByName("btn_right"):getChildByName("suo"):setVisible(true)
	else
		panel_down:getChildByName("btn_right"):getChildByName("suo"):setVisible(false)
	end

	panel_down:getChildByName("btn_right"):addClickEventListener(function ( sender )
		playEffectSound("sound/system/click.mp3")
		if player:getTrialDoorType(self.data_.scene) then
			if self.selectPanel_ then
				self.selectPanel_ = nil
			end

			if self.infoNode_ then
				self.infoNode_ = nil
			end

			self.data_.scene = self.data_.scene + 1

			self:resetDownInfo()
			self:resetLayer(self.data_.scene)
		else
			tips:tips(CONF:getStringValue("DoorNotOpen"))
		end

	end)

	local starNum = 0
	local starNowNum = 0
	for i,v in ipairs(conf.T_COPY_LIST) do
		starNum = starNum + CONF.TRIAL_COPY.get(v).START_NUM
		for ii,vv in ipairs(CONF.TRIAL_COPY.get(v).LEVEL_ID) do
			starNowNum = starNowNum + player:getTrialLevelStar(vv)
		end
	end

	panel_down:getChildByName("star_now_num"):setString(starNowNum)
	panel_down:getChildByName("star_max_num"):setString("/"..starNum)
end


function TrialStageScene:onEnter()
	printInfo("TrialStageScene:onEnter()")

end

function TrialStageScene:onExit()
	
	printInfo("TrialStageScene:onExit()")
end

function TrialStageScene:onEnterTransitionFinish()
	printInfo("TrialStageScene:onEnterTransitionFinish()")

	broadcastRun()

	guideManager:checkInterface(CONF.EInterface.kTrialStage)

	if g_System_Guide_Id ~= 0 then
		systemGuideManager:createGuideLayer(g_System_Guide_Id)
	end

	--layer
	local rn = self:getResourceNode()

	for i,v in ipairs(rn:getChildren()) do
		v:setLocalZOrder(11)
	end
	
	self:resetLayer(self.data_.scene)

	--setInfo
	local conf = CONF.TRIAL_SCENE.get(self.data_.scene)

	print("self.data_.scene", self.data_.scene)

	local forms_num = 0
    for i,v in ipairs(player:getTrialLineup(math.floor(self.data_.scene/100))) do
        if v ~= 0 then
            forms_num = forms_num + 1
        end
    end

    local ship_num = 0
    for i,v in ipairs(player:getTrialShipList(math.floor(self.data_.scene/100))) do
        if v.hp ~= 0 then
            ship_num = ship_num + 1
        end
    end

    if forms_num < ship_num then
        rn:getChildByName("Panel_down"):getChildByName("form"):getChildByName("point"):setVisible(true)
    end

	rn:getChildByName("hp_touch"):addClickEventListener(function ( ... )
		tips:tips(CONF:getStringValue("trial_hp_tips"))
	end)

	local userInfoNode = require("util.UserInfoNode"):create()
	userInfoNode:init(self)
	userInfoNode:getResourceNode():getChildByName("fight_num"):setString(player:getTrialPower(math.floor(self.data_.scene/100)))
	rn:getChildByName("info_node"):addChild(userInfoNode)

	-- local panel_top = rn:getChildByName("Panel_top")

	-- panel_top:getChildByName("headImage"):loadTexture("HeroImage/"..player:getPlayerIcon()..".png")
	-- panel_top:getChildByName("reaper_aleriness"):setString(player:getNickName())
	-- panel_top:getChildByName("lv_0"):setString("Lv."..player:getLevel())
	-- panel_top:getChildByName("fight_num"):setString(CONF:getStringValue("combat")..":"..player:getTrialPower(math.floor(self.data_.scene/100)))
	rn:getChildByName("money_num"):setString(tostring(player:getMoney()))--formatRes(player:getMoney()))
	rn:getChildByName("time_num"):setString(formatTime(86400 - player:getServerTime()%86400))

	rn:getChildByName("touch"):addClickEventListener(function ( ... )
		playEffectSound("sound/system/click.mp3")

		local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

		rechargeNode:init(self, {index = 1})
		self:addChild(rechargeNode)
	end)

	rn:getChildByName("money_add"):addClickEventListener(function ( ... )
		playEffectSound("sound/system/click.mp3")

		local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

		rechargeNode:init(self, {index = 1})
		self:addChild(rechargeNode)
	end)

	rn:getChildByName("btn_time"):addClickEventListener(function ( ... )
		-- local node = require("app.ExResInterface"):getInstance():FastLoad("CityScene/QueueNode.csb")
		-- node:getChildByName("cancel"):getChildByName("text"):setString(CONF:getStringValue("cancel"))
		-- node:getChildByName("yes"):getChildByName("text"):setString(CONF:getStringValue("yes"))
		-- node:getChildByName("text"):setString(CONF:getStringValue("reset tips"))
		-- node:getChildByName("queue_node"):removeFromParent()

		-- node:getChildByName("cancel"):addClickEventListener(function ( ... )
		--     node:removeFromParent()
		-- end)

		-- node:getChildByName("yes"):addClickEventListener(function ( ... )
		--     local strData = Tools.encode("TrialAreaReq", {
		--         type = 3,
		--         area_id = math.floor(self.data_.scene/100),
		--     })
		--     GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_TRIAL_OPEN_ATEA_REQ"),strData)

		--     gl:retainLoading()

		--     node:removeFromParent()
		-- end)

		-- node:getChildByName("bg"):setSwallowTouches(true)
		-- node:getChildByName("bg"):addClickEventListener(function ( ... )
		--     node:removeFromParent()
		-- end)

		-- node:setPosition(cc.exports.VisibleRect:center())
		-- rn:addChild(node)
		local function resetTrial( ... )
			local strData = Tools.encode("TrialAreaReq", {
				type = 3,
				area_id = math.floor(self.data_.scene/100),
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_TRIAL_OPEN_ATEA_REQ"),strData)

			gl:retainLoading()

			-- node:removeFromParent()
		end
		playEffectSound("sound/system/click.mp3")
		messageBox:reset(CONF.STRING.get("reset tips").VALUE, resetTrial)

	end)

	local hp_now = 0
	local hp_max = 0
	for i,v in ipairs(player:getTrialShipList(math.floor(self.data_.scene/100))) do
		hp_now = hp_now + v.hp

		local cal_ship = player:calShip(v.guid)
		hp_max = hp_max + cal_ship.attr[CONF.EShipAttr.kHP]

	end

	rn:getChildByName("ev_num"):setString(formatRes(hp_now).."/"..formatRes(hp_max))

	-- panel_top:getChildByName("exp_progress"):setContentSize(cc.size(player:getNextLevelExpPercent()/100*panel_top:getChildByName("exp_progress"):getTag(), panel_top:getChildByName("exp_progress"):getContentSize().height))

	-- rn:getChildByName("progress"):setContentSize(cc.size((hp_now/hp_max)*rn:getChildByName("progress"):getTag(), rn:getChildByName("progress"):getContentSize().height))
	local progress = require("util.ScaleProgressDelegate"):create(rn:getChildByName("progress"), 141)
	progress:setPercentage(hp_now/hp_max*100)
	--down
	rn:getChildByName("Panel_down"):setSwallowTouches(false)
	rn:getChildByName("Panel_down"):getChildByName("zhan"):setString(CONF:getStringValue("occupation")..":")
	self:resetDownInfo()

	--form
	local shipNum = 0
	local formNum = 0 
	for i,v in ipairs(player:getTrialShipList(math.floor(self.data_.scene/100))) do
		if v.guid ~= 0 then
			formNum = formNum + 1
		end
	end

	for i,v in ipairs(player:getTrialLineup(math.floor(self.data_.scene/100))) do
		if v ~= 0 then
			shipNum = shipNum + 1
		end
	end

	rn:getChildByName("Panel_down"):getChildByName("form"):getChildByName("ship_now_num"):setString(shipNum)
	rn:getChildByName("Panel_down"):getChildByName("form"):getChildByName("ship_max_num"):setString("/"..formNum)

	rn:getChildByName("Panel_down"):getChildByName("form"):addClickEventListener(function ( ... )
		playEffectSound("sound/system/click.mp3")
		self:getApp():addView2Top("NewFormLayer", {from = "trial", index = math.floor(self.data_.scene/100)})
	end)

	rn:getChildByName("Panel_down"):getChildByName("buff_"):setString(CONF:getStringValue("buff")..":")

	--

	--setZOrder
	-- rn:getChildByName("Image_1"):setLocalZOrder(11)
	-- rn:getChildByName("mask_02_74"):setLocalZOrder(11)

	-- rn:getChildByName("info_node"):setLocalZOrder(11)
	-- rn:getChildByName("Panel_down"):setLocalZOrder(11)
	-- rn:getChildByName("close"):setLocalZOrder(12)

	-- rn:getChildByName("touch"):setLocalZOrder(11)
	-- rn:getChildByName("btn_time"):setLocalZOrder(11)
	-- rn:getChildByName("time_num"):setLocalZOrder(11)
	-- rn:getChildByName("money_add"):setLocalZOrder(11)
	-- rn:getChildByName("Image_9"):setLocalZOrder(11)
	-- rn:getChildByName("Image_10"):setLocalZOrder(11)
	-- rn:getChildByName("ui_icon_money_56"):setLocalZOrder(11)
	-- rn:getChildByName("money_num"):setLocalZOrder(11)
	-- rn:getChildByName("line_fg01_47_1"):setLocalZOrder(11)
	-- rn:getChildByName("line_fg01_47"):setLocalZOrder(11)
	-- rn:getChildByName("line_fg01_47_0"):setLocalZOrder(11)
	-- rn:getChildByName("hp_touch"):setLocalZOrder(11)
	-- rn:getChildByName("progress_back"):setLocalZOrder(11)
	-- rn:getChildByName("progress"):setLocalZOrder(11)
	-- rn:getChildByName("ev_num"):setLocalZOrder(11)
	-- rn:getChildByName("Image_38"):setLocalZOrder(11)



	animManager:runAnimOnceByCSB(rn, "TrialScene/TrialStageScene/TrialStageScene.csb", "intro", function ( )
		rn:getChildByName("Panel_down"):getChildByName("zhan_name"):setPositionX(rn:getChildByName("Panel_down"):getChildByName("zhan"):getPositionX() + rn:getChildByName("Panel_down"):getChildByName("zhan"):getContentSize().width)
	end)

	-- animManager:runAnimByCSB(panel_top:getChildByName("zhanli"), "CityScene/sfx/zhanli/zhanli.csb",  "1")

	local function update(dt)

		rn:getChildByName("time_num"):setString(formatTime(86400 - player:getServerTime()%86400))
		
	end

	schedulerEntry = scheduler:scheduleScriptFunc(update,1,false)

	local function recvMsg()
		print("TrialStageScene:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_TRIAL_GET_BUILDING_INFO_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("TrialGetBuildingInfoResp",strData)

			if proto.result ~= 0 then
				print("error :",proto.result)
			else

				local panel_down = self:getResourceNode():getChildByName("Panel_down")
				panel_down:getChildByName("zhan_name"):setString(proto.building_info.user_name)

				if proto.building_info.user_name == "" then
					panel_down:getChildByName("zhan_name"):setString(CONF:getStringValue("trial_building_no_player"))
				else
					self.building_lineup = proto.building_info.id_lineup
				end

				local texts,widths = self:getBuffString(20)
				local pos =  cc.p(panel_down:getChildByName("buff_"):getPosition())

				local posX = pos.x + panel_down:getChildByName("buff_"):getContentSize().width + 15
				for i,v in ipairs(texts) do
					v:setAnchorPoint(cc.p(0,0.5))

					v:setPosition(cc.p(posX, pos.y))
					posX = posX + v:getContentSize().width

					if proto.building_info.user_name ~= player:getName() then
						if i%2 == 1 then
			                v:setTextColor(cc.c4b(209,209,209,255))
                        else
                            v:setTextColor(cc.c4b(33, 255, 70, 255))
                        end
--						v:enableShadow(cc.c4b(209,209,209,255), cc.size(0.5,0.5))

					end
					v:setName("panel_down_text_"..i)

					panel_down:addChild(v)
				end

				panel_down:getChildByName("buff"):setVisible(false)

				local building = self.layer_:getChildByName("building")
				if proto.building_info.user_name ~= "" then

					local strData = Tools.encode("CmdGetOtherUserInfoReq", {
						user_name = proto.building_info.user_name,
						lineup = proto.building_info.lineup,
					})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_OTHER_USER_INFO_REQ"),strData)

					gl:retainLoading()
				else

					self.player_zhan = nil
					building:getChildByName("head"):loadTexture(getEnemyIcon(CONF.TRIAL_LEVEL.get(self.data_.scene).MONSTER_ID))
					
					for i=1,10 do
						if building:getChildByName("building_buff_"..i) then
							building:getChildByName("building_buff_"..i):setTextColor(cc.c4b(209,209,209,255))
--							building:getChildByName("building_buff_"..i):enableShadow(cc.c4b(209,209,209,255), cc.size(0.5,0.5))
						end
					end

					building:getChildByName("building_name"):setTextColor(cc.c4b(209,209,209,255))
--					building:getChildByName("building_name"):enableShadow(cc.c4b(209,209,209,255), cc.size(0.5,0.5))
				end
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_OTHER_USER_INFO_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("CmdGetOtherUserInfoResp",strData)

			if proto.result ~= 0 then
				print("error :",proto.result)
			else
				
				self.layer_:getChildByName("building"):getChildByName("head"):loadTexture("HeroImage/"..proto.info.icon_id..".png")

				print("zhanzhanli",proto.info.power)

				self.player_zhan = proto.info
				self:getResourceNode():getChildByName("Panel_down"):getChildByName("zhan_name"):setString(proto.info.nickname)

			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_TRIAL_GET_REWARD_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("TrialGetRewardResp",strData)

			if proto.result ~= 0 then
				print("error :",proto.result)
			else
				playEffectSound("sound/system/reward.mp3")
				local node = require("util.UpgradeOverNode"):createNode(CONF:getStringValue("getSucess"))
				node:setPosition(cc.exports.VisibleRect:center())
				self:addChild(node)

				local conf = CONF.TRIAL_SCENE.get(self.data_.scene)
		
				for i=1,table.getn(conf.T_COPY_LIST) do

					local node = self.layer_:getChildByName(string.format("enemyNode_%d", i))

					if node:getChildByName("icon"):getTag() == proto.copy_id then
						node:getChildByName("Panel"):getChildByName("box"):setVisible(true)
						node:getChildByName("Panel"):getChildByName("btn_box"):setVisible(false)
						node:getChildByName("Panel"):getChildByName("box_light"):setVisible(false)

						node:getChildByName("Panel"):getChildByName("now_num"):setTextColor(cc.c4b(209, 209, 209, 255))
--						node:getChildByName("Panel"):getChildByName("now_num"):enableShadow(cc.c4b(209, 209, 209, 255),cc.size(0.5,0.5))
					end
				end

				player:setTrialCopyReward(proto.copy_id)

			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_TRIAL_OPEN_ATEA_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("TrialAreaResp",strData)

			if proto.result ~= 0 then
				print("error :",proto.result)
			else
				self:getApp():pushToRootView("TrialScene/TrialAreaScene")
			end

		end
	   
	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

	self.broadcastListener_ = cc.EventListenerCustom:create("broadcastRun", function ()
		broadcastRun()
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.broadcastListener_, FixedPriority.kNormal)
 
end

function TrialStageScene:getBuffString(font_size)
	local texts = {}
	local buff_size = 0

	local conf = CONF.TRIAL_SCENE.get(self.data_.scene)
	for i,v in ipairs(conf.KEY) do
		local label1 = cc.Label:createWithTTF(CONF:getStringValue("Attr_"..v), "fonts/cuyabra.ttf", font_size)
		label1:setTextColor(cc.c4b(173, 242, 255, 255))
--		label1:enableShadow(cc.c4b(173, 242, 255, 255),cc.size(0.5,0.5))

		buff_size = buff_size + label1:getContentSize().width
		table.insert(texts, label1)

		local str = " "
		if conf.KEY_PERCENT[i] ~= 0 then
			str = str.."+"..conf.KEY_PERCENT[i].."%"
		end

		if conf.KEY_VALUE[i] ~= 0 then
			str = str.."+"..conf.KEY_VALUE[i]
		end

		if i ~= table.getn(conf.KEY) then
			str = str..", "
		end

		local label2 = cc.Label:createWithTTF(str, "fonts/cuyabra.ttf", font_size)
		label2:setTextColor(cc.c4b(33, 255, 70, 255))
--		label2:enableShadow(cc.c4b(33, 255, 70, 255),cc.size(0.5,0.5))

		buff_size = buff_size + label2:getContentSize().width
		table.insert(texts, label2)

	end

	for i,v in ipairs(texts) do
		v:setOpacity(0)
		v:runAction(cc.FadeIn:create(0.1))
	end


	return texts,buff_size
  
end

function TrialStageScene:openIns( ... )
	local conf = CONF.TRIAL_SCENE.get(self.data_.scene)
	for i=1,table.getn(conf.T_COPY_LIST) do
				
		local node = self.layer_:getChildByName(string.format("enemyNode_%d", i))

		if node:getChildByName("icon"):getTag() == self.data_.copy_id then
			self.selectPanel_ = node:getChildByName("Panel")
			self.selectPanel_:setVisible(false)

			self.infoNode_ = self:createInfoNode(node:getChildByName("icon"):getTag())
			self.infoNode_:setPosition(cc.p(node:getChildByName("icon"):getPositionX(), node:getChildByName("icon"):getPositionY() + node:getChildByName("icon"):getContentSize().height/2))
			node:addChild(self.infoNode_)
		end

	end
end

function TrialStageScene:onExitTransitionStart()
	printInfo("TrialStageScene:onExitTransitionStart()")


	if schedulerEntry ~= nil then
	  scheduler:unscheduleScriptEntry(schedulerEntry)
	end

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
	eventDispatcher:removeEventListener(self.broadcastListener_)

end

return TrialStageScene