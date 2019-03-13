-- Coded by Wei Jingjun 20180704
--print( "###LUA ExTileMapHelper.lua" )
local ExTileMapHelper = class("ExTileMapHelper")


ExTileMapHelper.IS_DEBUG_LOG_LOCAL = false

function ExTileMapHelper:_print(_log)
	if( self.IS_DEBUG_LOG_LOCAL ) then
		print(_log)
	end
end

ExTileMapHelper.TILES_RELATIVE_TO_CENTER = {
	[1]={["x"]=0,["y"]=0}
	,[2]={["x"]=-1,["y"]=0}
	,[3]={["x"]=0,["y"]=1}
	,[4]={["x"]=1,["y"]=0}
	,[5]={["x"]=0,["y"]=-1}
	,[6]={["x"]=-1,["y"]=-1}
	,[7]={["x"]=-1,["y"]=1}
	,[8]={["x"]=1,["y"]=1}
	,[9]={["x"]=1,["y"]=-1}
	,[10]={["x"]=-2,["y"]=0}
	,[11]={["x"]=-2,["y"]=1}
	,[12]={["x"]=-2,["y"]=2}
	,[13]={["x"]=-1,["y"]=2}
	,[14]={["x"]=0,["y"]=2}
	,[15]={["x"]=1,["y"]=2}
	,[16]={["x"]=2,["y"]=2}
	,[17]={["x"]=2,["y"]=1}
	,[18]={["x"]=2,["y"]=0}
	,[19]={["x"]=2,["y"]=-1}
	,[20]={["x"]=2,["y"]=-2}
	,[21]={["x"]=1,["y"]=-2}
	,[22]={["x"]=0,["y"]=-2}
	,[23]={["x"]=-1,["y"]=-2}
	,[24]={["x"]=-2,["y"]=-2}
}

------------------------------------------------

function ExTileMapHelper:GetTileInfoAtPos(info_list, x, y)
	local is_target = false
	for _k,_v in ipairs(info_list) do
		local _x = _v.pos_list[1].x
		local _y = _v.pos_list[1].y

		is_target = (tonumber(_x) == tonumber(x)) and (tonumber(_y) == tonumber(y))
		if( is_target ) then
			--self:_print(string.format(" @@@@ GetTileInfoAtPos is_target: %s   x: %s   y: %s", tostring(is_target), tostring(_x), tostring(_y) ))
			return true, _v
		end
	end

	--self:_print(string.format(" @@@@ GetTileInfoAtPos is_target: %s   x: %s   y: %s", tostring(is_target), tostring(x), tostring(y) ))
	return is_target, nil
end


function ExTileMapHelper:GetTileFromCenter(_i, _relative_tiles)
	local max = table.nums(_relative_tiles)
	--self:_print(string.format(" @@@  GetTileFromCenter _i: %s  max: %s", tostring(_i), tostring(max) ))
	local is_bad_i = (_i < 1) or (_i > max)
	if( is_bad_i ) then
		--self:_print(string.format(" @@@  BAD _i: %s  max: %s", tostring(_i), tostring(max) ))
		return false, 0, 0
	end
	local x = _relative_tiles[_i]["x"]
	local y = _relative_tiles[_i]["y"]
	return true, x, y
end

function ExTileMapHelper:GetTileListOfCenterPos(_x, _y, _center_pos)
	--self:_print(string.format("@@@ center x: %s, y: %s ", _x , _y))
	local new_list = {}
	for k,v in ipairs(self.TILES_RELATIVE_TO_CENTER) do
		local x = v["x"] + _x
		local y = v["y"] + _y
		new_list[k] = {["x"]=x ,["y"]=y }
		--self:_print(string.format("@@@ new [%s] = x: %s, y: %s ", k,  x, y))
	end
	return new_list
end

------------------------------------------------

function ExTileMapHelper:getInstance()
	--print( "###LUA ExTileMapHelper.lua getInstance" )
	if self.instance == nil then
		self.instance = self:create()
	end

	return self.instance
end

function ExTileMapHelper:onCreate()
	--print( "###LUA ExTileMapHelper.lua onCreate" )


	return self.instance
end

--print( "###LUA Return ExTileMapHelper.lua" )
return ExTileMapHelper