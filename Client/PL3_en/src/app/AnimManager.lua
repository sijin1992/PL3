local cache = cc.SpriteFrameCache:getInstance()

local AnimManager = class("AnimManager")

local spriteFrameCache = cc.SpriteFrameCache:getInstance()
local animationCache = cc.AnimationCache:getInstance()

AnimManager._battleSfxList = nil

-- ADDED BY WJJ 20180612
AnimManager.EX_OptimizedLoader = require("app.ExResPreloader"):getInstance()
AnimManager.IS_OPTIMIZE = true
AnimManager.IS_DEBUG_LOG_VERBOSE = false
--------------------------------------------------

function AnimManager:_print(_log)
	if( self.IS_DEBUG_LOG_VERBOSE ) then
		print(_log)
	end
end

--------------------------------------------------

function AnimManager:ctor()
	
end

function AnimManager:getInstance()
	if self.instance == nil then
		self.instance = self:create()
		self._battleSfxList = {}
	end  
		
	return self.instance  
end


function AnimManager:registerAnim(name, durationTime)
	local animFrames = {}

	local i = 1
	while i do 
		local frame = spriteFrameCache:getSpriteFrame( string.format("%s_%02d.png", name, i-1) )
		--print(string.format("load %s_%02d.png",name, i-1))
		if frame == nil then
			assert(i ~= 1, string.format("load sprite frame : %s_%02d.png error!",name, i))
			break
		end
		animFrames[i] = frame
		i = i + 1
	end

	local animation = cc.Animation:createWithSpriteFrames(animFrames, durationTime)
	animationCache:addAnimation(animation,name)

	--print("create anim :"..name)
end

function AnimManager:registerAnimById(beginName, id, effectName, durationTime)

	  
	self:registerAnim( string.format("%s_%02d_%s", beginName, id, effectName), durationTime )

end


function AnimManager:unregisterAnim( name )
	animationCache:removeAnimation(name)
end

function AnimManager:unregisterAnimById( beginName, id, effectName )
	self:unregisterAnim(string.format("%s_%02d_%s", beginName, id, effectName))
end

function AnimManager:runAnim( node, animName)
	local anim = animationCache:getAnimation(animName)
	assert(anim ~= nil, "load animation error!")
			--print(string.format("run anim : %s ",animName))
	node:runAction(cc.RepeatForever:create(cc.Animate:create(anim)))
end

function AnimManager:runAnimOnce( node, animName, callfunc)
	local anim = animationCache:getAnimation(animName)
	assert(anim ~= nil, "load animation error!")
	--print(string.format("run anim : %s ",animName))
	if callfunc ~= nil then
		node:runAction(cc.Sequence:create(cc.Animate:create(anim),callfunc))
	else
		node:runAction(cc.Animate:create(anim))
	end
	
end

function AnimManager:isAnimExistsByCSB( csbName, animName )
	local action = {}
	if( self.IS_OPTIMIZE ) then
		action = self.EX_OptimizedLoader:CacheLoadTimeline(csbName)
	else
		action = cc.CSLoader:createTimeline(csbName)
	end

	if action then
		return action:IsAnimationInfoExists(animName) 
	end
	return false
end

function AnimManager:runAnimByCSB( node, csbName, animName)
	self:_print("### LUA AnimManager runAnimByCSB : csbName = " .. tostring( csbName or " nil " ))

	node:stopAllActions()

	local action = {}
	if( self.IS_OPTIMIZE ) then
		action = self.EX_OptimizedLoader:CacheLoadTimeline(csbName)
	else
		action = cc.CSLoader:createTimeline(csbName)
	end

	if( action == nil ) then
		self:_print("### LUA AnimManager action == nil ")
		return false, nil
	end

	if animName == nil then
		action:gotoFrameAndPlay(0,true)
	else
		if action:IsAnimationInfoExists(animName) == true then
			action:play(animName,true)
		else
			self:_print("warning can't find anim :",animName)
			return false
		end
		action:play(animName,true)
	end

	node:runAction(action)
	return true, action
end

function AnimManager:runAnimOnceByCSB( node, csbName, animName, func, onFrameEvent)

	self:_print("### LUA AnimManager runAnimOnceByCSB : csbName = " .. tostring( csbName or " nil " ))

	node:stopAllActions()

	local action = {}
	if( self.IS_OPTIMIZE ) then
		action = self.EX_OptimizedLoader:CacheLoadTimeline(csbName)
	else
		action = cc.CSLoader:createTimeline(csbName)
	end

	node:runAction(action)
	if animName == nil then
		action:gotoFrameAndPlay(0,false)
	else
		if action:IsAnimationInfoExists(animName) == true then
			action:play(animName,true)
		else
			self:_print("warning: can't find anim :",animName)
			return false
		end
		action:play(animName,false)
	end
	
	

	if func ~= nil then
		action:setLastFrameCallFunc(func)
	end

	if onFrameEvent ~= nil then

		action:setFrameEventCallFunc(onFrameEvent)
	end

	return true, action
end

return AnimManager