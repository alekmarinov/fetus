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
local version = require "los.lospec.format.version"

local _G, assert, type, string =
      _G, assert, type, string

module "los.lospec.format.package"

function parse(pack)
	if type(pack.name) ~= "string" then
		return nil, "name field is mendatory string"
	end
	if type(pack.version) ~= "string" then
		return nil, "version field is mendatory string"
	end
	pack.name = string.lower(pack.name)
	pack.version = version.parse(pack.version)
	pack.source = config.subst(_G._conf, pack.source)
	return pack
end
