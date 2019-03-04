
local FileUtils = cc.FileUtils:getInstance()

local player = require("app.Player"):getInstance()

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()

local ColonizeScene = class("ColonizeScene", cc.load("mvc").ViewBase)

ColonizeScene.RESOURCE_FILENAME = "ColonizeScene/ColonizeScene.csb"

ColonizeScene.RUN_TIMELINE = true

ColonizeScene.NEED_ADJUST_POSITION = true

ColonizeScene.RESOURCE_BINDING = {
}

function ColonizeScene:onCreate(data)
	self.data_ = data
end

function ColonizeScene:onEnter()
	
	printInfo("ColonizeScene:onEnter()")
end

function ColonizeScene:onExit()
	
	printInfo("ColonizeScene:onExit()")

end

function ColonizeScene:onEnterTransitionFinish()
	printInfo("ColonizeScene:onEnterTransitionFinish()")

	if g_System_Guide_Id ~= 0 then
		systemGuideManager:createGuideLayer(g_System_Guide_Id)
	end

	-- broadcastRun()
	local rn = self:getResourceNode()

	if self.data_.type == "enemy" then
		self.uiLayer_ = self:getApp():createView("ColonizeScene/EnemyLayer",{noRetain = self.data_ and self.data_.noRetain})
	elseif self.data_.type == "save" then
		self.uiLayer_ = self:getApp():createView("ColonizeScene/SaveFriendLayer",{noRetain = self.data_ and self.data_.noRetain})
	elseif self.data_.type == "slave" then
		self.uiLayer_ = self:getApp():createView("ColonizeScene/SlaveLayer",{noRetain = self.data_ and self.data_.noRetain})
	end

	self:addChild(self.uiLayer_)

	if self.data_.result then

		print("self.data_.result ",self.data_.result )

		local node = require("app.ExResInterface"):getInstance():FastLoad("SlaveScene/content.csb")
		node:getChildByName("confirm"):setString(CONF:getStringValue("yes"))

		if self.data_.type == "enemy" then
			if self.data_.result == "win" then

				if self.data_.isCatch then
					node:getChildByName("text"):setString(CONF:getStringValue("enslave_win_1")..self.data_.nickname..CONF:getStringValue("enslave_win_2"))
				else
					node:getChildByName("text"):setString(CONF:getStringValue("enslave_defeated_1")..self.data_.nickname..CONF:getStringValue("enslave_defeated_2"))
				end
			else
				node:getChildByName("text"):setString(CONF:getStringValue("enslave_defeated_1")..self.data_.nickname..CONF:getStringValue("enslave_defeated_2"))
			end
		elseif self.data_.type == "save" then
			if self.data_.result == "win" then
				node:getChildByName("text"):setString(CONF:getStringValue("save_gain"))
			else
				node:getChildByName("text"):setString(CONF:getStringValue("slave_over"))
			end
		elseif self.data_.type == "slave" then
			if self.data_.result == "win" then

				print("self.data_.isCatch ",self.data_.isCatch )

				if self.data_.isCatch then
					node:getChildByName("text"):setString(CONF:getStringValue("enslave_win_1")..self.data_.nickname..CONF:getStringValue("enslave_win_2"))
				else
					node:getChildByName("text"):setString(CONF:getStringValue("enslave_defeated_1")..self.data_.nickname..CONF:getStringValue("enslave_defeated_2"))
				end
			else
				node:getChildByName("text"):setString(CONF:getStringValue("enslave_defeated_1")..self.data_.nickname..CONF:getStringValue("enslave_defeated_2"))
			end
		end

		node:getChildByName("confirm_button"):addClickEventListener(function ( ... )
			node:removeFromParent()
		end)

		node:getChildByName("back"):addClickEventListener(function ( ... )
			node:removeFromParent()
		end)

		self:addChild(node)

		tipsAction(node)
	end

	local function recvMsg()
		print("ColonizeScene:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_UPDATE_SLAVE_DATA") then

			print("CMD_UPDATE_SLAVE_DATA")
			
			local strData = Tools.encode("SlaveSyncDataReq", {    
				type = 0,
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SLAVE_SYNC_DATA_REQ"),strData)

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_SLAVE_SYNC_DATA_RESP") then

			local proto = Tools.decode("SlaveSyncDataResp",strData)
			--print("SlaveSyncDataResp",proto.result)

			if proto.result ~= "OK" then
				print("error :",proto.result)
			else
				if player:getSlaveData().master == nil or player:getSlaveData().master == "" then

				else
					self:getApp():pushToRootView("SlaveScene/SlaveScene")
				end
			end

		end

	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)
end

function ColonizeScene:changeLayer( type )
	self.uiLayer_:removeFromParent()

	if type == "enemy" then
		self.uiLayer_ = self:getApp():createView("ColonizeScene/EnemyLayer")
	elseif type == "save" then
		self.uiLayer_ = self:getApp():createView("ColonizeScene/SaveFriendLayer")
	elseif type == "slave" then
		self.uiLayer_ = self:getApp():createView("ColonizeScene/SlaveLayer")
	end

	self.data_.type = type

	self:addChild(self.uiLayer_)
end

function ColonizeScene:onExitTransitionStart()
	printInfo("ColonizeScene:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)

	self.data_.result = nil
	self.data_ = nil
	
end

return ColonizeScene