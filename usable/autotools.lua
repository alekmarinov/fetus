-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2015, Intelibo Ltd                             --
--                                                                   --
-- Project:       LOS                                                --
-- Filename:      autotools.lua                                      --
-- Description:   build implementation with autotools                --
--                                                                   --
-----------------------------------------------------------------------

local function make(srcdir, target)
	local cmd = "mingw32-make"
	if target then
		cmd = cmd.." "..target
	end
	print("making ", target)
	return lfs.execute("cd "..lfs.Q(srcdir).." && "..cmd)
end

function configure(dirname)
	print("configure in "..dirname)
	return lfs.execute("cd "..lfs.Q(dirname).." && ./configure")
end

function build()
	print("build")
	if __dependencies then
		print("install dependencies")
		for _, pck in ipairs(__dependencies) do
			pck:install()
		end
	end
	local packname, err = download(source)
	if not packname then
		return nil, err
	end
	local dirname, err = extract(packname)
	if not dirname then
		return nil, err
	end
	local ok, err = configure(dirname)
	if not ok then
		return nil, err
	end
	ok, err = make(dirname, "all")
	if not ok then
		return nil, err
	end

	if type(buildafter) == "function" then
		buildafter()
	end

	return true
end

function install()
	print("install")
	return make(srcdirfromurl(source), "install")
end

