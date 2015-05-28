-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2015, Intelibo Ltd                             --
--                                                                   --
-- Project:       LOS                                                --
-- Filename:      env.lua                                            --
-- Description:   Creates lua environment for .lospec execution      --
--                                                                   --
-----------------------------------------------------------------------

local lfs        = require "lrun.util.lfs"
local config     = require "lrun.util.config"
local string     = require "lrun.util.string"
local table      = require "lrun.util.table"

module ("los.env", package.seeall)

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
	"loadfile"
}

local function loader(env, lospec)
	local f, err = loadfile(lospec)
	if not f then
		return nil, err
	end
	setfenv(f, env)
	setfenv(1, env)
	use "api"
	print("loading "..lospec)
	f()
end

local requirestack = {}

function requires(pckname, version)
	print("requires "..pckname.." "..(version or ""))

	local lospecdir = lfs.concatfilenames(config.get(_conf, "dir.lospec"), pckname)
	if not lfs.isdir(lospecdir) then
		return nil, lospecdir.." doesn't exists"
	end
	local lospec
	if not version then
		local lospecs = {}
		for file in lfs.dir(lospecdir) do
			if lfs.ext(file) == ".lospec" and string.starts(file, pckname.."-", 1) then
				table.insert(lospecs, file)
			end
		end
		if #lospecs == 0 then
			return nil, "No .lospecs found for `"..pckname.."'"
		end
		table.sort(lospecs)
		lospec = lospecs[#lospecs]
		string.gsub(lospec, "[^%-]*%-(.-)%.lospec", function (v)
			version = v
		end)
		lospec = lfs.concatfilenames(lospecdir, lospec)
	else
		lospec = lfs.concatfilenames(lospecdir, pckname.."-"..version..".lospec")
	end
	if not lfs.isfile(lospec) then
		return nil, lospec.." not found"
	end

	for _, pck in ipairs(requirestack) do
		if pck[1] == pckname then
			return nil, "Requires loop error on `"..pckname.."'"
		end
	end
	table.insert(requirestack, {pckname, version})

	-- prepare environment
	local env = {}
	for _, f in ipairs(API) do
		env[f] = _G[f]
	end
	for i, f in pairs(API) do
		if type(i) == "string" then
			env[i] = f
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
	loader(env, lospec)
	package.lospec = package.lospec or {}
	package.lospec[pckname] = package.lospec[pckname] or {}
	package.lospec[pckname][version] = env
	table.remove(requirestack)
	return env
end

return _M
