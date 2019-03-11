local player = require("app.Player"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local winSize = cc.Director:getInstance():getWinSize()

local gl = require("util.GlobalLoading"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()

local LotteryScene = class("LotteryScene", cc.load("mvc").ViewBase)

LotteryScene.RESOURCE_FILENAME = "LotteryScene/LotteryScene.csb"

LotteryScene.RUN_TIMELINE = true

LotteryScene.NEED_ADJUST_POSITION = true

LotteryScene.RESOURCE_BINDING = {
	--["Button_1"]   = {["varname"] = "btn"},
	["close"]={["parent"]="SHIPEI_TOP_BANNER", ["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

local schedulerEntry = nil

local max_lottery_num = 30
	print("~~~ LotteryScene.lua 33")
function LotteryScene:onCreate(data)
	self.data_ = data

end

function LotteryScene:OnBtnClick(event)
	printInfo(event.name)


	if event.name == "ended" and event.target:getName() == "close" then
		printInfo("close")

		if self.ani_ then
			return
		end

		-- self:getApp():popView()
		self:getApp():pushToRootView("CityScene/CityScene", {pos = -1350})
	end

end

function LotteryScene:onEnter()
  
	printInfo("LotteryScene:onEnter()")

end

function LotteryScene:onExit()
	
	printInfo("LotteryScene:onExit()")
end
	print("~~~ LotteryScene.lua 66")
function LotteryScene:resetRes( ... )

	local rn = self:getResourceNode()
	--set res

	-- for i=1,4 do
	-- 	local res = rn:getChildByName(string.format("res_%d", i))

	-- 	res:getChildByName("text"):setString(formatRes(player:getResByIndex(i)))
	-- end
	rn:getChildByName("SHIPEI_TOP_BANNER"):getChildByName("res_1"):getChildByName("text"):setString(formatRes(player:getResByIndex(1)))
	--set credit

	rn:getChildByName("SHIPEI_TOP_BANNER"):getChildByName("res_5"):getChildByName("text"):setString(tostring(player:getMoney()))--formatRes(player:getMoney()))
end

function LotteryScene:resetInfo()
	local gold_data = player:getLotteryInfo(1)
	local money_data = player:getLotteryInfo(2)

	local gold_conf = CONF.SHIP_LOTTERY.get(1)
	local money_conf = CONF.SHIP_LOTTERY.get(2)

	local rn = self:getResourceNode()
	local gold_ins = rn:getChildByName("gold_ins")
	rn:getChildByName("cishu_num"):setString(CONF:getStringValue("residue time")..":"..(CONF.VIP.get(player:getVipLevel()).CREDIT_LOTTERY_TIMES - player:getDailyLotteryCount()))

	if gold_data.single_times%(gold_conf.HEAP) ~= 0 or gold_data.single_times == 0 then
		gold_ins:getChildByName("num"):setVisible(true)
		gold_ins:getChildByName("string_2"):setVisible(true)

		gold_ins:getChildByName("string_1"):setString(CONF:getStringValue("buy_after_1"))
		gold_ins:getChildByName("num"):setString(gold_conf.HEAP - gold_data.single_times)
		gold_ins:getChildByName("num"):setPositionX(gold_ins:getChildByName("string_1"):getPositionX() + gold_ins:getChildByName("string_1"):getContentSize().width)
		gold_ins:getChildByName("string_2"):setPositionX(gold_ins:getChildByName("num"):getPositionX() + gold_ins:getChildByName("num"):getContentSize().width)
		gold_ins:getChildByName("string_3"):setPositionX(gold_ins:getChildByName("string_2"):getPositionX() + gold_ins:getChildByName("string_2"):getContentSize().width)
		gold_ins:getChildByName("string_4"):setPositionX(gold_ins:getChildByName("string_3"):getPositionX() + gold_ins:getChildByName("string_3"):getContentSize().width)

	else
		gold_ins:getChildByName("string_1"):setString(CONF:getStringValue("buy_after_3"))
		gold_ins:getChildByName("num"):setVisible(false)
		gold_ins:getChildByName("string_2"):setVisible(false)

		gold_ins:getChildByName("string_3"):setPositionX(gold_ins:getChildByName("string_1"):getPositionX() + gold_ins:getChildByName("string_1"):getContentSize().width)
		gold_ins:getChildByName("string_4"):setPositionX(gold_ins:getChildByName("string_3"):getPositionX() + gold_ins:getChildByName("string_3"):getContentSize().width)
	end

	local money_ins = rn:getChildByName("money_ins")
	if money_data.single_times%(money_conf.HEAP) ~= 0 or money_data.single_times == 0 then
		money_ins:getChildByName("num"):setVisible(true)
		money_ins:getChildByName("string_2"):setVisible(true)

		money_ins:getChildByName("string_1"):setString(CONF:getStringValue("buy_after_1"))
		money_ins:getChildByName("num"):setString(money_conf.HEAP - money_data.single_times)
		money_ins:getChildByName("num"):setPositionX(money_ins:getChildByName("string_1"):getPositionX() + money_ins:getChildByName("string_1"):getContentSize().width)
		money_ins:getChildByName("string_2"):setPositionX(money_ins:getChildByName("num"):getPositionX() + money_ins:getChildByName("num"):getContentSize().width)
		money_ins:getChildByName("string_3"):setPositionX(money_ins:getChildByName("string_2"):getPositionX() + money_ins:getChildByName("string_2"):getContentSize().width)
		money_ins:getChildByName("string_4"):setPositionX(gold_ins:getChildByName("string_3"):getPositionX() + gold_ins:getChildByName("string_3"):getContentSize().width)
	else
		money_ins:getChildByName("string_1"):setString(CONF:getStringValue("buy_after_3"))
		money_ins:getChildByName("num"):setVisible(false)
		money_ins:getChildByName("string_2"):setVisible(false)

		money_ins:getChildByName("string_3"):setPositionX(money_ins:getChildByName("string_1"):getPositionX() + money_ins:getChildByName("string_1"):getContentSize().width)
		money_ins:getChildByName("string_4"):setPositionX(gold_ins:getChildByName("string_3"):getPositionX() + gold_ins:getChildByName("string_3"):getContentSize().width)
	end

	local gold_one = rn:getChildByName("gold_one")

	if gold_data.cd_start_time == 0 and gold_data.free_times > 0 then
		gold_one:getChildByName("free_text"):setVisible(true)
		gold_one:getChildByName("icon"):setVisible(false)
		gold_one:getChildByName("text"):setVisible(false)
		gold_one:getChildByName("time_text"):setString(CONF:getStringValue("residue degree")..":"..gold_data.free_times)
		gold_one:getChildByName("green"):setVisible(true)
	else
		gold_one:getChildByName("green"):setVisible(false)
		gold_one:getChildByName("free_text"):setVisible(false)
		gold_one:getChildByName("icon"):setVisible(true)
		gold_one:getChildByName("text"):setVisible(true)

		local diff = gold_conf.SINGLE_CD - (player:getServerTime() - gold_data.cd_start_time)
		gold_one:getChildByName("time_text"):setString(formatTime(diff)..CONF:getStringValue("after_free"))

		if gold_data.free_times == 0 then
			gold_one:getChildByName("time_text"):setString("")
		else
			if diff <= 0 then
				local strData = Tools.encode("ShipLotteryReq", {
					id = 1,
					type = 0,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SHIP_LOTTERY_REQ"),strData)

				gl:retainLoading()
			end
		end
	end

	local money_one = rn:getChildByName("money_one")
	if money_data.add_free_start_time == 0 then
		money_one:getChildByName("green"):setVisible(true)
		money_one:getChildByName("free_text"):setVisible(true)
		money_one:getChildByName("icon"):setVisible(false)
		money_one:getChildByName("text"):setVisible(false)

		money_one:getChildByName("time_text"):setString("")
	else
		money_one:getChildByName("green"):setVisible(false)
		money_one:getChildByName("free_text"):setVisible(false)
		money_one:getChildByName("icon"):setVisible(true)
		money_one:getChildByName("text"):setVisible(true)

		local diff = money_conf.RESET - (player:getServerTime() - money_data.add_free_start_time)
		money_one:getChildByName("time_text"):setString(formatTime(diff)..CONF:getStringValue("after_free"))

		if diff <= 0 then
			local strData = Tools.encode("ShipLotteryReq", {
				id = 2,
				type = 0,
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SHIP_LOTTERY_REQ"),strData)

			gl:retainLoading()
		end
	end
end
	print("~~~ LotteryScene.lua 194")
function LotteryScene:createAniNode( type,item_list ) -- 1.dan 2.10

	local rn = self:getResourceNode()

	-- self.ani_ = true

	local node = require("app.ExResInterface"):getInstance():FastLoad("LotteryScene/aniNode.csb")

	-- node:getChildByName("text"):setString(CONF:getStringValue("lottery_after"))

	if type == 1 then

		if CONF.ITEM.get(item_list[1].id).TYPE == 18 then
			table.insert(self.get_ship, CONF.ITEM.get(item_list[1].id).KEY)
		end

		local item_node = require("util.ItemNode"):create():init(item_list[1].id, item_list[1].num)
		item_node:setScale(1.3)
		
		item_node:getChildByName("icon"):setSwallowTouches(true)

		item_node:setPosition(cc.p(node:getChildByName("item"):getPosition()))
		node:addChild(item_node)

		self:showGetShip()
		-- node:getChildByName("item"):removeFromParent()

	elseif type == 2 then
		for i,v in ipairs(item_list) do

			if CONF.ITEM.get(v.id).TYPE == 18 then
				table.insert(self.get_ship, CONF.ITEM.get(v.id).KEY)
			end

			local item_node = require("util.ItemNode"):create():init(v.id, v.num)
			item_node:setScale(1.3)

			item_node:setName("item_"..i)
			item_node:setPosition(cc.p(node:getChildByName("item"):getPosition()))
			item_node:setLocalZOrder(11-i)
			item_node:setOpacity(0)
			node:addChild(item_node)

			item_node:getChildByName("icon"):setSwallowTouches(true)

			item_node:runAction(cc.Sequence:create(cc.DelayTime:create(0.1*(i-1)), cc.FadeIn:create(0.1),cc.MoveTo:create(0.1, cc.p(node:getChildByName("pos_"..i):getPosition())), cc.CallFunc:create(function ( ... )
				if i == #item_list then
					self:showGetShip()
				end
			end)))
		end

		node:getChildByName("item"):removeFromParent()

	end

	local time = 0.2 
	if type == 2 then
		time = 1.2
	end
	-- node:runAction(cc.Sequence:create(cc.DelayTime:create(time), cc.CallFunc:create(function ( ... )
	-- 	self.ani_ = false
	-- end)))
	
	node:setPosition(cc.p(rn:getChildByName("node_pos"):getPosition()))
	node:setName("ani_node")
	rn:addChild(node)

end

function LotteryScene:showGetShip( )
	if Tools.isEmpty(self.get_ship) then
		return
	end

	local layer = self:getApp():createView("ShipDevelopScene/DevelopSucessLayer", {data = CONF.AIRSHIP.get(self.get_ship[1]), type = "lottery"})
	self:addChild(layer)

	-- table.remove(self.get_ship,1)
	self.get_ship = {}
end

function LotteryScene:nodeRunAction( flag )

	local dic = 400

	local rn = self:getResourceNode()
	local money_ins = rn:getChildByName("money_ins")
	local gold_ins = rn:getChildByName("gold_ins")
	local gold_one = rn:getChildByName("gold_one")
	local gold_ten = rn:getChildByName("gold_ten")
	local money_one = rn:getChildByName("money_one")
	local money_ten = rn:getChildByName("money_ten")

	local function run( node )
		if flag then
			node:runAction(cc.Spawn:create(cc.MoveBy:create(0.5, cc.p(0, -dic)), cc.FadeOut:create(0.5)))


		else
			node:runAction(cc.Spawn:create(cc.MoveBy:create(0.5, cc.p(0, dic)), cc.FadeIn:create(0.5)))
		end
	end

	run(money_ins)
	run(gold_ins)
	run(gold_one)
	run(gold_ten)
	run(money_one)
	run(money_ten)
	
end

function LotteryScene:onEnterTransitionFinish()

	printInfo("LotteryScene:onEnterTransitionFinish()")

	self.ani_ = false
	self.get_ship = {}

	guideManager:checkInterface(CONF.EInterface.kLottery)
	if player:getSystemGuideStep(CONF.ESystemGuideInterFace.kLottery)== 0 and g_System_Guide_Id == 0 then
		systemGuideManager:createGuideLayer(CONF.FUNCTION_OPEN.get("city_2_open").INTERFACE)
	else
		if g_System_Guide_Id ~= 0 then
			systemGuideManager:createGuideLayer(g_System_Guide_Id)
		end
	end

	local rn = self:getResourceNode()

	animManager:runAnimOnceByCSB(rn, "LotteryScene/LotteryScene.csb", "intro", function ( ... )
		-- animManager:runAnimByCSB(rn:getChildByName("circle"), "LotteryScene/choujiang.csb", "0")
	end)

	animManager:runAnimOnceByCSB(rn:getChildByName("circle"), "LotteryScene/choujiang.csb", "0", function ( ... )
		animManager:runAnimByCSB(rn:getChildByName("circle"), "LotteryScene/choujiang.csb", "1")
	end)

	rn:getChildByName("SHIPEI_TOP_BANNER"):getChildByName("name"):setString(CONF:getStringValue("BuildingName_8"))

	rn:getChildByName("btn_show"):getChildByName("time_text"):setString(CONF:getStringValue("jackpot"))
	rn:getChildByName("btn_show"):addClickEventListener(function()
		playEffectSound("sound/system/click.mp3")
		local lotteryShowNode = require("app.views.LotteryScene.LotteryShowNode"):create()

		lotteryShowNode:init(self:getParent(), {index = 1})
		self:getParent():addChild(lotteryShowNode)
		end)
	rn:getChildByName("bg"):setSwallowTouches(true)
	rn:getChildByName("bg"):addClickEventListener(function ( ... )

		if not self.ani_ then
			if rn:getChildByName("ani_node") then
				
				rn:getChildByName("ani_node"):removeFromParent()

				self:nodeRunAction(false)
				animManager:runAnimByCSB(rn:getChildByName("circle"), "LotteryScene/choujiang.csb", "1")
			end

			-- animManager:runAnimByCSB(rn:getChildByName("circle"), "LotteryScene/circle.csb", "0")
		end
	end)

	local gold_ins = rn:getChildByName("gold_ins")
	gold_ins:getChildByName("string_1"):setString(CONF:getStringValue("buy_after_1"))
	gold_ins:getChildByName("string_2"):setString(CONF:getStringValue("buy_after_2"))
	gold_ins:getChildByName("string_3"):setString(CONF:getStringValue("purple_spacecraft_drawings"))
	gold_ins:getChildByName("string_4"):setString(string.format("(%s%s)", CONF:getStringValue("ten_tips"), CONF:getStringValue("purple_spacecraft_drawings")))

	local money_ins = rn:getChildByName("money_ins")
	money_ins:getChildByName("string_1"):setString(CONF:getStringValue("buy_after_1"))
	money_ins:getChildByName("string_2"):setString(CONF:getStringValue("buy_after_2"))
	money_ins:getChildByName("string_3"):setString(CONF:getStringValue("orange_spacecraft_drawings"))
	money_ins:getChildByName("string_4"):setString(string.format("(%s%s)", CONF:getStringValue("ten_tips"), CONF:getStringValue("orange_spacecraft_drawings")))

	rn:getChildByName("gold_ten"):getChildByName("time_text"):setString(CONF:getStringValue("buy_ten"))
	rn:getChildByName("money_ten"):getChildByName("time_text"):setString(CONF:getStringValue("buy_ten"))
	rn:getChildByName("gold_one"):getChildByName("free_text"):setString(CONF:getStringValue("free"))
	rn:getChildByName("money_one"):getChildByName("free_text"):setString(CONF:getStringValue("free"))

	local gold_conf = CONF.SHIP_LOTTERY.get(1)
	local money_conf = CONF.SHIP_LOTTERY.get(2)

	rn:getChildByName("gold_one"):getChildByName("text"):setString(gold_conf.SINGLE)
	rn:getChildByName("gold_ten"):getChildByName("text"):setString(gold_conf.MULTI)
	rn:getChildByName("money_one"):getChildByName("text"):setString(money_conf.SINGLE)
	rn:getChildByName("money_ten"):getChildByName("text"):setString(money_conf.MULTI)

	self:resetRes()
	-- self:resetInfo()

	local function addMoney( )
		playEffectSound("sound/system/click.mp3")
		if self.ani_ then
			return
		end

		local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

		rechargeNode:init(self, {index = 1})
		self:addChild(rechargeNode)

	end

	rn:getChildByName("SHIPEI_TOP_BANNER"):getChildByName("res_5"):getChildByName("money_touch"):addClickEventListener(addMoney)
	rn:getChildByName("SHIPEI_TOP_BANNER"):getChildByName("res_5"):getChildByName("add"):addClickEventListener(addMoney)

	rn:getChildByName("gold_one"):addClickEventListener(function ( ... )
		if self.ani_ then
			return
		end

		-- if player:getDailyLotteryCount() + 1 > max_lottery_num then
		-- 	tips:tips(CONF:getStringValue("starport upper limit"))
		-- 	return
		-- end

		if rn:getChildByName("ani_node") then
			rn:getChildByName("ani_node"):removeFromParent()
		end

		if player:getResByIndex(1) < tonumber(rn:getChildByName("gold_one"):getChildByName("text"):getString()) and rn:getChildByName("gold_one"):getChildByName("free_text"):isVisible() == false then
			tips:tips(CONF:getStringValue("notEnoughGold"))
			return
		end

		local strData = Tools.encode("ShipLotteryReq", {
			id = 1,
			type = 1,
		})
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SHIP_LOTTERY_REQ"),strData)

		gl:retainLoading()
	end)

	rn:getChildByName("gold_ten"):addClickEventListener(function ( ... )

		if self.ani_ then
			return
		end

		-- if player:getDailyLotteryCount() + 10 > max_lottery_num then
		-- 	tips:tips(CONF:getStringValue("starport upper limit"))
		-- 	return
		-- end

		if rn:getChildByName("ani_node") then
			rn:getChildByName("ani_node"):removeFromParent()
		end

		if player:getResByIndex(1) < tonumber(rn:getChildByName("gold_ten"):getChildByName("text"):getString()) then
			tips:tips(CONF:getStringValue("notEnoughGold"))
			return
		end

		local strData = Tools.encode("ShipLotteryReq", {
			id = 1,
			type = 2,
		})
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SHIP_LOTTERY_REQ"),strData)

		gl:retainLoading()
	end)

	rn:getChildByName("money_one"):addClickEventListener(function ( ... )
		if self.ani_ then
			return
		end

		if player:getDailyLotteryCount() + 1 > CONF.VIP.get(player:getVipLevel()).CREDIT_LOTTERY_TIMES then
			tips:tips(CONF:getStringValue("starport upper limit"))
			return
		end

		if rn:getChildByName("ani_node") then
			rn:getChildByName("ani_node"):removeFromParent()
		end

		if player:getMoney() < tonumber(rn:getChildByName("money_one"):getChildByName("text"):getString()) and rn:getChildByName("money_one"):getChildByName("free_text"):isVisible() == false then
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

		local strData = Tools.encode("ShipLotteryReq", {
			id = 2,
			type = 1,
		})
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SHIP_LOTTERY_REQ"),strData)

		gl:retainLoading()
	end)

	rn:getChildByName("money_ten"):addClickEventListener(function ( ... )
		if self.ani_ then
			return
		end

		if player:getDailyLotteryCount() + 10 > CONF.VIP.get(player:getVipLevel()).CREDIT_LOTTERY_TIMES then
			tips:tips(CONF:getStringValue("starport upper limit"))
			return
		end

		if rn:getChildByName("ani_node") then
			rn:getChildByName("ani_node"):removeFromParent()
		end

		if player:getMoney() < tonumber(rn:getChildByName("money_ten"):getChildByName("text"):getString()) then
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

		local strData = Tools.encode("ShipLotteryReq", {
			id = 2,
			type = 2,
		})
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SHIP_LOTTERY_REQ"),strData)

		gl:retainLoading()
	end)

	if player:getLotteryInfo(1) == nil then     
		local strData = Tools.encode("ShipLotteryReq", {
				id = 1,
				type = 0,
			})
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SHIP_LOTTERY_REQ"),strData)

		gl:retainLoading()

		self.update_ = false
	else
		self.update_ = true
		self:resetInfo()
	end

	local function update(dt)

		self:resetInfo()

	end
	schedulerEntry = scheduler:scheduleScriptFunc(update,1,false)

	local function recvMsg()
		print("LotteryScene:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_SHIP_LOTTERY_RESP") then
			playEffectSound("sound/system/course_card.mp3")
			gl:releaseLoading()
			
			local proto = Tools.decode("ShipLotteryResp",strData)

			print("itemnum", #proto.item_list)

			if proto.result ~= 0 then
				print("error :",proto.result)
			else

				if not self.update_ then

					local strData = Tools.encode("ShipLotteryReq", {
							id = 2,
							type = 0,
						})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SHIP_LOTTERY_REQ"),strData)

					gl:retainLoading()

					self.update_ = true
				else
					self:resetInfo()
					self:resetRes()
					
					if #proto.item_list == 1 then
						self.ani_ = true

						self:nodeRunAction(true)

						animManager:runAnimOnceByCSB(rn:getChildByName("circle"), "LotteryScene/choujiang.csb", "2", function ( ... )
							
							animManager:runAnimByCSB(rn:getChildByName("circle"), "LotteryScene/choujiang.csb", "1")

							self.ani_ = false

							-- if rn:getChildByName("ani_node") then
							--     rn:getChildByName("ani_node"):removeFromParent()
							-- end
						end)

						self:runAction(cc.Sequence:create(cc.DelayTime:create(5), cc.CallFunc:create(function ( ... )
							self:createAniNode(1, proto.item_list)
						end)))
						
					elseif #proto.item_list == 10 then
						self.ani_ = true

						self:nodeRunAction(true)

						animManager:runAnimOnceByCSB(rn:getChildByName("circle"), "LotteryScene/choujiang.csb", "3", function ( ... )
							animManager:runAnimByCSB(rn:getChildByName("circle"), "LotteryScene/choujiang.csb", "1")

							self.ani_ = false

							-- if rn:getChildByName("ani_node") then
							--     rn:getChildByName("ani_node"):removeFromParent()
							-- end
						end)

						self:runAction(cc.Sequence:create(cc.DelayTime:create(5), cc.CallFunc:create(function ( ... )
							self:createAniNode(2, proto.item_list)
						end)))
					end
				end

			end
			
		end
	end
		
	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

	self.resListener_ = cc.EventListenerCustom:create("ResUpdated", function ()
		self:resetRes()
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.resListener_, FixedPriority.kNormal)

	self.moneyListener_ = cc.EventListenerCustom:create("MoneyUpdated", function ()
		self:resetRes()
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.moneyListener_, FixedPriority.kNormal)

	self.shipListener_ = cc.EventListenerCustom:create("get_ship", function ()
		self:showGetShip()
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.shipListener_, FixedPriority.kNormal)

	-- WJJ 180724
	require("util.ExConfigScreenAdapter"):getInstance():onFixQuanmianping_Choujiang(self)
end
	print("~~~ LotteryScene.lua 656")

function LotteryScene:onExitTransitionStart()

	printInfo("LotteryScene:onExitTransitionStart()")

	if schedulerEntry ~= nil then
	  scheduler:unscheduleScriptEntry(schedulerEntry)
	end

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
	eventDispatcher:removeEventListener(self.resListener_)
	eventDispatcher:removeEventListener(self.moneyListener_)
	eventDispatcher:removeEventListener(self.shipListener_)

end
	print("~~~ LotteryScene.lua 673")
return LotteryScene