
local FileUtils = cc.FileUtils:getInstance()

local player = require("app.Player"):getInstance()

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local NoSlaveLayer = class("NoSlaveLayer", cc.load("mvc").ViewBase)

NoSlaveLayer.RESOURCE_FILENAME = "SlaveScene/NoSlaveLayer.csb"

NoSlaveLayer.RUN_TIMELINE = true

NoSlaveLayer.NEED_ADJUST_POSITION = true

NoSlaveLayer.RESOURCE_BINDING = {
	["close"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

local schedulerEntry = nil

function NoSlaveLayer:OnBtnClick(event)
	if event.name == "ended" then
		if event.target:getName() == "close" then 
			playEffectSound("sound/system/return.mp3")
			-- self:getApp():popView()
			self:getApp():pushToRootView("HomeScene/HomeScene", {})
			
		end
	end
end

function NoSlaveLayer:onCreate(data)
	self.data_ = data
end

function NoSlaveLayer:onEnter()
	
	printInfo("NoSlaveLayer:onEnter()")
end

function NoSlaveLayer:onExit()
	
	printInfo("NoSlaveLayer:onExit()")

end

function NoSlaveLayer:createSlaveNode( slave_data, slave_brief_info, res, exp, index, isAction ) --1.slave_data 2.SlaveBriefInfo
	local node = require("app.ExResInterface"):getInstance():FastLoad("SlaveScene/SlaveNode.csb")

	node:setName("slave_node")
	node:setTag(index)

	node:getChildByName("back"):setSwallowTouches(true)
	node:getChildByName("close"):addClickEventListener(function ( ... )
		playEffectSound("sound/system/click.mp3")

		node:removeFromParent()
	end)

	node:getChildByName("head"):setTexture("HeroImage/"..slave_brief_info.icon_id..".png")
	node:getChildByName("name"):setString(slave_brief_info.nickname)

	local shifang_time = CONF.PARAM.get("slave_free_time").PARAM - (player:getServerTime() - slave_data.slaved_start_time)
	node:getChildByName("info_di_text"):setString(formatTime(shifang_time)..CONF:getStringValue("end_release"))

	node:getChildByName("level"):setString(CONF:getStringValue("level")..":")
	node:getChildByName("level_num"):setString(slave_brief_info.level)

	node:getChildByName("fight"):setString(CONF:getStringValue("combat")..":")
	node:getChildByName("fight_num"):setString(slave_brief_info.power)

	node:getChildByName("group"):setString(CONF:getStringValue("covenant")..":")
	node:getChildByName("group_info"):setString(slave_brief_info.group_nickname)

	node:getChildByName("shouqu"):getChildByName("text"):setString(CONF:getStringValue("may_take"))
	node:getChildByName("shifang"):getChildByName("text"):setString(CONF:getStringValue("release"))

	node:getChildByName("shifang"):addClickEventListener(function ( ... )
		playEffectSound("sound/system/click.mp3")

		if slave_data.show_start_time > 0 then
			local function func()
				local strData = Tools.encode("SlaveFreeReq", {    
					type = 1,
					slave_name =  slave_data.user_name,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SLAVE_FREE_REQ"),strData)
				gl:retainLoading()
			end

			local messageBox = require("util.MessageBox"):getInstance()
			messageBox:reset(slave_brief_info.nickname..CONF:getStringValue("show_text_1"), func)
		else
			local function func()
				local strData = Tools.encode("SlaveFreeReq", {    
					type = 1,
					slave_name =  slave_data.user_name,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SLAVE_FREE_REQ"),strData)
				gl:retainLoading()
			end

			local messageBox = require("util.MessageBox"):getInstance()
			messageBox:reset(CONF.STRING.get("release_text_1").VALUE..slave_brief_info.nickname..CONF:getStringValue("release_text_2"), func)
		end
	end)

	if slave_data.get_res_start_time > 0 then
		node:getChildByName("shouqu_time"):setString(formatTime(CONF.PARAM.get("slave_get_res_cd").PARAM - (player:getServerTime() - slave_data.get_res_start_time)))
		node:getChildByName("shouqu_time"):setVisible(true)
		node:getChildByName("shouqu"):setEnabled(false)
	else
		-- node:getChildByName("shouqu_time"):setString(formatTime(CONF.PARAM.get("slave_get_res_cd").PARAM - (player:getServerTime() - slave_data.get_res_start_time)))
		node:getChildByName("shouqu_time"):setVisible(false)
		node:getChildByName("shouqu"):setEnabled(true)
	end

	node:getChildByName("shouqu"):addClickEventListener(function ( ... )
		playEffectSound("sound/system/click.mp3")

		if slave_data.get_res_start_time > 0 then
			return
		end

		self.get_res_name = slave_data.user_name
		self.get_res_type = 2

		local strData = Tools.encode("SlaveGetResReq", {    
			type = 2,
			slave_name =  slave_data.user_name,
		})
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SLAVE_GET_RES_REQ"),strData)
		gl:retainLoading()
	end)

    local maxlist = {}
    maxlist[1] = CONF.PLAYERLEVEL.get(player:getLevel()).SLAVE_EXP
    maxlist[2] = CONF.PLAYERLEVEL.get(player:getLevel()).SLAVE_RESOURCE_2
    maxlist[3] = CONF.PLAYERLEVEL.get(player:getLevel()).SLAVE_RESOURCE_3
    maxlist[4] = CONF.PLAYERLEVEL.get(player:getLevel()).SLAVE_RESOURCE_4

    for i = 1 ,4 do
        local uiProgress = node:getChildByName("res_jd_"..i)
--        local progress_ = require('util.ScaleProgressDelegate'):create(uiProgress, uiProgress:getTag())
--        progress_:setPercentage(0)
        if i == 1 then
            node:getChildByName("res_now_num_1"):setString(exp)
            node:getChildByName("res_max_num_1"):setString("/"..maxlist[i])
            local per = (exp/maxlist[i] >= 1 and {1} or {exp/maxlist[i]})[1]
            uiProgress:setScaleX(per)
        else
            node:getChildByName("res_now_num_"..i):setString(res[i])
            node:getChildByName("res_max_num_"..i):setString("/"..maxlist[i])
            local per = (res[i]/maxlist[i] >= 1 and {1} or {res[i]/maxlist[i]})[1]
            uiProgress:setScaleX(per)
        end
    end

	if slave_data.state == 1 then --正常
		local policy = require("app.ExResInterface"):getInstance():FastLoad("SlaveScene/SlaveNoPolicy.csb")

		policy:getChildByName("shizhong_text"):setString(CONF:getStringValue("nonactivated"))
		policy:getChildByName("ins"):setString(CONF:getStringValue("show_describe"))
		policy:getChildByName("use"):setString(CONF:getStringValue("Cost"))
		policy:getChildByName("money_num"):setString(CONF.PARAM.get("slave_show_money").PARAM)
		policy:getChildByName("work"):getChildByName("text"):setString(CONF:getStringValue("job"))

		-- policy:getChildByName("use"):setPositionY(policy:getChildByName("ins"):getPositionY() - policy:getChildByName("ins"):getContentSize().height - 5)
		-- policy:getChildByName("use"):setPositionY(policy:getChildByName("ins"):getPositionY() - policy:getChildByName("ins"):getContentSize().height - 5)
		-- policy:getChildByName("use"):setPositionY(policy:getChildByName("ins"):getPositionY() - policy:getChildByName("ins"):getContentSize().height - 5)

		policy:getChildByName("jihuo"):getChildByName("text"):setString(CONF:getStringValue("activate"))
		policy:getChildByName("tips"):setString(CONF:getStringValue("work"))
		policy:getChildByName("work_time"):setString(formatTime(CONF.PARAM.get("slave_work_cd").PARAM - (player:getServerTime() - slave_data.work_cd_start_time)))
		policy:getChildByName("work_time"):setPositionX(policy:getChildByName("tips"):getPositionX() + policy:getChildByName("tips"):getContentSize().width + 5)

		if slave_data.work_cd_start_time == nil or slave_data.work_cd_start_time == 0 then
			policy:getChildByName("tips"):setVisible(false)
			policy:getChildByName("work_time"):setVisible(false)

			policy:getChildByName("work"):setEnabled(true)
		else
			policy:getChildByName("tips"):setVisible(true)
			policy:getChildByName("work_time"):setVisible(true)

			policy:getChildByName("work"):setEnabled(false)
		end

		policy:getChildByName("work"):addClickEventListener(function ( ... )
			playEffectSound("sound/system/click.mp3")

			local strData = Tools.encode("SlaveWorkReq", {    
				slave_name =  slave_data.user_name,
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SLAVE_WORK_REQ"),strData)
			gl:retainLoading()

		end)

		policy:getChildByName("jihuo"):addClickEventListener(function ( ... )
			playEffectSound("sound/system/click.mp3")

			local node = require("app.ExResInterface"):getInstance():FastLoad("SlaveScene/Show_consume.csb")

			node:getChildByName("back"):addClickEventListener(function ( ... )
				node:removeFromParent()
			end)

			node:getChildByName("confirm"):setString(CONF:getStringValue("yes"))
			node:getChildByName("cancel"):setString(CONF:getStringValue("cancel"))

			node:getChildByName("cancel_Button"):addClickEventListener(function ( ... )
				playEffectSound("sound/system/click.mp3")

				node:removeFromParent()
			end)

			node:getChildByName("confirm_button"):addClickEventListener(function ( ... )
				playEffectSound("sound/system/click.mp3")

				node:removeFromParent()

				if player:getMoney() < CONF.PARAM.get("slave_show_money").PARAM then

					local function func()
						local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

						rechargeNode:init(self, {index = 1})
						self:addChild(rechargeNode)
					end

					local messageBox = require("util.MessageBox"):getInstance()
					messageBox:reset(CONF.STRING.get("no_credit_message").VALUE, func)
					return
				end

				local strData = Tools.encode("SlaveShowReq", {    
					type = 1,
					slave_name =  slave_data.user_name,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SLAVE_SHOW_REQ"),strData)
				gl:retainLoading()

			end)

			local fontName = s_default_font

			local fontSize = node:getChildByName("text"):getFontSize()

			local size = node:getChildByName("text"):getContentSize()

			local richText = ccui.RichText:create()
			richText:ignoreContentAdaptWithSize(false)  
			-- richText:setMaxLineWidth(200)
			richText:setContentSize(cc.size(size.width,size.height))
			richText:setAnchorPoint(cc.p(0,1))

			local re1 = ccui.RichElementText:create( 1, cc.c3b(255, 255, 255), 255, CONF:getStringValue("consume_text_1"), fontName, fontSize, 2 ) 
			local re2 = ccui.RichElementText:create( 2, cc.c3b(250, 72, 72), 255, CONF.PARAM.get("slave_show_money").PARAM, fontName, fontSize, 2 ) 
			local re3 = ccui.RichElementText:create( 3, cc.c3b(255, 255, 255), 255, CONF:getStringValue("IN_7001"), fontName, fontSize , 2) 
			local re4 = ccui.RichElementText:create( 4, cc.c3b(33, 255, 70), 255, slave_brief_info.nickname, fontName, fontSize , 2) 
			local re5 = ccui.RichElementText:create( 5, cc.c3b(255, 255, 255), 255, CONF:getStringValue("consume_text_2"), fontName, fontSize , 2)  

			richText:pushBackElement(re1) 
			richText:pushBackElement(re2) 
			richText:pushBackElement(re3) 
			richText:pushBackElement(re4) 
			richText:pushBackElement(re5) 

			richText:setPosition(cc.p(node:getChildByName("text"):getPosition()))
			node:addChild(richText)

			node:getChildByName("text"):removeFromParent()

			self:addChild(node)

			tipsAction(node)

		end)

		policy:setName("noPolicy")
		policy:setPosition(cc.p(node:getChildByName("node_pos"):getPosition()))
		node:addChild(policy)

	elseif slave_data.state == 2 then--示众
		local policy = require("app.ExResInterface"):getInstance():FastLoad("SlaveScene/SlavePolicy.csb")

		policy:getChildByName("shizhong_text"):setString(CONF:getStringValue("show"))

		policy:getChildByName("weiguan"):setString(CONF:getStringValue("visit_quantity"))
		policy:getChildByName("weiguan_now_num"):setString(slave_data.show_watch_num)
		policy:getChildByName("weiguan_max_num"):setString("/"..CONF.PARAM.get("slave_watch_num").PARAM)

		policy:getChildByName("weiguan_now_num"):setPositionX(policy:getChildByName("weiguan"):getPositionX() + policy:getChildByName("weiguan"):getContentSize().width + 15)
		policy:getChildByName("weiguan_max_num"):setPositionX(policy:getChildByName("weiguan_now_num"):getPositionX() + policy:getChildByName("weiguan_now_num"):getContentSize().width)

		policy:getChildByName("over_time"):setString(formatTime(CONF.PARAM.get("slave_show_time").PARAM - (player:getServerTime() - slave_data.show_start_time)).." "..CONF:getStringValue("end"))

		policy:getChildByName("tips"):setString(CONF:getStringValue("show_cannotwork"))

		local svd = require("util.ScrollViewDelegate"):create(policy:getChildByName("list"),cc.size(0,0), cc.size(325,22))
		for i,v in ipairs(slave_data.watch_list) do
			local watch_node = require("app.ExResInterface"):getInstance():FastLoad("SlaveScene/watch_slave_message.csb")
			watch_node:getChildByName("string_1"):setString(v)
			watch_node:getChildByName("string_2"):setString(CONF:getStringValue("see_slave"))

			watch_node:getChildByName("string_2"):setPositionX(watch_node:getChildByName("string_1"):getPositionX() + watch_node:getChildByName("string_1"):getContentSize().width+ 2)

			svd:addElement(watch_node)
		end

		policy:setName("policy")
		policy:setPosition(cc.p(node:getChildByName("node_pos"):getPosition()))
		node:addChild(policy)

	end

	self:addChild(node)

	node:setPosition(cc.exports.VisibleRect:center())
	if isAction then
		tipsAction(node)
	end

end

function NoSlaveLayer:resetInfo( ... )

	local rn = self:getResourceNode()

	for i=1,5 do
		if player:getLevel() < CONF.PARAM.get("slave_room_open").PARAM[i] then
			rn:getChildByName("slave_"..i):getChildByName("back"):setEnabled(false)
			rn:getChildByName("slave_"..i):getChildByName("slave_Mirror"):setTexture("Common/newUI/slave_Mirror_gray.png")
			rn:getChildByName("slave_"..i):getChildByName("head_di"):setTexture("Common/newUI/my_txbottom_gray.png")
			rn:getChildByName("slave_"..i):getChildByName("head"):setTexture("Common/newUI/icon_suo_sl.png")
			rn:getChildByName("slave_"..i):getChildByName("name"):setVisible(false)
			rn:getChildByName("slave_"..i):getChildByName("shouhuo_type"):setVisible(false)
			rn:getChildByName("slave_"..i):getChildByName("shouhuo_di"):setVisible(false)
			rn:getChildByName("slave_"..i):getChildByName("work_di"):setVisible(false)
			rn:getChildByName("slave_"..i):getChildByName("work_type"):setVisible(false)
			rn:getChildByName("slave_"..i):getChildByName("work_ins"):setVisible(false)

			rn:getChildByName("slave_"..i):getChildByName("shouhuo_ins"):setTextColor(cc.c4b(255,255,255,255))
			-- rn:getChildByName("slave_"..i):getChildByName("shouhuo_ins"):enableShadow(cc.c4b(255,255,255,255),cc.size(0.5,0.5))
			rn:getChildByName("slave_"..i):getChildByName("shouhuo_ins"):setString(CONF.PARAM.get("slave_room_open").PARAM[i]..CONF:getStringValue("level_2")..CONF:getStringValue("open"))
		end
	end

	local slave_data = player:getSlaveData()

	if slave_data == nil then

		rn:getChildByName("you"):getChildByName("tf_num"):setString("0/"..CONF.PARAM.get("slave_enslave_num").PARAM)
		rn:getChildByName("you"):getChildByName("progress"):setContentSize(cc.size(0,18))

		for i=1,5 do
			if player:getLevel() >= CONF.PARAM.get("slave_room_open").PARAM[i] then

				rn:getChildByName("slave_"..i):getChildByName("head"):setTexture("StrongLayer/ui/zm_wh.png")

				rn:getChildByName("slave_"..i):getChildByName("name"):setVisible(false)
				rn:getChildByName("slave_"..i):getChildByName("shouhuo_type"):setVisible(false)
				rn:getChildByName("slave_"..i):getChildByName("shouhuo_di"):setVisible(false)
				rn:getChildByName("slave_"..i):getChildByName("work_di"):setVisible(false)
				rn:getChildByName("slave_"..i):getChildByName("work_type"):setVisible(false)
				rn:getChildByName("slave_"..i):getChildByName("work_ins"):setVisible(false)

				rn:getChildByName("slave_"..i):getChildByName("shouhuo_ins"):setTextColor(cc.c4b(140,155,159,255))
				-- rn:getChildByName("slave_"..i):getChildByName("shouhuo_ins"):enableShadow(cc.c4b(140,155,159,255),cc.size(0.5,0.5))
				rn:getChildByName("slave_"..i):getChildByName("shouhuo_ins"):setString(CONF:getStringValue("arrest_slave"))

				-- rn:getChildByName("slave_"..i):getChildByName("back"):addClickEventListener(function ( ... )
				-- 	playEffectSound("sound/system/click.mp3")

				-- 	self:getApp():pushToRootView("ColonizeScene/ColonizeScene", {type = "slave"})
				-- end)
				rn:getChildByName("slave_"..i):getChildByName("back"):setTag(0)
			end
		end

	else

		rn:getChildByName("you"):getChildByName("tf_num"):setString(slave_data.get_slaves_times.."/"..CONF.PARAM.get("slave_enslave_num").PARAM)

		local pp = player:getSlaveData().get_slaves_times/CONF.PARAM.get("slave_enslave_num").PARAM
		if pp > 1 then
			pp = 1
		end
		rn:getChildByName("you"):getChildByName("progress"):setContentSize(cc.size(math.floor(pp*100),18))

		for i=1,5 do

			if i <= #slave_data.slave_list then
				local data 
				local info 

				for i2,v2 in ipairs(self.slave_data_list) do
					if v2.user_name == slave_data.slave_list[i] then
						data = v2
						break
					end
				end

				for i2,v2 in ipairs(self.slave_brief_info_list) do
					if v2.user_name == slave_data.slave_list[i] then
						info = v2
						break
					end
				end

				rn:getChildByName("slave_"..i):getChildByName("name"):setString(info.nickname)
				rn:getChildByName("slave_"..i):getChildByName("head"):setTexture("HeroImage/"..info.icon_id..".png")
				rn:getChildByName("slave_"..i):getChildByName("shouhuo_type"):setString(CONF:getStringValue("gain"))

				if data.get_res_start_time == 0 then
					rn:getChildByName("slave_"..i):getChildByName("shouhuo_ins"):setString(CONF:getStringValue("can_gain"))
					rn:getChildByName("slave_"..i):getChildByName("shouhuo_ins"):setTextColor(cc.c4b(33,255,70,255))
					-- rn:getChildByName("slave_"..i):getChildByName("shouhuo_ins"):enableShadow(cc.c4b(33,255,70,255),cc.size(0.5,0.5))
				else
					rn:getChildByName("slave_"..i):getChildByName("shouhuo_ins"):setTextColor(cc.c4b(245,80,80,255))
					-- rn:getChildByName("slave_"..i):getChildByName("shouhuo_ins"):enableShadow(cc.c4b(245,80,80,255),cc.size(0.5,0.5))
					rn:getChildByName("slave_"..i):getChildByName("shouhuo_ins"):setString(CONF:getStringValue("cannot_gain"))
				end

				if data.state == 2 then
					rn:getChildByName("slave_"..i):getChildByName("work_type"):setString(CONF:getStringValue("show"))
					rn:getChildByName("slave_"..i):getChildByName("work_ins"):setString(formatTime(CONF.PARAM.get("slave_show_time").PARAM - (player:getServerTime() - data.show_start_time)))

					rn:getChildByName("slave_"..i):getChildByName("work_ins"):setVisible(true)
					rn:getChildByName("slave_"..i):getChildByName("work_type"):setVisible(true)
				elseif data.state == 1 then
					if data.work_cd_start_time == nil or data.work_cd_start_time == 0 then
						rn:getChildByName("slave_"..i):getChildByName("work_type"):setString(CONF:getStringValue("leisure"))
						-- rn:getChildByName("slave_"..i):getChildByName("work_ins"):setString(formatTime(CONF.PARAM.get("slave_show_time").PARAM - (player:getServerTime() - data.show_start_time)))
						rn:getChildByName("slave_"..i):getChildByName("work_ins"):setVisible(false)
					else
						rn:getChildByName("slave_"..i):getChildByName("work_type"):setString(CONF:getStringValue("work"))
						rn:getChildByName("slave_"..i):getChildByName("work_ins"):setString(formatTime(CONF.PARAM.get("slave_work_cd").PARAM - (player:getServerTime() - data.work_cd_start_time)))

						rn:getChildByName("slave_"..i):getChildByName("work_ins"):setVisible(true)
					end
				end


				rn:getChildByName("slave_"..i):getChildByName("back"):setTag(1)
					
			else
				if player:getLevel() >= CONF.PARAM.get("slave_room_open").PARAM[i] then

					rn:getChildByName("slave_"..i):getChildByName("head"):setTexture("StrongLayer/ui/zm_wh.png")

					rn:getChildByName("slave_"..i):getChildByName("name"):setVisible(false)
					rn:getChildByName("slave_"..i):getChildByName("shouhuo_type"):setVisible(false)
					rn:getChildByName("slave_"..i):getChildByName("shouhuo_di"):setVisible(false)
					rn:getChildByName("slave_"..i):getChildByName("work_di"):setVisible(false)
					rn:getChildByName("slave_"..i):getChildByName("work_type"):setVisible(false)
					rn:getChildByName("slave_"..i):getChildByName("work_ins"):setVisible(false)

					rn:getChildByName("slave_"..i):getChildByName("shouhuo_ins"):setTextColor(cc.c4b(140,155,159,255))
					-- rn:getChildByName("slave_"..i):getChildByName("shouhuo_ins"):enableShadow(cc.c4b(140,155,159,255),cc.size(0.5,0.5))
					rn:getChildByName("slave_"..i):getChildByName("shouhuo_ins"):setString(CONF:getStringValue("arrest_slave"))

					-- rn:getChildByName("slave_"..i):getChildByName("back"):addClickEventListener(function ( ... )
					-- 	playEffectSound("sound/system/click.mp3")

					-- 	self:getApp():pushToRootView("ColonizeScene/ColonizeScene", {type = "slave"})
					-- end)
					rn:getChildByName("slave_"..i):getChildByName("back"):setTag(0)
				end
			end
		end

	end
end

function NoSlaveLayer:getDataInfo( ... )
	local data 
	local info 
	local index = 0

	for i,v in ipairs(self.slave_data_list) do
		if self.get_res_name == v.user_name then
			data = v
			index = i
			break
		end
	end

	for i,v in ipairs(self.slave_brief_info_list) do
		if self.get_res_name == v.user_name then
			info = v
			break
		end
	end

	return data,info,index
end

function NoSlaveLayer:onEnterTransitionFinish()
	printInfo("NoSlaveLayer:onEnterTransitionFinish()")

	self.slave_info = {}

	local strData = Tools.encode("GetChatLogReq", {

		chat_id = 0,
		-- minor = {3},
	})
	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_CHAT_LOG_REQ"),strData)

	if player:getSlaveData() then

		local slave_str = ""
		for i,v in ipairs(player:getSlaveData().slave_list) do
			if slave_str ~= "" then
				slave_str = slave_str.."-"
			end

			slave_str = slave_str..v
		end

		flurryLogEvent("slave_info", {slave_num = #player:getSlaveData().slave_list, slave_info = slave_str}, 2)

	end

	local rn = self:getResourceNode()

	for i=1,5 do
		rn:getChildByName("slave_"..i):getChildByName("back"):addClickEventListener(function ( sender )
			playEffectSound("sound/system/click.mp3")

			if sender:getTag() == 0 then
				self:getApp():pushToRootView("ColonizeScene/ColonizeScene", {type = "slave"})
			elseif sender:getTag() == 1 then

				local data 

				for i2,v2 in ipairs(self.slave_data_list) do
					if v2.user_name == player:getSlaveData().slave_list[i] then
						data = v2
						break
					end
				end

				self.get_res_name = data.user_name
				self.get_res_type = 1

				local strData = Tools.encode("SlaveGetResReq", {    
					type = 1,
					slave_name = data.user_name ,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SLAVE_GET_RES_REQ"),strData)
				gl:retainLoading()

			end

		end)
	end

	print("player:getSlaveData()", player:getSlaveData())

	if player:getSlaveData() then
		local strData = Tools.encode("SlaveSyncDataReq", {    
			type = 0,
			user_name_list = player:getSlaveData().slave_list ,
		})
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SLAVE_SYNC_DATA_REQ"),strData)
		gl:retainLoading()
	else
		self:resetInfo()
	end

	rn:getChildByName("guize"):addClickEventListener(function ( ... )
		self:addChild(createIntroduceNode(CONF:getStringValue("slave_rule")))
	end)

	local userInfoNode = require("app.views.SlaveScene.UserInfoNode"):create()
	userInfoNode:init(self)
	userInfoNode:setName("userInfoNode")
	rn:getChildByName("info_node"):addChild(userInfoNode)

	rn:getChildByName("guize"):getChildByName("text"):setString(CONF:getStringValue("rule"))
	rn:getChildByName("jiejiu"):getChildByName("text"):setString(CONF:getStringValue("rescue_partner"))
	rn:getChildByName("jilu"):getChildByName("text"):setString(CONF:getStringValue("settlement_record"))
	rn:getChildByName("you"):getChildByName("taofa"):setString(CONF:getStringValue("settlement_time"))
	rn:getChildByName("my_slave"):setString(CONF:getStringValue("me_slave"))
	rn:getChildByName("my_slave_ins"):setString(CONF:getStringValue("me_describe"))

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

	rn:getChildByName("you"):getChildByName("strength_add"):addClickEventListener(function ( ... )

		playEffectSound("sound/system/click.mp3")

		if player:getSlaveData() and player:getSlaveData().get_slaves_times then

			-- if player:getSlaveData().get_slaves_times < CONF.PARAM.get("slave_enslave_num").PARAM then

				local function func(  )
					if player:getMoney() < CONF.PARAM.get("enslave_coupon").PARAM*(player:getSlaveData().buy_get_slaves_times + 1) then
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
						type = 1,
					})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SLAVE_ADD_TIMES_REQ"),strData)
					
					gl:retainLoading()
				end

				local node = require("util.TipsNode"):createWithBuyNode(CONF:getStringValue("buy_enslave"), CONF.PARAM.get("enslave_coupon").PARAM*(player:getSlaveData().buy_get_slaves_times + 1), func)

				self:addChild(node)
				tipsAction(node)
				return
			-- end

		end

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

			print("string_len", string_len)

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

		if self:getChildByName("slave_node") then

			local data,info,index = self:getDataInfo()

			local shifang_time = CONF.PARAM.get("slave_free_time").PARAM - (player:getServerTime() - data.slaved_start_time)
			self:getChildByName("slave_node"):getChildByName("info_di_text"):setString(formatTime(shifang_time)..CONF:getStringValue("end_release"))

			if data.get_res_start_time > 0 then
				self:getChildByName("slave_node"):getChildByName("shouqu_time"):setString(formatTime(CONF.PARAM.get("slave_get_res_cd").PARAM - (player:getServerTime() - data.get_res_start_time)))
				self:getChildByName("slave_node"):getChildByName("shouqu_time"):setVisible(true)
				self:getChildByName("slave_node"):getChildByName("shouqu"):setEnabled(false)
			else

				self:getChildByName("slave_node"):getChildByName("shouqu_time"):setVisible(false)
				self:getChildByName("slave_node"):getChildByName("shouqu"):setEnabled(true)
			end

			if self:getChildByName("slave_node"):getChildByName("noPolicy") then

				local policy =  self:getChildByName("slave_node"):getChildByName("noPolicy")

				if data.work_cd_start_time > 0 then
					if CONF.PARAM.get("slave_work_cd").PARAM - (player:getServerTime() - data.work_cd_start_time) > 0 then

						policy:getChildByName("work_time"):setString(formatTime(CONF.PARAM.get("slave_work_cd").PARAM - (player:getServerTime() - data.work_cd_start_time)))
						policy:getChildByName("work_time"):setPositionX(policy:getChildByName("tips"):getPositionX() + policy:getChildByName("tips"):getContentSize().width + 5)

						if data.work_cd_start_time == nil or data.work_cd_start_time == 0 then
							policy:getChildByName("tips"):setVisible(false)
							policy:getChildByName("work_time"):setVisible(false)

							policy:getChildByName("work"):setEnabled(true)
						else
							policy:getChildByName("tips"):setVisible(true)
							policy:getChildByName("work_time"):setVisible(true)

							policy:getChildByName("work"):setEnabled(false)
						end
					else
						local strData = Tools.encode("SlaveSyncDataReq", {    
							type = 0,
							user_name_list = player:getSlaveData().slave_list ,
						})
						GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SLAVE_SYNC_DATA_REQ"),strData)
						gl:retainLoading()
					end
				end

			end

			if self:getChildByName("slave_node"):getChildByName("policy") then

				local policy =  self:getChildByName("slave_node"):getChildByName("policy")

				if CONF.PARAM.get("slave_show_time").PARAM - (player:getServerTime() - data.show_start_time) > 0 then
					policy:getChildByName("over_time"):setString(formatTime(CONF.PARAM.get("slave_show_time").PARAM - (player:getServerTime() - data.show_start_time)).." "..CONF:getStringValue("end"))
				else
					local strData = Tools.encode("SlaveSyncDataReq", {    
						type = 0,
						user_name_list = player:getSlaveData().slave_list ,
					})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SLAVE_SYNC_DATA_REQ"),strData)
					gl:retainLoading()
				end
			end

		end
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

				print("player:getSlaveData().slave_list",#player:getSlaveData().slave_list)

				if player:getSlaveData().master == nil or player:getSlaveData().master == "" then

					if self:getChildByName("chatLayer") then

					else
						
						self.slave_data_list = proto.slave_data_list
						self.slave_brief_info_list = proto.info_list

						self:resetInfo()

						if self.get_res_name then
							local data,info, index = self:getDataInfo()

							if self:getChildByName("slave_node") then
								self:getChildByName("slave_node"):removeFromParent()
								self:createSlaveNode(data,info,self.slave_info.res, self.slave_info.exp, index, false)
							else
								self:createSlaveNode(data,info,self.slave_info.res, self.slave_info.exp, index, true)
							end
						end
					end
				else
					self:getParent():getSlave()
				end
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_SLAVE_SHOW_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("SlaveShowResp",strData)
			print("SlaveShowResp",proto.result)

			if proto.result ~= "OK" then
				print("error :",proto.result)
			else
				local strData = Tools.encode("SlaveSyncDataReq", {    
					type = 0,
					user_name_list = player:getSlaveData().slave_list ,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SLAVE_SYNC_DATA_REQ"),strData)
				gl:retainLoading()
		
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_SLAVE_GET_RES_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("SlaveGetResResp",strData)
			print("SlaveGetResResp",proto.result)

			if proto.result ~= "OK" then
				print("error :",proto.result)
			else

				self.slave_info = {}
				self.slave_info = {res = proto.res, exp = proto.exp}

				print("get_res", proto.res[1], proto.res[2], proto.res[3], proto.res[4], proto.exp)

				if self.get_res_type == 2 then
					local node = require("util.UpgradeOverNode"):createNode(CONF:getStringValue("gether_succeed"))
					node:setPosition(cc.exports.VisibleRect:center())
					self:addChild(node,3)

					local res = {0,0,0,0}
					local exp = 0

					self.slave_info = {res = res, exp = exp}

					-- self.get_res_type = 1
					-- local strData = Tools.encode("SlaveGetResReq", {    
					-- 	type = 1,
					-- 	slave_name =  self.get_res_name,
					-- })
					-- GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SLAVE_GET_RES_REQ"),strData)
					-- gl:retainLoading()

					-- for i=1,1000 do
					-- 	print("-----------------------")
					-- end
					
				end

				local strData = Tools.encode("SlaveSyncDataReq", {    
					type = 0,
					user_name_list = player:getSlaveData().slave_list ,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SLAVE_SYNC_DATA_REQ"),strData)
				gl:retainLoading()
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_UPDATE_SLAVE_DATA") then
			print("CMD_UPDATE_SLAVE_DATA")

			-- print("mmmaster", player:getSlaveData().master )

			-- if player:getSlaveData().master == nil or player:getSlaveData().master == "" then
			-- 	self:resetInfo()
				local strData = Tools.encode("SlaveSyncDataReq", {    
					type = 0,
					-- user_name_list = player:getSlaveData().slave_list ,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SLAVE_SYNC_DATA_REQ"),strData)
				gl:retainLoading()
			-- else
			-- 	self:getParent():getSlave()
			-- end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_SLAVE_FREE_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("SlaveFreeResp",strData)
			print("SlaveFreeResp",proto.result)

			if proto.result ~= "OK" then
				print("error :",proto.result)
			else

				if self:getChildByName("slave_node") then
					self:getChildByName("slave_node"):removeFromParent()
				end

				self:resetInfo()
				self.get_res_name = nil

				-- local strData = Tools.encode("SlaveSyncDataReq", {    
				-- 	type = 0,
				-- 	-- user_name_list = player:getSlaveData().slave_list ,
				-- })
				-- GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SLAVE_SYNC_DATA_REQ"),strData)
				-- gl:retainLoading()
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_SLAVE_WORK_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("SlaveWorkResp",strData)
			print("SlaveWorkResp",proto.result)

			if proto.result ~= "OK" then
				print("error :",proto.result)
			else
				local node = createSlaveNoteNode(24, proto.note_info.type, proto.note_info.text_index, proto.note_info.param_list)

				self:addChild(node,2)
				tipsAction(node)

				local strData = Tools.encode("SlaveSyncDataReq", {    
					type = 0,
					user_name_list = player:getSlaveData().slave_list ,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SLAVE_SYNC_DATA_REQ"),strData)
				gl:retainLoading()
		
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_SLAVE_ADD_TIMES_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("SlaveAddTimesResp",strData)

			if proto.result ~= "OK" then
				print("error :",proto.result)
			else
				
				rn:getChildByName("you"):getChildByName("tf_num"):setString(player:getSlaveData().get_slaves_times.."/"..CONF.PARAM.get("slave_enslave_num").PARAM)

				local pp = player:getSlaveData().get_slaves_times/CONF.PARAM.get("slave_enslave_num").PARAM
				if pp > 1 then
					pp = 1
				end
				rn:getChildByName("you"):getChildByName("progress"):setContentSize(cc.size(math.floor(pp*100),18))
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_CHAT_LOG_RESP") then

			local proto = Tools.decode("GetChatLogResp",strData)
			if proto.result < 0 then
				print("error :",proto.result)
			else
				local logCount = #proto.log_list
				if logCount > 0 then
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

    require("util.ExConfigScreenAdapter"):getInstance():onFixQuanmianping_NoSlave(self)
end


function NoSlaveLayer:onExitTransitionStart()
	printInfo("NoSlaveLayer:onExitTransitionStart()")

	if schedulerEntry ~= nil then
		scheduler:unscheduleScriptEntry(schedulerEntry)
	end

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
	eventDispatcher:removeEventListener(self.msgListener_)
	
end

return NoSlaveLayer