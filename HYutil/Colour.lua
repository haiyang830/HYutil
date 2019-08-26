local HYutil = require("HYutil.HY")
local math = require("HYutil.Math")
---------------------------------------------
-- Colour -----------------------------------
---------------------------------------------
--v1.0
local Colour = {HSV={}, HSL={}, RGB={}}
Colour = HYutil:new(Colour)

local RGB = Colour.RGB
RGB = HYutil:new(RGB)
--RGB (0~1, 0~1, 0~1)
local HSL = Colour.HSL
HSL = HYutil:new(HSL)
--HSL {0~360, 0~1, 0~1}
local HSV = Colour.HSV
HSV = HYutil:new(HSV)
--HSV (0~360, 0~1, 0~1)

function Colour:new(o) --> table RGBObj/HSLObj/HSVObj
	o = o or {}
	assert(type(o) == "table", "Object must be a table!")

	if (type(o.R) == "number") and (type(o.G) == "number") and (type(o.B) == "number") then
		setmetatable(o, self.RGB)
		self.RGB.__index = self.RGB
		return o
	elseif (type(o.H) == "number") and (type(o.S) == "number") and (type(o.L) == "number") then
		setmetatable(o, self.HSL)
		self.HSL.__index = self.HSL
		return o
	elseif (type(o.H) == "number") and (type(o.S) == "number") and (type(o.V) == "number") then
		setmetatable(o, self.HSV)
		self.HSV.__index = self.HSV
		return o
	end

	error("Colour Object error!")
end


-- RGB --------------------------------------------------------------


function RGB:clamp()
	self.R, self.G, self.B = math.clamp(self.R, 0, 1), math.clamp(self.G, 0, 1), math.clamp(self.B, 0, 1)
	return self
end

--返回HSL对象
function RGB:toHSL()

	self:clamp()

	local r, g, b = self.R, self.G, self.B
	local min = math.min(r, g, b)
	local max = math.max(r, g, b)
	local delta = max - min

	local h, s, l = 0, 0, (min + max) / 2

	if l > 0 and l < 0.5 then s = delta / (max + min) end
	if l >= 0.5 and l < 1 then s = delta / (2 - max - min) end

	if delta > 0 then
		if max == r and max ~= g then h = h + (g-b) / delta end
		if max == g and max ~= b then h = h + 2 + (b-r) / delta end
		if max == b and max ~= r then h = h + 4 + (r-g) / delta end
		h = h / 6
	end

	if h < 0 then h = h + 1 end
	if h > 1 then h = h - 1 end

	local new_HSL = {}
	new_HSL.H, new_HSL.S, new_HSL.L = h * 360, s, l

	return HSL:new(new_HSL)
end

--返回HSV对象
function RGB:toHSV()

	self:clamp()

	local r, g, b = self.R, self.G, self.B
	local K = 0
	if g < b then
		g, b = b, g
		K = -1
	end
	if r < g then
		r, g = g, r
		K = -2 / 6 - K
	end
	local chroma = r - math.min(g, b)
	local h = math.abs(K + (g - b) / (6 * chroma + 1e-20))
	local s = chroma / (r + 1e-20)
	local v = r

	local new_HSV = {}
	new_HSV.H, new_HSV.S, new_HSV.V = h * 360, s, v

	return HSV:new(new_HSV)
end

--返回颜色字符串
function RGB:toStr(mode)

	local str_r, str_g, str_b = string.format('%02X', self.R*255), string.format('%02X', self.G*255), string.format('%02X', self.B*255)

	local mode = string.lower(mode or "no_mode")
	if mode == "ass" then
		return "&H"..str_b..str_g..str_r.."&"
	elseif mode == "html" then
		return "#"..str_r..str_g..str_b
	end

	return self
end


-- HSL --------------------------------------------------------------


function HSL:clamp()
	self.H, self.S, self.L = self.H % 360, math.clamp(self.S, 0, 1), math.clamp(self.L, 0, 1)
	return self
end

function HSL.h2rgb(m1, m2, h)
	if h<0 then h = h+1 end
	if h>1 then h = h-1 end
	if h*6<1 then
		return m1+(m2-m1)*h*6
	elseif h*2<1 then
		return m2
	elseif h*3<2 then
		return m1+(m2-m1)*(2/3-h)*6
	else
		return m1
	end
end

--返回RGB对象
function HSL:toRGB()

	self:clamp()

	local h, s, L = self.H, self.S, self.L
	h = h / 360
	local m2 = L <= .5 and L*(s+1) or L+s-L*s
	local m1 = L*2-m2

	local new_RGB = {}
	new_RGB.R, new_RGB.G, new_RGB.B = self.h2rgb(m1, m2, h+1/3), self.h2rgb(m1, m2, h), self.h2rgb(m1, m2, h-1/3)

	return RGB:new(new_RGB)
end

--返回HSV对象
function HSL:toHSV() --TODO: direct conversion
	local RGB = self:toRGB()
	return RGB:toHSV()
end

--返回颜色字符串
function HSL:toStr(mode)
	return self:toRGB():toStr(mode)
end


-- HSV --------------------------------------------------------------


function HSV:clamp()
	self.H, self.S, self.V = self.H % 360, math.clamp(self.S, 0, 1), math.clamp(self.V, 0, 1)
	return self
end

--返回RGB对象
function HSV:toRGB()

	self:clamp()

	local h, s, v = self.H, self.S, self.V
	if s == 0 then --gray
		return v, v, v
	end
	local H = h / 60
	local i = math.floor(H) --which 1/6 part of hue circle
	local f = H - i
	local p = v * (1 - s)
	local q = v * (1 - s * f)
	local t = v * (1 - s * (1 - f))

	local new_RGB = {}
	if i == 0 then
		new_RGB.R, new_RGB.G, new_RGB.B = v, t, p
	elseif i == 1 then
		new_RGB.R, new_RGB.G, new_RGB.B = q, v, p
	elseif i == 2 then
		new_RGB.R, new_RGB.G, new_RGB.B = p, v, t
	elseif i == 3 then
		new_RGB.R, new_RGB.G, new_RGB.B = p, q, v
	elseif i == 4 then
		new_RGB.R, new_RGB.G, new_RGB.B = t, p, v
	else
		new_RGB.R, new_RGB.G, new_RGB.B = v, p, q
	end

	return RGB:new(new_RGB)
end

--返回HSL对象
function HSV:toHSL() --TODO: direct conversion
	local RGB = self:toRGB()
	return RGB:toHSL()
end

--返回颜色字符串
function HSV:toStr(mode)
	return self:toRGB():toStr(mode)
end



return Colour
