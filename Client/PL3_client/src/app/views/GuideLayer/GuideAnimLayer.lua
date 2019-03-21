
local FileUtils = cc.FileUtils:getInstance()

local VisibleRect = cc.exports.VisibleRect

local player = require("app.Player"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local GuideAnimLayer = class("GuideAnimLayer", cc.load("mvc").ViewBase)

GuideAnimLayer.RESOURCE_FILENAME = "GuideLayer/sfx/GuideAnimation/GuideAnimLayer.csb"
GuideAnimLayer.NEED_ADJUST_POSITION = true

local id = 1000001

function GuideAnimLayer:onCreate( data )
	self.data_ = data
end

function GuideAnimLayer:onEnterTransitionFinish()
	-- printInfo("GuideAnimLayer:onEnterTransitionFinish()")

	local animManager = require("app.AnimManager"):getInstance()
	local rn = self:getResourceNode()
	animManager:runAnimByCSB(rn:getChildByName("sfx"), "CityScene/sfx/star/star.csb", "1")
	-- printInfo("#### LUA runAnimOnceByCSB  ")
	animManager:runAnimOnceByCSB(rn, GuideAnimLayer.RESOURCE_FILENAME,  self.data_.anim, function ( ... )
		-- Added by Wei Jingjun 20180605
		-- printInfo("#### LUA runAnimOnceByCSB GuideAnimLayer.RESOURCE_FILENAME: " .. tostring(GuideAnimLayer.RESOURCE_FILENAME))
		-- printInfo("#### LUA runAnimOnceByCSB self.data_.anim: " .. tostring(self.data_.anim))
		if self.data_.anim == "1" then
			guideManager:createGuideLayer(3)
		elseif self.data_.anim == "2" then

			local strData = Tools.encode("PveReq", {
				checkpoint_id = id,
				type = 3,
			})
			-- printInfo("#### LUA runAnimOnceByCSB strData: " .. tostring(strData))
			-- printInfo("#### LUA Tools.enum_id: " .. tostring(Tools.enum_id("CMD_DEFINE","CMD_PVE_REQ")))
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PVE_REQ"),strData)

			gl:retainLoading()
		end
	end)

	rn:getChildByName("btn"):addClickEventListener(function ( ... )

		if self.data_.anim == "1" then
			guideManager:createGuideLayer(5)
		end
		self:removeFromParent()

	end)

	self.showListener_ = cc.EventListenerCustom:create("showBtn", function ()
		rn:getChildByName("btn"):setVisible(true)
		rn:getChildByName("sfx"):setVisible(true)

	end)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.showListener_, FixedPriority.kNormal)

	local function recvMsg()
		-- printInfo("GuideManager:recvMsg")

		local cmd,strData = GameHandler.handler_c.recvProtobuf()



		if cmd == Tools.enum_id("CMD_DEFINE","CMD_PVE_RESP") then
			-- Added by Wei Jingjun 20180605
			-- printInfo("#### LUA GuideManager:recvMsg : " .. tostring(Tools.enum_id("CMD_DEFINE","CMD_PVE_RESP")))
			-- printInfo("#### LUA GuideManager:recvMsg : " .. tostring(strData))

			gl:releaseLoading()

			local proto = Tools.decode("PveResp",strData)
			-- printInfo("#### LUA GuideManager:recvMsg proto.result: " .. tostring(proto.result))
			if proto.result == 2 then
					tips:tips(CONF:getStringValue("durable_not_enought"))

			elseif proto.result ~= 0 then
				print("error :",proto.result)
			else
					--存exp
				g_Player_OldExp.oldExp = 0
				g_Player_OldExp.oldExp = player:getNowExp()
				g_Player_OldExp.oldLevel = player:getLevel()

				--存stageInfo
				g_Views_config.copy_id = id
				-- g_Views_config.slPosX = self.data_.slPosX

				local name = CONF:getStringValue(CONF.CHECKPOINT.get(id).NAME_ID)
				local enemy_name = getEnemyIcon(CONF.CHECKPOINT.get(id).MONSTER_LIST)

				-- printInfo("#### LUA GuideManager:recvMsg CHECKPOINT name: " .. tostring(name))
				-- printInfo("#### LUA GuideManager:recvMsg CHECKPOINT enemy_name: " .. tostring(enemy_name))
				-- printInfo("#### LUA GuideManager:recvMsg CHECKPOINT Tools.decode: " .. tostring(Tools.decode("PveResp",strData)))
				print("@@@@ GO BATTLE in GuideAnimLayer 104")
				self:getApp():pushToRootView("BattleScene/BattleScene", {BattleType.kCheckPoint,Tools.decode("PveResp",strData),true,name,enemy_name})

			end
		end
	
	end

	self.recvListener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	eventDispatcher:addEventListenerWithFixedPriority(self.recvListener_, FixedPriority.kNormal)
end

function GuideAnimLayer:onExitTransitionStart()
	-- printInfo("GuideAnimLayer:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.showListener_)
	eventDispatcher:removeEventListener(self.recvListener_)

end

return GuideAnimLayer