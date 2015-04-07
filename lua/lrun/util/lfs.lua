-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2015, Intelibo Ltd                             --
--                                                                   --
-- Project:       LRun                                               --
-- Filename:      lfs.lua                                            --
-- Description:   LRun extension to Lua File System                  --
--                                                                   --
-----------------------------------------------------------------------

local string       = require "string"
local table        = require "table"
local io           = require "io"
local os           = require "os"
local lfs          = require "lfs"

local assert, type, setfenv, loadfile, tonumber, ipairs, pcall, rawget, setmetatable =
      assert, type, setfenv, loadfile, tonumber, ipairs, pcall, rawget, setmetatable

local print = print

-----------------------------------------------------------------------
-- class definition ---------------------------------------------------
-----------------------------------------------------------------------
module "lrun.util.lfs"

buffersize = 131072

-----------------------------------------------------------------------
-- public interface ---------------------------------------------------
-----------------------------------------------------------------------

local _cache = {}

-- OS detection utilities
-----------------------------
function osname()
	if _cache.osname then
		return _cache.osname
	end
	local rc = nil
	local function haspopen()
		if rawget(io, "popen") then
			local ok, retval= pcall( io.popen, "echo 1" )  -- "protected call" (= don't nag to user)
			if ok and retval then
				retval:read "*a"
				retval:close()
				return true
			end
		end
	end

	if os.getenv("WINDIR") then
		local ostype = os.getenv("OSTYPE")
		if ostype and "msys" == ostype then
			_cache.unixlike = true
			local msystem = os.getenv("MSYSTEM")
			if msystem then
				rc = "MINGW32" == msystem and "mingw32" or "msys"
			end
		end
		if not rc then
			-- to skip next tests with /bin/true
			_cache.unixlike = false
			rc = "win32"
		end
	elseif haspopen() then
		local uname
		local f = io.popen "uname"
		uname = f:read'*a'
		assert(uname, "'uname' did not work! (should have)")
		f:close()

		if string.sub( uname, -1 ) == '\n' then
			uname = string.sub( uname, 1, -2 )    -- remove terminating newline
		end

		if string.find(uname, "BSD") then         -- "NetBSD"/"FreeBSD"
			rc = "bsd"
		else
			rc = string.lower(uname)            -- "linux"/"darwin"/"qnx"
		end
	else
		-- "darwin" (if no popen)/"msys"/..
		rc = assert(os.getenv("OSTYPE"), "Unknown OS! (or 'io.popen()' not enabled)")
	end
	_cache.osname = rc
	return rc
end

function isunixlike()
	if type(_cache.unixlike) ~= "boolean" then
		if osname() == "win32" then
			_cache.unixlike = false
		elseif osname() == "darwin" then
			_cache.unixlike = true
		else
			_cache.unixlike = exists("/bin/true") and execute("/bin/true") and true or false
		end
	end
	return _cache.unixlike
end

function devnull()
	if osname() ~= "win32" then
		return "/dev/null"
	else
		return "NUL"
	end
end

-- File name utilities
-----------------------------

--- quote string
function Q(arg)
	assert(type(arg) == "string")

	return "\"" .. arg:gsub("\"", "\\\""):gsub("`", "\\`") .. "\""
end

function basename(pathname)
	assert(type(pathname) == "string")

	local base = path(pathname):match(".*/([^/]*)")
	return base or pathname
end

function dirname(pathname)
	local dir = pathname:gsub("/*$", ""):match("(.*/)[^/]*")
	return dir or ""
end

function ext(pathname)
	assert(type(pathname) == "string")

	local ext
	pathname:gsub(".*(%..+)", function (s)
		ext = s
   	end)
   	return ext
end

function stripext(pathname)
	assert(type(pathname) == "string")

	local stripped
	pathname:gsub("(.*)%.", function (s)
		stripped = s
	end)
	return stripped or pathname
end

function ospath(name)
	assert(type(name) == "string")
	if isunixlike() then
		name = string.gsub(name, "\\", "/")
	else
		name = string.gsub(name, "/", "\\")
	end
	return name
end

function path(name)
	assert(type(name) == "string")
	local name = string.gsub(name, "\\", "/")
	return name
end

function addpathsep(name)
	assert(type(name) == "string")

	if string.sub(name, -1) ~= "/" then name=name.."/" end
	return name
end

function rmpathsep(name)
	assert(type(name) == "string")

	if string.sub(name, -1) == "/" then name = string.sub(name, 1, -2) end
	return name
end

function isfullpath(name)
	assert(type(name) == "string")

	if osname() ~= "win32" then
		return name:sub(1, 1) == "/"
	else
		return name:sub(1, 1) == "\\" or name:sub(1, 1) == "/" or (name:sub(1, 1):match("%a") and name:sub(2, 2) == ":")
	end
end

function concatfilenames(...)
	local t = {}
	for _, filename in ipairs{...} do
		table.insert(t, rmpathsep(path(filename)))
	end
	return table.concat(t, "/")
end

-- File information utilities
-----------------------------

function exists(file)
	assert(type(file) == "string", "string expected, got "..type(file))

	local f = io.open(file, "rb")
	if f then
		f:close()
		return true
	end
	return false
end

function isdir(dir)
	assert(type(dir) == "string")

	local attr = attributes(rmpathsep(dir))
	return attr and attr.mode == "directory"
end

function isfile(filename)
	assert(type(filename) == "string")

	local attr = attributes(rmpathsep(filename))
	return attr and attr.mode == "file"
end

function isemptydir(d)
	if isdir(d) then
		local iter = dir(d)
		return iter and not iter()
	end
end

function filesize(filename)
	local attr, err = stat(filename)
	if not attr then
		return nil, err
	end
	if attr.mode ~= "file" then
		return nil, "Invalid file mode `"..attr.mode.."'"
	end
	return attr.size
end

function stat(filename)
	filename = rmpathsep(filename)
	local attr, err = attributes(filename)
	if not attr then
		return nil, "Cannot obtain information for "..Q(filename)
	end
	attr.accessed = os.date("%Y-%m-%d %H:%M:%S", attr.access)
	attr.modified = os.date("%Y-%m-%d %H:%M:%S", attr.modification)
	attr.changed = os.date("%Y-%m-%d %H:%M:%S", attr.change)
	return attr
end

-- Directory functions
-----------------------------

function dir(dirname, mode)
	assert(type(dirname) == "string" and dirname:len() > 0)

	dirname = rmpathsep(dirname)
	local diriter,meta = assert(lfs.dir(dirname))
	return function ()
		local entry = diriter(meta)
		while entry do
			if entry:sub(1, 1) ~= "." then
				local attr = stat(concatfilenames(dirname, entry))
				if attr and (not mode or attr.mode == mode) then
					return entry, attr
				end
			end
			entry = diriter(meta)
		end
	end
end

function dirtree(dirname)
	assert(dirname and dirname ~= "", "directory parameter is missing or empty")

	dirname = rmpathsep(dirname)
	local diriter = assert(lfs.dir(dirname))
	local ok, err = diriter()
	if not ok then
		return nil, err
	end

	local diriters = {diriter}
	local dirs = {dirname}

	return function()
		repeat
			local entry = diriters[#diriters]()
			if entry then
				if entry:sub(1, 1) ~= "." then
					local filename = table.concat(dirs, "/").."/"..entry
					local attr = attributes(filename)
					if attr.mode == "directory" then
						table.insert(dirs, entry)
						table.insert(diriters, lfs.dir(filename))
					end
					return filename, attr
				end
			else
				table.remove(dirs)
				table.remove(diriters)
			end
		until #diriters==0
	end
end

-- File system utilities
-----------------------------

function mkdir(dir)
--[[
	assert(type(dir) == "string")
	if isunixlike() then
		return execute("mkdir -p", ospath(dir))
	else
		return execute("md", ospath(dir))
	end
--]]
	dir = path(dir)
	if not isdir(dir) then
		if isfile(dir) then
			return false, "Not a directory path `"..dir.."' already exists"
		end
		if not lfs.mkdir(dir) then
			local dirstack = {dir}
			dir = dirname(dir)
			while dir:len() > 0 and not (isdir(dir) or lfs.mkdir(dir)) do
				table.insert(dirstack, 1, dir)
				dir = dirname(dir)
			end
			for _, d in ipairs(dirstack) do
				lfs.mkdir(d)
			end
		end
	end
	return true
end

function delete(filename)
	assert(type(filename) == "string")

	if isunixlike() then
		return execute("rm -rf", ospath(filename))
	else
		if isdir(filename) then
			return execute("rd /s /q", ospath(filename))
		else
			os.remove(filename)
		end
	end
	return true
end

function copy(src, dst)
	assert(type(src) == "string")
	assert(type(dst) == "string")

	if isunixlike() then
		return execute("cp -rf", ospath(src), ospath(dst))
	else
		if isfile(src) then
			return execute("copy /B /Y", ospath(src), ospath(dst))
		else
			return execute("xcopy /H /R /Q /E /I", ospath(src), ospath(dst))
		end
	end
end

function move(src, dst)
	assert(type(src) == "string")
	assert(type(dst) == "string")
	if osname() ~= "win32" then
		return execute("mv", ospath(src), ospath(dst))
	else
		if dst:sub(2, 2) == ":" and (src:sub(2, 2) ~= ":" or string.lower(src:sub(1, 1)) ~= string.lower(dst:sub(1, 1))) then
			-- change drive assumed, do move by copy + delete src
			local ok, err = copy(src, dst)
			if not ok then
				return false, err
			end
			ok, err = delete(src)
			if not ok then
				return false, err
			end
		else
			return rename(src, dst)
		end
	end
	return true
end

rename = os.rename

function link(src, dst)
	assert(type(src) == "string")
	assert(type(dst) == "string")

	if osname() ~= "win32" then
		return execute("ln -s", src, dst)
	else
		return copy(src, dst)
	end
	return true
end

function diskspaceusage(drive)
	assert(type(drive) == "string")
	if osname() ~= "win32" then
		local fd, err = pipe("/bin/df", drive)
		if not fd then
			return nil, err
		end
		local lastline
		for line in fd:lines() do
			lastline = line
		end
		fd:close()

		local used, available
		if lastline then
			string.gsub(lastline, "%s+(%d+)%s+(%d+)%s+%d+%%%s", function (u, a)
				used, available = tonumber(u), tonumber(a)
			end)
		end
		return used, available or "Can't parse memory usage from `"..(lastline or "").."'"
	end
	return nil, osname().." is not supported yet"
end

-- Process control utilities
-----------------------------
function packargs(command, ...)
	assert(type(command) == "string")

	for _, arg in ipairs{...} do
		assert(type(arg) == "string")
		command = command .. " " .. Q(arg)
	end
	return command
end

function execute(command, ...)
	command = packargs(command, ...)
	local code = os.execute(command)
	if code ~= 0 then
		return false, "Error code="..code.." by `"..command.."'"
	end
	return true
end

function pipe(command, ...)
	command = packargs(command, ...)
	return io.popen(command.." 2>&1")
end

function execout(command, outf, ...)
	--if osname() ~= "win32" then
		local out = {}
		command = packargs(command, ...)
		local fd, err = io.popen(command.." 2>&1")
		if not fd then
			return false, "Error executing `"..command.."' -> `"..(err or "").."'"
		end
		for line in fd:lines() do
			outf(line)
		end
		fd:close()
	--[[
	else
		command = packargs(command, ...)
		local fd,err = lfs.popen(command)
		if not fd then
			return false, "Error executing `"..command.."' -> `"..(err or "").."'"
		end
		while true do
			line = lfs.pread(fd)
			if not line then break end
			outf(line)
		end
		lfs.pclose(fd)
	end
	--]]
	return true
end

function kill(name)
	if osname() ~= "win32" then
		return execute("killall "..name.." 2> /dev/null")
	end
	return false, "kill is not supported under "..osname()
end

function kill9(name)
	if osname() ~= "win32" then
		return execute("killall -9 "..name.." 2> /dev/null")
	end
	return false, "kill9 is not supported for "..osname()
end

function isprocess(name)
	local rc = false
	execout("ps -A | grep "..Q(name), function () rc = true end)
	return rc
end

-- Mounting device utilities
-----------------------------

function mount(src, dst)
	assert(type(src) == "string")
	assert(type(dst) == "string")

	if osname() ~= "win32" then
		if not exists(dst) then
			local ok, err = mkdir(dst)
			if not ok then
				return false, err
			end
		end
		return execute("mount", src, dst)
	else
		return false, "mount is not supported for "..osname()
	end
end

function umount(dst)
	assert(type(dst) == "string")

	if osname() ~= "win32" then
		return execute("umount -l", dst)
	else
		return false, "umount is not supported for "..osname()
	end
end

function mounts(mntpfx)
	assert(not mntpfx or type(mntpfx) == "string")

	if osname() ~= "win32" then
		local pipe, err = io.popen("mount")
		if not pipe then
			return nil, err
		end
		local mountiter = pipe:lines()
		return function ()
			local amount = mountiter()
			while amount do
				amount = string.gsub(amount, ".* on (%S+)(%s.*)", "%1")
				if not mntpfx or amount:sub(1, mntpfx:len()) == mntpfx then
					return amount
				end
				amount = mountiter()
			end
		end
	else
		return nil, "mounts is not supported for "..osname()
	end
end

function umountall(mntpfx)
	assert(type(mntpfx) == "string")

	if osname() ~= "win32" then
		local mountiter, err = mounts(mntpfx)
		if not mountiter then
			return false, err
		end
		for amount in mountiter do
			umount(amount)
		end
		return true
	else
		return false, "umountall is not supported for "..osname()
	end
end

function ismount(dst)
	assert(type(dst) == "string")

	if osname() ~= "win32" then
		if mounts(dst)() then
			return true
		end
		return false, dst.." is not mounted"
	else
		return false, "ismount is not supported for "..osname()
	end
end

-- Lua utilities
-----------------------------

function loadlua(filename, state)
	if exists(filename) then
		local chunk, err = loadfile(filename)
		if not chunk then
			return nil, err
		end
		state = state or {}
		setfenv(chunk, state)
		return state, chunk()
	else
		return nil, "Lua file `"..filename.."' is missing"
	end
end

function islua(filename)
	if not exists(filename) then
		return false, "File `"..filename.."' is missing"
	end
	local chunk, err = loadfile(filename)
	if not chunk then
		return false, err
	end
	return true
end

return setmetatable(_M, { __index = lfs })
