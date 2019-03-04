local BattleEvent = class("BattleEvent")

BattleEvent.bm = nil

function BattleEvent:ctor(data,bm)
	assert(false,"please overload me")
end

function BattleEvent:start()
	assert(false,"please overload me")
end

function BattleEvent:process(dt)
	assert(false,"please overload me")
	return false
end

function BattleEvent:finish()
	assert(false,"please overload me")
end

function BattleEvent:resume()
	
end

function BattleEvent:pause()
	
end

function BattleEvent:check()
	
end

return BattleEvent