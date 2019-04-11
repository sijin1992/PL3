local player = require("app.Player"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local TransferScene = class("TransferScene", cc.load("mvc").ViewBase)

local animManager = require("app.AnimManager"):getInstance()

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

TransferScene.RESOURCE_FILENAME = "PlanetScene/sfx/TransferEffect/transfer.csb"

TransferScene.NEED_ADJUST_POSITION = true

-- ADD WJJ 20180625
TransferScene.memoryInterface = require("app.ExMemoryInterface"):getInstance()
TransferScene.DELAY_TIME_PLAY = 0.3
TransferScene.DELAY_TIME_ADD = 0.1
TransferScene.DELAY_TIME = TransferScene.DELAY_TIME_PLAY + TransferScene.DELAY_TIME_ADD
TransferScene.DELAY_TIME_RELEASE = 1

TransferScene.KEY_OLD_SCENE = "global_transfer_old_scene_name"

TransferScene.fadeOutAction = {}
TransferScene.lagHelper = require("util.ExLagHelper"):getInstance()


function TransferScene:SetOldSceneName(_scene)
	-- cc.UserDefault:getInstance():setStringForKey(self.KEY_OLD_SCENE, tostring(_scene))
	-- cc.UserDefault:getInstance():flush()
	cc.exports.KEY_OLD_SCENE = tostring(_scene)
end

function TransferScene:GetOldSceneName()
	-- local old_scene = cc.UserDefault:getInstance():getStringForKey(self.KEY_OLD_SCENE)
	local old_scene = cc.exports.KEY_OLD_SCENE
	return old_scene
end

function TransferScene:onCreate(data)
	self.data_ = data
	self:SetOldSceneName(self.data_.from)
end

-- math.randomseed(tostring(os.time()):reverse():sub(1, 6))

function TransferScene:ToNextScene()

	local _self = require("app.views.CityScene.TransferScene")
	-- local _self = TransferScene
	-- local old_scene = _self.data_.from

	local old_scene = _self:GetOldSceneName()
	local _app = require("app.MyApp"):getInstance()
    local _node = display.getRunningScene()
	if ( old_scene == "planet" ) then
		_node:runAction(cc.Sequence:create(cc.DelayTime:create(0.1), cc.CallFunc:create(function ( ... )
			_app:pushToRootView("PlanetScene/PlanetScene", {come_in_type = 1,sfx = true})
		end)))
	elseif ( old_scene == "city" ) then
        _node:runAction(cc.Sequence:create(cc.DelayTime:create(0.1), cc.CallFunc:create(function ( ... )
			_app:pushToRootView("CityScene/CityScene", {pos = g_city_scene_pos,sfx = true})
		end)))
	elseif ( old_scene == "city2" ) then
        _node:runAction(cc.Sequence:create(cc.DelayTime:create(0.1), cc.CallFunc:create(function ( ... )
		    _app:pushToRootView("CityScene/CityScene", {pos = -1350,sfx = true})
		end)))
	elseif ( old_scene == "home" ) then
        _node:runAction(cc.Sequence:create(cc.DelayTime:create(0.1), cc.CallFunc:create(function ( ... )
		    _app:pushToRootView("HomeScene/HomeScene",{sfx = true})
		end)))
	elseif ( old_scene == "ChapterScene" ) then
        _node:runAction(cc.Sequence:create(cc.DelayTime:create(0.1), cc.CallFunc:create(function ( ... )
		    _app:pushToRootView("ChapterScene",{sfx = true})
		end)))
	elseif ( old_scene == "LoginScene" ) then
        _node:runAction(cc.Sequence:create(cc.DelayTime:create(0.1), cc.CallFunc:create(function ( ... )
		    _app:pushToRootView("UpdateScene",{sfx = true})
		end)))
	elseif ( (old_scene == "UpdateScene") or ( old_scene == "RegisterScene/RegisterShipScene" ) or ( old_scene == "BattleScene/WinLayer" )  ) then
        _node:runAction(cc.Sequence:create(cc.DelayTime:create(0.1), cc.CallFunc:create(function ( ... )
		    _app:pushToRootView("CityScene/CityScene", {pos = -1350})
		end)))
	elseif ( (old_scene == "BlueprintScene/BlueprintScene") or (old_scene == "ShipsScene/ShipsDevelopScene") or (old_scene == "BuildingUpgradeScene/BuildingUpgradeScene") ) then
		-- _app:popView()
        _node:runAction(cc.Sequence:create(cc.DelayTime:create(0.1), cc.CallFunc:create(function ( ... )
		    _app:pushToRootView("CityScene/CityScene", {pos = g_city_scene_pos})
		end)))
	elseif ( old_scene == "CitySceneGoShipsForm" ) then
		-- _app:pushView("ShipsScene/ShipsDevelopScene",{type = player:getTypeToShipsScene(), go = "form"})
        _node:runAction(cc.Sequence:create(cc.DelayTime:create(0.1), cc.CallFunc:create(function ( ... )
		    _app:pushToRootView("ShipsScene/ShipsDevelopScene",{type = require("app.Player"):getInstance():getTypeToShipsScene(), go = "form"})
		end)))

	elseif ( (old_scene == "ShopScene/ShopLayer") or (old_scene == "ActivityScene/ActivityScene") ) then
		local params = self.lagHelper.oldSceneParams[old_scene]
		_app:pushToRootView(old_scene, params)
		self.lagHelper.oldSceneParams[old_scene] = nil
	end

end

function TransferScene:BeginEffect()
	print( " @@@@ BeginEffect "  )
	print( string.format( " @@@@ before BeginEffect now: %s " , tostring(os.clock()) ) )

	-- animManager:runAnimOnceByCSB(self:getResourceNode(),"PlanetScene/sfx/TransferEffect/transfer.csb", "intro",function()
	-- 	local _self = require("app.views.CityScene.TransferScene")
	-- 	-- local _self = TransferScene

	-- 	-- release memory after remove child all.. do not release too late
	-- 	cc.exports.isTotalReleaseMemoryOnce = true

	-- 	_self:ToNextScene()

	-- 	print( string.format( " @@@@ after BeginEffect now: %s " , tostring(os.clock()) ) )
	-- end)
	local _self = require("app.views.CityScene.TransferScene")
	cc.exports.isTotalReleaseMemoryOnce = true
	_self:ToNextScene()
end

function TransferScene:onEnterTransitionFinish()

	print( string.format( " @@@@ TransferScene state: %s  now: %s" , tostring(self.data_.state or "  NIL"), tostring(os.clock()) ) )

	-- ADD WJJ 20180710
	local _node_transfer = self:getResourceNode()
	_node_transfer:setGlobalZOrder(9999)
	print(string.format(" transfer scene  z order : %s", tostring(_node_transfer:getGlobalZOrder()) ))

	local _bottom_text = ""

	if( CONF.PARAM ~= nil ) then
		local _txt = CONF.PARAM.get("loading_text")
		if( _txt ~= nil ) then
			local params = _txt.PARAM
			if( params ~= nil ) then
				local param = params[math.random(1,#params)]
				_bottom_text = CONF:getStringValue(param)
			end
		end
	end

	self:getResourceNode():getChildByName("Text_1"):setString(_bottom_text)

	self:getResourceNode():getChildByName("Text_1_0"):setVisible(false)



	if self.data_.state == "start" then 


		-- local _self = require("app.views.CityScene.TransferScene")
		-- local _self = TransferScene

		self:BeginEffect()

	elseif self.data_.state == "enter" then
		print( string.format( " @@@@ play EndEffect now: %s " , tostring(os.clock()) ) )
		-- local isOK, action = animManager:runAnimOnceByCSB(self:getResourceNode(),"PlanetScene/sfx/TransferEffect/transfer.csb", "intro2",function()
		-- 	print( string.format( " @@@@ anim end EndEffect now: %s " , tostring(os.clock()) ) )
		-- end)

		-- action:pause()
		-- self.fadeOutAction = action
		

		-- ADD WJJ 20180629
		-- print( string.format( " @@@@ before EndEffect now: %s " , tostring(os.clock()) ) )

		local _node = self:getResourceNode()
		require("app.ExMemoryInterface"):getInstance():OnEnableAnimationReleaseAsync()

		local delay_time = self.DELAY_TIME_PLAY
		local old_scene = self:GetOldSceneName()

		--[[
		print("@@@ old_scene: " .. tostring(old_scene))
		if( old_scene == "city" ) then
			delay_time = self.DELAY_TIME
			cc.exports.memoryReleaseAsync:SetUpdateFastOnTransfer()
		end
		]]

		local delay_time_over = self.DELAY_TIME

		-- _node:runAction(cc.Sequence:create(cc.DelayTime:create(delay_time), cc.CallFunc:create(function ( ... )
		-- 		if( self.fadeOutAction ~= nil ) then
		-- 			if( cc.exports.memoryReleaseAsync ~= nil ) then
		-- 				cc.exports.memoryReleaseAsync:ResetUpdateInterval()
		-- 			else
		-- 				cc.exports.memoryReleaseAsync = require("util.ExMemoryReleaseAsync"):getInstance()
		-- 				cc.exports.memoryReleaseAsync:onCreate()
		-- 			end
		-- 			self.fadeOutAction:resume()
		-- 			print( string.format( " @@@@ remove Begin Fadeout now: %s " , tostring(os.clock()) ) )
		-- 		end
		-- end)))
		_node:runAction(cc.Sequence:create(cc.DelayTime:create(delay_time), cc.CallFunc:create(function ( ... )
				-- if( self.fadeOutAction ~= nil ) then
					if( cc.exports.memoryReleaseAsync ~= nil ) then
						cc.exports.memoryReleaseAsync:ResetUpdateInterval()
					else
						cc.exports.memoryReleaseAsync = require("util.ExMemoryReleaseAsync"):getInstance()
						cc.exports.memoryReleaseAsync:onCreate()
					end
					-- self.fadeOutAction:resume()
					print( string.format( " @@@@ remove Begin Fadeout now: %s " , tostring(os.clock()) ) )
				-- end
		end)))


		_node:runAction(cc.Sequence:create(cc.DelayTime:create(delay_time_over), cc.CallFunc:create(function ( ... )

			-- local _self = require("app.views.CityScene.TransferScene")
			-- local animManager = require("app.AnimManager"):getInstance()
			-- animManager:runAnimOnceByCSB(_self:getResourceNode(),"PlanetScene/sfx/TransferEffect/transfer.csb", "intro2",function()
				-- local _self = require("app.views.CityScene.TransferScene")
				if( self ~= nil ) then
					require("app.ExMemoryInterface"):getInstance():OnDisableAnimationReleaseAsync()
					self:removeFromParent()
					print( string.format( " @@@@ remove EndEffect now: %s " , tostring(os.clock()) ) )
				end
			-- end)
		end)))
		display.removeUnusedSpriteFrames()


	end

end


function TransferScene:onExitTransitionStart()

end

return TransferScene