-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2015, Intelibo Ltd                             --
--                                                                   --
-- Project:       LOS                                                --
-- Filename:      autotools.lua                                      --
-- Description:   build implementation with autotools                --
--                                                                   --
-----------------------------------------------------------------------

function configure(dirname)
	
end

function build()
	print("build")
	if __dependencies then
		print("install dependencies")
		for _, pck in ipairs(__dependencies) do
			pck:install()
		end
	end
	local packname = download(source)
	local dirname = extract(packname)
	configure(dirname)
	make "all"

	if type(buildafter) == "function" then
		buildafter()
	end
end

function install()
	print("install")
	build()
	make "install"
end

function make(target)
	-- lfs.execute("make "..target)
	print("make "..(target or ""))
end
