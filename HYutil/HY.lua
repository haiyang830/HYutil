package.path = "L:\\HYutil\\HYutil\\?.lua;".."I:\\HYutil\\HYutil\\?.lua;"..package.path
local table = require("Table")
local math = require("Math")
---------------------------------------------
-- HYutil -----------------------------------
---------------------------------------------
local HYutil = {}

function HYutil:new(o) --> table obj
	o = o or {}
	assert(type(o) == "table", "Object must be a table!")
	if not o.tag then o.tag = {} end --用于存放方法执行标记
	if not o.cache then o.cache = {} end
	setmetatable(o, self)
	self.__index = self
	self.__newindex = function (t, k, v) return rawset(t, k, v) end
	return o
end

HYutil._tblSort = table.sort2
HYutil._tblClone = table.clone



return HYutil
