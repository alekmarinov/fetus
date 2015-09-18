-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2015, Intelibo Ltd                             --
--                                                                   --
-- Project:       LOS                                                --
-- Filename:      prebuilt.lua                                       --
-- Description:   installs prebuilt binaries                         --
--                                                                   --
-----------------------------------------------------------------------

-- prebuilt api imported and working in los module environment

function configure()

end

function build()
	log.i("build")
	local packname, err = download(path.src.url)
	if not packname then
		return nil, err
	end
	local dirname = unarch(packname)

	if type(buildafter) == "function" then
		buildafter()
	end

	return true
end

function install()
	local ret, err = build()
	if not ret then
		return nil, err
	end
	log.i("install")
	if type(installafter) == "function" then
		installafter()
	end
	return true
end
