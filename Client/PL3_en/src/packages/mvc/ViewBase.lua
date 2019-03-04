
local ViewBase = class("ViewBase", cc.Node)

-- ADDED BY WJJ 20180612
ViewBase.EX_OptimizedLoader = require("app.ExResPreloader"):getInstance()


ViewBase.IS_DEBUG_LOG_VERBOSE_VIEWBASE = false
ViewBase.IS_DEBUG_LOG_NODE = false
-- ADD BY WJJ 20180619
ViewBase.IS_OPTIMIZE = true
ViewBase.VB_DELAY_INIT_LOAD_ANIMATION = 1

function ViewBase:_print_viewbase(_log)
	if( self.IS_DEBUG_LOG_VERBOSE_VIEWBASE ) then
		print(_log)
	end
end

function ViewBase:ctor(app, name, data)
    self:enableNodeEvents()
    self.app_ = app
    self.name_ = name

    -- check CSB resource file
    local res = rawget(self.class, "RESOURCE_FILENAME")
    if res then
	if(self.IS_DEBUG_LOG_NODE) then
		self:_print_viewbase( "### LUA ViewBase:ctor rawget res = " .. ( tostring(res) or " nil"  ) )
		self:_print_viewbase( "### LUA ViewBase:ctor name = " .. ( tostring(name) or " nil"  ) )
		self:_print_viewbase( "### LUA ViewBase:ctor app = " .. ( tostring(app) or " nil"  ) )
	end

        self:createResoueceNode(res)
    end

    local binding = rawget(self.class, "RESOURCE_BINDING")
    if res and binding then
        self:createResoueceBinding(binding)
    end


    if self.onCreate then self:onCreate(data) end
end

function ViewBase:getApp()
    return self.app_
end

function ViewBase:getName()
    return self.name_
end

function ViewBase:getResourceNode()

	if(self.resourceNode_ == nil) then
		self:_print_viewbase("### LUA DBG ViewBase getResourceNode : NIL ")
	else
		if(self.IS_DEBUG_LOG_VERBOSE_VIEWBASE) then
			-- self:_print_viewbase("### LUA DBG ViewBase getResourceNode : name " .. (  tostring(self.resourceNode_:getName()) or " nil"  ))
			-- self:_print_viewbase("### LUA DBG ViewBase getResourceNode : ref count " .. (  tostring(self.resourceNode_:getReferenceCount()) or " nil"  ))
		end
	end

    return self.resourceNode_
end

------------------------------------------------------------------------------------

-- 
------------------------------------------------------------------------------------
-- do not load animation one time,  delay to play animation
-- or lag

ViewBase.VB_LoadPlayAnimation_scheduler = {}
ViewBase.VB_LoadPlayAnimation_schedulerEntry = {}
ViewBase.VB_LoadPlayAnimation_isEnd = false
function ViewBase:VB_OnLoadPlayAnimation(resourceFilename)
	print(" __________ BEGIN VB_OnLoadPlayAnimation: " .. tostring(os.clock()))
	self.VB_LoadPlayAnimation_scheduler = cc.Director:getInstance():getScheduler()
	self.VB_LoadPlayAnimation_schedulerEntry = self.VB_LoadPlayAnimation_scheduler:scheduleScriptFunc(function(...)
			if( self.VB_LoadPlayAnimation_isEnd == false ) then
				print(" __________ END VB_OnLoadPlayAnimation: " .. tostring(os.clock()))
				self.VB_LoadPlayAnimation_isEnd = true
				self:VB_LoadAndPlay(resourceFilename)
				self.VB_LoadPlayAnimation_scheduler:unscheduleScriptEntry(self.VB_LoadPlayAnimation_schedulerEntry)
			end
		end
	,self.VB_DELAY_INIT_LOAD_ANIMATION, false)


end

function ViewBase:VB_LoadAndPlay(resourceFilename)
    local flag = rawget(self.class, "RUN_TIMELINE")
    local str = resourceFilename:match(".+%.(%w+)$")
    if flag == true and str == "csb" then
	local action = {}
	-- ADD BY WJJ 20180619
	if( self.IS_OPTIMIZE ) then
		action = self.EX_OptimizedLoader:CacheLoadTimeline(resourceFilename)
	else
        	action = cc.CSLoader:createTimeline(resourceFilename)
	end
        self.resourceNode_:runAction(action)
        action:gotoFrameAndPlay(0,false)
    end
end

------------------------------------------------------------------------------------


function ViewBase:createResoueceNode(resourceFilename)
	self:_print_viewbase("### LUA DBG ViewBase createResoueceNode : " .. (  tostring(resourceFilename) or " nil"  ))

    if self.resourceNode_ then
        self.resourceNode_:removeSelf()
        self.resourceNode_ = nil
    end

	if( self.IS_OPTIMIZE ) then
	    -- self.EX_OptimizedLoader:PauseReloader()
	    self.resourceNode_ = self.EX_OptimizedLoader:CacheLoad(resourceFilename, true)
	else
    	    self.resourceNode_ = cc.CSLoader:createNode(resourceFilename)
	end

	self:_print_viewbase("### LUA DBG ViewBase resourceFilename :  " .. (  tostring(resourceFilename) or " nil"  ))
	self:_print_viewbase("### LUA DBG ViewBase CacheLoad : name " .. (  tostring(self.resourceNode_:getName()) or " nil"  ))
	self:_print_viewbase("### LUA DBG ViewBase CacheLoad : ref count " .. (  tostring(self.resourceNode_:getReferenceCount()) or " nil"  ))

    assert(self.resourceNode_, string.format("ViewBase:createResoueceNode() - load resouce node from file \"%s\" failed", resourceFilename))
    self:addChild(self.resourceNode_)

	-- WJJ BUG: self is nil, use self.class
	if( self.IS_DEBUG_LOG_NODE ) then
		self:_print_viewbase( "###LUA  ViewBase:createResoueceNode self = "  .. (  tostring(self) or " nil"  ) )
		self:_print_viewbase( "###LUA  ViewBase:createResoueceNode self.class = "  .. (  tostring(self.class) or " nil"  ) )
	end

    local udcu = require("util.UserDataCmdUtil"):getInstance()
    
    local needAdjustPos = rawget(self.class, "NEED_ADJUST_POSITION")
    if needAdjustPos == true then
        
        local diffSize = udcu:getDiffSize()
        self:getResourceNode():setPosition(diffSize.width,diffSize.height)
    end
    
	-- ADD WJJ 20180706
	-- WJJ 20180706 DO NOT LOAD AND PLAY csb file , scene will auto play animation
	-- self:VB_OnLoadPlayAnimation(resourceFilename)

--[[
    local flag = rawget(self.class, "RUN_TIMELINE")
    local str = resourceFilename:match(".+%.(%w+)$")
    if flag == true and str == "csb" then
	local action = {}
	-- ADD BY WJJ 20180619
	if( self.IS_OPTIMIZE ) then
		action = self.EX_OptimizedLoader:CacheLoadTimeline(resourceFilename)
	else
        	action = cc.CSLoader:createTimeline(resourceFilename)
	end
        self.resourceNode_:runAction(action)
        action:gotoFrameAndPlay(0,false)
    end
]]

    udcu:execute(self:getResourceNode():getChildren())
end

function ViewBase:createResoueceBinding(binding)
    assert(self.resourceNode_, "ViewBase:createResoueceBinding() - not load resource node")
    for nodeName, nodeBinding in pairs(binding) do
	print(string.format("~~~ createResoueceBinding nodeName:%s  nodeBinding.varname:%s ", nodeName, nodeBinding.varname) )

        local node = self.resourceNode_:getChildByName(nodeName)

	-- ADD WJJ 20180725
	if( nodeBinding["parent"] ~= nil )then
		local parent = self.resourceNode_:getChildByName(nodeBinding["parent"])
		node = parent:getChildByName(nodeName)
	end

	if( node == nil )then
		print(string.format("~~~ ERR: NOT FOUND!! createResoueceBinding nodeName:%s  nodeBinding.varname:%s ", nodeName, nodeBinding.varname) )
		return
	end

        if nodeBinding.varname then
            self[nodeBinding.varname] = node
        end
        for _, event in ipairs(nodeBinding.events or {}) do
            if event.event == "touch" then
                node:onTouch(handler(self, self[event.method]))
            end
        end
    end
end

function ViewBase:showWithScene(transition, time, more)
    self:setVisible(true)
    local scene = display.newScene(self.name_)
    scene:addChild(self)
    display.runScene(scene, transition, time, more)
    return self
end

return ViewBase
