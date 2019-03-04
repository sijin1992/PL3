
local FileUtils = cc.FileUtils:getInstance()

local player = require("app.Player"):getInstance()

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local tips = require("util.TipsMessage"):getInstance()

local SlaveLayer = class("SlaveLayer", cc.load("mvc").ViewBase)

SlaveLayer.RESOURCE_FILENAME = "SlaveScene/SlaveLayer.csb"

SlaveLayer.RUN_TIMELINE = true

SlaveLayer.NEED_ADJUST_POSITION = true

SlaveLayer.RESOURCE_BINDING = {
	["close"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

local schedulerEntry = nil

function SlaveLayer:OnBtnClick(event)
	if event.name == "ended" then
		if event.target:getName() == "close" then 
			playEffectSound("sound/system/return.mp3")
			-- self:getApp():popView()
			self:getApp():pushToRootView("HomeScene/HomeScene", {})
			
		end
	end
end

function SlaveLayer:onCreate(data)
	self.data_ = data
end

function SlaveLayer:onEnter()
	
	printInfo("SlaveLayer:onEnter()")
end

function SlaveLayer:onExit()
	
	printInfo("SlaveLayer:onExit()")

end

function SlaveLayer:updateData( ... )
	local strData = Tools.encode("SlaveSyncDataReq", {    
		type = 0,
	})
	
	g_sendList:addSend({define = "CMD_SLAVE_SYNC_DATA_REQ", strData = strData})

	gl:retainLoading()

	local strData = Tools.encode("SlaveSyncDataReq", {    
		type = 0,
		user_name_list = {player:getSlaveData().master} ,
	})
	g_sendList:addSend({define = "CMD_SLAVE_SYNC_DATA_REQ", strData = strData})

	gl:retainLoading()
end

function SlaveLayer:resetInfo( ... )

	if self.slave_brief_info_list == nil or self.slave_brief_info_list[1] == nil then
		return
	end

	local rn = self:getResourceNode()

	rn:getChildByName("zhuren_info"):setString(self.slave_brief_info_list[1].nickname)
	rn:getChildByName("level_num"):setString(self.slave_brief_info_list[1].level)
	rn:getChildByName("fight_num"):setString(self.slave_brief_info_list[1].power)

	local slave_data = player:getSlaveData()

	if slave_data.show_start_time > 0 then
		rn:getChildByName("sz_kuang_81"):setVisible(true)
		rn:getChildByName("sz_kuang_text"):setVisible(true)
		rn:getChildByName("sz_kuang_time"):setVisible(true)
		rn:getChildByName("taohao"):setVisible(false)
		rn:getChildByName("duli"):setVisible(false)
		rn:getChildByName("qiujiu"):setVisible(false)
		rn:getChildByName("taohao_time"):setVisible(false)
		rn:getChildByName("duli_time"):setVisible(false)
		rn:getChildByName("qiujiu_time"):setVisible(false)
	else
		rn:getChildByName("sz_kuang_81"):setVisible(false)
		rn:getChildByName("sz_kuang_text"):setVisible(false)
		rn:getChildByName("sz_kuang_time"):setVisible(false)
		rn:getChildByName("taohao"):setVisible(true)
		rn:getChildByName("duli"):setVisible(true)
		rn:getChildByName("qiujiu"):setVisible(true)
		rn:getChildByName("taohao_time"):setVisible(true)
		rn:getChildByName("duli_time"):setVisible(true)
		rn:getChildByName("qiujiu_time"):setVisible(true)

	end

	rn:getChildByName("info_di_text"):setString(formatTime(CONF.PARAM.get("slave_free_time").PARAM - (player:getServerTime() - slave_data.slaved_start_time) )..CONF:getStringValue("flee"))


	if slave_data.show_start_time == 0 then
		if slave_data.fawn_on_cd_start_time and slave_data.fawn_on_cd_start_time > 0 then
			rn:getChildByName("taohao_time"):setString(formatTime(CONF.PARAM.get("slave_fawn_on_cd").PARAM - (player:getServerTime() - slave_data.fawn_on_cd_start_time)))
			rn:getChildByName("taohao_time"):setVisible(true)
			rn:getChildByName("taohao"):setEnabled(false)

			if CONF.PARAM.get("slave_fawn_on_cd").PARAM - (player:getServerTime() - slave_data.fawn_on_cd_start_time) <= 0 then
				self:updateData()
			end

		else
			rn:getChildByName("taohao_time"):setVisible(false)
			rn:getChildByName("taohao"):setEnabled(true)
		end

		if slave_data.help_cd_start_time and slave_data.help_cd_start_time > 0 then
			rn:getChildByName("qiujiu_time"):setString(formatTime(CONF.PARAM.get("slave_help_cd").PARAM - (player:getServerTime() - slave_data.help_cd_start_time)))
			rn:getChildByName("qiujiu_time"):setVisible(true)
			rn:getChildByName("qiujiu"):setEnabled(false)

			if CONF.PARAM.get("slave_help_cd").PARAM - (player:getServerTime() - slave_data.help_cd_start_time) <= 0 then
				self:updateData()
			end
		else
			rn:getChildByName("qiujiu_time"):setVisible(false)
			rn:getChildByName("qiujiu"):setEnabled(true)
		end

		if slave_data.revolt_cd_start_time and slave_data.revolt_cd_start_time > 0 then
			rn:getChildByName("duli_time"):setString(formatTime(CONF.PARAM.get("slave_revolt_cd").PARAM - (player:getServerTime() - slave_data.revolt_cd_start_time)))
			rn:getChildByName("duli_time"):setVisible(true)
			rn:getChildByName("duli"):setEnabled(false)

			if CONF.PARAM.get("slave_revolt_cd").PARAM - (player:getServerTime() - slave_data.revolt_cd_start_time) <= 0 then
				self:updateData()
			end
		else
			rn:getChildByName("duli_time"):setVisible(false)
			rn:getChildByName("duli"):setEnabled(true)
		end
	end

	rn:getChildByName("sz_kuang_text"):setString(CONF:getStringValue("affiliation_describe"))
	rn:getChildByName("sz_kuang_time"):setString(formatTime(CONF.PARAM.get("slave_show_time").PARAM - (player:getServerTime() - slave_data.show_start_time)))

	

end

function SlaveLayer:createTipsNode( str )
	local node = require("app.ExResInterface"):getInstance():FastLoad("SlaveScene/content.csb")
	node:getChildByName("text"):setString(str)
	node:getChildByName("confirm"):setString(CONF:getStringValue("yes"))

	node:getChildByName("back"):addClickEventListener(function ( ... )
		node:removeFromParent()
	end)

	node:getChildByName("confirm_button"):addClickEventListener(function ( ... )
		playEffectSound("sound/system/click.mp3")

		node:removeFromParent()
	end)

	self:addChild(node)

	tipsAction(node)
end

function SlaveLayer:onEnterTransitionFinish()
	printInfo("SlaveLayer:onEnterTransitionFinish()")

	local strData = Tools.encode("SlaveSyncDataReq", {    
		type = 0,
		user_name_list = {player:getSlaveData().master} ,
	})
	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SLAVE_SYNC_DATA_REQ"),strData)
	gl:retainLoading()

	local strData = Tools.encode("GetChatLogReq", {

        chat_id = 0,
        -- minor = {3},
    })
    GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_CHAT_LOG_REQ"),strData)

	local rn = self:getResourceNode()

	rn:getChildByName("guize"):addClickEventListener(function ( ... )
		self:addChild(createIntroduceNode(CONF:getStringValue("slave_rule")))
	end)

	local userInfoNode = require("app.views.SlaveScene.UserInfoNode"):create()
	userInfoNode:init(self)
	userInfoNode:setName("userInfoNode")
	rn:getChildByName("info_node"):addChild(userInfoNode)

	local icon_id = math.floor(player:getPlayerIcon()/100)
	rn:getChildByName("role"):setTexture("HeroImage/"..icon_id..".png")

	rn:getChildByName("guize"):getChildByName("text"):setString(CONF:getStringValue("rule"))
	rn:getChildByName("text_info"):setString(CONF:getStringValue("affiliation_text"))
	rn:getChildByName("zhuren"):setString(CONF:getStringValue("host")..":")
	rn:getChildByName("level"):setString(CONF:getStringValue("level")..":")
	rn:getChildByName("fight"):setString(CONF:getStringValue("combat")..":")
	rn:getChildByName("taohao"):getChildByName("text"):setString(CONF:getStringValue("taohao"))
	rn:getChildByName("duli"):getChildByName("text"):setString(CONF:getStringValue("duli"))
	rn:getChildByName("qiujiu"):getChildByName("text"):setString(CONF:getStringValue("qiujiu"))
	rn:getChildByName("jiejiu"):getChildByName("text"):setString(CONF:getStringValue("rescue_partner"))
	rn:getChildByName("jilu"):getChildByName("text"):setString(CONF:getStringValue("settlement_record"))

	rn:getChildByName("zhuren_info"):setPositionX(rn:getChildByName("zhuren"):getPositionX() + rn:getChildByName("zhuren"):getContentSize().width + 5)
	rn:getChildByName("level_0"):setPositionX(rn:getChildByName("level"):getPositionX() + rn:getChildByName("level"):getContentSize().width + 5)
	rn:getChildByName("level_num"):setPositionX(rn:getChildByName("level_0"):getPositionX() + rn:getChildByName("level_0"):getContentSize().width)
	rn:getChildByName("fight_num"):setPositionX(rn:getChildByName("fight"):getPositionX() + rn:getChildByName("fight"):getContentSize().width + 5)

	rn:getChildByName("btn_chat"):addClickEventListener(function ( ... )
		playEffectSound("sound/system/click.mp3")

		local layer = self:getApp():createView("ChatLayer/ChatLayer", {name = "world"})
		layer:setName("chatLayer")
		self:addChild(layer)
	end)

	rn:getChildByName("chat_bottom"):addClickEventListener(function ( ... )
		playEffectSound("sound/system/click.mp3")

		local layer = self:getApp():createView("ChatLayer/ChatLayer", {name = "world"})
		layer:setName("chatLayer")
		self:addChild(layer)
	end)

	rn:getChildByName("taohao"):addClickEventListener(function ( ... )
		playEffectSound("sound/system/click.mp3")

		local strData = Tools.encode("SlaveFawnOnReq", {    
			type = 0,
		})
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SLAVE_FAWN_ON_REQ"),strData)
		gl:retainLoading()
	end)

	rn:getChildByName("qiujiu"):addClickEventListener(function ( ... )
		playEffectSound("sound/system/click.mp3")

		local strData = Tools.encode("SlaveHelpReq", {    
			type = 0,
		})
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SLAVE_HELP_REQ"),strData)
		gl:retainLoading()
	end)

	rn:getChildByName("duli"):addClickEventListener(function ( ... )
		playEffectSound("sound/system/click.mp3")

		self:getApp():addView2Top("NewFormLayer", {from = "slave", type = 2, user_name = player:getName(), name = self.slave_brief_info_list[1].nickname, icon_id = self.slave_brief_info_list[1].icon_id, layer = "save"})
	end)

	rn:getChildByName("jiejiu"):addClickEventListener(function ( ... )
		playEffectSound("sound/system/click.mp3")

		self:getApp():pushToRootView("ColonizeScene/ColonizeScene", {type = "save"})
	end)

	rn:getChildByName("jilu"):addClickEventListener(function ( ... )
		playEffectSound("sound/system/click.mp3")

		local note_node = require("app.ExResInterface"):getInstance():FastLoad("SlaveScene/SlaveNote.csb")
		note_node:setName("note_node")

		note_node:getChildByName("title"):setString(CONF:getStringValue("settlement_record"))

		note_node:getChildByName("close"):addClickEventListener(function ( ... )
			playEffectSound("sound/system/click.mp3")

			note_node:removeFromParent()
		end)

		local svd = require("util.ScrollViewDelegate"):create(note_node:getChildByName("list"),cc.size(0,2), cc.size(656,52))

		print("note", player:getSlaveData().note)

		for i,v in ipairs(player:getSlaveData().note) do
			local item = require("app.ExResInterface"):getInstance():FastLoad("SlaveScene/SlaveNoteItem.csb")

			local size = item:getChildByName("text"):getContentSize()

			local richText,string_len = createSlaveNote(20, v.type, v.text_index, v.param_list)

			richText:ignoreContentAdaptWithSize(false)  
			richText:setContentSize(cc.size(size.width,size.height))
			richText:setAnchorPoint(cc.p(0,1))

			richText:setPosition(cc.p(item:getChildByName("text"):getPosition()))

			item:addChild(richText)

			item:getChildByName("text"):removeFromParent()

			local ddd 
			if server_platform == 0 then
				ddd = 84 
			elseif server_platform == 1 then
				ddd = 55 
			end

			local canshu = math.ceil(string_len/ddd)
			local hhh = 14+24*canshu

			svd:addElement(item, {size = cc.size(656,hhh)})
		end

		svd:getScrollView():getInnerContainer():setPositionY(0)

		self:addChild(note_node)

		tipsAction(note_node)

	end)

	local function update(dt)
		self:resetInfo()
	end

	schedulerEntry = scheduler:scheduleScriptFunc(update,1,false)

	local function recvMsg()
		print("NoSlaveLayer:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_SLAVE_SYNC_DATA_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("SlaveSyncDataResp",strData)
			--print("SlaveSyncDataResp",proto.result)

			if proto.result ~= "OK" then
				print("error :",proto.result)
			else

				if player:getSlaveData().master == nil or player:getSlaveData().master == "" then

					self:getParent():getNoSlave()
					
				else

					if self:getChildByName("chatLayer") then


					else

						self.slave_data_list = proto.slave_data_list
						self.slave_brief_info_list = proto.info_list

						self:resetInfo()
					end
					
				end
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_SLAVE_HELP_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("SlaveHelpResp",strData)
			print("SlaveHelpResp",proto.result)

			if proto.result ~= "OK" then
				print("error :",proto.result)

				if proto.result == "SEND_LIST_EMPTY" then
					tips:tips(CONF:getStringValue("you_no_friend"))
				end

			else
				self:resetInfo()
				self:createTipsNode(CONF:getStringValue("qiujiu_success"))
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_SLAVE_FAWN_ON_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("SlaveFawnOnResp",strData)
			print("SlaveFawnOnResp",proto.result)

			if proto.result ~= "OK" then
				print("error :",proto.result)
			else
				local node = createSlaveNoteNode(24, proto.note_info.type, proto.note_info.text_index, proto.note_info.param_list)

				self:addChild(node)
				tipsAction(node)
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_UPDATE_SLAVE_DATA") then

			print("CMD_UPDATE_SLAVE_DATA")

			-- if player:getSlaveData().master ~= nil and player:getSlaveData().master ~= "" then
			-- 	self:resetInfo()
			-- else
			-- 	self:getParent():getSlave()
			-- end

			local strData = Tools.encode("SlaveSyncDataReq", {    
				type = 0,
				-- user_name_list = {player:getSlaveData().master} ,
			})
			g_sendList:addSend({define = "CMD_SLAVE_SYNC_DATA_REQ", strData = strData})
			gl:retainLoading()

			

			local strData = Tools.encode("SlaveSyncDataReq", {    
				type = 0,
				user_name_list = {player:getSlaveData().master} ,
			})
			g_sendList:addSend({define = "CMD_SLAVE_SYNC_DATA_REQ", strData = strData})
			gl:retainLoading()

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

end


function SlaveLayer:onExitTransitionStart()
	printInfo("SlaveLayer:onExitTransitionStart()")

	if schedulerEntry ~= nil then
		scheduler:unscheduleScriptEntry(schedulerEntry)
	end

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
	eventDispatcher:removeEventListener(self.msgListener_)
	
end

return SlaveLayer