-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2015, Intelibo Ltd                             --
--                                                                   --
-- Project:       LRun                                               --
-- Filename:      table.lua                                          --
-- Description:   table utilities                                    --
--                                                                   --
-----------------------------------------------------------------------

local assert, type, pairs, ipairs, string, coroutine, tostring, setmetatable, loadstring, table, select, math =
      assert, type, pairs, ipairs, string, coroutine, tostring, setmetatable, loadstring, table, select, math

module "lrun.util.table"

-- http://www.lua.org/pil/19.3.html
function pairsbykeys(t, f)
	local a = {}
	for n in pairs(t) do insert(a, n) end
	sort(a, f)
	local i = 0      -- iterator variable
	local iter = function ()   -- iterator function
		i = i + 1
		if a[i] == nil then
			return nil
		else
			return a[i], t[a[i]]
		end
	end
	return iter
end

-- http://www.lua.org/pil/9.3.html
function permutator(a)
	local function permgen (a, n)
		if n == 0 then
			coroutine.yield(a)
		else
			for i=1,n do
				-- put i-th element as the last one
				a[n], a[i] = a[i], a[n]

				-- generate all permutations of the other elements
				permgen(a, n - 1)

				-- restore i-th element
				a[n], a[i] = a[i], a[n]
			end
		end
	end
	local n = #a
	local co = coroutine.create(function () permgen(a, n) end)
	return function ()   -- iterator
		local code, res = coroutine.resume(co)
		return res
	end
end

function deepconcat(t)
	for i, v in ipairs(t) do
		if type(v)=="table" then
			t[i]=deepconcat(v)
		end
	end
	return concat(t)
end

-- recursive table copy
function deepcopy(t1, t2, refs)
	refs=refs or {}
	t2=t2 or {}
	refs[t1]=t2
	for i,v in pairs(t1) do
		if type(i) == "table" then
			if refs[i] then
				i=refs[i]
			else
				i=deepcopy(i, {}, refs)
			end
		end
		if type(v) == "table" then
			if refs[v] then
				-- cyclic reference
				t2[i]=refs[v]
			else
				t2[i]=deepcopy(v, {}, refs)
			end
		else
			t2[i]=v
		end
	end
	return t2
end

function deepcomp(t1, t2)
	if type(t1) ~= type(t2) then
		return false
	end
	if type(t1) ~= "table" then
		return t1 == t2
	else
		local keys = {}

		for i, v in pairs(t1) do
			keys[i] = true
		end

		for i, v in pairs(t2) do
			keys[i] = true
		end

		for k in ipairs(keys) do
			local res = deepcomp(t1[k], t2[k])
			if not res then
				return false
			end
		end

		return true
	end
end

-- non-recursive table copy
function fastcopy(t1, t2)
	t2 = t2 or {}
	for i,v in pairs(t1) do
		t2[i]=v
	end
	return t2
end

----------------------------------------------------------------------------
-- Serializes a table.
-- @param tab Table representing the session.
-- @param outf Function used to generate the output.
-- @param ind String with indentation pattern.
-- @param pre String with indentation prefix.
----------------------------------------------------------------------------
function serialize(tab, outf, ind, pre)
	----------------------------------------------------------------------------
	-- Serializes a value.
	----------------------------------------------------------------------------
	local function serialize_value(v, outf, ind, pre)
		local t = type (v)
		if t == "string" then
			outf (string.format ("%q", v))
		elseif t == "number" then
			outf (tostring(v))
		elseif t == "boolean" then
			outf (tostring(v))
		elseif t == "table" then
			serialize(v, outf, ind, pre)
		else
			outf (string.format ("%q", tostring(v)))
		end
	end

	if type(tab) ~= "table" then
		return serialize_value(tab, outf)
	end

	local sep_n, sep, _n = ",\n", ", ", "\n"
	if (not ind) or (ind == "") then ind = ""; sep_n = ", "; _n = "" end
	if not pre then pre = "" end
	outf ("{")
	local p = pre..ind
	-- prepare list of keys
	local keys = { boolean = {}, number = {}, string = {} }
	local total = 0
	for key in pairs (tab) do
		total = total + 1
		local t = type(key)
		if t == "string" then
			insert (keys.string, key)
		else
			keys[t][key] = true
		end
	end
	local many = total > 5
	if not many then sep_n = sep; _n = " " end
	outf (_n)
	-- serialize entries with numeric keys
	if many then
		local _f,_s,_v = ipairs(tab)
		if _f(_s,_v) then outf (p) end
	end
	local num = keys.number
	local ok = false
	-- entries with automatic index
	for key, val in ipairs (tab) do
		serialize_value (val, outf, ind, p)
		outf (sep)
		num[key] = nil
		ok = true
	end
	if ok and many then outf (_n) end
	-- entries with explicit index
	for key in pairs (num) do
		if many then outf (p) end
		outf ("[")
		outf (key)
		outf ("] = ")
		serialize_value (tab[key], outf, ind, p)
		outf (sep_n)
	end
	-- serialize entries with boolean keys
	local tr = keys.boolean[true]
	if tr then
		outf (string.format ("%s[true] = ", many and p or ''))
		serialize_value (tab[true], outf, ind, p)
		outf (sep_n)
	end
	local fa = keys.boolean[false]
	if fa then
		outf (string.format ("%s[false] = ", many and p or ''))
		serialize_value (tab[false], outf, ind, p)
		outf (sep_n)
	end
	-- serialize entries with string keys
	sort (keys.string)
	for _, key in ipairs (keys.string) do
		outf (string.format ("%s[%q] = ", many and p or '', key))
		serialize_value (tab[key], outf, ind, p)
		outf (sep_n)
	end
	if many then outf (pre) end
	outf ("}")
end
----------------------------------------------------------------------------

function deserialize(s)
	local f, err = loadstring("return "..s)
	if f then
		return f()
	end
	return nil, err
end

function makestring(tab)
	if type(tab) == "table" then
		local t = {}
		serialize(tab, function (s)
			table.insert(t, s)
		end)
		return concat(t)
	else
		return tostring(tab)
	end
end

--[[
function ipairsall(...)
	local tables = {...}
	local tabiter = ipairs(tables)
	local tab
	tabiter, _, tab = tabiter(tables, 1)
	local i, k, v
	return function()
		if tabiter then
			if not i then
				i, k, v = ipairs(tab, 1)
			end
			while not k do
				_, tab, next = tabiter(next)
				k, v, n = ipairs(tab)
			end
			return k, v
		end
	end
end
--]]

function ipairsall(...)
	local alltabs = {...}
	local iall = ipairs(alltabs)
	local ktab, tab = iall(alltabs, 0)
	local k, i, v = 0
	return function()
		while tab do
			if not i then
				i = ipairs(tab)
			end
			k, v = i(tab, k)
			if k then
				return tab, k, v
			end
			ktab, tab = iall(alltabs, ktab)
			i = nil
			k = 0
		end
	end
end

function pairsall(...)
	local alltabs = {...}
	local iall = pairs(alltabs)
	local ktab, tab = iall(alltabs, nil)
	local k, i, v
	return function()
		while tab do
			if not i then
				i = pairs(tab)
			end
			k, v = i(tab, k)
			if k then
				return tab, k, v
			end
			ktab, tab = iall(alltabs, ktab)
			i = nil
			k = nil
		end
	end
end

function indexof(t, val)
	for i,v in pairs(t) do
		if v == val then
			return i
		end
	end
end

function indexofi(t, val)
	for i,v in ipairs(t) do
		if v == val then
			return i
		end
	end
end

function elementiterator(t)
	local iter = ipairs(t)
	local k = -1
	return function ()
		k = k + 1
		return select(2, iter(t, k))
	end
end

function reverse(t)
	local m = math.floor(#t/2)
	for i = 1, m do
		t[i], t[#t-i+1] = t[#t-i+1], t[i]
	end
	return t
end

function keys(t, issort)
	local keyset = {}
	for k in pairs(t) do
		table.insert(keyset, k)
	end
	if issort then
		table.sort(keyset)
	end
	return keyset
end

function values(t, issort)
	local valueset = {}
	for _, v in pairs(t) do
		table.insert(valueset, v)
	end
	if issort then
		table.sort(valueset)
	end
	return valueset
end

return setmetatable(_M, { __index = table} )
