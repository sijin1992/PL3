-- Coded by Wei Jingjun 20180806
print( "###LUA ExGuideBugHelper_SystemGuide.lua" )
local ExGuideBugHelper_SystemGuide = class("ExGuideBugHelper_SystemGuide")

ExGuideBugHelper_SystemGuide.IS_DEBUG_LOG_VERBOSE_LOCAL = false

function ExGuideBugHelper_SystemGuide:_print(_log)
	if( self.IS_DEBUG_LOG_VERBOSE_LOCAL ) then
		print(_log)
	end
end

------------------------------------------------
ExGuideBugHelper_SystemGuide.list_JianzhuJihuo = {
-- zhan zheng gong fang
-- "401",
"402"
,"403"

-- wu qi yan jiu
,"902"
,"903"
-- click gongneng 

-- wai jiao ju
,"1302"
,"1303"

-- ??
-- 2001
-- 2002
-- 2003

-- zhen cha ta
,"2202"
,"2203"
-- ,"2204"

-- cang ku
-- ,"2301"
,"2302"
,"2303"
-- ,"2304"

-- duan zao gong fang
,"602"
,"603"
-- 604

-- ke ji shi yan shi
,"2602"
,"2603"


-- xiu li chang
,"502"
,"503"
-- click gong neng


}
------------------------------------------------
-- click gong neng




------------------------------------------------

function ExGuideBugHelper_SystemGuide:GetData()
	local sys_guide_instance = cc.exports.instance_systemGuideManager
	local g_data = cc.exports.instance_systemGuide_data
	if( g_data == nil ) then
		if ( sys_guide_instance == nil ) then 
			return nil
		end
		g_data = sys_guide_instance.data_
	end
	return g_data
end

-- simulate a click
function ExGuideBugHelper_SystemGuide:DoEvent(_id)
	self:_print(string.format( " ~~~~ ExGuideBugHelper_SystemGuide DoEvent : %s " , tostring(84) ))
	if( cc.exports.instance_systemGuideManager == nil ) then
		return
	end

	local _data = self:GetData()
	self:_print(string.format( " ~~~~ ExGuideBugHelper_SystemGuide DoEvent : %s " , tostring(90) ))
	if ( _data == nil ) then 
		return 
	end

	local g_id = _data.id
	local conf = CONF.SYSTEM_GUIDANCE.get(g_id)
	self:_print(string.format( " ~~~~ ExGuideBugHelper_SystemGuide DoEvent g_id : %s " , tostring(g_id) ))
	self:_print(string.format( " ~~~~ ExGuideBugHelper_SystemGuide DoEvent conf.EVENT : %s " , tostring(conf.EVENT) ))
	local sys_guide_instance = cc.exports.instance_systemGuideManager
	if ( sys_guide_instance == nil ) then 
		return 
	end
	sys_guide_instance:doEvent(conf.EVENT, g_id)

end

------------------------------------------------

function ExGuideBugHelper_SystemGuide:IsNextCursor(_id) 
	local is_next = (self:IsJianzhuJihuo(_id) == false)

	self:_print(string.format( " ~~~~ ExGuideBugHelper_SystemGuide IsNextCursor : %s " , tostring(is_next) ))

	return is_next
end

function ExGuideBugHelper_SystemGuide:IsJianzhuJihuo(_id) 
	for k,v in pairs(self.list_JianzhuJihuo) do
		if( tonumber(v) == tonumber(_id) ) then
			return true
		end
	end

	return false
end

function ExGuideBugHelper_SystemGuide:CheckSystemGuideNextCursor() 
	self:_print(string.format( " ~~~~ CheckSystemGuideNextCursor: %s " , tostring(os.clock()) ))

	local g_data = self:GetData()

	local is_bug = g_data == nil
	self:_print(string.format( " ~~~~ g_data == nil: %s " , tostring(is_bug) ))
	if( is_bug ) then
		return
	end

	local g_id = g_data.id
	local is_jianzhu_jihuo = self:IsJianzhuJihuo(g_id)
	self:_print(string.format( " ~~~~ heckSystemGuideNextCursor is_jianzhu_jihuo: %s " , tostring(is_jianzhu_jihuo) ))
	self:_print(string.format( " ~~~~ CheckSystemGuideNextCursor g_id: %s " , tostring(g_id) ))
	-- go next cursor
	if ( is_jianzhu_jihuo ) then
		self:DoEvent()
	end
end

------------------------------------------------

function ExGuideBugHelper_SystemGuide:getInstance()
	print( "###LUA ExGuideBugHelper_SystemGuide.lua getInstance" )
	if self.instance == nil then
		self.instance = self:create()
	end

	return self.instance
end

function ExGuideBugHelper_SystemGuide:onCreate()
	print( "###LUA ExGuideBugHelper_SystemGuide.lua onCreate" )


	return self.instance
end

print( "###LUA Return ExGuideBugHelper_SystemGuide.lua" )
return ExGuideBugHelper_SystemGuide