-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2015, Intelibo Ltd                             --
--                                                                   --
-- Project:       LOS                                                --
-- Filename:      autotools.lua                                      --
-- Description:   build implementation with autotools                --
--                                                                   --
-----------------------------------------------------------------------

-- prebuilt api imported and working in los module environment

module "los.use.prebuilt"

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
	local packname,err = download(source)
	if not packname then
		return nil,err
	end
	local dirname = extract(packname)
	configure(dirname)
	make "all"

	if type(buildafter) == "function" then
		buildafter()
	end
	return true
end

function install()
	print("install")
	local ret,err = build()
	if not ret then
		return nit, err
	end
	make "install"
end

function make(target)
	-- lfs.execute("make "..target)
	print("make "..(target or ""))
end

