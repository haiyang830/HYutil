local HYutil = require("HYutil.HY")
---------------------------------------------
-- POINT ------------------------------------
---------------------------------------------
--v1.0

local Point = {}

Point = HYutil:new(Point)
--self --> {x, y}

function Point:new(o) --> table PointObj
	o = o or {}
	assert(type(o) == "table", "Object must be a table!")
	setmetatable(o, self)
	self.__index = function (t, k)
		if k == "x" then return rawget(t, 1)
		elseif k == "y" then return rawget(t, 2)
		else return self[k]
		end
	end
	self.__newindex = function (t, k, v)
		if k == "x" then return rawset(t, 1, v)
		elseif k == "y" then return rawset(t, 2, v)
		else return rawset(t, k, v)
		end
	end
	return o
end

--向量模长
function Point:len() --> number len
	return math.hypot(self.x, self.y)
end

--法向量
function Point:normal() --> number noraml
	local l = self:len()
	return -self.y / l, self.x / l
end



return Point
