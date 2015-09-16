-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2015, Intelibo Ltd                             --
--                                                                   --
-- Project:       LOS                                                --
-- Filename:      prebuilt.lua                                       --
-- Description:   installs prebuilt binaries                         --
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
	local ret,err = build()
	if not ret then
		return nil, err
	end
	print("install")
	if type(installafter) == "function" then
		installafter()
	end
	return true
end

function make(target)

end
