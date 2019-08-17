package.path = "L:\\HYutil\\HYutil\\?.lua;".."I:\\HYutil\\HYutil\\?.lua;"..package.path
local HYutil = require("HY")
local Point = require("Point")
---------------------------------------------
-- BEZIER -----------------------------------
---------------------------------------------
local Bezier = {}

Bezier = HYutil:new(Bezier)
-- self -> {{ax, ay}, {bx, by}, {cx, cy}, {dx, dy}, step}

function Bezier:new(o) --> table BezierObj
	o = o or {}
	assert(type(o) == "table", "Object must be a table!")
	setmetatable(o, self)
	self.__index = function (t, k)
		if k == "a" then return rawget(t, 1)
		elseif k == "b" then return rawget(t, 2)
		elseif k == "c" then return rawget(t, 3)
		elseif k == "d" then return rawget(t, 4)
		else return self[k]
		end
	end
	self.__newindex = function (t, k, v)
		if k == "a" then return rawset(t, 1, v)
		elseif k == "b" then return rawset(t, 2, v)
		elseif k == "c" then return rawset(t, 3, v)
		elseif k == "d" then return rawset(t, 4, v)
		else return rawset(t, k, v)
		end
	end
	o = o:pointNew()
	return o
end

--继承Point
function Bezier:pointNew() --> table BezierObj
	self.a = Point:new(self.a)
	self.b = Point:new(self.b)
	self.c = Point:new(self.c)
	self.d = Point:new(self.d)
	return self
end

--三次贝赛尔
function Bezier:path(t) --> number x, number y
	local it = 1 - t
	-- f(x) = it^3*p1 + 3*it^2*t*p2 + 3*it*t^2*p3 + t^3*p4
	local x = it^3*self.a.x + 3*it^2*t*self.b.x + 3*it*t^2*self.c.x + t^3*self.d.x
	local y = it^3*self.a.y + 3*it^2*t*self.b.y + 3*it*t^2*self.c.y + t^3*self.d.y
	return x, y
end

--贝赛尔平面速度
function Bezier:speed(t) --> number speed
	local it = 1 - t
	--f(x) = -3*p1*it^2 + 3*p2*it^2 - 6*p2*it*t + 6*p3*it*t - 3*p3*t^2 + 3*p4*t^2
	local speed_x = -3*self.a.x*it^2 + 3*self.b.x*it^2 - 6*self.b.x*it*t + 6*self.c.x*it*t - 3*self.c.x*t^2 + 3*self.d.x*t^2
	local speed_y = -3*self.a.y*it^2 + 3*self.b.y*it^2 - 6*self.b.y*it*t + 6*self.c.y*it*t - 3*self.c.y*t^2 + 3*self.d.y*t^2
	local speed = math.sqrt(speed_x^2 + speed_y^2)
	return speed
end

--Gauss积分
Bezier.abscissae = {
	-0.0640568928626056299791002857091370970011,
	 0.0640568928626056299791002857091370970011,
	-0.1911188674736163106704367464772076345980,
	 0.1911188674736163106704367464772076345980,
	-0.3150426796961633968408023065421730279922,
	 0.3150426796961633968408023065421730279922,
	-0.4337935076260451272567308933503227308393,
	 0.4337935076260451272567308933503227308393,
	-0.5454214713888395626995020393223967403173,
	 0.5454214713888395626995020393223967403173,
	-0.6480936519369755455244330732966773211956,
	 0.6480936519369755455244330732966773211956,
	-0.7401241915785543579175964623573236167431,
	 0.7401241915785543579175964623573236167431,
	-0.8200019859739029470802051946520805358887,
	 0.8200019859739029470802051946520805358887,
	-0.8864155270044010714869386902137193828821,
	 0.8864155270044010714869386902137193828821,
	-0.9382745520027327978951348086411599069834,
	 0.9382745520027327978951348086411599069834,
	-0.9747285559713094738043537290650419890881,
	 0.9747285559713094738043537290650419890881,
	-0.9951872199970213106468008845695294439793,
	 0.9951872199970213106468008845695294439793,
	}

Bezier.weights = {
	0.1279381953467521593204025975865079089999,
	0.1279381953467521593204025975865079089999,
	0.1258374563468283025002847352880053222179,
	0.1258374563468283025002847352880053222179,
	0.1216704729278033914052770114722079597414,
	0.1216704729278033914052770114722079597414,
	0.1155056680537255991980671865348995197564,
	0.1155056680537255991980671865348995197564,
	0.1074442701159656343712356374453520402312,
	0.1074442701159656343712356374453520402312,
	0.0976186521041138843823858906034729443491,
	0.0976186521041138843823858906034729443491,
	0.0861901615319532743431096832864568568766,
	0.0861901615319532743431096832864568568766,
	0.0733464814110802998392557583429152145982,
	0.0733464814110802998392557583429152145982,
	0.0592985849154367833380163688161701429635,
	0.0592985849154367833380163688161701429635,
	0.0442774388174198077483545432642131345347,
	0.0442774388174198077483545432642131345347,
	0.0285313886289336633705904233693217975087,
	0.0285313886289336633705904233693217975087,
	0.0123412297999872001830201639904771582223,
	0.0123412297999872001830201639904771582223,
	}

function Bezier.coefficients(p1, p2, p3, p4) --> number coefficients
	return p4 - p1 + 3 * (p2 - p3), 3 * p1 - 6 * p2 + 3 * p3, 3 * (p2 - p1), p1
end

function Bezier.derivative1For(t, a, b, c) --> number derivative
	return c + t * (2 * b + 3 * a * t)
end

--贝赛尔曲线t时的长度
function Bezier:length(t) --> number length
	local ax, bx, cx = self.coefficients(self.a.x, self.b.x, self.c.x, self.d.x)
	local ay, by, cy = self.coefficients(self.a.y, self.b.y, self.c.y, self.d.y)
	local z2 = t / 2
	local sum = 0
	for i=1, #self.abscissae do
		local corrected_t = z2 * self.abscissae[i] + z2
		local dx = self.derivative1For(corrected_t, ax, bx, cx)
		local dy = self.derivative1For(corrected_t, ay, by, cy)
		sum = sum + self.weights[i] * math.hypot(dx, dy)
	end
	local length = z2 * sum
	return length
end

--根据t求匀速自变量t2
function Bezier:even(t) --> number t2
	--曲线总长度计算
	local total_length = self:length(1)
	--在t时（匀速）的曲线长度
	local length = t * total_length
	local t1, t2 = t, _

	--当t在1或0时，bezier:speed均为0（除0非法）
	if t == 0 then
		t2 = 0
	elseif t == 1 then
		t2 = 1
	else
		while true do
			t2 = t1 - (self:length(t1) - length) / self:speed(t1)
			if (math.abs(t1 - t2) < 0.0001) then break end
			t1 = t2
		end
	end

	return t2
end

--返回匀速贝赛尔路径点
function Bezier:pEven(index) --> number x, number y

	assert(type(self.step) == "number", "number 'step' not found!")

	local t, x, y
	if index >= 0 and index <= self.step then
		t = index / self.step
		--匀速运动对应的t
		t = self:even(t)
		--求匀速后t的位置
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

--返回t0-t1的匀速贝赛尔点集表
function Bezier:pointCollection(len) --> table pt

	assert(type(self.len) == "number", "number 'len' not found!")

	len = len or 1
	assert(len >= 0.1, "length must >= 0.1 !") --阈值 最小分割长度高于0.1像素

	local pt = {x={}, y={}} --保存点集
	local side = self.len / len
	side = math.floor(math.abs(side)) - 1

	for i=0, side do
		local step = self.step / side * i
		pt.x[i], pt.y[i] = self:pEven(step)
	end

	return pt --> {x={...},y={...}}
end

--返回t0和t1的坐标表
function Bezier:T0andT1() --> table pt

	local pt = {x={}, y={}}

	pt.x[0], pt.y[0] = self.a.x, self.a.y
	pt.x[1], pt.y[1] = self.d.x, self.d.y

	return pt --> {x={...},y={...}}
end

--bezier路径边界框
function Bezier:bounding() --> number x_min, number y_min, number x_max, number y_max

	local len = 1 --默认精度1像素
	local pt = self:pointCollection(len)

	local x_min, y_min = math.min(table.unpack(pt.x)), math.min(table.unpack(pt.y))
	local x_max, y_max = math.max(table.unpack(pt.x)), math.max(table.unpack(pt.y))

	return x_min, y_min, x_max, y_max
end



return Bezier
