
local BattleManager = require("app.battle.BattleManager")
local animManager = require("app.AnimManager"):getInstance()
local app = require("app.MyApp"):getInstance()
local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()
local tips = require("util.TipsMessage"):getInstance()

print("###LUA DEBUG BattleScene.lua line 7")

local userDefault = cc.UserDefault:getInstance()

local g_player = require("app.Player"):getInstance()

local VisibleRect = cc.exports.VisibleRect
local Gmath = cc.exports.Gmath

local schedulerEntry = nil
local scheduler = cc.Director:getInstance():getScheduler()
local cache = cc.SpriteFrameCache:getInstance()

local messageBox = require("util.MessageBox"):getInstance()


local SpeedList = {1,2}--,4}
local SpeedDefault = 1

local function showLightLine(pos1, pos2, name)
	
	local vec = cc.pSub(pos2, pos1)
	local length = cc.pGetLength(vec)
	local lightSize = cc.size(3,length)

	local angle = math.deg(cc.pGetAngle(vec,cc.p(0,1)))

	local sideLight = cc.Sprite:create("fire.png")
	sideLight:setColor(cc.RED)
	sideLight:setRotation(angle)
	sideLight:setPosition(cc.pMidpoint(pos1,pos2))
	sideLight:setBlendFunc(cc.blendFunc(gl.ONE, gl.ONE))
	sideLight:setName(name)

	local seq = cc.Sequence:create(cc.ScaleTo:create(0.5,lightSize.width*0.5,lightSize.height*0.5), cc.ScaleTo:create(0.5,lightSize.width*0.1,lightSize.height*0.75))
	local seq2 = cc.Sequence:create(cc.FadeTo:create(0.5, 150),cc.FadeTo:create(0.5, 255))
	local spawn = cc.Spawn:create(seq,seq2)
	sideLight:runAction(cc.RepeatForever:create(spawn))

	return sideLight
end



--BattleScene
local BattleScene = class("BattleScene", cc.load("mvc").ViewBase)

BattleScene.RESOURCE_FILENAME = "BattleScene/BattleScene.csb"
--BattleScene.RUN_TIMELINE = true

BattleScene.NEED_ADJUST_POSITION = true




BattleScene._bm = nil
BattleScene.data = nil
BattleScene.isPve = true


-- ADDED BY WJJ 20180619
BattleScene.EX_OptimizedLoader = require("app.ExResPreloader"):getInstance()
BattleScene.IS_OPTIMIZE = true
print("###LUA DEBUG BattleScene.lua line 11")

function BattleScene:getStencilPositions()


	local bulletLayer = self:getResourceNode():getChildByName("bullet_layer")
	--get plane:
	local plane1_1 = cc.p(bulletLayer:getChildByName("plane_1_1"):getPosition())
	local plane1_2 = cc.p(bulletLayer:getChildByName("plane_1_2"):getPosition())
	local plane2_1 = cc.p(bulletLayer:getChildByName("plane_2_1"):getPosition())
	local plane2_2 = cc.p(bulletLayer:getChildByName("plane_2_2"):getPosition())

	local plane = Gmath.getPlane({plane1_1,plane1_2})
	BattleManager.owner.bullet_plane = plane


	plane = Gmath.getPlane({plane2_1,plane2_2})
	BattleManager.enemy.bullet_plane = plane


	local function getTriangle( point, dir1, dir2, plane )
		local ray1 = Gmath.ray(point,dir1)
		local point1 = Gmath.isRayPlaneIntersection(ray1, plane)

		local ray2 = Gmath.ray(point,dir2)
		local point2 = Gmath.isRayPlaneIntersection(ray2, plane)

		return point,point1,point2
	end

	-- add wjj 20180731
	-- quan mian ping shi pei
	-- local p_right_top = cc.p(1136,768)
	local p_right_top = cc.p(1707,768)
	-- local p_left_bottom = VisibleRect:leftBottom()
	local p_left_bottom = cc.p(-400,0)

	return   {getTriangle(p_left_bottom,cc.p(1,0),cc.p(0,1),BattleManager.owner.bullet_plane)} ,    
		{getTriangle(p_right_top ,cc.p(-1,0),cc.p(0,-1),BattleManager.enemy.bullet_plane)}
end

print("###LUA DEBUG BattleScene.lua line 102")

--ui layer
function BattleScene:addBattleSceneAnim()

	local bgLayer = self:getResourceNode():getChildByName("background_layer")
	bgLayer:addChild(require("app.ExResInterface"):getInstance():FastLoad("BattleScene/SceneAnim_1/SceneAnim.csb"))

	local points1,points2 = self:getStencilPositions()

	local owner = cc.ClippingNode:create()
	bgLayer:addChild(owner)
	owner:setName("owner")

	local draw = cc.DrawNode:create()
	draw:drawPolygon(points1, table.getn(points1), cc.c4f(1,0,0,0.5), 4, cc.c4f(0,0,1,1))
	owner:setStencil(draw)

	local animName = "BattleScene/SceneAnim_1/SceneAnim_1.csb"
	local layer = require("app.ExResInterface"):getInstance():FastLoad(animName)
	
	local action = {}
	if( self.IS_OPTIMIZE ) then
		action = self.EX_OptimizedLoader:CacheLoadTimeline(animName)
	else
		action = cc.CSLoader:createTimeline(animName)
	end

		layer:runAction(action)
		action:gotoFrameAndPlay(0,true)

	owner:addChild(layer)



	local enemy = cc.ClippingNode:create()
	bgLayer:addChild(enemy)
	enemy:setName("enemy")

	draw = cc.DrawNode:create()
	draw:drawPolygon(points2, table.getn(points2), cc.c4f(0,1,0,0.5), 4, cc.c4f(0,0.5,1,1))
	enemy:setStencil(draw)

	-- fuck, do not code like this. WJJ
	local animName2 = "BattleScene/SceneAnim_1/SceneAnim_2.csb"
	local layer2 = {}
	local action2 = {}
	if( self.IS_OPTIMIZE ) then
		layer2 = self.EX_OptimizedLoader:CacheLoad(animName2)
		action2 = self.EX_OptimizedLoader:CacheLoadTimeline(animName2)
	else
		layer2 = require("app.ExResInterface"):getInstance():FastLoad(animName2)
		action2 = cc.CSLoader:createTimeline(animName2)
	end
	layer2:runAction(action)
	action2:gotoFrameAndPlay(0,true)
 
	enemy:addChild(layer2)

end
print("###LUA DEBUG BattleScene.lua line 162")
--object layer
function BattleScene:setBattleManagerValue()

	local object = self:getResourceNode():getChildByName("object_layer")

	--get ship pos
	for i=1,9 do
		BattleManager.owner.ship_pos[i] = cc.p(object:getChildByName(string.format("ship_1_%d", i)):getPosition())
	end

	for i=1,9 do
		BattleManager.enemy.ship_pos[i] = cc.p(object:getChildByName(string.format("ship_2_%d", i)):getPosition())
	end
end

function BattleScene:setBulletLayer()

	local layer = self:getResourceNode():getChildByName("bullet_layer")

	local points1,points2 = self:getStencilPositions()


	local owner = cc.ClippingNode:create()
	layer:addChild(owner)
	owner:setName("owner")


	local draw = cc.DrawNode:create()
	draw:drawPolygon(points1, table.getn(points1), cc.c4f(1,0,0,0.5), 4, cc.c4f(0,0,1,1))
	owner:setStencil(draw)

	-- owner:addChild(showLightLine(points1[1],points1[2]))
	-- owner:addChild(showLightLine(points1[2],points1[3]))
	-- owner:addChild(showLightLine(points1[3],points1[1]))

	local enemy = cc.ClippingNode:create()
	layer:addChild(enemy)
	enemy:setName("enemy")

	draw = cc.DrawNode:create()
	draw:drawPolygon(points2, table.getn(points2), cc.c4f(0,1,0,0.5), 4, cc.c4f(0,0.5,1,1))
	enemy:setStencil(draw)

	-- enemy:addChild(showLightLine(points2[1],points2[2]))
	-- enemy:addChild(showLightLine(points2[2],points2[3]))
	-- enemy:addChild(showLightLine(points2[3],points2[1]))
end

function BattleScene:onCreate(data)

	self.battleType = data[1]

	self.data = data[2]

	self.isPve = data[3]

	if data[4] == nil then
		self.enemyName_ = "nil"
	else
		self.enemyName_ = data[4]
	end

	if data[5] ~= nil and type(data[5]) == "string" then
		self.enemyIconStr_ = data[5]
	end

	if data[6] ~= nil and type(data[6]) == "number" then
		self.enemyPower_ = data[6]
	end

	if data[7] ~= nil then
		self.myName_ = data[7]
	end

	if data[8] ~= nil and type(data[8]) == "string" then
		self.myIconStr_ = data[8]
	end

	if data[9] ~= nil and type(data[9]) == "number" then
		self.myPower_ = data[9]
	end

	if self.isPve == false then
		self.switchGroup_ =  data.switchGroup

		if self.switchGroup_ == true then
			-- local temp
			-- temp = self.enemyName_
			-- self.enemyName_ = self.myName_
			-- self.myName_ = temp

			-- temp = self.enemyPower_
			-- self.enemyPower_ = self.myPower_
			-- self.myPower_ = temp

			-- temp = self.enemyIconStr_
			-- self.enemyIconStr_ = self.myIconStr_
			-- self.myIconStr_ = temp
		end
	end
	self.data.from = data.from --邮件用 传出后打开对应邮件界面
	self.from = data.from
end

function BattleScene:getEnemyName( )
	return self.enemyName_
end

function BattleScene:getEnemyIconStr( )
	return self.enemyIconStr_
end

function BattleScene:getBattleType( )
	return self.battleType
end

function BattleScene:getData()
	return self.data
end

function BattleScene:getAttackList( )

	return self.data.attack_list
end
 
function BattleScene:onEnter()

	printInfo("BattleScene:onEnter()")

	-- ADD WJJ 20180705
	require("app.ExMemoryInterface"):getInstance():OnDisableMemoryReleaseAsync()
end

function BattleScene:onExit()

	printInfo("BattleScene:onExit()")
end

function BattleScene:onEnterTransitionFinish()

	printInfo("BattleScene:onEnterTransitionFinish()")
	-- cache:addSpriteFrames("BattleScene/Bullet.plist")

	-- animManager:registerAnimById("Arrow", 1, "move", 0.1)
	-- animManager:registerAnimById("Arrow", 1, "disappear", 0.1)

	-- animManager:registerAnimById("NoxiousCloud", 1, "attack", 0.1)
	-- animManager:runAnimOnceByCSB(rn, "BattleScene/BattleScene", "intro")
	local rn = self:getResourceNode()
	rn:getChildByName("ui_layer"):getChildByName("ui_lab_round"):setString(CONF:getStringValue("Round"))
	local function onFrameEvent(frame)
		if nil == frame then
			return
		end
		local str = frame:getEvent()
		if str == "icon_bg_in" then
			if self.isPve == false then
				rn:getChildByName("ui_layer"):getChildByName("auto_text"):setVisible(true)
				rn:getChildByName("ui_layer"):getChildByName("auto_text"):getChildByName("auto_text"):setString(CONF:getStringValue("auto_fight"))
			end
		end

		self._bm:onFrameEvent(str)
	end
	animManager:runAnimOnceByCSB(rn, "BattleScene/BattleScene.csb", "intro", nil, onFrameEvent)

	if self.from then
		rn:getChildByName("ui_layer"):getChildByName("zidonggj"):setVisible(false)
	end


	-- ADD WJJ 20180802
	-- add this line before create battle manager!
	require("util.ExConfigScreenAdapter"):getInstance():onFixQuanmianping_Battle(self)
	require("util.ExConfigScreenAdapterFixedHeight"):getInstance():onFixQMP_Battle(self)


	self:addBattleSceneAnim()

	self:setBattleManagerValue()

	self:setBulletLayer()

	local function onTouchBegan(touch, event)

		self._bm:onTouchBegan(touch,event)

			return true
	end

	local function onTouchEnded(touch, event)
		
		local location = touch:getLocation()
		printInfo("x:%d y:%d", location.x,location.y)


		local center = cc.pSub(location ,VisibleRect:center()) 
		printInfo("center pos : fx:%d fy:%d", center.x,center.y)
		
	end

	local objLayer = rn:getChildByName("object_layer")
	local listener = cc.EventListenerTouchOneByOne:create()
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
	local eventDispatcher = objLayer:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, objLayer)

	if self.isPve == true then
		self._bm = BattleManager:create(self, self.data.attack_list, self.data.hurter_list, nil)
	else
		self._bm = BattleManager:create(self, self.data.attack_list, self.data.hurter_list, self.data.event_list, self.switchGroup_)
	end

	local function update(dt)
		dt = dt * scheduler:getTimeScale()
		if self._bm ~= nil then
			self._bm:update(dt)
		end
	end

	performWithDelay(self, function ()
		schedulerEntry = scheduler:scheduleScriptFunc(update,0.033,false)
	end, 3.6)

	rn:runAction(cc.Sequence:create(cc.DelayTime:create(3.8), cc.CallFunc:create(function ()
		--if self.battleType == BattleType.kTest then
			--cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("BattlePause")
			--guideManager:createGuideLayer(101)
		--end
	end)))

	
	if self.myIconStr_ == nil then
		if g_player:isInited() == false then
			self.myIconStr_ = "RoleIcon/3.png"
		else
			self.myIconStr_ = "HeroImage/"..g_player:getPlayerIcon()..".png"
		end
	end
	rn:getChildByName("start_sfx"):getChildByName("role_icon_1"):setTexture(self.myIconStr_)
	rn:getChildByName("ui_layer"):getChildByName("role_1"):setTexture(self.myIconStr_)

	local enemyIconStr = self:getEnemyIconStr()
	print("enemyIconStr",enemyIconStr)
	if enemyIconStr ~= nil then
		rn:getChildByName("start_sfx"):getChildByName("role_icon_2"):setTexture(enemyIconStr)
		rn:getChildByName("ui_layer"):getChildByName("role_2"):setTexture(enemyIconStr)
	end

	if self.myName_ == nil then
		if g_player:isInited() == false then
			self.myName_ = CONF:getStringValue("test_name")
		else
			self.myName_ = g_player:getNickName()
		end
	end
	rn:getChildByName("start_sfx"):getChildByName("name_1"):setString(self.myName_)
	rn:getChildByName("ui_layer"):getChildByName("name_1"):setString(self.myName_)

	rn:getChildByName("start_sfx"):getChildByName("name_2"):setString(self.enemyName_)
	rn:getChildByName("ui_layer"):getChildByName("name_2"):setString(self.enemyName_)

	if self.myPower_ == nil then
		rn:getChildByName("start_sfx"):getChildByName("fight_num_1"):setString(string.format("%d",self._bm.ownerFightPower))
	else
		rn:getChildByName("start_sfx"):getChildByName("fight_num_2"):setString(string.format("%d",self.myPower_))
	end

	if self.enemyPower_ == nil then
		rn:getChildByName("start_sfx"):getChildByName("fight_num_2"):setString(string.format("%d",self._bm.enemyFightPower))
        if self.battleType == BattleType.kCheckPoint then
            local conf = CONF.CHECKPOINT.get(tonumber(self.data.checkpoint_id))
            rn:getChildByName("start_sfx"):getChildByName("fight_num_2"):setString(conf.COMBAT)
        end
	else
		rn:getChildByName("start_sfx"):getChildByName("fight_num_2"):setString(string.format("%d",self.enemyPower_))
	end
	
	rn:getChildByName("ui_layer"):getChildByName("back"):addClickEventListener(function (sender)

		self._bm:pause()

		local pauseLayer = require("app.ExResInterface"):getInstance():FastLoad("BattleScene/PauseLayer.csb")
		pauseLayer:getChildByName("yes"):addClickEventListener(function ( sender )
			if self.isPve == true then
				self._bm:loseNow()
			else
				self._bm:showResult()
			end
			self._bm:resume()
			pauseLayer:removeFromParent()
		end)

		pauseLayer:getChildByName("cancel"):addClickEventListener(function ( sender )
			self._bm:resume()
			pauseLayer:removeFromParent()
		end)

		pauseLayer:getChildByName("black_background"):addClickEventListener(function ( sender )

		end)

		if self.isPve == true then
			pauseLayer:getChildByName("yes_text"):setString(CONF:getStringValue("quit"))
		else
			pauseLayer:getChildByName("yes_text"):setString(CONF:getStringValue("jump"))
		end
		pauseLayer:getChildByName("cancel_text"):setString(CONF:getStringValue("continue"))

		pauseLayer:setAnchorPoint(cc.p(0.5, 0.5))
		pauseLayer:setPosition(cc.exports.VisibleRect:center())
		self:addChild(pauseLayer)
	 end)

	rn:getChildByName("ui_layer"):getChildByName("back"):getChildByName("text"):setString(CONF:getStringValue("pause"))

	--------------------------------------------------------------------------------------------------------------------------------------------
	local _key = "BattleTimeScale" .. tostring(g_player:getName())
	local time_scale = g_player:isInited() == true and cc.exports[_key] or SpeedDefault
	-- local time_scale = g_player:isInited() == true and userDefault:getIntegerForKey("BattleTimeScale"..g_player:getName()) or SpeedDefault
	if time_scale == 0 then
		if g_player:isInited() == true then
			cc.exports[_key] = SpeedDefault
			-- userDefault:setIntegerForKey("BattleTimeScale"..g_player:getName(), SpeedDefault)
			-- userDefault:flush()
		end
		time_scale = SpeedDefault
	end
	scheduler:setTimeScale(time_scale)
	--------------------------------------------------------------------------------------------------------------------------------------------
	rn:getChildByName("ui_layer"):getChildByName("zidonggj"):loadTextures("Common/ui2/2.png","Common/ui2/4.png")
	if  cc.UserDefault:getInstance():getBoolForKey(g_player:getName().."_isPve") == true then
		rn:getChildByName("ui_layer"):getChildByName("zidonggj"):loadTextures("Common/ui2/1.png","Common/ui2/3.png")
	end

	if g_player:getLevel() >= CONF.PARAM.get("level_10_open_fight").PARAM then
		rn:getChildByName("ui_layer"):getChildByName("zidonggj"):setVisible(true)
	else
		rn:getChildByName("ui_layer"):getChildByName("zidonggj"):setVisible(false)
	end

	rn:getChildByName("ui_layer"):getChildByName("zidonggj"):addClickEventListener(function()
		local isPve = cc.UserDefault:getInstance():getBoolForKey(g_player:getName().."_isPve") and true or false
		self._bm:setPve(not isPve)
		if cc.UserDefault:getInstance():getBoolForKey(g_player:getName().."_isPve") == true then
			rn:getChildByName("ui_layer"):getChildByName("zidonggj"):loadTextures("Common/ui2/1.png","Common/ui2/3.png")
		else
			rn:getChildByName("ui_layer"):getChildByName("zidonggj"):loadTextures("Common/ui2/2.png","Common/ui2/4.png")
		end
		end)
	rn:getChildByName("ui_layer"):getChildByName("speed"):addClickEventListener(function (sender)

		if g_player:getVipLevel() < 1 then
			tips:tips(CONF:getStringValue("vip1_open"))
		else
			local _key = "BattleTimeScale" .. tostring(g_player:getName())
			local time_scale = (g_player:isInited() == true) and cc.exports[_key] or SpeedDefault
			-- local time_scale = g_player:isInited() == true and userDefault:getIntegerForKey("BattleTimeScale"..g_player:getName()) or SpeedDefault
			local index
			for i,v in ipairs(SpeedList) do
				if v == time_scale then
					index = Tools.mod(i+1, #SpeedList)
				end
			end

			time_scale = SpeedList[index]
		
			scheduler:setTimeScale(time_scale)
			if g_player:isInited() == true then
				cc.exports[_key] = time_scale
				-- userDefault:setIntegerForKey("BattleTimeScale"..g_player:getName(), time_scale)
				-- userDefault:flush()
			end

			rn:getChildByName("ui_layer"):getChildByName("speed"):getChildByName("text"):setString("X "..time_scale)
		end
	end)

	--------------------------------------------------------------------------------------------------------------------------------------------

	rn:getChildByName("ui_layer"):getChildByName("speed"):getChildByName("text"):setString("X "..time_scale)

	if g_player:isInited() then
		if guideManager:getShowGuide() then
			if g_player:getGuideStep() < 100 then
				rn:getChildByName("ui_layer"):getChildByName("back"):setVisible(false)
				rn:getChildByName("ui_layer"):getChildByName("speed"):setVisible(false)
				rn:getChildByName("ui_layer"):getChildByName("zidonggj"):setVisible(false)
			end
		end
	else
		rn:getChildByName("ui_layer"):getChildByName("back"):setVisible(false)
		rn:getChildByName("ui_layer"):getChildByName("speed"):setVisible(false)
	end

	rn:getChildByName("ui_layer"):getChildByName("energy_value"):setString(CONF:getStringValue("energy_value"))

	playMusic("sound/battle.mp3", true)

	self.battlePauseListener_ = cc.EventListenerCustom:create("BattlePause", function ()
		self._bm:pause()
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.battlePauseListener_, FixedPriority.kNormal)

	self.battleResumeListener_ = cc.EventListenerCustom:create("BattleResume", function ()
		self._bm:resume()
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.battleResumeListener_, FixedPriority.kNormal)

	self.talkListener_ = cc.EventListenerCustom:create("talk_over", function ()

		print("scene talk_over")

		if g_Player_Battle_Talk == 0 then
			self._bm:resume()
		end
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.talkListener_, FixedPriority.kNormal)

	self.guideActionListener_ = cc.EventListenerCustom:create("guideAction", function ()

		print("guideAction")

		self._bm:resume()
		-- self:getApp():removeTopView()

		g_guiding_can_skill = false
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.guideActionListener_, FixedPriority.kNormal)

	self.guideActionListener_ = cc.EventListenerCustom:create("SkillActive", function ()

		local guide 
		if guideManager:getSelfGuideID() ~= 0 then
			guide = guideManager:getSelfGuideID()
		else
			guide = player:getGuideStep() 
		end

		local big_id = guideManager:getTeshuGuideId(5)

		if guide < big_id and not g_guiding_can_skill then
			guideManager:createGuideLayer(big_id-1)
			g_guiding_can_skill = true
			self._bm:pause()
		end
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.guideActionListener_, FixedPriority.kNormal)
	self.specialGuide_ = cc.EventListenerCustom:create("special_guide", function (event)
		if guideManager:getShowGuide() and guideManager:getSelfGuideID()  == guideManager:getTeshuGuideId(5)-1 then
			-- self:getApp():removeTopView()
			guideManager:createGuideLayer(guideManager:getTeshuGuideId(5))
		end
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.specialGuide_, FixedPriority.kNormal)


end

function BattleScene:onExitTransitionStart()
	printInfo("BattleScene:onExitTransitionStart()")

	-- animManager:unregisterAnimById("Arrow", 1, "move")
	-- animManager:unregisterAnimById("Arrow", 1, "disappear")

	-- animManager:unregisterAnimById("NoxiousCloud", 1, "attack")

	-- cache:removeSpriteFramesFromFile("BattleScene/Bullet.plist")


	if schedulerEntry ~= nil then
		scheduler:unscheduleScriptEntry(schedulerEntry)
		schedulerEntry = nil
	end

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.battlePauseListener_)
	eventDispatcher:removeEventListener(self.battleResumeListener_)
	eventDispatcher:removeEventListener(self.guideActionListener_)
	eventDispatcher:removeEventListener(self.talkListener_)
	eventDispatcher:removeEventListener(self.specialGuide_)
end

function BattleScene:showSmallWeaponAction(  )
	local ship_id 
	for i,v in ipairs(CONF.PARAM.get("test_my_ship_list").PARAM) do
		if v ~= 0 then
			ship_id = v
			break
		end
	end

	local weapon_list = CONF.AIRSHIP.get(ship_id).WEAPON_LIST
	for i,v in ipairs(weapon_list) do
		local weapon = require("app.ExResInterface"):getInstance():FastLoad("Common/ItemNode_2.csb")
		weapon:getChildByName("background"):setTexture("RankLayer/ui_avatar_1.png")
		weapon:getChildByName("icon"):loadTexture("WeaponIcon/"..CONF.WEAPON.get(v).ICON_ID..".png")
		weapon:setPosition(cc.p(400,200))
		weapon:setScale(1.5)
		self:getResourceNode():addChild(weapon)

		weapon:setVisible(false)

		local spawn = cc.Spawn:create(cc.MoveTo:create(1,cc.p(self:getResourceNode():getChildByName("object_layer"):getChildByName("ship_1_6"):getPosition())), cc.ScaleTo:create(1,0))

		weapon:runAction(cc.Sequence:create(cc.DelayTime:create(0.5*(i-1)), cc.CallFunc:create(function ( ... )
			weapon:setVisible(true)
		end), spawn, cc.CallFunc:create(function ( ... )
			if i == #weapon_list then
				cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("BattleResume")
			end
		end)))
	end
end

function BattleScene:showSkillNameSfx( weaponConf )

	if weaponConf == nil then
		return
	end

	local ui = self:getResourceNode():getChildByName("ui_layer")

	local sfx = require("app.ExResInterface"):getInstance():FastLoad("BattleScene/SkillName.csb")

	sfx:getChildByName("node"):getChildByName("label_node"):getChildByName("name"):setString(CONF:getStringValue(weaponConf.NAME_ID))

	animManager:runAnimOnceByCSB( sfx, "BattleScene/SkillName.csb", "run", function ( )
		sfx:removeFromParent()
	end)

	ui:getChildByName("skill_name"):addChild(sfx)
end

function BattleScene:showHeroImage(resID)

	local function moveOK()
		
		self:getResourceNode():getChildByName("ui_layer"):removeChildByName("hero_layer")
		self._bm:resume()

		print("move ok !")
	end

	self._bm:pause()

	local layer = cc.LayerColor:create(cc.c4b( 16, 9, 2, 120))
	
	local winSize = cc.Director:getInstance():getWinSize()
	local diffSize = cc.size((CC_DESIGN_RESOLUTION.width - winSize.width)/2,(CC_DESIGN_RESOLUTION.height - winSize.height)/2)
	layer:setPosition(diffSize.width,diffSize.height)

	self:getResourceNode():getChildByName("ui_layer"):addChild(layer)

	layer:setName("hero_layer")

	local image = cc.Sprite:create(string.format("HeroImage/%d.png",resID))
	
	image:setPosition(cc.p(-image:getContentSize().width/2, CC_DESIGN_RESOLUTION.height/2))

	local move = cc.MoveTo:create(0.3,cc.p(image:getContentSize().width/3,CC_DESIGN_RESOLUTION.height/2 - 100))

	local callfunc = cc.CallFunc:create(moveOK)

	image:runAction(cc.Sequence:create( move, cc.DelayTime:create(0.3), callfunc))
	layer:addChild(image)

	local function onTouchBegan(touch, event)
		return true
	end

	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(true)
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, layer)
end

local EnergySfxTag = 120
function BattleScene:setEnergyPercentage( max, cur, orgPos )

	local ui = self:getResourceNode():getChildByName("ui_layer")

	local percentage = cur / max
	local progress = ui:getChildByName("energy_progress")
	local maxX = progress:getTag()

	local x = maxX*percentage

	local time = 0.5

	progress:stopAllActions()
	progress:runAction(mc.ContentSizeTo:create(time, x, progress:getContentSize().height))

	-- if orgPos ~= nil then
	-- 	if device.platform == "android" then
			-- local particle = cc.ParticleSystemQuad:create("particle_texture.plist") 
			-- --particle:setAutoRemoveOnFinish(true)
			-- particle:setTexture(cc.Director:getInstance():getTextureCache():addImage("particle_texture.png"))
			-- ui:addChild(particle)
			-- particle:setPosition(orgPos)
			-- local destPos = cc.p(progress:getPosition())
			-- destPos.x = destPos.x + x
			-- particle:runAction(cc.Sequence:create(cc.JumpTo:create(0.7, destPos, 150, 1), cc.RemoveSelf:create()))
	-- 	end
	-- end

	local energySfx = progress:getChildByName("sfx")
	if energySfx == nil then
		energySfx = require("app.ExResInterface"):getInstance():FastLoad("BattleScene/EnergySfx.csb")
		energySfx:setName("sfx")
		progress:addChild(energySfx)
		energySfx:setPositionY(progress:getContentSize().height*0.5)
		animManager:runAnimByCSB( energySfx, "BattleScene/EnergySfx.csb", "run")
	end
	energySfx:stopActionByTag(EnergySfxTag)
	if cur > 0 then
		energySfx:setVisible(true)
		local action = cc.MoveTo:create(time, cc.p(x, progress:getContentSize().height*0.5))
		action:setTag(EnergySfxTag)
		energySfx:runAction(action)
	else
		energySfx:setVisible(false)
	end

	local text = ui:getChildByName("energy_text")
	text:setString(string.format("%d", cur))
end


function BattleScene:setHpPercentage( group, max, cur, noSfx )

	local ui = self:getResourceNode():getChildByName("ui_layer")

	local progress = ui:getChildByName(string.format("role_hp_%d", group))
	local maxX = progress:getTag()

	if noSfx == nil or noSfx == false then
		local perPercentage = progress:getContentSize().width / maxX

		local sfx = ui:getChildByName(string.format("role_hp_sfx_%d", group))
		sfx:setPosition(progress:getPosition())
		sfx:setVisible(true)
		sfx:setOpacity(255)
		local sfxMaxX = sfx:getTag()
		sfx:setContentSize(cc.size(sfxMaxX*perPercentage, sfx:getContentSize().height))
		sfx:runAction(cc.Sequence:create(cc.DelayTime:create(0.7),cc.FadeTo:create(1, 0)))
	end

	local percentage = cur / max
	
	progress:stopAllActions()
	progress:runAction(mc.ContentSizeTo:create(0.5,maxX*percentage, progress:getContentSize().height))

	local text = ui:getChildByName(string.format("hp_text_%d", group))
	text:setString(string.format("%d", cur))
end

function BattleScene:highLightShipSfx( switch, list )
	
	local bulletLayer = self:getResourceNode():getChildByName("bullet_layer")

	local owner = bulletLayer:getChildByName("owner")
	local enemy = bulletLayer:getChildByName("enemy")

	if switch == true then

		-- ADD WJJ 20180731
		-- quan mian ping shi pei
		-- fixed_height mode, show full screen dark when big skill coming

		local grayLayer1 = cc.LayerColor:create(cc.c4b( 16, 9, 2, 200))
		-- local grayLayer1 = cc.LayerColor:create(cc.c4b( 0, 255, 255, 200))
		grayLayer1:setName("GrayLayer1")

		local grayLayer2 = cc.LayerColor:create(cc.c4b( 16, 9, 2, 200))
		-- local grayLayer2 = cc.LayerColor:create(cc.c4b( 255, 255, 0, 200))
		grayLayer2:setName("GrayLayer2")

		local winSize = cc.Director:getInstance():getWinSize()
		local diffSize = cc.size((CC_DESIGN_RESOLUTION.width - winSize.width)/2,(CC_DESIGN_RESOLUTION.height - winSize.height)/2)
		grayLayer1:setPosition(diffSize.width,diffSize.height)
		grayLayer2:setPosition(diffSize.width,diffSize.height)

		owner:addChild(grayLayer1, BattleZOrder.kSfxGrayLayer)
		enemy:addChild(grayLayer2, BattleZOrder.kSfxGrayLayer)

		for i,v in ipairs(list) do
			v:setHighLight(true)
		end
	else
		owner:removeChildByName("GrayLayer1")
		enemy:removeChildByName("GrayLayer2")
		for i,v in ipairs(list) do
			v:setHighLight(false)
		end
	end
end
print("###LUA DEBUG BattleScene.lua line 806")
return BattleScene