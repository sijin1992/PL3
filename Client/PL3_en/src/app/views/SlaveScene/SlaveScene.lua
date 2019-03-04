
local FileUtils = cc.FileUtils:getInstance()

local player = require("app.Player"):getInstance()

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local SlaveScene = class("SlaveScene", cc.load("mvc").ViewBase)

SlaveScene.RESOURCE_FILENAME = "SlaveScene/SlaveScene.csb"

SlaveScene.RUN_TIMELINE = true

SlaveScene.NEED_ADJUST_POSITION = true

SlaveScene.RESOURCE_BINDING = {
}

function SlaveScene:onCreate(data)
	if data then
		self.data_ = data
	else
		self.data_ = nil
	end
end

function SlaveScene:onEnter()
	
	printInfo("SlaveScene:onEnter()")
end

function SlaveScene:onExit()
	
	printInfo("SlaveScene:onExit()")

end

function SlaveScene:onEnterTransitionFinish()
	printInfo("SlaveScene:onEnterTransitionFinish()")

	local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()
	-- if player:getSystemGuideStep(CONF.ESystemGuideInterFace.kSlave)== 0 and g_System_Guide_Id == 0 then
	-- 	systemGuideManager:createGuideLayer(CONF.FUNCTION_OPEN.get("slave_open").INTERFACE)
	-- else
		if g_System_Guide_Id ~= 0 then
			systemGuideManager:createGuideLayer(g_System_Guide_Id)
		end
	-- end

	-- broadcastRun()
	local rn = self:getResourceNode()

	-- local slave_data = player:getSlaveData()

	-- if slave_data ~= nil then
	-- 	if slave_data.master == nil or slave_data.master == "" then
	-- 		self.uiLayer_ = self:getApp():createView("SlaveScene/NoSlaveLayer")
	-- 	else
	-- 		self.uiLayer_ = self:getApp():createView("SlaveScene/SlaveLayer")
	-- 	end
	-- else
	-- 	self.uiLayer_ = self:getApp():createView("SlaveScene/NoSlaveLayer")
	-- end

	-- self:addChild(self.uiLayer_)

	local strData = Tools.encode("SlaveSyncDataReq", {    
		type = 0,
		-- user_name_list = {player:getName()} ,
	})
	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SLAVE_SYNC_DATA_REQ"),strData)
	if self.data_ and self.data_.noRetain then

	else

		gl:retainLoading()
	end


	local function showTips( ... )
		if self.data_ then
			if self.data_.result then

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

						if player:getNickName() == self.data_.nickname then
							node:getChildByName("text"):setString(CONF:getStringValue("duli_succeed"))
						else

							if self.data_.item_list ~= nil then
								if Tools.isEmpty(self.data_.item_list) then
									node:getChildByName("text"):setString(CONF:getStringValue("save_gain"))
								else
									node:getChildByName("text"):setString(CONF:getStringValue("save_gain")..CONF:getStringValue(CONF.ITEM.get(tonumber(self.data_.item_list[1].key)).NAME_ID)..self.data_.item_list[1].value)
								end
							end
						end
					else

						if player:getNickName() == self.data_.nickname then
							-- node:getChildByName("text"):setString(CONF:getStringValue("duli_succeed"))
						else
							node:getChildByName("text"):setString(CONF:getStringValue("slave_over"))
						end
						
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

				self:addChild(node,2)

				tipsAction(node)

			end
		end
	end

	showTips()


	local function recvMsg()
		print("SlaveScene:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_SLAVE_SYNC_DATA_RESP") then
			if self.data_ and self.data_.noRetain then
			else
				gl:releaseLoading()
			end

			local proto = Tools.decode("SlaveSyncDataResp",strData)
			--print("SlaveSyncDataResp",proto.result)

			if proto.result ~= "OK" then
				print("error :",proto.result)
			else
				-- self.slave_data_list = proto.slave_data_list
				-- self.slave_brief_info_list = proto.info_list

				-- self:resetInfo()

				if self.uiLayer_ == nil then

					local slave_data = player:getSlaveData()

					if slave_data ~= nil then
						if slave_data.master == nil or slave_data.master == "" then
							self.uiLayer_ = self:getApp():createView("SlaveScene/NoSlaveLayer")
						else
							self.uiLayer_ = self:getApp():createView("SlaveScene/SlaveLayer")
						end
					else
						self.uiLayer_ = self:getApp():createView("SlaveScene/NoSlaveLayer")
					end

					self:addChild(self.uiLayer_)

				end
			end
		end

	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

end

function SlaveScene:getSlave( ... )
	self.uiLayer_:removeFromParent()

	self.uiLayer_ = self:getApp():createView("SlaveScene/SlaveLayer")
	self:addChild(self.uiLayer_)
end

function SlaveScene:getNoSlave( ... )
	self.uiLayer_:removeFromParent()

	self.uiLayer_ = self:getApp():createView("SlaveScene/NoSlaveLayer")
	self:addChild(self.uiLayer_)
end

function SlaveScene:onExitTransitionStart()
	printInfo("SlaveScene:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)

	self.data_ = nil
	
end

return SlaveScene