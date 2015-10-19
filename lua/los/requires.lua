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
local loader     = require "los.lospec.loader"
local version    = require "los.lospec.version"
local events     = require "los.events"

local _G, ipairs, pairs, type, package, tostring, assert, error =
	  _G, ipairs, pairs, type, package, tostring, assert, error

-- debug
local print = print

module "los"

local requirestack = {}

-- loads los module specified by dependency description
-- returns the loaded module as a table and its environment
-- @param depstring: string representation of dependency, e.g. "foo >= 1.2, foo < 2"
function requires(depstring)
	_G._log:info(_NAME..": "..depstring)
	local dep, err = version.parsedep(depstring)
	if not dep then
		_G._log:error(_NAME..": "..(err or "can't parse "..depstring))
		return nil, err
	end

	-- locates lospec file definition by required dependency description
	local lospecfile, versionorerr = loader.findfile(dep)
	if not lospecfile then
		_G._log:error(_NAME..": "..(err or "can't find lospec for "..depstring))
		return nil, versionorerr
	end
	local ver = versionorerr
	_G._log:info(_NAME..": loading "..lospecfile)

	-- avoid require loop
	for _, pck in ipairs(requirestack) do
		if pck.name == dep.name then
			error(_NAME..": ".."Requires loop error on `"..pck.name.."'")
		end
	end
	table.insert(requirestack, dep)

	-- loads lospec as module
	local lomod, err = loader.loadfile(lospecfile)
	if not lomod then
		_G._log:error(_NAME..": "..err)
		return nil, err
	end

	-- register requires function to los module environment
	lomod.requires = requires

	-- executes los module
	local ok, err = loader.exec(lomod)
	if not ok then
		_G._log:error(_NAME..": "..err)
		return nil, err
	end

	events.trigger("requires", lomod)

	-- remove from require stack
	table.remove(requirestack)

	return lomod
end

