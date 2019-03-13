-- Coded by Wei Jingjun 20180613
print( "###LUA ExViewZhucheng.lua" )
local ExViewZhucheng = class("ExViewZhucheng")

ExViewZhucheng.IS_DEBUG_LOG_LOCAL = false

function ExViewZhucheng:_print(_log)
	if( self.IS_DEBUG_LOG_LOCAL ) then
		print(_log)
	end
end

------------------------------------------------

ExViewZhucheng.TIME_DELAY_ENTERING = 10

ExViewZhucheng.EffectManager = {}
ExViewZhucheng.EffectManager.paused_list = {}
ExViewZhucheng.EffectManager.lastDragBeganTime = -1
cc.exports.IS_ZHUCHENG_SCALE_TITLES = false

function ExViewZhucheng.EffectManager:ScaleTo(_node, _time, _scale)
	
	if( cc.exports.IS_ZHUCHENG_SCALE_TITLES ) then
		_node:runAction(cc.ScaleTo:create(_time, _scale))
	else
		_node:setScale(_scale)
	end


end

function ExViewZhucheng:OnDrag(is_drag)
	self.EffectManager:OnDrag(is_drag)
end

function ExViewZhucheng.EffectManager:OnDrag(is_drag)
	local _base = require("app.ExViewZhucheng"):getInstance()
	_base:_print(string.format("@@@@ ExViewZhucheng.EffectManager OnDrag : %s   self.lastDragBeganTime: %s ", tostring(is_drag), tostring(self.lastDragBeganTime) ))
	local is_drag_began = self.lastDragBeganTime > 0
	if( is_drag ) then

		if( is_drag_began == false ) then
			self.lastDragBeganTime = os.clock()
			self:PauseAll( )
		end
	else
		self.lastDragBeganTime = -1
		if( is_drag_began  ) then
			self:ResumeAll( )
		end
	end

end

function ExViewZhucheng.EffectManager:IsPauseListNotEmpty( )
	return (self.paused_list ~= nil) and (table.nums(self.paused_list) > 0)
end

function ExViewZhucheng.EffectManager:PauseAll( )
	local is_paused = self:IsPauseListNotEmpty( )
	if( is_paused == false ) then
		self.paused_list = cc.Director:getInstance():getActionManager():pauseAllRunningActions()
	end
	
end
function ExViewZhucheng.EffectManager:ResumeAll( )
	local _base = require("app.ExViewZhucheng"):getInstance()
	_base:_print(string.format("@@@@ ExViewZhucheng.EffectManager ResumeAll   self.paused_list: %s    ", tostring(table.nums(self.paused_list))  ))
	local is_paused = self:IsPauseListNotEmpty( )
	if( is_paused ) then
		cc.Director:getInstance():getActionManager():resumeTargets(self.paused_list)
		self.paused_list = {}
	end
end

--[[
function CityScene:KeepStopLoading()
	for _i_load = 1, 3 do
		self:runAction(cc.Sequence:create(cc.DelayTime:create(self.TIME_DELAY_ENTERING + (_i_load-1)), cc.CallFunc:create(function ( ... )
			gl:releaseLoading()
		end)))
	end
end

function CityScene:KeepLoading()
	gl:retainLoading()

	if( self.TIME_DELAY_ENTERING >= 2 ) then
		for _i_load = 1, (self.TIME_DELAY_ENTERING-1) do
			self:runAction(cc.Sequence:create(cc.DelayTime:create(_i_load), cc.CallFunc:create(function ( ... )
				gl:retainLoading()
			end)))
		end
	end
end
]]

------------------------------------------------

function ExViewZhucheng:getInstance()
	--print( "###LUA ExViewZhucheng.lua getInstance" )
	if self.instance == nil then
		self.instance = self:create()
	end

	return self.instance
end

function ExViewZhucheng:onCreate()
	--print( "###LUA ExViewZhucheng.lua onCreate" )


	return self.instance
end

--print( "###LUA Return ExViewZhucheng.lua" )
return ExViewZhucheng