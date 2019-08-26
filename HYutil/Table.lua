---------------------------------------------
-- TABLE ------------------------------------
---------------------------------------------
--v1.0

local table = table
--兼容5.1
table.unpack = table.unpack or unpack
--表排序
--mode:"reverse"or"random" （翻转，随机）
--offset=1（偏移值） （比如mode="reverse"，offset=1, {1,2,3,4} -> {4,3,2,1}） （mode="reverse"，offset=2, {1,2,3,4} -> {3,4,1,2}）
--assign（true:给原始对象赋值 返回原对象 ，false:返回新对象 原对象不变）
function table:sort2(mode, offset, assign) --> table obj/new_obj
	assert(offset ~= 0, "offset cannot = 0 !")
	offset = math.abs(offset) or 1

	local function shuffleNum(num) --打乱数字
		local num_arr = {}
		for i = 1, num do
			num_arr[i] = i
		end
		for i = #num_arr, 1, -1 do
			local index = math.random(1, #num_arr)
			local num_tmp = num_arr[i]
			num_arr[i] = num_arr[index]
			num_arr[index] = num_tmp
		end
		return num_arr
	end

	local function tblReverse(offset) --反向计算
		local tbl = {}
		for index=#self, 1, -offset do
			local t = {}
			for i=1, offset do
				local diff = index-offset+i
				if diff < 1 then break end
				t[i] = self[diff]
			end
			tbl[#tbl+1] = t
		end
		if #tbl[#tbl] == 0 then
			rem = math.fmod(#self, offset)
			for i=1, rem do
				tbl[#tbl][i] = self[i]
			end
		end
		return tbl
	end

	local function tblForward(offset) --正向计算
		local tbl = {}
		for index=1, #self, offset do
			local t = {}
			for i=1, offset do
				local diff = index+i-1
				if index+offset-1 > #self then break end
				t[i] = self[diff]
			end
			tbl[#tbl+1] = t
		end
		if #tbl[#tbl] == 0 then
			rem = math.fmod(#self, offset)
			for i=1, rem do
				tbl[#tbl][i] = self[#self-rem+i]
			end
		end
		return tbl
	end

	local function tblRandom(tbl_func, offset) --乱序重排
		local tbl = tbl_func(offset)
		local num_arr = shuffleNum(#tbl)
		local tbl_random = {}
		for i=1,#self do
			tbl_random[i] = tbl[num_arr[i]]
		end
		return tbl_random
	end

	local function tblOut(tbl) --输出最终表
		local Tbl = {}
		for _, t in ipairs(tbl) do
			for _, v in ipairs(t) do
				Tbl[#Tbl+1] = v
			end
		end
		return Tbl
	end

	local self_sort
	if mode == "reverse" then --反向输出
		local tbl = tblReverse(offset)
		self_sort = tblOut(tbl)
	elseif mode == "random" then --乱序输出
		local tbl = tblRandom(tblForward, offset)
		self_sort = tblOut(tbl)
	else
		return self
	end

	if assign then
		for k, v in ipairs(self_sort) do
			self[k] = v
		end
		return self
	else
		for k,v in pairs(self) do
			if type(k) ~= "number" then
				self_sort[k] = v
			end
		end
		local mt = getmetatable(self)
		setmetatable(self_sort,mt)
		return self_sort
	end

end

--表深拷贝 返回新对象
function table:clone() --> table new_obj
    local lookup_table = {}
    local function copy(self)
        if type(self) ~= "table" then
            return self
        elseif lookup_table[self] then
            return lookup_table[self]
        end
        local new_table = {}
        lookup_table[self] = new_table
        for key, value in pairs(self) do
            new_table[copy(key)] = copy(value)
        end
        return setmetatable(new_table, getmetatable(self))
    end
    return copy(self)
end



return table
