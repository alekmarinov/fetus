------------------------------------------------------------------
--																--
-- Copyright (C) 2003-2015, Intelibo Ltd						--
--																--
-- Project:       los											--
-- Filename:      init.lua										--
-- Description:   Main interface to los							--
--																--
------------------------------------------------------------------

require "logging"
require "logging.console"

local getopt      = require "alt_getopt"
local lfs         = require "lrun.util.lfs"
local config      = require "lrun.util.config"
local string      = require "lrun.util.string"
local table       = require "lrun.util.table"
local requires    = require "los.requires"
local rollback    = require "los.rollback"

local los = {}

los._NAME = "los"
los._VERSION = "0.1"
los._DESCRIPTION = "los is command line tool providing lua powered development and runtime environment"

local defaultconf = "conf/los.conf"
local appwelcome = los._NAME.." "..los._VERSION.." Copyright (C) 2003-2015 Intelibo Ltd"
local usagetext = "%s\n\nUsage: "..los._NAME.." [OPTION]... COMMAND [ARGS]..."
local usagetexthelp = "Try "..los._NAME.." --help' for more options."
local errortext = "Error: %s"
local helptext = [[
-c   --config CONFIG  config file path (default ]]..defaultconf..[[)
     --config-dump    dumps all configuration
-Dname1=value1,name2=value2,...    overwrites config definition for name
-q   --quiet          no output messages
-v   --verbose        verbose messages
-h,  --help           print this help.

where COMMAND can be one below:

install <project> [version]
]]

local longopts = {
	verbose = "v",
	help    = "h",
	quiet   = "q",
	define  = "D",
	config  = "c",
	["config-dump"] = 0
}

local shortopts = "vhqD:c:"

--- exit with usage information when the application arguments are wrong
local function usage(errmsg)
	assert(type(errmsg) == "string", "expected string, got "..type(errmsg))
	io.stderr:write(string.format(usagetext, errmsg).."\n")
	io.stderr:write(usagetexthelp.."\n")
	os.exit(1)
end

--- exit with error message
local function exiterror(errmsg)
	assert(type(errmsg) == "string", "expected string, got "..type(errmsg))
	io.stderr:write(string.format(errortext, errmsg).."\n")
	io.stderr:write(los._NAME.." FAILED!\n")
	rollback.execute()
	os.exit(1)
end

--- exit with success
local function success()
	io.stderr:write("SUCCESS!\n")
	rollback.execute()
	os.exit(0)
end

function createlogger(opts)
	local logger = logging.console("[%level] %message\n")
	if not opts.v then
		if opts.q then
			logger:setLevel(logging.FATAL)
		else
			logger:setLevel(logging.INFO)
		end
	end
	return logger
end

-----------------------------------------------------------------------
-- Entry Point --------------------------------------------------------
-----------------------------------------------------------------------

function los.main(losdir, ...)
	local args = {...}
	local ok, err

	-- parse program options
	local opts, cmdidx = getopt.get_opts(args, shortopts, longopts)

	--- load configuration
	local confpath = opts.c or lfs.concatfilenames(losdir, defaultconf)
	if not lfs.isfile(confpath) then
		exiterror("Config file `"..confpath.."' is missing")
	end

	-- create logger
	_log = createlogger(opts)

	-- load configuration
	_log:debug("Load config from "..confpath)
	_conf, err = config.load(confpath)
	if not _conf then
		exiterror(err)
	end

	-- set lospec directory relative to los root
	config.set(_conf, "dir.lospec", lfs.concatfilenames(losdir, "lospec"))

	if opts.D then
		for dname, dvalue in string.gmatch(opts.D..",", "(.-)=(.-),") do
			config.set(_conf, dname, dvalue)
		end
	end

	if opts["config-dump"] then
		for _, key in ipairs(table.values(config.keys(_conf), true)) do
			print(string.format("%30s= %s", key, config.get(_conf, key)))
		end
		print()
	end

	args = { select(cmdidx, unpack(args)) }

	local command = table.remove(args, 1)
	if not command then
		usage("Missing COMMAND parameter")
	end
	command = command:lower()
	_log:info(los._NAME.." started with `"..command.." "..table.concat(args, " ").."'")

	if #args == 0 then
		exiterror("package [version] argument is missing")
	end

	local lomod, err = requires(unpack(args))
	if not lomod then
		exiterror(err)
	end

	if type(lomod[command]) ~= "function" then
		exiterror("command "..command.." is not supported by "..args[1])
	end

	_, ok, err = xpcall(function()
		local ok, err = lomod[command](lomod)
	end, function(err) exiterror(debug.traceback(err, 2)) end)

	if not ok and err then
		exiterror(err)
	end

	return success()
end

return los
