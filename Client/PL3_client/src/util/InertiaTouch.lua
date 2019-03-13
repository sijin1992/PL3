
local InertiaTouch = class("InertiaTouch")

InertiaTouch.offTime = 3

InertiaTouch.beginPos = nil
InertiaTouch.beginTime = 0

InertiaTouch.duration = 1

InertiaTouch.multi = 1.2

function InertiaTouch:ctor(d,multi)
	if type(d) == "number" then
		self.duration = d
		self.multi = multi
	end
end

function InertiaTouch:setBegin(pos,time)
	self.beginPos = pos
	self.beginTime = time
end

function InertiaTouch:setEnd(pos,time)

	local deltaTime = (time - self.beginTime)/1000
	if deltaTime > self.offTime then
		self.beginTime = 0
		return nil
	end

	local length = (pos.x - self.beginPos.x) * self.multi

	return self.duration, cc.p(length,0)
end

return InertiaTouch