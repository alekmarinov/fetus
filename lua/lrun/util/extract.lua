----------------------------------------------------------------------
--                                                                  --
-- Copyright (C) 2003-2015, Intelibo Ltd                            --
--                                                                  --
-- Project:       LRun                                              --
-- Filename:      extract.lua                                       --
-- Description:   Implements file extraction utilities              --
--                                                                  --
----------------------------------------------------------------------

local lfs    = require "lrun.util.lfs"
local gzip   = require "luagzip"
local zip    = require "luazip"
local string = require "lrun.util.string"

module ("lrun.util.extract", package.seeall)

BUFSIZE = 8192

local function transfer(fdin, fdout)
	local buf = fdin:read(BUFSIZE)
	while buf do
		fdout:write(buf)
		buf = fdin:read(BUFSIZE)
	end
end

function gunzip(infile, outfile)
	assert(type(infile) == "string", "expected string, got "..type(infile))
	assert(type(outfile) == "string", "expected string, got "..type(outfile))

	local fdin, err = gzip.open(infile)
	if not fdin then
		return nil, err
	end
	local fdout, err = io.open(outfile, "wb")
	if not fdout then
		return nil, err
	end
	transfer(fdin, fdout)
	fdin:close()
	fdout:close()
	return true
end

function unzip(infile, outdir)
	assert(type(infile) == "string", "expected string, got "..type(infile))
	if outdir then
		assert(type(outdir) == "string", "expected string, got "..type(outdir))
	end

	local zfd, err = zip.open(infile)
	if not zfd then
		return nil, err
	end
	for file in zfd:files() do
		if file.filename:sub(-1) ~= "/" then
			local fdin, err = zfd:open(file.filename)
			if not fdin then
				return nil, err
			end
			local ok, err = lfs.mkdir(lfs.concatfilenames(outdir, lfs.dirname(file.filename)))
			if not ok then
				return nil, err
			end
			local fdout, err = io.open(lfs.concatfilenames(outdir, file.filename), "wb")
			if not fdout then
				return nil, err
			end
			transfer(fdin, fdout)
			fdin:close()
			fdout:close()
		end
	end
	return true
end

function unarch(archive, dir)
	assert(type(archive) == "string", "expected string, got "..type(archive))
	assert(type(dir) == "string", "expected string, got "..type(dir))
	local resdir

	archive = lfs.path(archive)
	dir = lfs.path(dir)

	-- change current drive and directory
	local function CD(dir)
		if dir:sub(2, 2) == ":" then
			-- drive letter assummed
			return dir:sub(1,2).." && cd "..lfs.Q(dir)
		end
		return "cd "..lfs.Q(dir)
	end

	if string.ends(archive, ".tar.gz") then
		resdir = archive:sub(1, -string.len(".tar.gz")-1)
		cmd = CD(dir).." && gzip -d -c "..lfs.ospath(lfs.Q(archive)).." 2> "..lfs.devnull().." | tar -xvf - 1> "..lfs.devnull().." 2> "..lfs.devnull()
	elseif string.ends(archive, ".tgz")  then
		resdir = archive:sub(1, -string.len(".tgz")-1)
		cmd = CD(dir).." && gzip -d -c "..lfs.ospath(lfs.Q(archive)).." 2> "..lfs.devnull().." | tar -xvf - 1> "..lfs.devnull().." 2> "..lfs.devnull()
	elseif string.ends(archive, ".tar.bz2") then
		resdir = archive:sub(1, -string.len(".tar.bz2")-1)
		cmd = CD(dir).." && bzip2 -d -c "..lfs.ospath(lfs.Q(archive)).." 2> "..lfs.devnull().." | tar -xvf - 1> "..lfs.devnull().." 2> "..lfs.devnull()
	elseif string.ends(archive, ".zip") then
		resdir = archive:sub(1, -string.len(".zip")-1)
		cmd = "unzip -qq -o "..lfs.path(lfs.Q(archive)).." -d "..lfs.path(lfs.Q(dir)).." 2> "..lfs.devnull()
	elseif string.ends(archive, ".lzma") then
		return nil, "Archive type "..lfs.Q(archive).." is not supported yet"
	else
		return nil, "Unknown archive in "..lfs.Q(archive)
	end
	if os.execute(cmd) ~= 0 then
		return nil, "Error unarchiving file "..lfs.Q(archive)
	end
	return lfs.concatfilenames(resdir)
end
