-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2015, Intelibo Ltd                             --
--                                                                   --
-- Project:       LOS                                                --
-- Filename:      requies.lua                                        --
-- Description:   Finds and load lospec                              --
--                                                                   --
-----------------------------------------------------------------------

local lfs        = require "lrun.util.lfs"
local config     = require "lrun.util.config"
local string     = require "lrun.util.string"
local table      = require "lrun.util.table"
local lospec     = require "los.lospec"

local API =
{
	"os", -- temp
	"getfenv",
	"setfenv",
	"package",
	"require",
	"print",
	"pairs",
	"ipairs",
	["string"] = string,
	["table"] = table,
	["lfs"] = lfs,
	["config"] = config,
	"_conf",
	"type",
	"assert",
	"loadfile"
}

local function loader(env, lospecfile)
	local f, err = loadfile(lospecfile)
	if not f then
		return nil, err
	end
	setfenv(f, env)
	setfenv(1, env)
	use "api"
	print("loading "..lospecfile)
	f()
end

local requirestack = {}

function requires(pckname, version)
	print("requires "..pckname.." "..(version or ""))

	-- locates lospec file definition
	local lospecfile, versionorerr = lospec.findfile(pckname, version)
	if not lospecfile then
		return nil, err
	end
	version = versionorerr

	-- avoid require loop
	for _, pck in ipairs(requirestack) do
		if pck[1] == pckname then
			return nil, "Requires loop error on `"..pckname.."'"
		end
	end
	table.insert(requirestack, {pckname, version})

	-- prepare environment
	local env = {}
	for i, f in pairs(API) do
		if type(i) == "string" then
			env[i] = f
		else
			env[f] = _G[f]
		end
	end
	env.use = function (usable)
		local filename = lfs.concatfilenames(config.get(_conf, "dir.usable"), usable..".lua")
		print("Using "..usable.." from "..filename)
		local f, err = loadfile(filename)
		if not f then
			return nil, err
		end
		setfenv(f, env)
		f()
	end
	env.requires = function (...)
		return assert(requires(...))
	end
	loader(env, lospecfile)
	package.lospec = package.lospec or {}
	package.lospec[pckname] = package.lospec[pckname] or {}
	package.lospec[pckname][version] = env
	table.remove(requirestack)
	return env
end

return requires
