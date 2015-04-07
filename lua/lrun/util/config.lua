-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2015, Intelibo Ltd                             --
--                                                                   --
-- Project:       LRun                                               --
-- Filename:      config.lua                                         --
-- Description:   Configuration utility module                       --
--                                                                   --
-----------------------------------------------------------------------

local table = require "lrun.util.table"
local lfs   = require "lrun.util.lfs"
local error, assert, type, pairs, ipairs, tonumber, tostring, string, io, os, rawget, rawset, getmetatable =
      error, assert, type, pairs, ipairs, tonumber, tostring, string, io, os, rawget, rawset, getmetatable

local print = print

-----------------------------------------------------------------------
-- class definition ---------------------------------------------------
-----------------------------------------------------------------------
module "lrun.util.config"

-----------------------------------------------------------------------
-- local constants ----------------------------------------------------
-----------------------------------------------------------------------
local keypattern = "%w_%-/"

-----------------------------------------------------------------------
-- private functions --------------------------------------------------
-----------------------------------------------------------------------

--
-- validates a key if conforms key pattern
--
local function validatekey(key)
	assert(string.match(key, "["..keypattern.."]+"),
		   "invalid config key ("..tostring(key)..")")
end

--
-- substitute variable
--
local function subst(conftab, s, history)
	local c
	repeat
		s, c = string.gsub(s, "(%$%b())", function(key)
			key = key:sub(3, -2)
			while key:find("%$%(") do
				key = subst(conftab, key, history)
			end
			return get(conftab, "user."..key, false, history) or get(conftab, key, false, history)
		end)
	until c == 0
	return s
end

-----------------------------------------------------------------------
-- public methods -----------------------------------------------------
-----------------------------------------------------------------------

local function doget(conftab, key, nosubst, history)
	validatekey(key)
	local t = conftab
	local value
	for w in string.gfind(key, "["..keypattern.."]+") do
		t = rawget(t, w)
		if not t then 
			break
		end
	end
	local value = type(t)=="string" and (not nosubst and subst(conftab, t, history)) or t
	value = tonumber(value) or value
	if not value then
		local mt = getmetatable(conftab)
		if mt and mt.__index then
			if type(mt.__index) == "table" then
				value = doget(mt.__index, key, nosubst, history)
			end
		end
	end
	return value
end

--
-- get configuration property value
--
function get(conftab, key, nosubst, history)
	history = history or {}
	for i, v in ipairs(history) do
		if v == key then
			return ""
		end
	end
	table.insert(history, key)

	-- TODO: consider adding external command result, e.g. $(exec pwd)
	local value = os.getenv(key) or doget(conftab, "user."..key, nosubst, history)
	if type(value) == "nil" then
		value = doget(conftab, key, nosubst, history)
	end
	return value
end

--
-- get configuration property number
--
function getnumber(conftab, key)
	local value = get(conftab, key)
	return assert(tonumber(value), "value of "..key.." "..(value and "`"..tostring(value).."'" or "nil").." is not a number")
end

--
-- set configuration property value
--
function set(conftab, key, value)
	validatekey(key)
	local t = conftab
	for w in string.gfind(key, "(["..keypattern.."]+)%.") do
		rawset(t, w, rawget(t, w) or {})
		t = rawget(t, w)
		-- t[w] = t[w] or {}  -- create table if absent
		--t = t[w]           -- get the table
	end
	local w = string.gsub(key, "["..keypattern.."]+%.", "")    -- get last field key
	-- t[w] = value
	rawset(t, w, value)
end

--
-- remove configuration property
--
function remove(conftab, key)
	validatekey(key)
	set(conftab, key, nil)
end

--
-- load configuration from file
--
function load(storage, conftab, prefix)
	local lineiter, err
	if type(storage) == "string" then
		if not lfs.exists(storage) then
			return nil, "File `"..storage.."' does not exists"
		end
		lineiter = io.lines(storage)
		if not lineiter then
			return nil, "can't open `"..storage.."' for reading"
		end
	elseif type(storage) == "table" then
		lineiter = table.elementiterator(storage)
	else
		error("Storage type `"..type(storage).." is not supported")
	end
	if type(conftab) == "string" then
		conftab = nil
		prefix = conftab
	end
	assert(type(conftab) == "nil" or type(conftab) == "table", "optional 2nd argument must be table, got "..type(conftab))
	conftab = conftab or {}
	assert(type(prefix) == "nil" or type(prefix) == "string", "optional 3rd argument must be string, got "..type(prefix))
	prefix = prefix and prefix.."." or ""

	for line in lineiter do
		line = string.gsub(line, "(%-%-.*)", "")
		line = string.gsub(line, "^%s*(.-)%s*$", "%1")
		line = string.gsub(line, "\\(.)", "%1")
		if line:len() > 0 then
			string.gsub(line, "(.-)=(.*)", function (n, v)
				if string.sub(v, -1) == "\n" or string.sub(v, -1) == "\r" then
					v = string.sub(v, 1, -2)
				end
				set(conftab, prefix..n, tonumber(v) or v)
			end)
		end
	end
	return conftab
end

--
-- save configuration to file
--
function save(conftab, key, storage)
	if not storage then
		storage = key
		key = nil
	end
	local tab, tabkeys = {},{}
	local function maketable(k)
		local t = ((not k or k == "") and conftab) or get(conftab, k, true)
		if type(t) == "table" then
			for i,v in pairs(t) do
				if k then
					maketable(k.."."..i)
				else
					maketable(i)
				end
			end
		else
			table.insert(tabkeys, k)
			tab[k] = tostring(t)
		end
	end
	local function makekey(k)
		if key then
			return string.sub(k, 2+key:len())
		end
		return k
	end
	local function makeval(v)
		v = string.gsub(v, "\\", "\\\\")
		return v
	end
	maketable(key)
	table.sort(tabkeys)
	if type(storage) == "string" then
		local fd = io.open(storage, "w")
		if not fd then
			return nil, "Can't write to file "..storage
		end
		for _, k in ipairs(tabkeys) do
			fd:write(makekey(k).."="..makeval(tab[k]).."\n")
		end
		fd:close()
	elseif type(storage) == "table" then
		for _, k in ipairs(tabkeys) do
			table.insert(storage, makekey(k).."="..makeval(tab[k]).."\n")
		end
	elseif type(storage) == "nil" then
		local buf = {}
		for _, k in ipairs(tabkeys) do
			table.insert(buf, makekey(k).."="..makeval(tab[k]).."\n")
		end
		storage = table.concat(buf)
	end
	return storage
end
