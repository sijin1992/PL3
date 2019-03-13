local ScaleProgressDelegate = class("ScaleProgressDelegate")

function ScaleProgressDelegate:ctor( node, maxLength)
	self.maxLength_ = maxLength
	self.renderer_ = node
end

function ScaleProgressDelegate:setPercentage( percentage )
	if self.renderer_ then
		local cs = self.renderer_:getContentSize()
		self.renderer_:setContentSize(cc.size(self.maxLength_* (percentage / 100), self.renderer_:getContentSize().height))
	end
end

function ScaleProgressDelegate:getMaxLength(  )
	return self.maxLength_
end

return ScaleProgressDelegate