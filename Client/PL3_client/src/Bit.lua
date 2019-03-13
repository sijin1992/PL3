--[[
Description:
	FileName:Bit.lua
	This module provides a selection of Bitwise operations.
History:
	Initial version created by  ÕóÓê 2005-11-10.
Notes:
  ....
]]
--[[{2147483648,1073741824,536870912,268435456,134217728,67108864,33554432,16777216,
		8388608,4194304,2097152,1048576,524288,262144,131072,65536,
		32768,16384,8192,4096,2048,1024,512,256,128,64,32,16,8,4,2,1}
		]]


local Bit={data32={}}
for i=1,32 do
	Bit.data32[i]=2^(32-i)
end

function Bit:d2b(arg)
	local   tr={}
	for i=1,32 do
		if arg >= self.data32[i] then
			tr[i]=1
			arg=arg-self.data32[i]
		else
			tr[i]=0
		end
	end
	return   tr
end   --Bit:d2b

function Bit:b2d(arg)
	local   nr=0
	for i=1,32 do
		if arg[i] ==1 then
		nr=nr+2^(32-i)
		end
	end
	return  nr
end   --Bit:b2d

function Bit:_xor(a,b)
	local   op1=self:d2b(a)
	local   op2=self:d2b(b)
	local   r={}

	for i=1,32 do
		if op1[i]==op2[i] then
			r[i]=0
		else
			r[i]=1
		end
	end
	return  self:b2d(r)
end --Bit:xor

function Bit:_and(a,b)
	local   op1=self:d2b(a)
	local   op2=self:d2b(b)
	local   r={}

	for i=1,32 do
		if op1[i]==1 and op2[i]==1  then
			r[i]=1
		else
			r[i]=0
		end
	end
	return  self:b2d(r)

end --Bit:_and

function Bit:_or(a,b)
	local   op1=self:d2b(a)
	local   op2=self:d2b(b)
	local   r={}

	for i=1,32 do
		if  op1[i]==1 or   op2[i]==1   then
			r[i]=1
		else
			r[i]=0
		end
	end
	return  self:b2d(r)
end --Bit:_or

function Bit:_not(a)
	local   op1=self:d2b(a)
	local   r={}

	for i=1,32 do
		if  op1[i]==1   then
			r[i]=0
		else
			r[i]=1
		end
	end
	return  self:b2d(r)
end --Bit:_not

function Bit:_rshift(a,n)
	local   op1=self:d2b(a)
	local   r=self:d2b(0)

	if n < 32 and n > 0 then
		for i=1,n do
			for i=31,1,-1 do
				op1[i+1]=op1[i]
			end
			op1[1]=0
		end
	r=op1
	end
	return  self:b2d(r)
end --Bit:_rshift

function Bit:_lshift(a,n)
	local   op1=self:d2b(a)
	local   r=self:d2b(0)

	if n < 32 and n > 0 then
		for i=1,n   do
			for i=1,31 do
				op1[i]=op1[i+1]
			end
			op1[32]=0
		end
		r=op1
	end
	return  self:b2d(r)
end --Bit:_lshift


function Bit:print(ta)
	local   sr=""
	for i=1,32 do
		sr=sr..ta[i]
	end
	print(sr)
end

function Bit:has( a, n )
	return Bit:_and(a, n) == n
end

function Bit:add( a, n )
	return Bit:_or(a,n)
end

function Bit:remove( a, n )
	return Bit:_xor(a, n)
end

return Bit
-- bs=Bit:d2b(7)
-- Bit:print(bs)
-- -->00000000000000000000000000000111
-- Bit:print(Bit:d2b(Bit:_not(7)))
-- -->11111111111111111111111111111000
-- Bit:print(Bit:d2b(Bit:_rshift(7,2)))
-- -->00000000000000000000000000000001
-- Bit:print(Bit:d2b(Bit:_lshift(7,2)))
-- -->00000000000000000000000000011100
-- print(Bit:b2d(bs))                      -->     7
-- print(Bit:_xor(7,2))                    -->     5
-- print(Bit:_and(7,4))                    -->     4
-- print(Bit:_or(5,2))                     -->     7


--end of Bit.lua