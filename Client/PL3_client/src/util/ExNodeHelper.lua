-- Coded by Wei Jingjun 20180612
print( "###LUA ExNodeHelper.lua" )
local ExNodeHelper = class("ExNodeHelper")

------------------------------------------------

function ExNodeHelper:EX_IsChildrenGood(_node, _childNum)
	--print("LUA DBG EX_IsChildNodeGood ")

	if ( _node == nil  ) then
		--print( "###LUA EX_IsChildNodeGood: _node NIL" )
		do return false end
	end

	--print("LUA DBG _node getName : " .. tostring(_node:getName()))

	local parent = _node:getParent()

	if( parent ~= nil ) then
		--print("### LUA DBG parent _name : " .. tostring(parent:getName()))
	else
		--print("### LUA DBG parent _name : parent = nil")
	end

	local childs = _node:getChildren()

	if( childs == nil ) then
		--print( "###LUA EX_IsChildrenGood childs = nil !" )
		do return false end
	end

	local child_count = 0
	for __k,__v in pairs(childs) do
		--print("### LUA DBG ipairs(children) __k: " .. tostring(__k))
		if ( __v ~= nil ) then 
			--print("child getname: " .. tostring(__v:getName()))
		end
		child_count = child_count + 1
	end

	if( child_count < _childNum ) then
		--print( "###LUA EX_IsChildrenGood child_count BAD = " .. tostring(child_count) )
		do return false end
	end

	--print( "###LUA EX_IsChildrenGood OK" )
	return true
end

function ExNodeHelper:EX_AddView2Top(_self, _path, _arg)
	
	if ( _path == nil  ) then
		--print( "###LUA EX_AddView2Top: _path NIL" )
		do return end
	end

	if( _self == nil ) then
		--print( "###LUA EX_AddView2Top: _self NIL" )
		do return end
	end

	local app = _self:getApp()

	if( app == nil ) then
		--print( "###LUA EX_AddView2Top: app NIL, reload " )
		app = require("app.MyApp"):getInstance()
	end


	if( _arg == nil ) then
		app:addView2Top(_path)
	else
		app:addView2Top(_path, _arg)
	end
	
	--print( "###LUA EX_AddView2Top: OK  " ..  tostring(_path) )
end

function ExNodeHelper:SetChildVisibleByName(_parent, _name, _visible)

	if( _parent == nil ) then
		--print( "###LUA SetChildVisibleByName: _parent NIL" )
		do return end
	end

	local child = _parent:getChildByName(_name)

	if( child == nil ) then
		--print( "###LUA SetChildVisibleByName: child NIL" )
		do return end
	end

	child:setVisible(_visible)
end

ExNodeHelper.E_IS_CHILD_EXIST_TYPE = {}
ExNodeHelper.E_IS_CHILD_EXIST_TYPE.CHILD_NIL = 1
ExNodeHelper.E_IS_CHILD_EXIST_TYPE.PARENT_NIL = 2
ExNodeHelper.E_IS_CHILD_EXIST_TYPE.HAS_CHILD = 3
ExNodeHelper.E_IS_CHILD_EXIST_TYPE.PARENT_BAD = 4
ExNodeHelper.E_IS_CHILD_EXIST_TYPE.EXSIST = 5
ExNodeHelper.E_IS_CHILD_EXIST_TYPE.NOT_EXSIST = 6

function ExNodeHelper:IsAddChild_ByExistType(_type)
	return (_type == self.E_IS_CHILD_EXIST_TYPE.NOT_EXSIST ) 
end

function ExNodeHelper:IsChildExist(_parent, _child)
	

	if( _child == nil ) then
		--print( "###LUA IsChildExist: _child NIL" )
		do return self.E_IS_CHILD_EXIST_TYPE.CHILD_NIL end
	end

	--print( "###LUA IsChildExist: _child " .. tostring(_child:getName()) )

	if( _parent == nil ) then
		--print( "###LUA IsChildExist: _parent nil" )
		do return self.E_IS_CHILD_EXIST_TYPE.PARENT_NIL end
	end

	local parName = _parent:getName()
	--print( "###LUA IsChildExist: _parent name: " .. tostring(parName) )

	if( _parent.getTag ~= nil ) then
		local parTag = _parent:getTag()
		--print( "###LUA IsChildExist: _parent tag: " .. (tostring(parTag) or " nil") )
	end

	local is_node_good = self:EX_IsChildrenGood( _child, 1 )

	-- FIX BUG: child already added. It can't be added again
	if ( (tostring(parName) == "") or (parName == nil) ) then
		--print( "###LUA IsChildExist parName = nil " )
		--print( "###LUA IsChildExist parName = nil , is_node_good = " .. tostring(is_node_good) )
		if( is_node_good ) then
			do return self.E_IS_CHILD_EXIST_TYPE.HAS_CHILD end
		end
		do return self.E_IS_CHILD_EXIST_TYPE.PARENT_BAD end
	end

	local all_childs = _parent:getChildren()

	local child_count = 0

	if( all_childs == nil ) then
		--print( "###LUA IsChildExist all_childs = nil , add !" )
		do return self.E_IS_CHILD_EXIST_TYPE.PARENT_BAD end
	end

	for k,v in pairs(all_childs) do
		--print( "###LUA IsChildExist: v: " .. tostring(v:getName()) )
		--print( "###LUA IsChildExist: _child try add: "  .. tostring(_child:getName()) )
		if( v == _child ) then
			--print( "###LUA IsChildExist: true" )
			do return self.E_IS_CHILD_EXIST_TYPE.EXSIST end
		end
		child_count = child_count + 1
	end

	if( child_count == 0 ) then
		--print( "###LUA IsChildExist child_count = 0 , add !" )
		do return self.E_IS_CHILD_EXIST_TYPE.NOT_EXSIST end
	end

	do return self.E_IS_CHILD_EXIST_TYPE.NOT_EXSIST end
end

function ExNodeHelper:EX_AddClickEventByName(_parent, _name, _event)
	--print( "###LUA EX_AddClickEventByName " )

	if( _event == nil ) then
		--print( "###LUA EX_AddClickEventByName: _event NIL" )
		do return end
	end
	if( _parent == nil ) then
		--print( "###LUA EX_AddClickEventByName: _parent NIL" )
		do return end
	end
	local child = _parent:getChildByName(_name)
	if( child == nil ) then
		--print( "###LUA EX_AddClickEventByName: child NIL" )
		do return end
	end
	child:addClickEventListener(_event)
end

function ExNodeHelper:IsAddChild_IgnoreParent(_parent, _child)
	--print( "###LUA IsAddChild_IgnoreParent BEGIN" )
	if( _child == nil ) then
		--print( "###LUA IsAddChild_IgnoreParent: _child NIL" )
		do return false end
	end

	local existType = self:IsChildExist(_parent, _child)

	if(self:IsAddChild_ByExistType(existType)) then
		do return true end
	end

	if(existType == self.E_IS_CHILD_EXIST_TYPE.HAS_CHILD) then
		do return true end
	end

	return false
end

function ExNodeHelper:EX_AddChild(_parent, _child)
	--print( "###LUA EX_AddChild BEGIN" )

	if( _child == nil ) then
		--print( "###LUA EX_AddChild: _child NIL" )
		do return end
	end

	local isExistType = self:IsChildExist(_parent, _child)

	local isAdd = self:IsAddChild_ByExistType(isExistType)

	if( isAdd == false ) then
		--print( "###LUA EX_AddChild exsits, not needed!" )
	else
		--print( "###LUA EX_AddChild try add" )
		_parent:addChild(_child)
	end
end

------------------------------------------------

function ExNodeHelper:getInstance()
	--print( "###LUA ExNodeHelper.lua getInstance" )
	if self.instance == nil then
		self.instance = self:create()
	end

	return self.instance
end

function ExNodeHelper:onCreate()
	--print( "###LUA ExNodeHelper.lua onCreate" )



	return self
end

print( "###LUA Return ExNodeHelper.lua" )
return ExNodeHelper