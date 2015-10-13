-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2015, Intelibo Ltd                             --
--                                                                   --
-- Project:       LOS                                                --
-- Filename:      package.lua                                        --
-- Description:   parses lospec package format                       --
--                version parsing functions are gracefully           --
--                "borrowed" from luarock.deps                       --
--                                                                   --
-----------------------------------------------------------------------

local config  = require "lrun.util.config"
local version = require "los.lospec.version"

local _G, assert, type, string, pairs =
      _G, assert, type, string, pairs

module "los.lospec.package"

local function confsubst(t)
	for k in pairs(t) do
		if type(t[k]) == "string" then
			t[k] = config.subst(_G._conf, t[k])
		elseif type(t[k]) == "table" then
			confsubst(t[k])
		end
	end
end

function parse(pack)
	if type(pack.name) ~= "string" then
		return nil, "name field is mendatory string"
	end
	if type(pack.version) ~= "string" then
		return nil, "version field is mendatory string"
	end
	pack.name = string.lower(pack.name)
	pack.version = version.parse(pack.version)
	confsubst(pack)
	return pack
end
