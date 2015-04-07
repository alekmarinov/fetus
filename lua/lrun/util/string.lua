-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2015, Intelibo Ltd                             --
--                                                                   --
-- Project:       LRun                                               --
-- Filename:      string.lua                                         --
-- Description:   string utilities                                   --
--                                                                   --
-----------------------------------------------------------------------

local table = require "table"
local setmetatable, string, _tostring, type, assert, ipairs, pairs =
      setmetatable, string, _tostring, type, assert, ipairs, pairs

module ("lrun.util.string", package.seeall)

function empty(str)
	return str and string.len(str) == 0
end

function trimempty(str)
	return empty(trim(str))
end

function starts(str, s, casesense)
	if casesense then 
		return string.sub(str, 1, string.len(s)) == s
	else
		return string.lower(string.sub(str, 1, string.len(s))) == string.lower(s)
	end
end

function ends(str, e, casesense)
	if casesense then 
		return string.sub(str, -string.len(e)) == e
	else
		return string.lower(string.sub(str, -string.len(e))) == string.lower(e)
	end
end

function subst(s, tab, rexp)
	return string.gsub(s, rexp or "%$%((.-)%)", function(name) return tab[name] end)
end

local function fromarray(a)
	local s=""
	for i,v in ipairs(a) do
		if string.len(s)>0 then 
			s=s..","
		end
		s=s..tostring(v)
	end
	return "{"..s.."}"
end

local function fromtable(tab, fields)
	local s=""
	if tab then
		if fields then
			for i, field in ipairs(fields) do 
				if i>1 then
					s=s..","
				end
				local value=tab[field]
				s=s..field.."="..(value and (type(value) == "table" and value.tostring and value:tostring()) or tostring(value) or "nil")
			end
		else
			if #tab>0 then 
				return fromarray(tab)
			else
				for name, value in pairs(tab) do 
					if string.len(s)>0 then
						s=s..","
					end
					s=s..name.."="..(value and (type(value) == "table" and value.tostring and value:tostring()) or tostring(value) or "nil")
				end
			end
		end
	end
	return "{"..s.."}"
end

function tostring(v, order)
	if type(v)=="table" then 
		return fromtable(v, order)
	end
	return _tostring(v)
end

function explode(str, sep)
	local tab = {}
	string.gsub(sep..str, sep.."([^"..sep.."]*)", function (e)
		table.insert(tab, e)
	end)
	return tab
end

function trimleft(str)
	assert(type(str) == "string", "string expected, got "..type(str))
	str = string.gsub(str, "^%s*(.*)", "%1")
	return str
end

function trimright(str)
	assert(type(str) == "string", "string expected, got "..type(str))
	str = string.gsub(str, "(.-)%s*$", "%1")
	return str
end

function trim(str)
	return trimright(trimleft(str))
end

return setmetatable(getfenv(), { __index = string })
