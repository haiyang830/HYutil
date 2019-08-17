---------------------------------------------
-- MATH -------------------------------------
---------------------------------------------
--作为对lua math库的补充
local math = math

--float数值对比
function math.fCompar(a, mode, b, eps) --> bool floatCompar
	local function sgn(num, eps)
		local eps = eps or 1e-8 --精度
		if num < -eps then return -1
		elseif num < eps then return 0
		else return 1
		end
	end
	if mode == "==" then return sgn(a - b) == 0
	elseif mode == "~=" then return sgn(a - b) ~= 0
	elseif mode == "<" then return sgn(a - b) < 0
	elseif mode == "<=" then return sgn(a - b) <= 0
	elseif mode == ">" then return sgn(a - b) > 0
	elseif mode == ">=" then return sgn(a - b) >= 0
	else return error("wrong mode!")
	end
end

--直角三角形的斜边长
function math.hypot(a, b) --> number hypot
	if a == 0 and b == 0 then return 0 end
	a, b = math.abs(a), math.abs(b)
	a, b = math.max(a, b), math.min(a, b)
	return a * math.sqrt(1 + (b / a) ^ 2)
end

--四舍五入
function math.round(x)
	return math.floor(x + 0.5)
end

--数字大小限制
function math.clamp(num, clamp_min, clamp_max)
	clamp_min = clamp_min or -math.huge
	clamp_max = clamp_max or math.huge
	return  math.min(math.max(num, clamp_min), clamp_max)
end



return math
