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
local rollback    = require "los.rollback"
local loader      = require "los.lospec.loader"
local chroot      = require "los.command.chroot"

require "los.requires"

los._NAME = "los"
los._VERSION = "0.1"
los._DESCRIPTION = "los is command line tool providing lua powered development and runtime environment"

local defaultconf = "conf/los.conf"
local appwelcome = los._NAME.." "..los._VERSION.." Copyright (C) 2003-2015 Intelibo Ltd"
local usagetext = "%s\n\nUsage: "..los._NAME.." [OPTION]... COMMAND [ARGS]..."
local usagetexthelp = "Try "..los._NAME.." --help' for more options."
local errortext = "Error: %s"
local helptext = [[
-c   --config CONFIG    config file path (default ]]..defaultconf..[[)
     --config-dump      dumps all configuration
     --config-get name  prints the value of specified configuration name
-Dname1=value1,name2=value2,...    redefine configuration definitions
-e   --execute        executes lua file or script in los context
-q   --quiet          no output messages
-v   --verbose        verbose messages
-h,  --help           print this help.

where COMMAND can be one below:

install { "<project1> [version_spec]" [-options] ...}
]]

local longopts = {
	verbose = "v",
	help    = "h",
	quiet   = "q",
	define  = "D",
	config  = "c",
	execute = "e",
	["config-dump"] = 0,
	["config-get"] = 1
}

local shortopts = "vhqD:c:e:"

--- exit with usage information when the application arguments are wrong
local function usage(errmsg)
	assert(type(errmsg) == "string", "expected string, got "..type(errmsg))
	io.stderr:write(string.format(usagetext, errmsg).."\n")
	io.stderr:write(usagetexthelp.."\n")
	os.exit(1)
end

--- show help and exit
local function help()
	io.stderr:write(helptext.."\n")
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
local function exitsuccess()
	io.stderr:write("SUCCESS!\n")
	rollback.execute()
	os.exit(0)
end

--- exit with specified status
local function exitstatus(ok, err)
	if ok then
		exitsuccess()
	else
		exiterror(err)
	end
end

function createlogger(opts)
	local logger = logging.console("[%level] %message\n")
	-- avoid output "changing loglevel from DEBUG to FATAL"
	logger.level = nil
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

	-- search for los-local.conf in etc/ or any parent, ../etc, ../../etc and so on
	local parentdir = losdir
	while string.len(parentdir) > 0 do
		local localconf = lfs.concatfilenames(parentdir, "etc/los-local.conf")
		if lfs.isfile(localconf) then
			_log:debug("Load local config from "..localconf)
			config.load(localconf, _conf)
		end
		parentdir = lfs.dirname(parentdir)
	end

	-- set lospec directory relative to los root
	config.set(_conf, "dir.lospec", lfs.concatfilenames(losdir, "lospec"))

	if opts.D then
		for dname, dvalue in string.gmatch(opts.D..",", "(.-)=(.-),") do
			config.set(_conf, dname, dvalue)
		end
	end

	if opts.h then
		help()
	end

	if opts["config-dump"] then
		for _, key in ipairs(table.values(config.keys(_conf), true)) do
			print(string.format("%30s= %s", key, config.get(_conf, key)))
		end
		print()
	end

	if opts["config-get"] then
		print(config.get(_conf, opts["config-get"]))
		os.exit(0)
	elseif opts.e then
		local chunk, err
		if lfs.isfile(opts.e) then
			chunk, err = loadfile(opts.e)
		else
			chunk, err = load(function() local temp = opts.e opts.e = nil return temp end)
		end
		if not chunk then
			exiterror(err)
		else
			setfenv(chunk, _G)
			_, ok, err = xpcall(function()
				chunk()
			end, function(err) exiterror(debug.traceback(err, 2)) end)
			if not ok and err then
				exiterror(err)
			end
			os.exit(0)
		end
	end

	args = { select(cmdidx, unpack(args)) }

	local command = table.remove(args, 1)
	if not command then
		usage("Missing COMMAND parameter")
	end
	command = command:lower()

	if command == "list" then
		for _, name in ipairs(loader.list(args[1])) do
			print(name)
		end
		os.exit(0)
	elseif command == "chroot" then
		exitstatus(chroot.execute())
	end

	_log:info(los._NAME.." started with `"..command.." "..table.concat(args, " ").."'")

	if #args == 0 then
		exiterror("package [version] argument is missing")
	end

	local lomods = {}
	local i = 1
	while i <= #args do
		local dep = args[i]
		local lomod, err = los.requires(dep)
		if not lomod then
			exiterror(err)
		end
		local lomodargs = {lomod}
		while i + 1 <= #args and string.starts(args[i + 1], "-") do
			table.insert(lomodargs, args[i + 1])
			i = i + 1
		end
		i = i + 1
		table.insert(lomods, lomodargs)
	end

	for _, lomodargs in ipairs(lomods) do
		local lomod = table.remove(lomodargs, 1)
		if type(lomod[command]) ~= "function" then
			exiterror("command "..command.." is not supported by "..dep)
		end

		xpcall(function()
			ok, err = lomod[command](unpack(lomodargs))
			if not ok and err then
				error(err)
			end
		end, function(err)
			_log:error(command.." "..lomod.package.name.." "..lomod.package.version.string.." "..table.concat(lomodargs, " ").." failed")
			exiterror(debug.traceback(err, 2))
		end)
	end

	exitsuccess()
end

return los
