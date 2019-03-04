local MapLabel = class("MapLabel", function ()
    local node = cc.Node:create()
    return node
end)

function MapLabel:setString( str )
	
	self:removeAllChildren()

	local widthCount = 0

	for i=1,#str do

		local path = string.format("%s/%s.png", self.path_, string.sub(str,i,i))

		local sprite = cc.Sprite:createWithSpriteFrameName(path)
		assert(sprite,"error: no", path)

		self:addChild(sprite)
		sprite:setAnchorPoint(cc.p(0,0.5))
		sprite:setPosition(widthCount,0)

		local size = sprite:getContentSize()
		widthCount = widthCount + size.width
	end
end

function MapLabel:ctor( path, str )
	self.path_ = path
	self:setString(str)
end

return MapLabel