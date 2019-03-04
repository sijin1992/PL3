local g_player = require("app.Player"):getInstance()

local Tips = require("util.TipsMessage"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local ArenaTitleLayer = class("ArenaTitleLayer", cc.load("mvc").ViewBase)

ArenaTitleLayer.RESOURCE_FILENAME = "ArenaScene/ArenaTitleLayer.csb"
ArenaTitleLayer.NEED_ADJUST_POSITION = true

ArenaTitleLayer.RESOURCE_BINDING = {
	["close"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
	["upgrade"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

function ArenaTitleLayer:OnBtnClick(event)
	if event.name == "ended" then

		if event.target:getName() == "close" then
			playEffectSound("sound/system/return.mp3")
			self:getApp():removeTopView() 
		elseif event.target:getName() == "upgrade" then
			playEffectSound("sound/system/click.mp3")
			local arena_data = g_player:getArenaData()
			local next_conf = CONF.ARENATITLE.check(arena_data.title_level+1)
			if next_conf then
				local next_conf = CONF.ARENATITLE.get(arena_data.title_level+1)
				if arena_data.honour_point < next_conf.NEED_HONOUR then
					Tips:tips(CONF:getStringValue("no enough honor"))
					return
				end

				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ARENA_TITLE_REQ"),Tools.encode("ArenaTitleReq", {
					type = 1,
				}))
				gl:retainLoading()
			end
		end
	end
end

function ArenaTitleLayer:resetTitle( title_level )

	local rn = self:getResourceNode()

	local conf = CONF.ARENATITLE.check(title_level)

	rn:getChildByName("cur_frame"):getChildByName("attr_org"):removeAllChildren()
	self.list1:clear()
	self.list2:clear()
	if title_level > 0 then
		
		rn:getChildByName("no_cur"):setVisible(false)
		rn:getChildByName("cur_frame"):setVisible(true)

		rn:getChildByName("cur_frame"):getChildByName("name"):setString(CONF:getStringValue("ARENA_TITLE_"..title_level))

		for i,key in ipairs(conf.ATTR_KEY) do
			local node = require("app.ExResInterface"):getInstance():FastLoad("ArenaScene/ArenaTitleAttr.csb")
			animManager:runAnimOnceByCSB(node,"ArenaScene/ArenaTitleAttr.csb" ,"cur")

			node:getChildByName("attr"):setString(CONF:getStringValue("Attr_"..key)..": ")

			local attrsize = node:getChildByName("attr"):getAutoRenderSize()

			node:getChildByName("cur"):setString(string.format("+%d",conf.ATTR_VALUE[i]))
			node:getChildByName("cur"):setPosition(attrsize.width,node:getChildByName("attr"):getPositionY())
			-- node:setPosition(cc.p(0, -30*(i-1)))
			-- rn:getChildByName("cur_frame"):getChildByName("attr_org"):addChild(node)
			self.list1:addElement(node)
		end
	else
		rn:getChildByName("cur_frame"):setVisible(false)
		rn:getChildByName("no_cur"):setVisible(true)
	end

	local honour = g_player:getArenaHonour()

	rn:getChildByName("next_frame"):getChildByName("attr_org"):removeAllChildren()

	if (title_level + 1) == CONF.ARENATITLE.len then

		rn:getChildByName("next_frame"):setVisible(false)
		-- rn:getChildByName("cur_num"):setVisible(false)
		-- rn:getChildByName("all_num"):setVisible(false)
		local Conf = CONF.ARENATITLE.get(title_level)
		rn:getChildByName("cur_num"):setString(string.format("%d", honour))
		rn:getChildByName("all_num"):setString("/"..tostring(Conf.NEED_HONOUR))
		rn:getChildByName("no_next"):setVisible(true)

		rn:getChildByName("progress"):setPercent(100)
		local sprite = cc.Sprite:create("StarLeagueScene/ui/MAX.png")
		sprite:setPosition(rn:getChildByName("upgrade"):getPosition())
		rn:addChild(sprite)
		rn:getChildByName("upgrade"):setVisible(false)
	else

		rn:getChildByName("next_frame"):setVisible(true)
		rn:getChildByName("cur_num"):setVisible(true)
		rn:getChildByName("all_num"):setVisible(true)

		rn:getChildByName("no_next"):setVisible(false)

		rn:getChildByName("next_frame"):getChildByName("name"):setString(CONF:getStringValue("ARENA_TITLE_"..title_level+1))
		
		local nextConf = CONF.ARENATITLE.check(title_level + 1)
		if nextConf then
			local nextConf = CONF.ARENATITLE.get(title_level + 1)
			rn:getChildByName("cur_num"):setString(string.format("%d", honour))
			rn:getChildByName("all_num"):setString("/"..tostring(nextConf.NEED_HONOUR))
		
			rn:getChildByName("progress"):setPercent(honour / nextConf.NEED_HONOUR * 100)

			for i,key in ipairs(nextConf.ATTR_KEY) do
				local node = require("app.ExResInterface"):getInstance():FastLoad("ArenaScene/ArenaTitleAttr.csb")
				animManager:runAnimOnceByCSB(node,"ArenaScene/ArenaTitleAttr.csb" ,"next")
				
				node:getChildByName("attr"):setString(CONF:getStringValue("Attr_"..key)..":  ")

				local attrsize = node:getChildByName("attr"):getAutoRenderSize()

				node:getChildByName("next"):setString(string.format("+%d",nextConf.ATTR_VALUE[i]))
				node:getChildByName("next"):setPosition(attrsize.width,node:getChildByName("attr"):getPositionY())

				-- node:setPosition(cc.p(0, -30*(i-1)))
				-- rn:getChildByName("next_frame"):getChildByName("attr_org"):addChild(node)
				self.list2:addElement(node)
			end
		end
	end
end

function ArenaTitleLayer:onEnterTransitionFinish()
	printInfo("ArenaTitleLayer:onEnterTransitionFinish()")

	if g_System_Guide_Id ~= 0 then
			systemGuideManager:createGuideLayer(g_System_Guide_Id)
		end

	local rn = self:getResourceNode()

	rn:getChildByName("sfx"):setVisible(false)

	rn:getChildByName("title"):setString(CONF:getStringValue("arena_title"))
	rn:getChildByName("cur_frame"):getChildByName("title"):setString(CONF:getStringValue("cur_title"))
	rn:getChildByName("next_frame"):getChildByName("title"):setString(CONF:getStringValue("next_title"))
	rn:getChildByName("upgrade"):getChildByName("text"):setString(CONF:getStringValue("title_upgrade"))

	rn:getChildByName("no_cur"):setString(CONF:getStringValue("no_title"))

	rn:getChildByName("no_next"):setString(CONF:getStringValue("notOpen"))
	self.list1 = require("util.ScrollViewDelegate"):create(rn:getChildByName("cur_frame"):getChildByName("list"),cc.size(3,3), cc.size(194,30))
	self.list2 = require("util.ScrollViewDelegate"):create(rn:getChildByName("next_frame"):getChildByName("list"),cc.size(3,3), cc.size(194,30))
	rn:getChildByName("cur_frame"):getChildByName("list"):setScrollBarEnabled(false)
	rn:getChildByName("next_frame"):getChildByName("list"):setScrollBarEnabled(false)

	local arena_data = g_player:getArenaData()
	self:resetTitle(arena_data.title_level)
	local next_conf = CONF.ARENATITLE.check(arena_data.title_level+1)
	if next_conf == nil then
		rn:getChildByName("upgrade"):setVisible(false)
	end

	local function onTouchBegan(touch, event)
		
		return true
	end

	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(true)
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)

	local function recvMsg()
		print("ArenaTitleLayer:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_ARENA_TITLE_RESP") then
			gl:releaseLoading()
			local proto = Tools.decode("ArenaTitleResp",strData)

			if proto.result ~= 0 then
				return
			end
			playEffectSound("sound/system/upgrade_skill.mp3")
			local arena_data = g_player:getArenaData()
			self:resetTitle(arena_data.title_level)
			Tips:tips(CONF:getStringValue("title_upgrade_success"))
			rn:getChildByName("sfx"):setVisible(true)
			animManager:runAnimOnceByCSB( rn:getChildByName("sfx"), "ArenaScene/sfx/jinsheng.csb", "1", function ()
				rn:getChildByName("sfx"):setVisible(false)
			end)
		end

	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)
end

function ArenaTitleLayer:onExitTransitionStart()
	printInfo("ArenaTitleLayer:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
end

return ArenaTitleLayer