local HYutil = require("HYutil.HY")
local Point = require("HYutil.Point")
---------------------------------------------
-- LINE -------------------------------------
---------------------------------------------
--v1.0

local Line = {}

Line = HYutil:new(Line)
-- self -> {{ax, ay}, {bx, by}, step}

function Line:new(o) --> table LineObj
	o = o or {}
	assert(type(o) == "table", "Object must be a table!")
	setmetatable(o, self)
	self.__index = function (t, k)
		if k == "a" then return rawget(t, 1)
		elseif k == "b" then return rawget(t, 2)
		else return self[k]
		end
	end
	self.__newindex = function (t, k, v)
		if k == "a" then return rawset(t, 1, v)
		elseif k == "b" then return rawset(t, 2, v)
		else return rawset(t, k, v)
		end
	end
	o = o:pointNew()
	return o
end

 --继承Point
function Line:pointNew() --> table LineObj
	self.a = Point:new(self.a)
	self.b = Point:new(self.b)
	return self
end

--点积 （点积<0为钝角，点积>0为锐角）
function Line:dot() --> number dot
	return self.a.x * self.b.x + self.a.y * self.b.y
end

--叉积
function Line:cross() --> number cross
	return self.a.x * self.b.y - self.a.y * self.b.x
end

--两向量的夹角弧度
function Line:rad() --> number rad
	return math.acos(self:dot() / self.a:len() / self.b:len())
end

--两向量的夹角角度
function Line:angle() --> number angle
	return math.deg(Line:rad())
end

--直线两点距离
function Line:distance() --> number distance
	return math.hypot(self.b.x - self.a.x, self.b.y - self.a.y)
end

--直线在t的位置
function Line:path(t) --> number x, number y
	local x = self.a.x + t * (self.b.x - self.a.x)
	local y = self.a.y + t * (self.b.y - self.a.y)
	return x, y
end

--直线在t时的长度
function Line:length(t) --> number length
	local length = t * self:distance()
	return length
end


function Line:pEven(index) --> number x, number y

	assert(type(self.step) == "number", "number 'step' not found!")

	local t, x, y
	if index >= 0 and index <= self.step then
		t = index / self.step
		--t的位置
		x, y = self:path(t)
	--超出step区间，t为1
	elseif (index > self.step) then
		x, y = self:path(1)
	--小于step区间，t为0
	elseif (index < 0) then
		x, y = self:path(0)
	end

	return x, y
end

--返回t0-t1的匀速点集表
function Line:pointCollection(len) --> table pt

	assert(type(self.len) == "number", "number 'len' not found!")

	len = len or 1
	assert(len >= 0.1, "length must >= 0.1 !") --阈值 最小分割长度高于0.1像素

	local pt = {x={},y={}} --保存点集
	local side = self.len / len
	side = math.floor(math.abs(side)) - 1

	for i=0, side do
		local step = self.step / side * i
		pt.x[i], pt.y[i] = self:pEven(step)
	end

	return pt --> {x={...},y={...}}
end

--返回t0和t1的坐标表
function Line:T0andT1() --> table pt

	local pt = {x={}, y={}}

	pt.x[0], pt.y[0] = self.a.x, self.a.y
	pt.x[1], pt.y[1] = self.b.x, self.b.y

	return pt --> {x={...},y={...}}
end

--直线边界框
function Line:bounding() --> number x_min, number y_min, number x_max, number y_max

	local x_min, y_min = math.min(self.a.x, self.b.x), math.min(self.a.y, self.b.y)
	local x_max, y_max = math.max(self.a.x, self.b.x), math.max(self.a.y, self.b.y)

	return x_min, y_min, x_max, y_max
end



return Line
