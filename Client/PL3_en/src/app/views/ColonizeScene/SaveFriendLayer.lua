
local FileUtils = cc.FileUtils:getInstance()

local player = require("app.Player"):getInstance()

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local SaveFriendLayer = class("SaveFriendLayer", cc.load("mvc").ViewBase)

SaveFriendLayer.RESOURCE_FILENAME = "ColonizeScene/SaveFriendLayer.csb"

SaveFriendLayer.RUN_TIMELINE = true

SaveFriendLayer.NEED_ADJUST_POSITION = true

SaveFriendLayer.RESOURCE_BINDING = {
	["close"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

function SaveFriendLayer:OnBtnClick(event)
	if event.name == "ended" then
		if event.target:getName() == "close" then 
			playEffectSound("sound/system/return.mp3")
			-- self:getApp():popView()
			self:getApp():pushToRootView("SlaveScene/SlaveScene")
			
		end
	end
end

function SaveFriendLayer:onCreate(data)
	self.data_ = data
end

function SaveFriendLayer:onEnter()
	
	printInfo("SaveFriendLayer:onEnter()")
end

function SaveFriendLayer:onExit()
	
	printInfo("SaveFriendLayer:onExit()")

end

function SaveFriendLayer:resetStars( ... )
	local rn = self:getResourceNode()

	local stars = rn:getChildByName("star_node"):getChildByName("stars")

	for i=1,6 do
		stars:getChildByName("star_"..i):setVisible(true)
	end

	for i,v in ipairs(self.slave_brief_info_list) do

		if i > 6 then
			break
		end

		local star = stars:getChildByName("star_"..i):getChildByName("StarCard")

		star:getChildByName("level"):setString(v.level)
		star:getChildByName("name"):setString(v.nickname)
		star:getChildByName("head"):setTexture("HeroImage/"..v.icon_id..".png")
		star:getChildByName("fight_num"):setString(v.power)
		star:getChildByName("type"):setString(CONF:getStringValue("friend"))

		-- if v.slave_count > 0 then
		-- 	star:getChildByName("type"):setString(CONF:getStringValue("own_slave")..":"..v.slave_count)
		-- 	star:getChildByName("type"):setTextColor(cc.c4b(241,67,67,255))
		-- 	star:getChildByName("type"):enableShadow(cc.c4b(231,67,67,255), cc.size(0.5,0.5))
		-- else
		-- 	if v.master == nil or v.master == "" then
		-- 		star:getChildByName("type"):setString(CONF:getStringValue("free_man"))
		-- 	else
		-- 		star:getChildByName("type"):setString(CONF:getStringValue("affiliation")..":"..v.master)
		-- 		star:getChildByName("type"):setTextColor(cc.c4b(231,145,64,255))
		-- 		star:getChildByName("type"):enableShadow(cc.c4b(231,145,64,255), cc.size(0.5,0.5))
		-- 	end

		-- end

		star:getChildByName("touch"):addClickEventListener(function ( ... )
			playEffectSound("sound/system/click.mp3")
			-- self:getApp():pushView("newFormScene", {from = "slave", type = 2, user_name = v.user_name, name = v.nickname, icon_id = v.icon_id})
			self:createInfoNode(self.slave_brief_info_list[i])
		end)

	end

	if #self.slave_brief_info_list < 6 then
		for i=#self.slave_brief_info_list+1,6 do
			stars:getChildByName("star_"..i):setVisible(false)
		end
	end
end

function SaveFriendLayer:createInfoNode( info )

	local node = require("app.ExResInterface"):getInstance():FastLoad("SlaveScene/identity.csb")
	node:setName("slave_info_node")

	node:getChildByName("touxiang"):loadTexture("HeroImage/"..info.icon_id..".png")
	node:getChildByName("name"):setString(info.nickname)

	node:getChildByName("back"):addClickEventListener(function ( ... )
		node:removeFromParent()
	end)

	if info.slave_count > 0 then
		node:getChildByName("fight_num"):setString(CONF:getStringValue("host"))
		node:getChildByName("icon"):setTexture("Common/newUI/icon_ruler.png")
		node:getChildByName("icon_di"):setTexture("Common/newUI/icon_ruler_bottom.png")
	else
		if info.master == nil or info.master == "" then
			node:getChildByName("fight_num"):setString(CONF:getStringValue("free_man"))
			node:getChildByName("icon"):setTexture("Common/newUI/icon_free.png")
			node:getChildByName("icon_di"):setTexture("Common/newUI/icon_free_bottom.png")
		else
			node:getChildByName("fight_num"):setString(CONF:getStringValue("slave"))
			node:getChildByName("icon"):setTexture("Common/newUI/icon_slave.png")
			node:getChildByName("icon_di"):setTexture("Common/newUI/icon_slave_bottom.png")
		end
	end

	node:getChildByName("level"):setString(CONF:getStringValue("level")..":")
	node:getChildByName("level_num"):setString(info.level)

	node:getChildByName("LV"):setPositionX(node:getChildByName("level"):getPositionX() + node:getChildByName("level"):getContentSize().width + 5)
	node:getChildByName("level_num"):setPositionX(node:getChildByName("LV"):getPositionX() + node:getChildByName("LV"):getContentSize().width)

	node:getChildByName("zhandouli"):setString(CONF:getStringValue("combat")..":")
	node:getChildByName("zhandouli_num"):setString(info.power)

	node:getChildByName("zhandouli_num"):setPositionX(node:getChildByName("zhandouli"):getPositionX() + node:getChildByName("zhandouli"):getContentSize().width)

	node:getChildByName("league"):setString(CONF:getStringValue("covenant")..":")
	node:getChildByName("league_name"):setString(info.group_nickname)

	node:getChildByName("league_name"):setPositionX(node:getChildByName("league"):getPositionX() + node:getChildByName("league"):getContentSize().width)

	node:getChildByName("enslave_text"):setString(CONF:getStringValue("settlement_time"))

	if player:getSlaveData() ~= nil and player:getSlaveData().get_slaves_times ~= nil then
		node:getChildByName("enslave_quantity"):setString(player:getSlaveData().get_slaves_times)
	else
		node:getChildByName("enslave_quantity"):setString(0)
	end

	node:getChildByName("enslave_limit"):setString("/"..CONF.PARAM.get("slave_enslave_num").PARAM)

	node:getChildByName("enslave_quantity"):setPositionX(node:getChildByName("enslave_text"):getPositionX() + node:getChildByName("enslave_text"):getContentSize().width + 5)
	node:getChildByName("enslave_limit"):setPositionX(node:getChildByName("enslave_quantity"):getPositionX() + node:getChildByName("enslave_quantity"):getContentSize().width)

	node:getChildByName("enslave"):setString(CONF:getStringValue("rescue"))
	
	node:getChildByName("enslave_button"):addClickEventListener(function ( ... )
		playEffectSound("sound/system/click.mp3")

		if info.master == player:getName() then
			tips:tips(CONF:getStringValue("save_oneself"))
			return
		end

		if info.state == 2 then
			tips:tips(CONF:getStringValue("show"))
			return
		end

		if player:getSlaveData() and player:getSlaveData().get_slaves_times then

			if player:getSlaveData().get_save_times == 0 then

				local function func(  )
					if player:getMoney() < CONF.PARAM.get("enslave_coupon").PARAM*(player:getSlaveData().buy_get_save_times + 1) then
						-- tips:tips(CONF:getStringValue("no enought credit"))

						local function func()
							local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

							rechargeNode:init(self, {index = 1})
							self:addChild(rechargeNode)
						end

						local messageBox = require("util.MessageBox"):getInstance()
						messageBox:reset(CONF.STRING.get("no_credit_message").VALUE, func)
						return
					end

					local strData = Tools.encode("SlaveAddTimesReq", {
						type = 2,
					})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SLAVE_ADD_TIMES_REQ"),strData)
					
					gl:retainLoading()
				end

				local node = require("util.TipsNode"):createWithBuyNode(CONF:getStringValue("but_save"), CONF.PARAM.get("enslave_coupon").PARAM*(player:getSlaveData().buy_get_save_times + 1), func)

				self:addChild(node)
				tipsAction(node)
				return
			end

		end

		if info.master == nil or info.master == "" then
			self:getApp():addView2Top("NewFormLayer", {from = "slave", type = 2, user_name = info.user_name, name = info.nickname, icon_id = info.icon_id, layer = "save"})
		else
			self:getApp():addView2Top("NewFormLayer", {from = "slave", type = 2, user_name = info.user_name, name = info.master_nickname, icon_id = info.icon_id, layer = "save"})
		end
	end)

	node:getChildByName("Button_2"):addClickEventListener(function ( ... )
		playEffectSound("sound/system/click.mp3")

		local function func(  )
			if player:getMoney() < CONF.PARAM.get("enslave_coupon").PARAM*(player:getSlaveData().buy_get_save_times + 1) then
				-- tips:tips(CONF:getStringValue("no enought credit"))

				local function func()
					local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

					rechargeNode:init(self, {index = 1})
					self:addChild(rechargeNode)
				end

				local messageBox = require("util.MessageBox"):getInstance()
				messageBox:reset(CONF.STRING.get("no_credit_message").VALUE, func)
				return
			end

			local strData = Tools.encode("SlaveAddTimesReq", {
				type = 2,
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SLAVE_ADD_TIMES_REQ"),strData)
			
			gl:retainLoading()
		end

		local node = require("util.TipsNode"):createWithBuyNode(CONF:getStringValue("but_save"), CONF.PARAM.get("enslave_coupon").PARAM*(player:getSlaveData().buy_get_save_times + 1), func)

		self:addChild(node)
		tipsAction(node)
	end)

	self:addChild(node)

	tipsAction(node)

end

function SaveFriendLayer:onEnterTransitionFinish()
	printInfo("SaveFriendLayer:onEnterTransitionFinish()")

	local strData = Tools.encode("GetChatLogReq", {

        chat_id = 0,
        -- minor = {3},
    })
    GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_CHAT_LOG_REQ"),strData)

	local rn = self:getResourceNode()

	self.one_ = true

	local stars = require("app.ExResInterface"):getInstance():FastLoad("ColonizeScene/Stars.csb")
	stars:setName("stars")
	rn:getChildByName("star_node"):addChild(stars)

	animManager:runAnimOnceByCSB(stars, "ColonizeScene/Stars.csb", "0", function ( ... )
		animManager:runAnimByCSB(stars, "ColonizeScene/Stars.csb", "1")
	end)

	local userInfoNode = require("app.views.SlaveScene.UserInfoNode"):create()
	userInfoNode:init(self)
	userInfoNode:setName("userInfoNode")
	rn:getChildByName("info_node"):addChild(userInfoNode)

	rn:getChildByName("my_slave"):setString(CONF:getStringValue("rescue_partner"))
	rn:getChildByName("my_slave_ins"):setString(CONF:getStringValue("rescue_describe"))

	-- rn:getChildByName("guize"):getChildByName("text"):setString(CONF:getStringValue("rule"))

	rn:getChildByName("shuaxin_text"):setString(CONF:getStringValue("shuaxin"))

	rn:getChildByName("you"):getChildByName("taofa"):setString(CONF:getStringValue("rescue_time"))

	rn:getChildByName("you"):getChildByName("tf_num"):setString(player:getSlaveData().get_save_times.."/"..CONF.PARAM.get("slave_save_num").PARAM)

	local pp = player:getSlaveData().get_save_times/CONF.PARAM.get("slave_save_num").PARAM
	if pp > 1 then
		pp = 1
	end
	rn:getChildByName("you"):getChildByName("progress"):setContentSize(cc.size(math.floor(pp*100),18))

	rn:getChildByName("you"):getChildByName("strength_add"):addClickEventListener(function ( ... )
		playEffectSound("sound/system/click.mp3")

		if player:getSlaveData() and player:getSlaveData().get_save_times then

			-- if player:getSlaveData().get_save_times < CONF.PARAM.get("slave_save_num").PARAM then

				local function func(  )
					if player:getMoney() < CONF.PARAM.get("enslave_coupon").PARAM*(player:getSlaveData().buy_get_save_times + 1) then
						-- tips:tips(CONF:getStringValue("no enought credit"))

						local function func()
							local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

							rechargeNode:init(self, {index = 1})
							self:addChild(rechargeNode)
						end

						local messageBox = require("util.MessageBox"):getInstance()
						messageBox:reset(CONF.STRING.get("no_credit_message").VALUE, func)
						return
					end

					local strData = Tools.encode("SlaveAddTimesReq", {
						type = 2,
					})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SLAVE_ADD_TIMES_REQ"),strData)
					
					gl:retainLoading()
				end

				local node = require("util.TipsNode"):createWithBuyNode(CONF:getStringValue("but_save"), CONF.PARAM.get("enslave_coupon").PARAM*(player:getSlaveData().buy_get_save_times + 1), func)

				self:addChild(node)
				tipsAction(node)
				return
			-- end

		end

	end)

	rn:getChildByName("btn_chat"):addClickEventListener(function ( ... )
		playEffectSound("sound/system/click.mp3")

		local layer = self:getApp():createView("ChatLayer/ChatLayer", {name = "world"})
		self:addChild(layer)
	end)

	rn:getChildByName("chat_bottom"):addClickEventListener(function ( ... )
		playEffectSound("sound/system/click.mp3")

		local layer = self:getApp():createView("ChatLayer/ChatLayer", {name = "world"})
		self:addChild(layer)
	end)

	local function click_Callback( sender, eventType )
		if eventType == ccui.TouchEventType.began then 
			playEffectSound("sound/system/click.mp3")

			rn:getChildByName(sender:getName().."_di"):setTexture("StarOccupationLayer/ui/gn_case_light.png")
			playEffectSound("sound/system/click.mp3")
		elseif eventType == ccui.TouchEventType.ended then 
			rn:getChildByName(sender:getName().."_di"):setTexture("StarOccupationLayer/ui/gn_case.png")

			if sender:getName() == "duo" then

			elseif sender:getName() == "shuaxin" then
				local strData = Tools.encode("SlaveSearchReq", {    
					type = 3,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SLAVE_SEARCH_REQ"),strData)
				if self.data_ and self.data_.noRetain then
				else
					gl:retainLoading()
				end
			end
		elseif eventType == ccui.TouchEventType.canceled then 
			rn:getChildByName(sender:getName().."_di"):setTexture("StarOccupationLayer/ui/gn_case.png")

		end
	end

	-- rn:getChildByName("duo"):addTouchEventListener(click_Callback)
	rn:getChildByName("shuaxin"):addTouchEventListener(click_Callback)

	local strData = Tools.encode("SlaveSearchReq", {    
		type = 3,
	})
	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SLAVE_SEARCH_REQ"),strData)
	if self.data_ and self.data_.noRetain then
	else
		gl:retainLoading()
	end
	local function recvMsg()
		print("SaveFriendLayer:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_SLAVE_SEARCH_RESP") then
			if self.data_ and self.data_.noRetain then
			else
				gl:releaseLoading()
			end
			local proto = Tools.decode("SlaveSearchResp",strData)
			print("SlaveSearchResp",proto.result)

			if proto.result == "EMPTY" then
				self.slave_brief_info_list = proto.info_list

				if self.one_ == false then
					animManager:runAnimOnceByCSB(stars, "ColonizeScene/Stars.csb", "2", function ( ... )
						animManager:runAnimByCSB(stars, "ColonizeScene/Stars.csb", "1")
					end)
				end

				self.one_ = false

				self:resetStars()

				rn:getChildByName("empty"):setVisible(true)
				rn:getChildByName("empty"):getChildByName("text"):setString(CONF:getStringValue("no_save_text"))
				rn:getChildByName("empty"):getChildByName("konque_line_4"):setPositionX(0-((rn:getChildByName("empty"):getChildByName("text"):getContentSize().width + 22)/2))
				rn:getChildByName("empty"):getChildByName("konque_line_4_0"):setPositionX((rn:getChildByName("empty"):getChildByName("text"):getContentSize().width + 22)/2)
			elseif proto.result ~= "OK" then
				print("error :",proto.result)
			else

				if self.one_ == false then
					animManager:runAnimOnceByCSB(stars, "ColonizeScene/Stars.csb", "2", function ( ... )
						animManager:runAnimByCSB(stars, "ColonizeScene/Stars.csb", "1")
					end)
				end

				self.one_ = false

				self.slave_brief_info_list = proto.info_list

				self:resetStars()
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_SLAVE_ADD_TIMES_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("SlaveAddTimesResp",strData)

			if proto.result ~= "OK" then
				print("error :",proto.result)
			else
				
				rn:getChildByName("you"):getChildByName("tf_num"):setString(player:getSlaveData().get_save_times.."/"..CONF.PARAM.get("slave_save_num").PARAM)
				local pp = player:getSlaveData().get_save_times/CONF.PARAM.get("slave_save_num").PARAM
				if pp > 1 then
					pp = 1
				end
				rn:getChildByName("you"):getChildByName("progress"):setContentSize(cc.size(math.floor(pp*100),18))
				
				if self:getChildByName("slave_info_node") then
					self:getChildByName("slave_info_node"):getChildByName("enslave_quantity"):setString(player:getSlaveData().get_save_times)
				end
	
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_CHAT_LOG_RESP") then

            local proto = Tools.decode("GetChatLogResp",strData)
            if proto.result < 0 then
                print("error :",proto.result)
            else

                if #proto.log_list > 0 then
	                local time = 0
					local str = ""
					local tt 

					for i,v in ipairs(proto.log_list) do
						if v.stamp > time then
							if v.user_name ~= "0" and not player:isBlack(v.user_name) then
								time = v.stamp

								local strc = ""
								if v.group_name ~= "" then
									strc = string.format("[%s]%s:", v.group_name, v.nickname)
								else
									strc = string.format("%s:", v.nickname)
								end
								str = handsomeSubString(strc..v.chat, CONF.PARAM.get("chat number").PARAM)

								tt = {user_name = v.user_name, chat = v.chat, time = v.stamp}
							end
						end
					end

	                rn:getChildByName("di_text"):setString(str)
	            end

            end
		end
	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

	self.msgListener_ = cc.EventListenerCustom:create("slaveMsg", function (event)
		playEffectSound("sound/system/message_update.mp3")

		local strData = Tools.encode("GetChatLogReq", {

	        chat_id = 0,
	        minor = {3},
	    })
	    GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_CHAT_LOG_REQ"),strData)

	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.msgListener_, FixedPriority.kNormal)
    require("util.ExConfigScreenAdapter"):getInstance():onFixQuanmianping_SaveFriend(self)
end



function SaveFriendLayer:onExitTransitionStart()
	printInfo("SaveFriendLayer:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
	eventDispatcher:removeEventListener(self.msgListener_)
	
end

return SaveFriendLayer