local gl = require("util.GlobalLoading"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local ServerSelectLayer = class("ServerSelectLayer", cc.load("mvc").ViewBase)

ServerSelectLayer.RESOURCE_FILENAME = "LoginScene/ServerSelectLayer.csb"

ServerSelectLayer.NEED_ADJUST_POSITION = true

ServerSelectLayer.RESOURCE_BINDING = {
	["close"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

function ServerSelectLayer:OnBtnClick(event)
	printInfo(event.name)
	if event.name == "ended" and event.target:getName() == "close" then
		
		animManager:runAnimOnceByCSB(self:getResourceNode(), "LoginScene/ServerSelectLayer.csb", "animation0", function ( ... )
				self:getApp():removeTopView()
		end)

		-- local app = require("app.MyApp"):getInstance()
		-- app:addView2Top("LoginScene/StartLayer", {ani = "stop"})
	end
end

function ServerSelectLayer:loadServerList()
	
	local server_list = display.getRunningScene():getChildByName("LoginScene/LoginScene"):getServers()

	local function buttonClickCallback(sender)

		local server = server_list[sender:getTag()]

		local ud = cc.UserDefault:getInstance()
		-- BUG WJJ 180718
		ud:setIntegerForKey("server_id", tonumber(server.id or 0))
		ud:setStringForKey("server_address", server.ip)
		ud:setIntegerForKey("server_port", tonumber(server.pt or 0))
		ud:setStringForKey("server_version", server.vn)


		-- Added by Wei Jingjun 20180531 for Dangle SDK bug
		ud:setStringForKey("server_name", server.nm)


		ud:flush()

		cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("changeServer")
		self:getApp():removeTopView()

		-- local app = require("app.MyApp"):getInstance()
		-- app:addView2Top("LoginScene/StartLayer", {ani = "stop"})
	end

	local function createLab(index)

		local server = server_list[index]

		local lab = require("app.ExResInterface"):getInstance():FastLoad("LoginScene/server_lab.csb")

		lab:getChildByName("name"):setString(server.nm)

		local icon_string = {"server_unimpedede", "server_full", "server_maintain"}

		if server.st > -1 and server.st < 3 then
			lab:getChildByName("icon"):setTexture("LoginScene/ui/"..icon_string[server.st+1]..".png")
			lab:getChildByName("state"):setString(CONF.STRING.get(string.format("server_state_%d", server.st)).VALUE)

			if server.st == 0 then
				lab:getChildByName("state"):setTextColor(cc.c4b(126,243,142,255))
				-- lab:getChildByName("state"):enableShadow(cc.c4b(126,243,142,255), cc.size(0.5,0.5))
			elseif server.st == 1 then
				lab:getChildByName("state"):setTextColor(cc.c4b(245,93,88,255))
				-- lab:getChildByName("state"):enableShadow(cc.c4b(245,93,88,255), cc.size(0.5,0.5))
			elseif server.st == 2 then
				lab:getChildByName("state"):setTextColor(cc.c4b(222,222,222,255))
				-- lab:getChildByName("state"):enableShadow(cc.c4b(222,222,222,255), cc.size(0.5,0.5))
			end
		end

		local button = lab:getChildByName("button")
		button:setTag(index)
		button:addClickEventListener(buttonClickCallback)

		return lab
	end

	for i,v in ipairs(server_list) do
		
		self.serverList_:addElement(createLab(i))
	end

end

function ServerSelectLayer:onEnterTransitionFinish()
	printInfo("ServerSelectLayer:onEnterTransitionFinish()")

	local res = self:getResourceNode()

	res:getChildByName("layer_name"):setString(CONF:getStringValue("select_server"))

	res:getChildByName("title"):setString(CONF:getStringValue("server_list"))

--    animManager:runAnimByCSB(res:getChildByName("number"),"LoginScene/sfx/number/suzibofang.csb","1")
--    animManager:runAnimByCSB(res:getChildByName("squres"),"LoginScene/sfx/squres/squres.csb","1")
	animManager:runAnimOnceByCSB(self:getResourceNode(), "LoginScene/ServerSelectLayer.csb", "animation", function ( ... )
		
		end)



	self.serverList_ = require("util.ScrollViewDelegate"):create(res:getChildByName("list"),cc.size(5,5),cc.size(267,71))
	-- local sv = self.serverList_:getScrollView()
	res:getChildByName("list"):setScrollBarEnabled(false)
	res:getChildByName("list_server"):setScrollBarEnabled(false)
	
	self:loadServerList()
end

function ServerSelectLayer:onExitTransitionStart()
	printInfo("ServerSelectLayer:onExitTransitionStart()")

end

return ServerSelectLayer