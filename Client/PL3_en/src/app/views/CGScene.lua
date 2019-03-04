local animManager = require("app.AnimManager"):getInstance()

local CGScene = class("CGScene", cc.load("mvc").ViewBase)

CGScene.RESOURCE_FILENAME = "cg/cg.csb"
CGScene.NEED_ADJUST_POSITION = true

function CGScene:onEnterTransitionFinish()
	printInfo("CGScene:onEnterTransitionFinish()")

	local rn = self:getResourceNode()

	for i=1,7 do
		local index = i + 1
		rn:getChildByName("part"..i):setString(CONF:getStringValue("novice_01"..index))
	end

	rn:getChildByName("btn_tiao"):addClickEventListener(function ( ... )
		self:getApp():pushToRootView("RegisterScene/RegisterPlayerScene")
	end)

	animManager:runAnimOnceByCSB(rn, "cg/cg.csb",  "1", function ()
		local resp = {
			result = 0,
			type = 0,
			attack_list = {},
			hurter_list = {},
		}
		for index,id in ipairs(CONF.PARAM.get("test_my_ship_list").PARAM) do
			if id > 0 then
				local ship_info = Tools.createShipByConf(id)
				ship_info.position = index
				ship_info.body_position = {index}
				table.insert(resp.attack_list, ship_info)
			end
		end
		for index,id in ipairs(CONF.PARAM.get("test_enemy_ship_list").PARAM) do
			if id > 0 then
				local ship_info = Tools.createShipByConf(id)
				ship_info.position = index
				ship_info.body_position = {index}
				table.insert(resp.hurter_list, ship_info)
			end
		end
		
		-- self:getApp():pushToRootView("BattleScene/BattleScene", {BattleType.kTest, resp, true, CONF:getStringValue("tester"), "RoleIcon/4.png"})
	
		self:getApp():pushToRootView("RegisterScene/RegisterPlayerScene")
	end)
end

function CGScene:onExitTransitionStart()
	printInfo("CGScene:onExitTransitionStart()")

end

return CGScene