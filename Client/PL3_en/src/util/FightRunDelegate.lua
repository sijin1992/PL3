local g_player = require("app.Player"):getInstance()

local FightRunDelegate = class("FightRunDelegate")

function FightRunDelegate:ctor(text)
	self.text_ = text

	self.change_num = 0
	self.diff_num = 1
end

function FightRunDelegate:getOwner(  )
	return self.text_
end

function FightRunDelegate:setUpNum( num )
	self.change_num = num
	self.diff_num = 1
	self.now_num = tonumber(self.text_:getString())
end	

function FightRunDelegate:getFlag( ... )

	return self.diff_num <= 20
end

function FightRunDelegate:update( dt )

	if self.diff_num <= 20 then

		local num = math.floor((self.change_num - self.now_num)/20*self.diff_num)
		self.diff_num = self.diff_num + 1
		self.text_:setString(self.now_num + num)
	end
end

return FightRunDelegate