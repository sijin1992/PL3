local planetManager = require('app.views.PlanetScene.Manager.PlanetManager'):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local player = require("app.Player"):getInstance()

local app = require("app.MyApp"):getInstance()

local messageBox = require("util.MessageBox"):getInstance()

local PlanetSelectNode = class("PlanetSelectNode")

local tips = require("util.TipsMessage"):getInstance()

local infoType = {
	BASE = 1,
	RES = 2 ,
	RUINS = 3 ,
	BOSS = 4 ,
	CITY = 5,
	CITYRES = 6,
    MONSTER = 11,
    KING = 12,
    TOWER = 13,
}

local btnTag = {
	[10001] = "PlanetScene/ui/btn_gongji.png",-- 攻击
	[10002] = "PlanetScene/ui/btn_caiji.png",-- 采集
	[10003] = "PlanetScene/ui/btn_fangyu.png",-- 防御
	[10004] = "PlanetScene/ui/btn_cuihui.png",-- 摧毁
	[10005] = "PlanetScene/ui/btn_dalao.png",-- 打捞
	[10006] = "PlanetScene/ui/btn_jijie.png", -- 集结
	[10007] = "PlanetScene/ui/btn_zhancha.png", -- 侦查
	[10008] = "PlanetScene/ui/btn_zhujun.png", -- 查看驻军
	[10009] = "PlanetScene/ui/btn_shengji.png",-- 升级
	[10010] = "PlanetScene/ui/btn_yueqian.png",-- 跃迁
	[10011] = "PlanetScene/ui/btn_shuoming.png",-- 说明
	[10012] = "PlanetScene/ui/btn_zhiyuan.png",-- 支援
	[10013] = "PlanetScene/ui/btn_huicheng.png",-- 回城
	[10014] = "PlanetScene/ui/btn_fancheng.png",-- 返程
	[10015] = "PlanetScene/ui/btn_xinxi.png",-- 信息
	[10016] = "PlanetScene/ui/btn_zhuzha.png",-- 驻扎
	[10017] = "PlanetScene/ui/btn_chenghao.png", --称号
    [10018] = "PlanetScene/ui/btn_opentower.png",-- 开启塔攻
	[10019] = "PlanetScene/ui/btn_closetower.png", -- 关闭塔攻
}

local function creatSeeNode()
	if not display:getRunningScene():getChildByName("station_amry_layer") then
		local station_amry_layer = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/otherNodeLayer/SeeStationedArmyLayer.csb")
		station_amry_layer:setName("station_amry_layer")
		station_amry_layer:getChildByName("title"):setString(CONF:getStringValue("team_browse"))
		station_amry_layer:getChildByName("close"):addClickEventListener(function ( ... )
			station_amry_layer:removeFromParent()
		end)
		station_amry_layer:getChildByName("wenzi"):setString(CONF:getStringValue("no fleet"))
		station_amry_layer:getChildByName("wenzi"):setVisible(true)
		local xx,yy = getScreenDiffLocation()
		station_amry_layer:setPosition(cc.p(-xx/2,-yy/2))
		station_amry_layer:getChildByName("list"):setScrollBarEnabled(false)
        require("util.ExConfigScreenAdapterFixedHeight"):getInstance():onFixQuanmianping_SeeStationedArmy(station_amry_layer)
		display:getRunningScene():addChild(station_amry_layer)
	end
end


function PlanetSelectNode:setPlanetSelectNode(data , rn)
	local node = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/otherNodeLayer/planetSelectNode.csb")
	-- animation
	animManager:runAnimOnceByCSB(node, "PlanetScene/otherNodeLayer/planetSelectNode.csb", "animation")
	node:getChildByName('Text_2'):setVisible(false)
	node:getChildByName('Image_1'):setVisible(false)
	node:getChildByName('btn_all'):getChildByName('Text'):setString(CONF:getStringValue('mass'))
	for i=1,5 do
		node:getChildByName('Button_'..i):setVisible(false)
		node:getChildByName('Button_'..i):setSwallowTouches(true)
	end
--Image_location   Button_share
	node:getChildByName("Image_location"):addClickEventListener(function ( ... )
		local info = planetManager:getInfoByNodeGUID( data.info.node_id, data.info.guid )
		if info and info.type == infoType.CITY then
			data.info.pos[1] = info.pos_list[1].x
			data.info.pos[2] = info.pos_list[1].y
		end
		local er_node = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/add_marker.csb")
		er_node:getChildByName("pos"):setString('('..data.info.pos[1]..','..data.info.pos[2]..')')
		er_node:getChildByName("btn"):getChildByName("text"):setString(CONF:getStringValue("yes"))
		er_node:getChildByName("title"):setString(CONF:getStringValue("add_marker"))

		local msg = ""
		if data.info.node_id then
			local info = planetManager:getInfoByNodeGUID( data.info.node_id, data.info.guid )
			if info then
				msg = planetManager:GetNodeName(info)
			end
		end

		if string.len(msg) == 0 then
			msg = "X="..data.info.pos[1].." Y="..data.info.pos[2]
		end

		er_node:getChildByName("text_field"):setString(msg)

		-- local x = math.random(-50,50)
		-- local y = math.random(-50,50)
		-- local name = ""
		-- for i=1,5 do
		-- 	local num = math.random(10)
		-- 	name = name.."_"..num
		-- end
		er_node:getChildByName("close"):addClickEventListener(function ( ... )
			er_node:removeFromParent()
		end)

		er_node:getChildByName("btn"):addClickEventListener(function ( ... )

			if er_node:getChildByName("text_field"):getString() == "" then
				tips:tips(CONF:getStringValue("point name"))
			else

				for i=1,CONF.DIRTYWORD.len do
				  -- assert(not string.find(self.edit:getText(), CONF.DIRTYWORD[i].KEY), "dirty word", self.edit:getText())
				  if string.find(er_node:getChildByName("text_field"):getString(), CONF.DIRTYWORD[i].KEY) then
				  	tips:tips(CONF:getStringValue("dirty_message"))
				  	return
				  end
				end

				local str = shuaiSubString(er_node:getChildByName("text_field"):getString())
				for i=1,CONF.DIRTYWORD.len do
				  -- assert(not string.find(self.edit:getText(), CONF.DIRTYWORD[i].KEY), "dirty word", self.edit:getText())
				  if string.find(str, CONF.DIRTYWORD[i].KEY) then
				  	tips:tips(CONF:getStringValue("dirty_message"))
				  	return
				  end
				end

				local strData = Tools.encode("PlanetMarkReq", {
					type = 1,
					name = er_node:getChildByName("text_field"):getString(),
					pos = {x = data.info.pos[1], y = data.info.pos[2]},
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_MARK_REQ"),strData)

				er_node:removeFromParent()
			end
		end)

		display:getRunningScene():addChild(er_node)

	end)

	node:getChildByName("Button_share"):addClickEventListener(function ( ... )
		playEffectSound("sound/system/click.mp3")

		local msg = ""
		if data.info.node_id then
			local info = planetManager:getInfoByNodeGUID( data.info.node_id, data.info.guid )
			if info then
				msg = planetManager:GetNodeName(info)
			end
		end
		if string.len(msg)>1 then
			msg = msg .. " "
		end
		msg = msg .. "X:"..data.info.pos[1].." Y:"..data.info.pos[2]

		local uiLayer = rn:getParent():getParent():getUILayer()
		local layer = uiLayer:getApp():createView("ChatLayer/ChatLayer", {name = "world",msg = msg})
		layer:setName("chatLayer")
		uiLayer:addChild(layer)		

		uiLayer:getResourceNode():getChildByName("chat"):getChildByName("point"):setVisible(false)
		--rn:getChildByName("chat"):getChildByName("point"):setVisible(false)

	end)

	if data.bool == true then
		node:getChildByName('Button_3'):setVisible(true)
		node:getChildByName('Text_1'):setString('('..data.info.pos[1]..','..data.info.pos[2]..')')
		node:getChildByName('Button_3'):getChildByName('Text'):setString(CONF:getStringValue('yueqian'))--跃迁
		node:getChildByName("Button_3"):setTag(10010)
		node:getChildByName('Button_3'):addClickEventListener(function()

				local function func( ... )

					local pos = {x = data.info.pos[1], y = data.info.pos[2]}
					local node_id = getNodeIDByGlobalPos(pos)
					if CONF.PLANETWORLD.get(node_id).TYPE == 3 then
						tips:tips(CONF:getStringValue("throne migration"))
						return
					end

					if CONF.PLANETWORLD.get(node_id).TYPE == 1 then
						if CONF.PLANETWORLD.get(node_id).NATION ~=  CONF.PLANETWORLD.get(tonumber(Split(planetManager:getUserBaseElementInfo().global_key, "_")[1])).NATION   then
							tips:tips(CONF:getStringValue("transition_2"))
							return
						end
					end

					if CONF.PLANETWORLD.get(node_id).TYPE == 2 then

						local info_list = planetManager:getInfoByNodeID(node_id)
						if info_list then
							for i,v in ipairs(info_list) do
								if v.type == 5 then
									if v.city_data.status == 2 then
										tips:tips(CONF:getStringValue("nation_error"))
										return
									end
									
									if player:getGroupData().groupid == "" or player:getGroupData().groupid == nil then
										tips:tips(CONF:getStringValue("transition_1"))
										return
									end

									if v.city_data.groupid ~= player:getGroupData().groupid then
										tips:tips(CONF:getStringValue("transition_1"))
										return
									end

									
								end
							end
						end
					end

					if player:getItemNumByID(17001) <= 0 then
						tips:tips(CONF:getStringValue("item not enought"))
						return
					end
					cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")

	        		local event = cc.EventCustom:new("resetChoose")
					event.m = data.info.pos[1]
					event.n = data.info.pos[2]
					cc.Director:getInstance():getEventDispatcher():dispatchEvent(event) 

					
				end

				local use_node = require("util.TipsNode"):createWithUseNode(CONF:getStringValue("jump_base"), 17001, 1, func)
				display:getRunningScene():addChild(use_node)
				tipsAction(use_node)

				cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")

					-- node:removeFromParent()


			end)
		node:getChildByName("wangge"):setVisible(true)
		animManager:runAnimByCSB(node:getChildByName("wangge"), "PlanetScene/sfx/kongjianzhanxuanzhong/wangge.csb", "1")
	else
		local info = planetManager:getInfoByNodeGUID( data.info.node_id, data.info.guid )
		if info then
			node:getChildByName('Text_1'):setString('('..info.pos_list[1].x..':'..info.pos_list[1].y..')')

			-- if #info.pos_list == 1 then
			-- 	node:getChildByName("wangge"):setVisible(true)
			-- 	animManager:runAnimByCSB(node:getChildByName("wangge"), "PlanetScene/sfx/kongjianzhanxuanzhong/wangge.csb", "1")
			-- end
            local nodename = planetManager:GetNodeName(info)
			if info.type == infoType.CITY then -- 据点

				local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()
				if player:getSystemGuideStep(CONF.ESystemGuideInterFace.kPlanetCity)== 0 and g_System_Guide_Id == 0 then
					systemGuideManager:createGuideLayer(CONF.FUNCTION_OPEN.get("judian_open").INTERFACE)
				else
					if g_System_Guide_Id ~= 0 then
						systemGuideManager:createGuideLayer(g_System_Guide_Id)
					end
				end

				for i=1,5 do
					node:getChildByName("Button_"..i):setVisible(true)
				end

				local function setInfo1( ... )

					node:getChildByName("Button_2"):setVisible(false)
					node:getChildByName("Button_4"):setVisible(false)

					node:getChildByName("Button_3"):getChildByName("Text"):setString(CONF:getStringValue('zhencha'))
					node:getChildByName("Button_1"):getChildByName("Text"):setString(CONF:getStringValue('shuoming'))
					node:getChildByName("Button_5"):getChildByName("Text"):setString(CONF:getStringValue('gongji'))		
					node:getChildByName("Button_3"):setTag(10007)
					node:getChildByName("Button_1"):setTag(10011)
					node:getChildByName("Button_5"):setTag(10001)
					node:getChildByName("Button_3"):addClickEventListener(function ( ... )
						cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
							local canClick = true
							if Tools.isEmpty(planetManager:getPlanetUser( )) == false then
								if Tools.isEmpty(planetManager:getPlanetUser( ).army_list) == false then
									-- for k,v in pairs(planetManager:getPlanetUser( ).army_list) do
									-- 	if v.element_global_key == info.global_key then
									-- 		canClick = false
									-- 		tips:tips(CONF:getStringValue("notice shipsComing"))
									-- 		break
									-- 	end
									-- end
									if #planetManager:getPlanetUser( ).army_list >= CONF.BUILDING_1.get(player:getBuildingInfo(1).level).ARMY_NUM then
										canClick = false
										tips:tips(CONF:getStringValue("notice maxTeam"))
									end
								end
							end

							--if info.city_data.status == 1 then
							--	canClick = false
							--	tips:tips(CONF:getStringValue("peacet_notice2"))
							--end

							if canClick then
								-- app:addView2Top("NewFormLayer",{from="bigMapRaid",element_global_key=info.global_key,type=2})
								app:addView2Top("PlanetScene/PlanetSpyMakeSureLayer",{element_global_key=info.global_key})

								-- node:removeFromParent()
							end
					end)

					node:getChildByName("Button_1"):addClickEventListener(function ( ... )
						cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
						app:addView2Top("PlanetScene/PlanetDetail/PlanetDetailType_city",{info = info,node_name = nodename})
					end)

					node:getChildByName("Button_5"):addClickEventListener(function ( ... )
						cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
						local canClick = true

							--if info.city_data.status == 1 then
							--	canClick = false
							--	tips:tips(CONF:getStringValue("peacet_notice1"))
							--else

								if Tools.isEmpty(planetManager:getPlanetUser( )) == false then
									if Tools.isEmpty(planetManager:getPlanetUser( ).army_list) == false then
										-- for k,v in pairs(planetManager:getPlanetUser( ).army_list) do
										-- 	if v.element_global_key == info.global_key then
										-- 		canClick = false
										-- 		tips:tips(CONF:getStringValue("notice shipsComing"))
										-- 		break
										-- 	end
										-- end
										if #planetManager:getPlanetUser( ).army_list >= CONF.BUILDING_1.get(player:getBuildingInfo(1).level).ARMY_NUM then
											canClick = false
											tips:tips(CONF:getStringValue("notice maxTeam"))
										end
									end
								end

								if canClick then
									app:addView2Top("NewFormLayer",{from="bigMapRaid",element_global_key=info.global_key,type=6,cfg_type = 'CITY',cfg_id = info.city_data.id})
									-- node:removeFromParent()
								end
							--end
					end)

					if player:getBuildingInfo(1).level >= CONF.PARAM.get("mass_activa").PARAM then
						node:getChildByName("btn_all"):setVisible(true)

						node:getChildByName("btn_all"):addClickEventListener(function ( ... )
							cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")

							if player:isGroup() then
								if info.city_data.groupid ~= player:getGroupData().groupid then

									--if info.city_data.status == 1 then
									--	tips:tips(CONF:getStringValue("peacet_notice1"))
									--	return
									--end
									app:addView2Top("PlanetScene/PlanetAllFightLayer",{element_global_key=info.global_key,type=6,cfg_type = 'CITY',cfg_id = info.city_data.id,status =info.city_data.status,pos_list = info.pos_list })
								else
									node:getChildByName("btn_all"):setVisible(false)
								end

							else
								tips:tips(CONF:getStringValue("you no group"))

							end
						end)
						
					end
				end

				local function setInfo2( ... )

					node:getChildByName("Button_3"):setVisible(false)
					
					node:getChildByName("Button_2"):getChildByName("Text"):setString(CONF:getStringValue("upgrade"))
					node:getChildByName("Button_1"):getChildByName("Text"):setString(CONF:getStringValue('shuoming'))
					node:getChildByName("Button_4"):getChildByName("Text"):setString(CONF:getStringValue("chakanzhujun"))
					node:getChildByName("Button_2"):setTag(10009)
					node:getChildByName("Button_1"):setTag(10011)
					node:getChildByName("Button_4"):setTag(10008)
					local yizhuzha = false
					local army_guid = 0
					for i,v in ipairs(info.city_data.guarde_list) do
						if Split(v, "_")[1] == player:getName() then
							yizhuzha = true
							army_guid = tonumber(Split(v, "_")[2])
							break
						end
					end

					if yizhuzha then
						node:getChildByName("Button_5"):getChildByName("Text"):setString(CONF:getStringValue('huicheng'))
						node:getChildByName("Button_5"):setTag(10013)
						node:getChildByName("Button_5"):addClickEventListener(function ( ... )
                            cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
                            local function click()
							    local strData = Tools.encode("PlanetRideBackReq", {
								    type = 2,
								    army_guid = {army_guid},
							     })
							    GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_RIDE_BACK_REQ"),strData)
                            end
                            local messageBox = require("util.MessageBox"):getInstance()
			                messageBox:reset(CONF:getStringValue("ishuicheng"), click)
						end)
					else
						node:getChildByName("Button_5"):getChildByName("Text"):setString(CONF:getStringValue('station_centre'))
						node:getChildByName("Button_5"):setTag(10016)
						node:getChildByName("Button_5"):addClickEventListener(function ( ... )
							cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
							local canClick = true
							if Tools.isEmpty(planetManager:getPlanetUser( )) == false then
								if Tools.isEmpty(planetManager:getPlanetUser( ).army_list) == false then
									for k,v in pairs(planetManager:getPlanetUser( ).army_list) do
										if v.element_global_key == info.global_key then
											canClick = false
											tips:tips(CONF:getStringValue("notice shipsComing"))
											break
										end
									end
									if #planetManager:getPlanetUser( ).army_list >= CONF.BUILDING_1.get(player:getBuildingInfo(1).level).ARMY_NUM then
										canClick = false
										tips:tips(CONF:getStringValue("notice maxTeam"))
									end
								end
							end
							if canClick then
								app:addView2Top("NewFormLayer",{from="bigMapRaid",element_global_key=info.global_key,type=3,cfg_type = 'CITY',cfg_id = info.city_data.id})
								-- node:removeFromParent()
							end
						end)	
					end

					node:getChildByName("Button_1"):addClickEventListener(function ( ... )
						cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
						app:addView2Top("PlanetScene/PlanetDetail/PlanetDetailType_city",{info = info,node_name = nodename})
					end)	

					node:getChildByName("Button_2"):addClickEventListener(function ( ... )
						cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
						tips:tips(CONF:getStringValue("coming soon"))
					end)	

					node:getChildByName("Button_4"):addClickEventListener(function ( ... )
						cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")

						if Tools.isEmpty(info.city_data.guarde_list) then
							-- tips:tips(CONF:getStringValue("no fleet"))
							creatSeeNode()
						else
							local strData = Tools.encode("PlanetGetReq", {
									army_key_list = info.city_data.guarde_list,
									type = 5,
								 })
							GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData) 
						end
					end)	

					
				end


				if info.city_data.hasMonster then
					setInfo1()

				else

					if info.city_data.groupid ~= "" then
						if player:isGroup() then
							if player:getGroupData().groupid == info.city_data.groupid then
								setInfo2()

							
							else
								--hong
								setInfo1()
							end

						else
							--hong

							setInfo1()
						end
					else
						setInfo1()

					end

				end

			elseif info.type == infoType.BASE then -- 基地
				if info.base_data.user_name == player:getName() then
					node:getChildByName('Button_1'):setVisible(true)
					node:getChildByName('Button_3'):setVisible(true)
					node:getChildByName('Button_5'):setVisible(true)
					node:getChildByName('Button_1'):getChildByName('Text'):setString(CONF:getStringValue('chakanzhujun'))--查看驻军
					node:getChildByName('Button_3'):getChildByName('Text'):setString(CONF:getStringValue('information'))--信息
					node:getChildByName('Button_5'):getChildByName('Text'):setString(CONF:getStringValue('shezhifangyu'))--设置防御
					node:getChildByName('Button_1'):setTag(10008)
					node:getChildByName('Button_3'):setTag(10015)
					node:getChildByName('Button_5'):setTag(10003)
					node:getChildByName('Button_1'):addClickEventListener(function()
						-- print('********************查看驻军')
						cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")

						print(" info.base_data.guarde_list", #info.base_data.guarde_list)

						local flag = false
						for i,v in ipairs( info.base_data.guarde_list) do
							if info.global_key == planetManager:getPlanetUserBaseElementKey() and Split(v,"_")[1] == player:getName() then
								flag = true
							end
						end

						if Tools.isEmpty(info.base_data.guarde_list) then
							tips:tips(CONF:getStringValue("no fleet"))
						else

							if flag then
								if #info.base_data.guarde_list == 1 then
									-- tips:tips(CONF:getStringValue("no fleet"))
									creatSeeNode()
								else
									local strData = Tools.encode("PlanetGetReq", {
										army_key_list = info.base_data.guarde_list,
										type = 5,
									 })
									GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData) 
								end
							else
								local strData = Tools.encode("PlanetGetReq", {
									army_key_list = info.base_data.guarde_list,
									type = 5,
								 })
								GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData) 
							end

						end
						-- node:removeFromParent()

						end)
					node:getChildByName('Button_3'):addClickEventListener(function()
						cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
						app:addView2Top("PlanetScene/PlanetDetail/PlanetDetailType_base",{node_id=data.info.node_id,guid=data.info.guid})
						-- node:removeFromParent()
						end)
					node:getChildByName('Button_5'):addClickEventListener(function()
						--********************设置防御
						cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
						app:addView2Top("PlanetScene/DefensiveLineupNode", {info = data, isPlanet = true})
						-- node:removeFromParent()
						end)
				else
					if player:checkPlayerIsInGroup(info.base_data.user_name) then
						node:getChildByName('Button_1'):setVisible(true)
						node:getChildByName('Button_5'):setVisible(true)
						node:getChildByName('Button_5'):getChildByName('Text'):setString(CONF:getStringValue('Stationed'))--支援
						node:getChildByName('Button_1'):getChildByName('Text'):setString(CONF:getStringValue('information'))--信息
						node:getChildByName('Button_5'):setTag(10012)
						node:getChildByName('Button_1'):setTag(10015)
						node:getChildByName('Button_1'):addClickEventListener(function()
							cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
							app:addView2Top("PlanetScene/PlanetDetail/PlanetDetailType_base",{node_id=data.info.node_id,guid=data.info.guid})
							-- node:removeFromParent()
							end)
						local station_already = false
						if planetManager:getPlanetUser( ) and Tools.isEmpty(planetManager:getPlanetUser( ).army_list) == false then
							for k,v in ipairs(planetManager:getPlanetUser( ).army_list) do
								local split = Tools.split(v.element_global_key,"_")
								if data.info.node_id == tonumber(split[1]) and data.info.guid == tonumber(split[2]) then
									if v.status_machine == 5 and v.status == 6 then
										station_already = true
										break
									end
								end
							end
						end
						if station_already then
							node:getChildByName('Button_5'):getChildByName('Text'):setString(CONF:getStringValue('chakanzhujun'))--查看驻军
							node:getChildByName('Button_5'):setTag(10008)
						end
						node:getChildByName('Button_5'):addClickEventListener(function()
							cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
							if station_already then
								if Tools.isEmpty(info.base_data.guarde_list) then
									-- tips:tips(CONF:getStringValue("no fleet"))
									creatSeeNode()
								else
									local strData = Tools.encode("PlanetGetReq", {
											army_key_list = info.base_data.guarde_list,
											type = 5,
										 })
									GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData) 
								end
							else
								local canClick = true
								if Tools.isEmpty(planetManager:getPlanetUser( )) == false then
									if Tools.isEmpty(planetManager:getPlanetUser( ).army_list) == false then
										for k,v in pairs(planetManager:getPlanetUser( ).army_list) do
											if v.element_global_key == info.global_key then
												canClick = false
												tips:tips(CONF:getStringValue("notice shipsComing"))
												break
											end
										end
										if #planetManager:getPlanetUser( ).army_list >= CONF.BUILDING_1.get(player:getBuildingInfo(1).level).ARMY_NUM then
											canClick = false
											tips:tips(CONF:getStringValue("notice maxTeam"))
										end
									end
								end
								if canClick then
									app:addView2Top("NewFormLayer",{from="bigMapRaid",element_global_key=info.global_key,type=3,cfg_type = 'BASE'})
									-- node:removeFromParent()
								end
							end
							end)
					else
						node:getChildByName('Button_1'):setVisible(true)
						node:getChildByName('Button_3'):setVisible(true)
						node:getChildByName('Button_5'):setVisible(true)
						node:getChildByName('Button_3'):getChildByName('Text'):setString(CONF:getStringValue('zhencha'))--侦查
						node:getChildByName('Button_1'):getChildByName('Text'):setString(CONF:getStringValue('information'))--信息
						node:getChildByName('Button_5'):getChildByName('Text'):setString(CONF:getStringValue('gongji'))--gongji
						node:getChildByName('Button_3'):setTag(10007)
						node:getChildByName('Button_1'):setTag(10015)
						node:getChildByName('Button_5'):setTag(10001)
						node:getChildByName('Button_1'):addClickEventListener(function()
							cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")

							

							-- if info.base_data.shield_start_time > 0 then
							-- 	local function func( ... )
							-- 		app:addView2Top("PlanetScene/PlanetDetail/PlanetDetailType_base",{node_id=data.info.node_id,guid=data.info.guid})
							-- 	end

							-- 	messageBox:reset(CONF.STRING.get("shield text").VALUE, func)
							-- else
								app:addView2Top("PlanetScene/PlanetDetail/PlanetDetailType_base",{node_id=data.info.node_id,guid=data.info.guid})
							-- end
							-- node:removeFromParent()
							end)
						node:getChildByName('Button_3'):addClickEventListener(function()
							cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
							local canClick = true
							if Tools.isEmpty(planetManager:getPlanetUser( )) == false then
								if Tools.isEmpty(planetManager:getPlanetUser( ).army_list) == false then
									-- for k,v in pairs(planetManager:getPlanetUser( ).army_list) do
									-- 	if v.element_global_key == info.global_key then
									-- 		canClick = false
									-- 		tips:tips(CONF:getStringValue("notice shipsComing"))
									-- 		break
									-- 	end
									-- end
									if #planetManager:getPlanetUser( ).army_list >= CONF.BUILDING_1.get(player:getBuildingInfo(1).level).ARMY_NUM then
										canClick = false
										tips:tips(CONF:getStringValue("notice maxTeam"))
									end
								end
							end
							if canClick then
								-- app:addView2Top("NewFormLayer",{from="bigMapRaid",element_global_key=info.global_key,type=2})
								if info.base_data.shield_start_time > 0 then
									
									tips:tips(CONF:getStringValue("shield text"))

								else
									app:addView2Top("PlanetScene/PlanetSpyMakeSureLayer",{element_global_key=info.global_key})
								end
								-- node:removeFromParent()
							end
							end)
						node:getChildByName('Button_5'):addClickEventListener(function()
							cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
							local canClick = true
							if Tools.isEmpty(planetManager:getPlanetUser( )) == false then
								if Tools.isEmpty(planetManager:getPlanetUser( ).army_list) == false then
									-- for k,v in pairs(planetManager:getPlanetUser( ).army_list) do
									-- 	if v.element_global_key == info.global_key then
									-- 		canClick = false
									-- 		tips:tips(CONF:getStringValue("notice shipsComing"))
									-- 		break
									-- 	end
									-- end
									if #planetManager:getPlanetUser( ).army_list >= CONF.BUILDING_1.get(player:getBuildingInfo(1).level).ARMY_NUM then
										canClick = false
										tips:tips(CONF:getStringValue("notice maxTeam"))
									end
								end
							end
							if canClick then
								
								if info.base_data.shield_start_time > 0 then
									tips:tips(CONF:getStringValue("shield text"))
								else
									app:addView2Top("NewFormLayer",{from="bigMapRaid",element_global_key=info.global_key,type=1,cfg_type = 'BASE'})
								end
								-- node:removeFromParent()
							end
							end)

						if player:getBuildingInfo(1).level >= CONF.PARAM.get("mass_activa").PARAM then
							node:getChildByName("btn_all"):setVisible(true)

							node:getChildByName("btn_all"):addClickEventListener(function ( ... )
								cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")

								if player:isGroup() then
									if info.city_data.groupid ~= player:getGroupData().groupid then
										app:addView2Top("PlanetScene/PlanetAllFightLayer",{element_global_key=info.global_key,type=1,cfg_type = 'BASE',status =info.base_data.shield_start_time > 0 and 3 or 2,pos_list = info.pos_list })

									else
										node:getChildByName("btn_all"):setVisible(false)
									end

								else
									tips:tips(CONF:getStringValue("you no group"))

								end
							end)
							
						end
					end
				end
			elseif info.type == infoType.RUINS then -- 废墟
				if CONF.PLANET_RUINS.get(info.ruins_data.id).TYPE == 2 then -- 行星带 
					local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()
					if player:getSystemGuideStep(CONF.ESystemGuideInterFace.kPlanetStar)== 0 and g_System_Guide_Id == 0 then
						systemGuideManager:createGuideLayer(CONF.FUNCTION_OPEN.get("star_open").INTERFACE)
					else
						if g_System_Guide_Id ~= 0 then
							systemGuideManager:createGuideLayer(g_System_Guide_Id)
						end
					end

					node:getChildByName('Button_5'):setVisible(true)
					node:getChildByName('Button_5'):getChildByName('Text'):setString(CONF:getStringValue('destroy'))--摧毁
					node:getChildByName('Button_5'):addClickEventListener(function()
						cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
						-- print('********************摧毁行星带')
						local canClick = true
						if Tools.isEmpty(planetManager:getPlanetUser( )) == false then
							if Tools.isEmpty(planetManager:getPlanetUser( ).army_list) == false then
								for k,v in pairs(planetManager:getPlanetUser( ).army_list) do
									if v.element_global_key == info.global_key then
										canClick = false
										tips:tips(CONF:getStringValue("notice shipsComing"))
										break
									end
								end
								if #planetManager:getPlanetUser( ).army_list >= CONF.BUILDING_1.get(player:getBuildingInfo(1).level).ARMY_NUM then
									canClick = false
									tips:tips(CONF:getStringValue("notice maxTeam"))
								end
							end
						end
						if canClick then
							app:addView2Top("NewFormLayer",{from="bigMapRuins",element_global_key=info.global_key,cfg_type = 'RUINS',cfg_id = info.ruins_data.id})
							-- node:removeFromParent()
						end
						end)
					node:getChildByName('Button_1'):setVisible(true)
					node:getChildByName('Button_1'):getChildByName('Text'):setString(CONF:getStringValue('shuoming'))--说明
					node:getChildByName('Button_5'):setTag(10004)
					node:getChildByName('Button_1'):setTag(10011)
					node:getChildByName('Button_1'):addClickEventListener(function()
						cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
						-- print('********************shuoming行星带')
						app:addView2Top("PlanetScene/PlanetDetail/PlanetDetailType_ruins",{node_id=data.info.node_id,guid=data.info.guid,node_name = nodename})
						-- node:removeFromParent()
						end)
				else
					local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()
					if player:getSystemGuideStep(CONF.ESystemGuideInterFace.kPlanetRuins)== 0 and g_System_Guide_Id == 0 then
						systemGuideManager:createGuideLayer(CONF.FUNCTION_OPEN.get("ruins_open").INTERFACE)
					else
						if g_System_Guide_Id ~= 0 then
							systemGuideManager:createGuideLayer(g_System_Guide_Id)
						end
					end
					if info.ruins_data and info.ruins_data.user_name and info.ruins_data.user_name ~= '' then
						if info.ruins_data.user_name == player:getName() then
							node:getChildByName('Button_1'):setVisible(true)
							node:getChildByName('Button_1'):getChildByName('Text'):setString(CONF:getStringValue('shuoming'))--说明
							node:getChildByName('Button_1'):addClickEventListener(function()
								cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
								-- print('********************shuoming行星带')
								app:addView2Top("PlanetScene/PlanetDetail/PlanetDetailType_ruins",{node_id=data.info.node_id,guid=data.info.guid,node_name = nodename})
								-- node:removeFromParent()
								end)
							node:getChildByName('Button_5'):setVisible(true)
							node:getChildByName('Button_5'):getChildByName('Text'):setString(CONF:getStringValue('huicheng'))--回城
							node:getChildByName('Button_5'):setTag(10013)
							node:getChildByName('Button_1'):setTag(10011)
							node:getChildByName('Button_5'):addClickEventListener(function()
								cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
                                local function click()
									local strData = Tools.encode("PlanetRideBackReq", {
										type = 2,
										army_guid = {info.ruins_data.army_guid},
									 })
									GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_RIDE_BACK_REQ"),strData)
                                end
                                local messageBox = require("util.MessageBox"):getInstance()
			                    messageBox:reset(CONF:getStringValue("ishuicheng"), click)
									-- node:removeFromParent()
							end)
						else
							if player:checkPlayerIsInGroup( info.ruins_data.user_name ) then
								node:getChildByName('Button_3'):setVisible(true)
								node:getChildByName('Button_3'):getChildByName('Text'):setString(CONF:getStringValue('shuoming'))--说明
								node:getChildByName('Button_3'):setTag(10011)
								node:getChildByName('Button_3'):addClickEventListener(function()
									cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
									-- print('********************shuoming行星带')
									app:addView2Top("PlanetScene/PlanetDetail/PlanetDetailType_ruins",{node_id=data.info.node_id,guid=data.info.guid,node_name = nodename})
									-- node:removeFromParent()
									end)
							else
								node:getChildByName('Button_3'):setVisible(true)
								node:getChildByName('Button_3'):getChildByName('Text'):setString(CONF:getStringValue('shuoming'))--说明
								node:getChildByName('Button_3'):setTag(10011)
								node:getChildByName('Button_3'):addClickEventListener(function()
									cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
									-- print('********************shuoming行星带')
									app:addView2Top("PlanetScene/PlanetDetail/PlanetDetailType_ruins",{node_id=data.info.node_id,guid=data.info.guid,node_name = nodename})
									-- node:removeFromParent()
									end)
							end
						end
					else
						node:getChildByName('Button_1'):setVisible(true)
						node:getChildByName('Button_1'):getChildByName('Text'):setString(CONF:getStringValue('shuoming'))--说明
						node:getChildByName('Button_1'):setTag(10011)
						node:getChildByName('Button_1'):addClickEventListener(function()
							cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
							-- print('********************shuoming行星带')
							app:addView2Top("PlanetScene/PlanetDetail/PlanetDetailType_ruins",{node_id=data.info.node_id,guid=data.info.guid,})
							-- node:removeFromParent()
							end)
						node:getChildByName('Button_5'):setVisible(true)
						node:getChildByName('Button_5'):getChildByName('Text'):setString(CONF:getStringValue('tansuo'))--探索
						node:getChildByName('Button_5'):setTag(10005)
						node:getChildByName('Button_5'):addClickEventListener(function()
							cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
							local canClick = true
							if Tools.isEmpty(planetManager:getPlanetUser( )) == false then
								if Tools.isEmpty(planetManager:getPlanetUser( ).army_list) == false then
									for k,v in pairs(planetManager:getPlanetUser( ).army_list) do
										if v.element_global_key == info.global_key then
											canClick = false
											tips:tips(CONF:getStringValue("notice shipsComing"))
											break
										end
									end
									if #planetManager:getPlanetUser( ).army_list >= CONF.BUILDING_1.get(player:getBuildingInfo(1).level).ARMY_NUM then
										canClick = false
										tips:tips(CONF:getStringValue("notice maxTeam"))
									end
								end
							end
							if canClick then 
								app:addView2Top("NewFormLayer",{from="bigMapRuins",element_global_key=info.global_key,cfg_type = 'RUINS',cfg_id = info.ruins_data.id})
								--node:removeFromParent()
							end
							end)
					end
				end
			elseif info.type == infoType.RES then -- 资源
				node:getChildByName('Text_2'):setString(info.res_data.cur_storage) -- 资源数量
				node:getChildByName('Image_1'):setVisible(true)
				node:getChildByName('Text_2'):setVisible(true)
				local resID = CONF.ITEM.get(CONF.PLANET_RES.get(info.res_data.id).PRODUCTION_ID).ICON_ID
				node:getChildByName('Image_1'):loadTexture('ItemIcon/'..resID..'.png')
				node:getChildByName('Text_2'):setPositionX(node:getChildByName('Image_1'):getPositionX()+node:getChildByName('Text_2'):getContentSize().width/2+5)
				if info.res_data and info.res_data.user_name and info.res_data.user_name ~= '' then
					if info.res_data.user_name == player:getName() then
						node:getChildByName('Button_1'):setVisible(true)
						node:getChildByName('Button_5'):setVisible(true)
						node:getChildByName('Button_1'):getChildByName('Text'):setString(CONF:getStringValue('shuoming'))--说明
						node:getChildByName('Button_1'):setTag(10011)
						node:getChildByName('Button_5'):setTag(10014)
						node:getChildByName('Button_1'):addClickEventListener(function()
							cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
							app:addView2Top("PlanetScene/PlanetDetail/PlanetDetailType_res",{node_id=data.info.node_id,guid=data.info.guid,node_name = nodename})
							-- node:removeFromParent()
							end)
						node:getChildByName('Button_5'):getChildByName('Text'):setString(CONF:getStringValue('huicheng'))--返程
						node:getChildByName('Button_5'):addClickEventListener(function()
							cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
                            local function click()
							    local strData = Tools.encode("PlanetRideBackReq", {
								    type = 2,
								    army_guid = {info.res_data.army_guid},
							     })
							    GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_RIDE_BACK_REQ"),strData)
                            end
                            local messageBox = require("util.MessageBox"):getInstance()
			                messageBox:reset(CONF:getStringValue("ishuicheng"), click)
							-- node:removeFromParent()
						end)
					else
						if player:checkPlayerIsInGroup( info.res_data.user_name ) then
							node:getChildByName('Button_1'):setVisible(true)
							node:getChildByName('Button_5'):setVisible(true)
							node:getChildByName('Button_1'):setTag(10011)
							node:getChildByName('Button_5'):setTag(10015)
							node:getChildByName('Button_1'):getChildByName('Text'):setString(CONF:getStringValue('shuoming'))--说明
							node:getChildByName('Button_1'):addClickEventListener(function()
								cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
								app:addView2Top("PlanetScene/PlanetDetail/PlanetDetailType_res",{node_id=data.info.node_id,guid=data.info.guid,node_name = nodename})
								-- node:removeFromParent()
								end)
							node:getChildByName('Button_5'):getChildByName('Text'):setString(CONF:getStringValue('wanjiaxinxi'))--玩家信息
							node:getChildByName('Button_5'):addClickEventListener(function()
								cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
								--********************玩家信息资源
								-- node:removeFromParent()
								end)
						else
							node:getChildByName('Button_1'):setVisible(true)
							node:getChildByName('Button_5'):setVisible(true)
							node:getChildByName('Button_1'):setTag(10011)
							node:getChildByName('Button_5'):setTag(10001)
							node:getChildByName('Button_1'):getChildByName('Text'):setString(CONF:getStringValue('shuoming'))--说明
							node:getChildByName('Button_1'):addClickEventListener(function()
								cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
								app:addView2Top("PlanetScene/PlanetDetail/PlanetDetailType_res",{node_id=data.info.node_id,guid=data.info.guid,node_name = nodename})
								-- node:removeFromParent()
								end)
							node:getChildByName('Button_5'):getChildByName('Text'):setString(CONF:getStringValue('gongji'))--玩家信息
							node:getChildByName('Button_5'):addClickEventListener(function()
								cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
								local canClick = true
								if Tools.isEmpty(planetManager:getPlanetUser( )) == false then
									if Tools.isEmpty(planetManager:getPlanetUser( ).army_list) == false then
										for k,v in pairs(planetManager:getPlanetUser( ).army_list) do
											if v.element_global_key == info.global_key then
												canClick = false
												tips:tips(CONF:getStringValue("notice shipsComing"))
												break
											end
										end
										if #planetManager:getPlanetUser( ).army_list >= CONF.BUILDING_1.get(player:getBuildingInfo(1).level).ARMY_NUM then
											canClick = false
											tips:tips(CONF:getStringValue("notice maxTeam"))
										end
									end
								end
								if canClick then
									app:addView2Top("NewFormLayer",{from="bigMapCollct",cfg_type = 'RES',element_global_key=info.global_key, type = "fight"})
									-- node:removeFromParent()
								end
								end)
						end
					end
				else
					node:getChildByName('Button_5'):setVisible(true)
					node:getChildByName('Button_1'):getChildByName('Text'):setString(CONF:getStringValue('shuoming'))--说明
					node:getChildByName('Button_1'):setVisible(true)
					node:getChildByName('Button_1'):setTag(10011)
					node:getChildByName('Button_5'):setTag(10002)
					node:getChildByName('Button_1'):addClickEventListener(function()
						cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
						app:addView2Top("PlanetScene/PlanetDetail/PlanetDetailType_res",{node_id=data.info.node_id,guid=data.info.guid,node_name = nodename})
						-- node:removeFromParent()
						end)
					node:getChildByName('Button_5'):getChildByName('Text'):setString(CONF:getStringValue('collect'))--采集
					node:getChildByName('Button_5'):addClickEventListener(function()
						cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
						local canClick = true
						if Tools.isEmpty(planetManager:getPlanetUser( )) == false then
							if Tools.isEmpty(planetManager:getPlanetUser( ).army_list) == false then
								for k,v in pairs(planetManager:getPlanetUser( ).army_list) do
									if v.element_global_key == info.global_key then
										canClick = false
										tips:tips(CONF:getStringValue("notice shipsComing"))
										break
									end
								end
								if #planetManager:getPlanetUser( ).army_list >= CONF.BUILDING_1.get(player:getBuildingInfo(1).level).ARMY_NUM then
									canClick = false
									tips:tips(CONF:getStringValue("notice maxTeam"))
								end
							end
						end
						if canClick then
							app:addView2Top("NewFormLayer",{from="bigMapCollct",cfg_type = 'RES',element_global_key=info.global_key, type = "collect"})
							-- node:removeFromParent()
						end
						end)
				end
			elseif info.type == infoType.BOSS then

				local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()
				if player:getSystemGuideStep(CONF.ESystemGuideInterFace.kPlanetBoss)== 0 and g_System_Guide_Id == 0 then
					systemGuideManager:createGuideLayer(CONF.FUNCTION_OPEN.get("ai_open").INTERFACE)
				else
					if g_System_Guide_Id ~= 0 then
						systemGuideManager:createGuideLayer(g_System_Guide_Id)
					end
				end

				node:getChildByName('Button_1'):setVisible(true)
				node:getChildByName('Button_5'):setVisible(true)
				node:getChildByName('Button_1'):setTag(10015)
				node:getChildByName('Button_5'):setTag(10001)
				node:getChildByName('Button_1'):getChildByName('Text'):setString(CONF:getStringValue('information'))--信息
				node:getChildByName('Button_5'):getChildByName('Text'):setString(CONF:getStringValue('gongji'))--攻击
				node:getChildByName('Button_1'):addClickEventListener(function()
					cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
					app:addView2Top("PlanetScene/PlanetDetail/PlanetDetailType_boss",{node_id=data.info.node_id,guid=data.info.guid,node_name = nodename})
					end)
				node:getChildByName('Button_5'):addClickEventListener(function()
						cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
						local canClick = true
						if Tools.isEmpty(planetManager:getPlanetUser( )) == false then
							if Tools.isEmpty(planetManager:getPlanetUser( ).army_list) == false then
								for k,v in pairs(planetManager:getPlanetUser( ).army_list) do
									if v.element_global_key == info.global_key then
										canClick = false
										tips:tips(CONF:getStringValue("notice shipsComing"))
										break
									end
									if v.status_machine == 9 then
										canClick = false
										tips:tips(CONF:getStringValue("no attack base"))
										break
									end
								end
								if #planetManager:getPlanetUser( ).army_list >= CONF.BUILDING_1.get(player:getBuildingInfo(1).level).ARMY_NUM then
									canClick = false
									tips:tips(CONF:getStringValue("notice maxTeam"))
								end
							end
						end
						if canClick then
							app:addView2Top("NewFormLayer",{from="bigMapRaid",element_global_key=info.global_key,type=7,cfg_type = 'BOSS',cfg_id = info.boss_data.id})
							-- node:removeFromParent()
						end
						end)
			 elseif info.type == infoType.CITYRES then -- 据点矿
				if Tools.isEmpty(info) or Tools.isEmpty(info.city_res_data) then return end
				local isMyGroup = false
				local collectArmyGuid
				local collectting = false	
				if info.city_res_data.groupid and info.city_res_data.groupid ~= "" then
					if player:isGroup() then
						if player:getGroupData().groupid == info.city_res_data.groupid then
							isMyGroup = true
						end
					end
				end
				if isMyGroup then
					node:getChildByName("Button_1"):getChildByName("Text"):setString(CONF:getStringValue('information'))
					node:getChildByName('Button_1'):setVisible(true)
					node:getChildByName('Button_5'):setVisible(true)
					node:getChildByName("Button_1"):setTag(10015)
					for k,v in ipairs(info.city_res_data.user_list) do
						if v.user_name == player:getName() then
							collectting = true
							collectArmyGuid = v.army_guid
							break
						end
					end
					if collectting then
						node:getChildByName("Button_5"):setTag(10014)
						node:getChildByName("Button_5"):getChildByName("Text"):setString(CONF:getStringValue("huicheng"))
					else
						node:getChildByName("Button_5"):setTag(10002)
						node:getChildByName("Button_5"):getChildByName("Text"):setString(CONF:getStringValue("collect"))
					end
				else
					node:getChildByName('Button_3'):setVisible(true)
					node:getChildByName("Button_3"):setTag(10015)
					node:getChildByName("Button_3"):getChildByName("Text"):setString(CONF:getStringValue('information'))
				end
				node:getChildByName("Button_1"):addClickEventListener(function()
					app:addView2Top("PlanetScene/PlanetDetail/PlanetDetailType_cityRes",{node_id=data.info.node_id,guid=data.info.guid})
					end)
				node:getChildByName("Button_3"):addClickEventListener(function()
					app:addView2Top("PlanetScene/PlanetDetail/PlanetDetailType_cityRes",{node_id=data.info.node_id,guid=data.info.guid})
					end)
				node:getChildByName("Button_5"):addClickEventListener(function()
					if isMyGroup then
						cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
						if collectting then
                            local function click()
							    local strData = Tools.encode("PlanetRideBackReq", {
								    type = 2,
								    army_guid = {collectArmyGuid},
							     })
							    GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_RIDE_BACK_REQ"),strData)
                            end
                            local messageBox = require("util.MessageBox"):getInstance()
			                messageBox:reset(CONF:getStringValue("ishuicheng"), click)
						else
							local canClick = true
							if info.city_res_data.restore_start_time ~= 0 then
								tips:tips(CONF:getStringValue("res_recover"))
								return
							end
							if Tools.isEmpty(planetManager:getPlanetUser( )) == false then
								if Tools.isEmpty(planetManager:getPlanetUser( ).army_list) == false then
									for k,v in pairs(planetManager:getPlanetUser( ).army_list) do
										if v.element_global_key == info.global_key then
											canClick = false
											tips:tips(CONF:getStringValue("collect_notice"))
											break
										end
										local split = Split(v.element_global_key,"_")
										local info = planetManager:getInfoByNodeGUID( tonumber(split[1]), tonumber(split[2]) )
										if Tools.isEmpty(info) == false then
											if info.type == infoType.CITYRES then
												canClick = false
												tips:tips(CONF:getStringValue("collect_notice2"))
												break
											end
										end
									end
									if #planetManager:getPlanetUser( ).army_list >= CONF.BUILDING_1.get(player:getBuildingInfo(1).level).ARMY_NUM then
										canClick = false
										tips:tips(CONF:getStringValue("notice maxTeam"))
									end
								end
							end
							if canClick then
								app:addView2Top("NewFormLayer",{from="bigMapCollct",cfg_type = 'RES',element_global_key=info.global_key, type = "collect"})
								-- node:removeFromParent()
							end
						end
					end
				end)
            elseif info.type == infoType.MONSTER then --星系野怪
				node:getChildByName('Button_1'):setVisible(true)
				node:getChildByName('Button_5'):setVisible(true)
				node:getChildByName('Button_1'):setTag(10015)
				node:getChildByName('Button_5'):setTag(10001)
				node:getChildByName('Button_1'):getChildByName('Text'):setString(CONF:getStringValue('information'))--信息
				node:getChildByName('Button_5'):getChildByName('Text'):setString(CONF:getStringValue('gongji'))--攻击
				node:getChildByName('Button_1'):addClickEventListener(function()
					cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
					app:addView2Top("PlanetScene/PlanetDetail/PlanetDetailType_monster",{node_id=data.info.node_id,guid=data.info.guid,node_name = nodename})
				end)
				node:getChildByName('Button_5'):addClickEventListener(function()
					cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
					local canClick = true
					if Tools.isEmpty(planetManager:getPlanetUser( )) == false then
						if Tools.isEmpty(planetManager:getPlanetUser( ).army_list) == false then
							for k,v in pairs(planetManager:getPlanetUser( ).army_list) do
								if v.element_global_key == info.global_key then
									canClick = false
									tips:tips(CONF:getStringValue("notice shipsComing"))
									break
								end
								if v.status_machine == 9 then
									canClick = false
									tips:tips(CONF:getStringValue("no attack base"))
									break
								end
							end
							if #planetManager:getPlanetUser( ).army_list >= CONF.BUILDING_1.get(player:getBuildingInfo(1).level).ARMY_NUM then
								canClick = false
								tips:tips(CONF:getStringValue("notice maxTeam"))
							end
						end
					end
                    if false then
                        local monster_level = CONF.PLANETCREEPS.get(info.monster_data.id).LEVEL
                        if player:getLevel() > monster_level then
						    canClick = false
                            local t = {}
                            t.level = monster_level
                            t.name = CONF:getStringValue(CONF.PLANETCREEPS.get(info.monster_data.id).NAME)
                            local high_str = string.gsub(CONF:getStringValue('creeps caution'),"%$(%w+)",t)
						    tips:tips(high_str)
					    end
                    end
                    if player:getStrength() < CONF.PLANETCREEPS.get(info.monster_data.id).STRENGTH then
						canClick = false
						tips:tips(CONF:getStringValue("strength_not_enought"))
					end

					if canClick then
						app:addView2Top("NewFormLayer",{from="bigMapRaid",element_global_key=info.global_key,type=11,cfg_type = 'MONSTER',cfg_id = info.monster_data.id})
						-- node:removeFromParent()
					end
				end)
			elseif info.type == infoType.KING then -- 王座
				local wangzuo_data = info.wangzuo_data
				local conf = CONF.PLANETCITY.get(wangzuo_data.id)
				local seize = false
				if wangzuo_data.groupid and wangzuo_data.groupid ~= "" then
					if player:isGroup() then
						if player:getGroupData().groupid == wangzuo_data.groupid then
							seize = true
						end
					end
				else
					if wangzuo_data.user_name and player:getName() == wangzuo_data.user_name then
						seize = true
					end
				end
				node:getChildByName("Button_1"):setVisible(true)
				node:getChildByName("Button_2"):setVisible(true)
				node:getChildByName("Button_4"):setVisible(true)
				node:getChildByName("Button_5"):setVisible(true)
				node:getChildByName("btn_all"):setVisible(true)
				node:getChildByName("Button_1"):getChildByName('Text'):setString(CONF:getStringValue('information')) -- 信息
				node:getChildByName("Button_2"):getChildByName('Text'):setString(CONF:getStringValue('throne_state')) -- 王座状态
				node:getChildByName("Button_4"):getChildByName('Text'):setString(CONF:getStringValue('the_title')) -- 称号
				node:getChildByName("Button_1"):setTag(10015)
				node:getChildByName("Button_2"):setTag(10011)
				node:getChildByName("Button_4"):setTag(10017)
				node:getChildByName("Button_4"):addClickEventListener(function()
					cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
					app:addView2Top("PlanetScene/WangZuo/WangZuoBuff",{wangzuo_data})
					end)
				node:getChildByName('Button_1'):addClickEventListener(function()
					cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
					app:addView2Top("PlanetScene/PlanetDetail/PlanetDetailType_wangzuo",{info = info})
					-- node:removeFromParent()
					end)
				node:getChildByName("Button_2"):addClickEventListener(function()
					cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
					-- local view = app:createView("PlanetScene/WangZuo/WangZuoState",wangzuo_data)
					app:addView2Top("PlanetScene/WangZuo/WangZuoState",{wangzuo_data})
					end)
				if seize then
					node:getChildByName("Button_5"):getChildByName('Text'):setString(CONF:getStringValue('admission')) -- 入驻
					node:getChildByName("btn_all"):getChildByName('Text'):setString(CONF:getStringValue('back')) -- 返回
					node:getChildByName("Button_5"):setTag(10016)
					node:getChildByName("btn_all"):setTag(10014)
					node:getChildByName("Button_5"):addClickEventListener(function()
						local canClick = true
						if Tools.isEmpty(planetManager:getPlanetUser( )) == false then
							if Tools.isEmpty(planetManager:getPlanetUser( ).army_list) == false then
								if #planetManager:getPlanetUser( ).army_list >= CONF.BUILDING_1.get(player:getBuildingInfo(1).level).ARMY_NUM then
									canClick = false
									tips:tips(CONF:getStringValue("notice maxTeam"))
								end
							end
						end
						if #(wangzuo_data.guarde_list) >= conf.TROOPS_LIMIT then
							tips:tips(CONF:getStringValue("stationed_upperlimit"))
							canClick = false
						end
						if canClick then
							if wangzuo_data.status and wangzuo_data.status == 1 then
								tips:tips(CONF:getStringValue("peace_cannot_be_attacked"))
							else
								cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
								app:addView2Top("NewFormLayer",{from="bigMapRaid",element_global_key=info.global_key,type=3,cfg_type = 'CITY',cfg_id = wangzuo_data.id})
							end
						end
					end)
					node:getChildByName("btn_all"):addClickEventListener(function()
						local canBack = false
						local canBackList = {}
						if Tools.isEmpty(wangzuo_data.guarde_list) == false then
							for k,v in ipairs(wangzuo_data.guarde_list) do
								local user_name = Tools.split(v,"_")[1]
								if tostring(player:getName()) == user_name then
									canBack = true
									table.insert(canBackList,tonumber(Tools.split(v,"_")[2]))
								end
							end
						end
						if not canBack then
							tips:tips(CONF:getStringValue("no_stationed"))
						else
                            local function click()
							    cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
							    local strData = Tools.encode("PlanetRideBackReq", {
								    type = 2,
								    army_guid = canBackList,
							     })
							    GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_RIDE_BACK_REQ"),strData)
                            end
                            local messageBox = require("util.MessageBox"):getInstance()
			                messageBox:reset(CONF:getStringValue("ishuicheng"), click)
						end
						
						end)
				else
					node:getChildByName("Button_5"):getChildByName('Text'):setString(CONF:getStringValue('gongji')) -- 攻击
					node:getChildByName("btn_all"):getChildByName('Text'):setString(CONF:getStringValue('mass')) -- 集结
					node:getChildByName("Button_5"):setTag(10001)
					node:getChildByName("btn_all"):setTag(10006)
					node:getChildByName("btn_all"):addClickEventListener(function()
						if player:isGroup() then
							if wangzuo_data.groupid ~= player:getGroupData().groupid then
								if wangzuo_data.status == 1 then
									tips:tips(CONF:getStringValue("peace_cannot_be_attacked"))
									return
								end
								app:addView2Top("PlanetScene/PlanetAllFightLayer",{element_global_key=info.global_key,type=12,cfg_type = 'CITY',cfg_id = wangzuo_data.id,status =wangzuo_data.status,pos_list = info.pos_list })
							else
								node:getChildByName("btn_all"):setVisible(false)
							end
						else
							tips:tips(CONF:getStringValue("you no group"))
						end
						end)
					node:getChildByName("Button_5"):addClickEventListener(function()
						local canClick = true
						if Tools.isEmpty(planetManager:getPlanetUser( )) == false then
							if Tools.isEmpty(planetManager:getPlanetUser( ).army_list) == false then
								if #planetManager:getPlanetUser( ).army_list >= CONF.BUILDING_1.get(player:getBuildingInfo(1).level).ARMY_NUM then
									canClick = false
									tips:tips(CONF:getStringValue("notice maxTeam"))
								end
							end
						end
						if canClick then
							if wangzuo_data.status and wangzuo_data.status == 1 then
								tips:tips(CONF:getStringValue("peace_cannot_be_attacked"))
							else
								cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
								app:addView2Top("NewFormLayer",{from="bigMapRaid",element_global_key=info.global_key,type=12,cfg_type = 'CITY'})
							end
						end
					end)
				end
            elseif info.type == infoType.TOWER then -- tower
                local tower_data = info.tower_data
				local conf = CONF.PLANETTOWER.get(tower_data.id)

                local function hostile ()    -- case1:hostile
                    node:getChildByName("btn_all"):setVisible(true)
                    node:getChildByName("btn_all"):getChildByName('Text'):setString(CONF:getStringValue('mass')) -- mass
                    node:getChildByName("Button_5"):getChildByName('Text'):setString(CONF:getStringValue('gongji')) -- attack
                    node:getChildByName("btn_all"):setTag(10006)
                    node:getChildByName("Button_5"):setTag(10001)
                    node:getChildByName("btn_all"):addClickEventListener(function()
                    	cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
                    	if player:isGroup() then
							if tower_data.groupid ~= player:getGroupData().groupid then
								if tower_data.status == 1 then
									tips:tips(CONF:getStringValue("peace_cannot_be_attacked"))
									return
								end
								app:addView2Top("PlanetScene/PlanetAllFightLayer",{element_global_key=info.global_key,type=13,cfg_type = 'TOWER',cfg_id = tower_data.id,status =tower_data.status ,pos_list = info.pos_list})
							else
								node:getChildByName("btn_all"):setVisible(false)
							end
						else
							tips:tips(CONF:getStringValue("you no group"))
						end
                    	end)
                    node:getChildByName("Button_5"):addClickEventListener(function()
                    	cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
                    	local canClick = true
						if Tools.isEmpty(planetManager:getPlanetUser( )) == false then
							if Tools.isEmpty(planetManager:getPlanetUser( ).army_list) == false then
								if #planetManager:getPlanetUser( ).army_list >= CONF.BUILDING_1.get(player:getBuildingInfo(1).level).ARMY_NUM then
									canClick = false
									tips:tips(CONF:getStringValue("notice maxTeam"))
								end
							end
						end
						if canClick then
							if tower_data.status and tower_data.status == 1 then
								tips:tips(CONF:getStringValue("peace_cannot_be_attacked"))
							else
								cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
								app:addView2Top("NewFormLayer",{from="bigMapRaid",element_global_key=info.global_key,type=13,cfg_type = 'TOWER'})
							end
						end
                    	end)
                end
                local function league()    -- case2:league
                    node:getChildByName("Button_3"):setVisible(true)
			        node:getChildByName("Button_3"):getChildByName('Text'):setString(CONF:getStringValue('admission')) -- admission
                    node:getChildByName("Button_5"):getChildByName('Text'):setString(CONF:getStringValue('back')) -- back
                    node:getChildByName("Button_3"):setTag(10016)
                    node:getChildByName("Button_5"):setTag(10014)
                    node:getChildByName("Button_3"):addClickEventListener(function()
                    	cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
                    	local canClick = true
						if Tools.isEmpty(planetManager:getPlanetUser( )) == false then
							if Tools.isEmpty(planetManager:getPlanetUser( ).army_list) == false then
								if #planetManager:getPlanetUser( ).army_list >= CONF.BUILDING_1.get(player:getBuildingInfo(1).level).ARMY_NUM then
									canClick = false
									tips:tips(CONF:getStringValue("notice maxTeam"))
								end
							end
						end
						if #(tower_data.guarde_list) >= conf.TROOPS_LIMIT then
							tips:tips(CONF:getStringValue("stationed_upperlimit"))
							canClick = false
						end
						if canClick then
							if tower_data.status and tower_data.status == 1 then
								tips:tips(CONF:getStringValue("peace_cannot_be_attacked"))
							else
								cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
								app:addView2Top("NewFormLayer",{from="bigMapRaid",element_global_key=info.global_key,type=3,cfg_type = 'TOWER',cfg_id = tower_data.id})
							end
						end
                    	end)
                    node:getChildByName("Button_5"):addClickEventListener(function()
                        	cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
                        	local canBack = false
							local canBackList = {}
							if Tools.isEmpty(tower_data.guarde_list) == false then
								for k,v in ipairs(tower_data.guarde_list) do
									local user_name = Tools.split(v,"_")[1]
									if tostring(player:getName()) == user_name then
										canBack = true
										table.insert(canBackList,tonumber(Tools.split(v,"_")[2]))
									end
								end
							end
							if not canBack then
								tips:tips(CONF:getStringValue("no_stationed"))
							else
                                local function click()
								    cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
								    local strData = Tools.encode("PlanetRideBackReq", {
									    type = 2,
									    army_guid = canBackList,
								     })
								    GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_RIDE_BACK_REQ"),strData)
                                end
                                local messageBox = require("util.MessageBox"):getInstance()
			                    messageBox:reset(CONF:getStringValue("ishuicheng"), click)
							end
                        	end)
                end
                local function myself()    -- case3:self
                    node:getChildByName("btn_all"):setVisible(true)
                    node:getChildByName("Button_3"):setVisible(true)
			        node:getChildByName("Button_3"):getChildByName('Text'):setString(CONF:getStringValue('admission')) -- admission
                    node:getChildByName("Button_5"):getChildByName('Text'):setString(CONF:getStringValue('back')) -- back
                    node:getChildByName("Button_3"):setTag(10016)
                    node:getChildByName("Button_5"):setTag(10014)
                    if tower_data.is_attack then -- showclose
                        node:getChildByName("btn_all"):getChildByName('Text'):setString(CONF:getStringValue('closed')) -- closed
                        node:getChildByName("btn_all"):setTag(10019)
                        node:getChildByName("btn_all"):addClickEventListener(function()
                        	cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
                        	local strData = Tools.encode("PlanetTowerReq", {
								type = 2,
								element_global_key = info.global_key,
							 })
							GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_TOWER_REQ"),strData)
                        	end)
                    else -- showopen
                        node:getChildByName("btn_all"):getChildByName('Text'):setString(CONF:getStringValue('open')) -- open
                        node:getChildByName("btn_all"):setTag(10018)
                        node:getChildByName("btn_all"):addClickEventListener(function()
                        	cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
                        	local strData = Tools.encode("PlanetTowerReq", {
								type = 1,
								element_global_key = info.global_key,
							 })
							GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_TOWER_REQ"),strData)
                        	end)
                    end
                    node:getChildByName("Button_3"):addClickEventListener(function()
                    	cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
                    	cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
                    	local canClick = true
						if Tools.isEmpty(planetManager:getPlanetUser( )) == false then
							if Tools.isEmpty(planetManager:getPlanetUser( ).army_list) == false then
								if #planetManager:getPlanetUser( ).army_list >= CONF.BUILDING_1.get(player:getBuildingInfo(1).level).ARMY_NUM then
									canClick = false
									tips:tips(CONF:getStringValue("notice maxTeam"))
								end
							end
						end
						if #(tower_data.guarde_list) >= conf.TROOPS_LIMIT then
							tips:tips(CONF:getStringValue("stationed_upperlimit"))
							canClick = false
						end
						if canClick then
							if tower_data.status and tower_data.status == 1 then
								tips:tips(CONF:getStringValue("peace_cannot_be_attacked"))
							else
								cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
								app:addView2Top("NewFormLayer",{from="bigMapRaid",element_global_key=info.global_key,type=3,cfg_type = 'TOWER',cfg_id = tower_data.id})
							end
						end
                    	end)
                    node:getChildByName("Button_5"):addClickEventListener(function()
                        	cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
                        	cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
                        	local canBack = false
							local canBackList = {}
							if Tools.isEmpty(tower_data.guarde_list) == false then
								for k,v in ipairs(tower_data.guarde_list) do
									local user_name = Tools.split(v,"_")[1]
									if tostring(player:getName()) == user_name then
										canBack = true
										table.insert(canBackList,tonumber(Tools.split(v,"_")[2]))
									end
								end
							end
							if not canBack then
								tips:tips(CONF:getStringValue("no_stationed"))
							else
                                local function click()
								    cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
								    local strData = Tools.encode("PlanetRideBackReq", {
									    type = 2,
									    army_guid = canBackList,
								     })
								    GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_RIDE_BACK_REQ"),strData)
                                end
                                local messageBox = require("util.MessageBox"):getInstance()
			                    messageBox:reset(CONF:getStringValue("ishuicheng"), click)
							end
                        	end)
                end
                ---- on-state
                if tower_data.status == 1 then -- 1:peace
                    print("peace state")
                    cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
                elseif tower_data.status == 2 then
                    node:getChildByName("Button_5"):setVisible(true)
                    node:getChildByName("Button_1"):setVisible(true)
                    node:getChildByName("Button_1"):getChildByName('Text'):setString(CONF:getStringValue('information')) -- information
                    node:getChildByName("Button_1"):setTag(10015)
                    node:getChildByName('Button_1'):addClickEventListener(function()
					    cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
					    app:addView2Top("PlanetScene/PlanetDetail/PlanetDetailType_wangzuo",{info = info})
					end)
                    ---- occupy-state

                    if tower_data.user_name then
                    	if tower_data.user_name ~= "" then
                    		if tower_data.user_name == player:getName() then
	                    		myself()
	                    	else
	                    		if tower_data.groupid and tower_data.groupid ~= "" then
	                    			if player:isGroup() and player:getGroupData().groupid == tower_data.groupid then
	                    				league()
	                    			else
	                    				hostile()
	                    			end
	                    		else
	                    			hostile()
	                    		end
	                    	end
                    	else
                    		hostile()
                    	end
                    end
                end

			end
		end
	end
	for i=1,5 do
		local tag = node:getChildByName("Button_"..i):getTag()
		if tag >= 10001 and tag <= 10019 then 
			node:getChildByName("Button_"..i):getChildByName("sp"):setVisible(true)
			node:getChildByName("Button_"..i):getChildByName("sp"):setTexture(btnTag[tag])
		end
	end
    return node
end

return PlanetSelectNode